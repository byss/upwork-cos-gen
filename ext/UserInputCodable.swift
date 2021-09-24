import Foundation

public protocol UserInputCodable {
	init? (userInput: String);
	func encodeAsUserInput () -> String;
}

extension UserInputCodable where Self: CustomStringConvertible {
	public func encodeAsUserInput () -> String { self.description }
}

extension UserInputCodable where Self: LosslessStringConvertible {
	public init? (userInput: String) {
		self.init (userInput);
	}
}

extension UserInputCodable where Self: RawRepresentable, RawValue: UserInputCodable {
	public init? (userInput: String) {
		guard
			let rawValue = RawValue (userInput: userInput) else {
			return nil;
		}
		self.init (rawValue: rawValue);
	}
	
	public func encodeAsUserInput () -> String { self.rawValue.encodeAsUserInput () }
}

extension Decimal: UserInputCodable {
	public init? (userInput: String) {
		self.init (string: userInput, locale: .posix);
	}
}

extension Int: UserInputCodable {}
extension String: UserInputCodable {}

extension Date: UserInputCodable {
	public static var userInputFormatter: DateFormatter = {
		let result = DateFormatter ();
		result.calendar = .init (identifier: .gregorian);
		result.locale = .posix;
		result.timeZone = .init (secondsFromGMT: 0);
		result.dateFormat = "yyyyMMdd";
		return result;
	} ();
	
	public init? (userInput: String) {
		guard !userInput.isEmpty, let result = Self.userInputFormatter.date (from: userInput) else {
			return nil;
		}
		self = result;
	}
	
	public func encodeAsUserInput () -> String { Self.userInputFormatter.string (from: self) }
}

@propertyWrapper
public struct UserInput <T> where T: UserInputCodable {
	public var wrappedValue: T {
		mutating get { self.wrappedValueStorage ?? self.storeWrappedValue () }
	}
	
	fileprivate var isEmpty: Bool { self.wrappedValueStorage == nil }
	
	private let prompt: String;
	private let envKey: String?;
	private let `default`: () -> T?;
	private let userInteractionAllowed: Bool;
	private var wrappedValueStorage: T?;
	
	public init (prompt: String, envKey: String? = nil, default: @escaping @autoclosure () -> T? = nil) {
		(self.prompt, self.envKey, self.default) = (prompt, envKey, `default`);
		self.userInteractionAllowed = !ProcessInfo ().environment ["COS_NON_INTERACTIVE"].boolValue;
	}
	
	private mutating func storeWrappedValue () -> T {
		let `default` = self.getDefaultValue ();
		if (self.userInteractionAllowed) {
			return self.readUserInput (default: `default`);
		} else {
			return `default`!;
		}
	}
	
	private func getDefaultValue () -> T? {
		if let result = `default` () {
			return result;
		} else if let envKey = self.envKey, let rawValue = ProcessInfo ().environment [envKey], let result = T (userInput: rawValue) {
			return result;
		} else if (self.userInteractionAllowed) {
			return nil;
		} else if let envKey = self.envKey {
			fatalError ("\(envKey) is not set in non-interactive mode");
		} else {
			fatalError ("\(self.prompt) may only be entered manually");
		}
	}
	
	private mutating func readUserInput (default: T?) -> T {
		while (true) {
			print ("\(self.prompt)", terminator: "");
			if let `default` = `default` {
				print (" [\(`default`.encodeAsUserInput ())]", terminator: "");
			}
			print (": ", terminator: "");
			let userInput = readLine ()  !! "Unexpected end of input";
			guard let result = userInput.isEmpty ? `default` : T (userInput: userInput) else {
				continue;
			}
			self.wrappedValueStorage = result;
			return result;
		}
	}
}

@propertyWrapper
public struct StoredUserInput <T> where T: UserDefaultsCodable, T: UserInputCodable {
	public var wrappedValue: T {
		mutating get {
			let shouldStore = self.userInput.isEmpty;
			let result = self.userInput.wrappedValue;
			if (shouldStore) {
				self.defaults.wrappedValue = result;
			}
			return result;
		}
	}
	
	private let defaults: Defaults <T>;
	@Lazy
	private var userInput: UserInput <T>;
	
	public init (_ defaults: UserDefaults = .standard, key: String, prompt: String, envKey: String? = nil) {
		let defaults = Defaults <T> (defaults, key: key);
		self.defaults = defaults;
		self._userInput = Lazy (wrappedValue: UserInput (prompt: prompt, envKey: envKey, default: defaults.isEmpty ? nil : defaults.wrappedValue));
	}
}

/* fileprivate */ extension Locale {
	fileprivate static let posix = Locale (identifier: "POSIX");
}

/* fileprivate */ extension Optional where Wrapped == String {
	fileprivate var boolValue: Bool { (self as NSString?)?.boolValue ?? false }
}
