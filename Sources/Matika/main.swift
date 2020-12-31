import Foundation
import Gtk
import GLibObject

extension WidgetProtocol {
    /// Syntactic sugar for creating UI in the code. Provides reference to the instance in provided block and as a return type to allow chaining.
    public func apply(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }
}

/// Filters string in text buffer to remove non-number non "-" character.
func filterNonNumbers(bufferRef: EntryBufferRef, arg1: UInt, arg2: String, arg3: UInt) {
    if let current = bufferRef.text {
        current.unicodeScalars.enumerated().compactMap { 
            CharacterSet.decimalDigits.union(CharacterSet(["-"])).contains($0.element) ? nil : $0.offset
        }.reversed().forEach {
            _ = bufferRef.deleteText(position: $0, nChars: 1)
        }
    }
}

/// Application model for exercise. Some features (such as accessible list of exercises) are not used by the implementation.
final class AppModel {
    enum Exercise {
        case addition(lhs: Int, rhs: Int, userInput: Int?)
        case substraction(lhs: Int, rhs: Int, userInput: Int?)

        /// String formated for the UI
        var string: String {
            switch self {
            case let .addition(lhs, rhs, _):
                return "\(lhs)   +   \(rhs) = "
            case let .substraction(lhs, rhs, _):
                return  "\(lhs)   -   \(rhs) = "
            }
        }

        /// Returns copy of `self` with difference user input. 
        func with(userInput: Int) -> Exercise {
            switch self {
            case let .addition(lhs, rhs, _):
                return .addition(lhs: lhs, rhs: rhs, userInput: userInput) 
            case let .substraction(lhs, rhs, _):
                return .substraction(lhs: lhs, rhs: rhs, userInput: userInput) 
            }
        }

        /// Returns true if computation is correct.
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

    /// Returns new exercise.
    private func makeNewExercise() -> Exercise {
        let lhs = (min...max).randomElement() ?? min
        let rhs = (min...max).randomElement() ?? max

        if rand() % 2 == 0 {
            return .addition(lhs: lhs, rhs: rhs, userInput: nil)
        } else {
            return .substraction(lhs: lhs, rhs: rhs, userInput: nil)
        }
    }

    /// Lower bound of interval for exercise generation
    private(set) var min: Int = 10

    /// Upper bound of interval for exercise generation
    private(set) var max: Int = 200

    /// List of past exercises
    private(set) var exercises = [Exercise]()

    /// Current exercise
    private(set) lazy var currentExercise: Exercise = makeNewExercise()

    /// Number of correctly answered exercises 
    var numberOfCorrect: Int { exercises.lazy.filter(\.isSuccess).count }

    /// Number of incorrectly answered exercises
    var numberOfFailed: Int { exercises.lazy.filter(\.isFailure).count }

    /// Changes the lower an upper bound of interval for exercise generation, immediately changes current exercise.
    func adjust(min: Int, max: Int) {
        self.min = min
        self.max = max
        currentExercise = makeNewExercise()
    }

    /// Passes result to the current exercise, return true if correctly answered, immediately sets new exercise.
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