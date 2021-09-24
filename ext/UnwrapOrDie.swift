infix operator !!: NilCoalescingPrecedence;

public func !! <T> (lhs: () throws -> T, message: @autoclosure () -> String) -> T { unwrapThrowing (block: lhs, orDie: message) }
public func !! <T> (lhs: @autoclosure () throws -> T?, message: @autoclosure () -> String) -> T { unwrapThrowing (block: { unwrapOptional (value: try lhs (), orDie: message) }, orDie: message) }

public func unavailable (_ func: StaticString = #function) -> Never { fatalError ("\(`func`) is not available") }

private func unwrapOptional <T> (value: T?, orDie message: () -> String) -> T {
	if let value = value {
		return value;
	}
	fatalError (message ());
}

private func unwrapThrowing <T> (block: () throws -> T, orDie message: () -> String) -> T {
	do {
		return try block ();
	} catch {
		fatalError ("\(message ())\nError: \(error)");
	}
}
