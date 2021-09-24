import AppKit.NSGraphicsContext

public typealias NSGraphicsContext = AppKit.NSGraphicsContext;

/* public */ extension NSGraphicsContext {
	public func setCurrentAndPerform (_ actions: (NSGraphicsContext) -> ()) {
		let prevContext = Self.current;
		if (prevContext !== self) {
			Self.current = self;
		}
		
		actions (self);
		
		switch (prevContext) {
		case nil, self: break;
		case .some (let context): Self.current = context;
		}
	}
}

/* public */ extension CGContext {
	public func setCurrentAndPerform (_ actions: (CGContext) -> ()) {
		let prevContext = NSGraphicsContext.current;
		if (prevContext?.cgContext !== self) {
			NSGraphicsContext.current = .init (cgContext: self, flipped: false);
		}
		
		actions (self);
		
		if (prevContext?.cgContext !== self) {
			NSGraphicsContext.current = prevContext;
		}
	}
}
