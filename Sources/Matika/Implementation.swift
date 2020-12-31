import Foundation
import Gtk
import GLibObject

/// Base class for Widnow instance holders. WindowModel should deallocate only when the referenced Window instance is being deallocated.
class WindowModel {

    /// Weak referene to window
    @GWeak var window: WindowRef! = nil

    /// Observer which keeps strong reference to `self`. This observer is disposed when window is being deallocated.
    private var observer: AnyObject? = nil

    /// Initializes and shows the window. Function `make(window:)` is called by this initializer.
    /// - Parameters window: By default, `.topLevel` window is initialized. In case the instance represents main window, pass the window as an argument.
    @discardableResult
    init(window: Window = Window(type: .toplevel)) {
        // Creating instance of WindowRef from Window which is passed to the weak property wrapper
        self.window = .unowned(window)

        // This closure captures strong reference to self which is released when window instance is deallocated.
        self.observer = window.addWeakObserver { _ in _ = self }  
        
        self.make(window: window)

        window.onDeleteEvent { [weak self] _, _ -> Bool in
            self?.windowWillClose()
            return false
        }

        self.windowWillOpen()
        window.showAll()
    }

    /// This method is called in order to fill window with widgets. This method is ment to be overriden.
    func make(window: Window) { }

    /// This method is called after window is constructed immediately before `showAll()` is called. This method is ment to be overriden.
    func windowWillOpen() { }

    /// This method is called when window close event raised before window closes. This method is ment to be overriden.
    func windowWillClose() { }

}

/// Class representing root window. 
final class RootWindow: WindowModel {

    /// Reference to state of the application.
    private let appModel = AppModel()

    /// Reference to setting window (if exists)
    private var settingWindow: SettingsWindow?

    // UI Elements

    private lazy var exerciseLabel = Label(text: "").apply { widget in
        widget.setWidthChars(nChars: 20)
    }

    private lazy var entry = Entry().apply { widget in 
        widget.setWidthChars(nChars: 5)
        widget.setMaxLength(max: 5)
        widget.onKeyPressEvent { [weak self] _, press -> Bool in
            if press.hardwareKeycode == 36 {
                self?.computeEvent()
            }
            return false
        }
        widget.buffer.onInsertedText(handler: filterNonNumbers(bufferRef:arg1:arg2:arg3:))
    }

    private lazy var solveButton = Button(label: "Check!").apply { widget in 
        widget.onClicked { [weak self] _ in self?.computeEvent()}
    }

    private lazy var correctLabel = Label(text: "")
    private lazy var incorrectLabel = Label(text: "")

    private lazy var settings = Button(label: "Preferences").apply { widget in
        widget.onClicked { [weak self] _ in self?.didClickSettings() }
    }

    override func make(window: Window) {
        super.make(window: window)

        let grid = Grid.init()
        grid.halign = .center
        grid.valign = .center

        grid.columnSpacing = 10
        grid.rowSpacing = 10
        
        grid.attach(child: exerciseLabel,   left: 0, top: 0, width: 3, height: 1)
        grid.attach(child: entry,           left: 3, top: 0, width: 1, height: 1)
        grid.attach(child: solveButton,     left: 4, top: 0, width: 1, height: 1)
        grid.attach(child: correctLabel,    left: 0, top: 1, width: 2, height: 1)
        grid.attach(child: incorrectLabel,  left: 2, top: 1, width: 2, height: 1)
        grid.attach(child: settings,        left: 4, top: 1, width: 1, height: 1)

        window.add(widget: grid)
    }

    override func windowWillOpen() {
        super.windowWillOpen()

        updateState()
    }

    /// Calling this function will look at current state of the app model and update the window to reflect the state.
    private func updateState() {
        exerciseLabel.text = appModel.currentExercise.string
        correctLabel.text = "Correct: \(appModel.numberOfCorrect)"
        incorrectLabel.text = "Failed: \(appModel.numberOfFailed)"
    }

