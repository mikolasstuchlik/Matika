import Foundation
import Gtk
import GLibObject

class WindowModel {

    @GWeak var window: WindowRef! = nil
    private var observer: AnyObject? = nil

    @discardableResult
    init(window: Window = Window(type: .toplevel)) {
        self.window = .unowned(window)
        self.observer = window.addWeakObserver { _ in _ = self }  
        
        self.make(window: window)

        window.onDeleteEvent { [weak self] _, _ -> Bool in
            self?.windowWillClose()
            return false
        }

        self.windowWillOpen()
        window.showAll()
    }

    func make(window: Window) { }
    func windowWillOpen() { }
    func windowWillClose() { }

}

final class RootWindow: WindowModel {

    private let appModel = AppModel()

    private var settingWindow: SettingsWindow?

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

    private func updateState() {
        exerciseLabel.text = appModel.currentExercise.string
        correctLabel.text = "Correct: \(appModel.numberOfCorrect)"
        incorrectLabel.text = "Failed: \(appModel.numberOfFailed)"
    }

    private func computeEvent() {
        guard let input = Int(entry.text) else {
            return
        }

        entry.text = ""
        _ = appModel.solved(with: input)
        updateState()
    }

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

final class SettingsWindow: WindowModel {

    private var closeHandler: ()->()
    private var modelUpdated: (()->())?
    private let appModel: AppModel

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

    override func windowWillOpen() {
        super.windowWillOpen()
        minEntry.text = "\(appModel.min)"
        maxEntry.text = "\(appModel.max)"
        checkValidity()
    }

    override func windowWillClose() {
        super.windowWillClose()

        closeHandler()
    }

    private func checkValidity() {
        if let min = Int(minEntry.text), let max = Int(maxEntry.text), min < max {
            applybutton.set(sensitive: true)
        } else {
            applybutton.set(sensitive: false)
        }
    }

    private func applyPressed() {
        if let min = Int(minEntry.text), let max = Int(maxEntry.text), min < max {
            appModel.adjust(min: min, max: max)
            modelUpdated?()
        }
    }

}