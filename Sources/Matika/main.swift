import Foundation
import Gtk
import GLibObject

extension WidgetProtocol {
    public func apply(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}

func filterNonNumbers(bufferRef: EntryBufferRef, arg1: UInt, arg2: String, arg3: UInt) {
    if let current = bufferRef.text {
        current.unicodeScalars.enumerated().compactMap { 
            CharacterSet.decimalDigits.union(CharacterSet(["-"])).contains($0.element) ? nil : $0.offset
        }.reversed().forEach {
            _ = bufferRef.deleteText(position: $0, nChars: 1)
        }
    }
}

final class AppModel {
    enum Exercise {
        case addition(lhs: Int, rhs: Int, userInput: Int?)
        case substraction(lhs: Int, rhs: Int, userInput: Int?)

        var string: String {
            switch self {
            case let .addition(lhs, rhs, _):
                return "\(lhs)   +   \(rhs) = "
            case let .substraction(lhs, rhs, _):
                return  "\(lhs)   -   \(rhs) = "
            }
        }

        func with(userInput: Int) -> Exercise {
            switch self {
            case let .addition(lhs, rhs, _):
                return .addition(lhs: lhs, rhs: rhs, userInput: userInput) 
            case let .substraction(lhs, rhs, _):
                return .substraction(lhs: lhs, rhs: rhs, userInput: userInput) 
            }
        }

        var isSuccess: Bool {
            switch self {
            case let .addition(lhs, rhs, input?):
                return lhs + rhs == input
            case let .substraction(lhs, rhs, input?):
                return lhs - rhs == input
            default: return false
            }
        }

        var isFailure: Bool { !isSuccess }
    }

    private func makeNewExercise() -> Exercise {
        let lhs = (min...max).randomElement() ?? min
        let rhs = (min...max).randomElement() ?? max

        if rand() % 2 == 0 {
            return .addition(lhs: lhs, rhs: rhs, userInput: nil)
        } else {
            return .substraction(lhs: lhs, rhs: rhs, userInput: nil)
        }
    }

    private(set) var min: Int = 10
    private(set) var max: Int = 200

    private(set) var exercises = [Exercise]()
    private(set) lazy var currentExercise: Exercise = makeNewExercise()

    var numberOfCorrect: Int { exercises.lazy.filter(\.isSuccess).count }
    var numberOfFailed: Int { exercises.lazy.filter(\.isFailure).count }

    func adjust(min: Int, max: Int) {
        self.min = min
        self.max = max
        currentExercise = makeNewExercise()
    }

    func solved(with value: Int) -> Bool {
        let solved = currentExercise.with(userInput: value)
        currentExercise = makeNewExercise()
        exercises.append(solved)
        return solved.isSuccess
    }
}

// MARK: - Main
let status = Application.run(startupHandler: nil) { app in
    RootWindow(window: ApplicationWindow(application: app))
}

guard let status = status else {
    fatalError("Could not create Application")
}
guard status == 0 else {
    fatalError("Application exited with status \(status)")
}