    /// Function called from inside of onClicked signal when Check button is clicked or enter was pressed. This window will pass user input to app model and update.
    private func computeEvent() {
        guard let input = Int(entry.text) else {
            return
        }

        entry.text = ""
        _ = appModel.solved(with: input)
        updateState()
    }

    /// This function is called from inside of onClicked signal when Settings button is clicked. If settings window is opened, main window shall be insensitive.
    private func didClickSettings() {
        guard settingWindow == nil else { return }
        window.set(sensitive: false)
        settingWindow = SettingsWindow(model: appModel) { [weak self] in
            self?.settingWindow = nil
            self?.updateState()
            self?.window.set(sensitive: true)
        } modelUpdated: { [weak self] in
            self?.updateState()
        }
    }
}

/// Class representing Setting window. 
final class SettingsWindow: WindowModel {

    /// Close handler is called to inform, that window is being closed.
    private var closeHandler: ()->()

    /// Update handler is called whenever app model was changed.
    private var modelUpdated: (()->())?

    private let appModel: AppModel

    // UI Elements
    
    private lazy var minLabel = Label(text: "Minimal value: ")

    private lazy var minEntry = Entry().apply { widget in 
        widget.setWidthChars(nChars: 4)
        widget.setMaxLength(max: 4)
        widget.buffer.onInsertedText(handler: filterNonNumbers(bufferRef:arg1:arg2:arg3:))
        widget.onChanged { [weak self] _ in
            self?.checkValidity()
        }
    }

    private lazy var maxLabel = Label(text: "Maximal value: ")

    private lazy var maxEntry = Entry().apply { widget in 
        widget.setWidthChars(nChars: 4)
        widget.setMaxLength(max: 4)
        widget.buffer.onInsertedText(handler: filterNonNumbers(bufferRef:arg1:arg2:arg3:))
        widget.onChanged { [weak self] _ in
            self?.checkValidity()
        }
    }

    private lazy var applybutton = Button(label: "Apply").apply { widget in
        widget.onClicked { [weak self] _ in
            self?.applyPressed()
        }
    }

    /// Custom initializer which receives reference to AppModel and two handlers.
    /// - Parameter handler: this closure is called when window closes
    /// - Parameter modelUpdated: this closure is called whenever app model is changed.
    init(model: AppModel, handler: @escaping ()->(), modelUpdated: (()->())? = nil) {
        self.closeHandler = handler
        self.modelUpdated = modelUpdated
        self.appModel = model
        super.init()
    }

    override func make(window: Window) {
        super.make(window: window)

        let grid = Grid.init()
        grid.halign = .center
        grid.valign = .center

        grid.columnSpacing = 10
        grid.rowSpacing = 10
        
        grid.attach(child: maxLabel,    left: 0, top: 0, width: 1, height: 1)
        grid.attach(child: maxEntry,    left: 1, top: 0, width: 1, height: 1)
        grid.attach(child: minLabel,    left: 0, top: 1, width: 1, height: 1)
        grid.attach(child: minEntry,    left: 1, top: 1, width: 1, height: 1)
        grid.attach(child: applybutton, left: 1, top: 2, width: 1, height: 1)

        window.add(widget: grid)
    }

    /// During call of this method, intial state is set to the window.
    override func windowWillOpen() {
        super.windowWillOpen()
        minEntry.text = "\(appModel.min)"
        maxEntry.text = "\(appModel.max)"
        checkValidity()
    }

    /// This method calls close handler.
    override func windowWillClose() {
        super.windowWillClose()

        closeHandler()
    }

    /// This method checks, whether user input is valid and apply button shall be sensitive.
    private func checkValidity() {
        if let min = Int(minEntry.text), let max = Int(maxEntry.text), min < max {
            applybutton.set(sensitive: true)
        } else {
            applybutton.set(sensitive: false)
        }
    }

    /// Callback of apply button. Modifies app model and calls model update handler.
    private func applyPressed() {
        if let min = Int(minEntry.text), let max = Int(maxEntry.text), min < max {
            appModel.adjust(min: min, max: max)
            modelUpdated?()
        }
    }

}