@propertyWrapper
internal struct Lazy <Value> {
	private enum Storage {
		case initial (() -> Value);
		case final (Value);
			
		fileprivate var value: Value {
			mutating get {
				switch (self) {
				case .initial (let initializer):
					self.value = initializer ();
					return self.value;
				case .final (let value):
					return value;
				}
			}
			set { self = .final (newValue) }
		}
	}
	
	internal var wrappedValue: Value {
		mutating get { self.storage.value }
		set { self.storage.value = newValue }
	}

	private var storage: Storage;

	internal init (wrappedValue: @escaping @autoclosure () -> Value) {
		self.storage = .initial (wrappedValue);
	}
}
