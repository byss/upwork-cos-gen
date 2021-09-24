import Foundation

public protocol UserDefaultsCodable {
	init (from defaults: UserDefaults, key: String);
	func encode (to defaults: UserDefaults, key: String);
}

@propertyWrapper
public struct Defaults <T> where T: UserDefaultsCodable {
	public var wrappedValue: T {
		get { T (from: self.defaults, key: self.key) }
		nonmutating set { newValue.encode (to: self.defaults, key: self.key) }
	}
	
	internal var isEmpty: Bool { self.defaults.object (forKey: self.key) == nil }
	
	private let key: String;
	
	@UserDefaultsReference
	private var defaults: UserDefaults;
	
	internal init (_ defaults: UserDefaults = .standard, key: String) {
		(self._defaults, self.key) = (.init (wrapped: defaults), key);
	}
}

@propertyWrapper
private struct UserDefaultsReference {
	private final class Wrapper {
		private struct Instance {
			fileprivate unowned var reference: Wrapper;
		}
		
		private static var instances = [String: Instance] ();
		
		fileprivate static func wrapping (_ defaults: UserDefaults) -> Wrapper {
			let suiteName = defaults.suiteName, result: Wrapper;
			if let existing = self.instances [suiteName]?.reference {
				result = existing;
			} else {
				result = Wrapper (defaults);
				self.instances [suiteName] = .init (reference: result);
			}
			return result;
		}
		
		fileprivate let wrapped: UserDefaults;
		
		private init (_ wrapped: UserDefaults) {
			self.wrapped = wrapped;
		}
		
		deinit {
			self.wrapped.synchronize ();
			Self.instances [self.wrapped.suiteName] = nil;
		}
	}
	
	fileprivate var wrappedValue: UserDefaults { self.wrapper.wrapped }
	
	private let wrapper: Wrapper;
	
	fileprivate init (wrapped: UserDefaults) {
		self.wrapper = .wrapping (wrapped);
	}
}

private protocol BuiltinUserDefaultsCodable: UserDefaultsCodable {
	static var getter: (UserDefaults) -> (String) -> Self? { get };
	static var setter: (UserDefaults) -> (Self?, String) -> () { get };
	init ();
}

/* internal */ extension BuiltinUserDefaultsCodable {
	public init (from defaults: UserDefaults, key: String) {
		self = Self.getter (defaults) (key) ?? Self ();
	}
	
	public func encode (to defaults: UserDefaults, key: String) {
		Self.setter (defaults) (self, key);
	}
}

extension String: BuiltinUserDefaultsCodable {
	fileprivate static let getter = UserDefaults.string;
	fileprivate static let setter: (UserDefaults) -> (String?, String) -> () = UserDefaults.set;
}

/* fileprivate */ extension UserDefaults {
	private static let suiteNameOffset = class_getInstanceVariable (UserDefaults.self, "_identifier_").map (ivar_getOffset) !! "Cannot find offset for \(UserDefaults.self)._identifier_";
	
	fileprivate var suiteName: String {
		UnsafePointer <CFString> (bitPattern: unsafeBitCast (self, to: Int.self) + Self.suiteNameOffset)?.pointee as String? ?? ""
	}
}
