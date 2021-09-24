import CoreGraphics

public enum OtherAxisAlignmment {
	fileprivate enum Axis {
		case horizontal;
		case vertical;
	}
	
	case min;
	case mid;
	case max;
	
	fileprivate func alignedKeyPath (forAxis axis: Axis) -> KeyPath <CGRect, CGFloat> {
		switch (self, axis) {
		case (.min, .horizontal): return \.minX;
		case (.mid, .horizontal): return \.midX;
		case (.max, .horizontal): return \.maxX;
		case (.min, .vertical): return \.minY;
		case (.mid, .vertical): return \.midY;
		case (.max, .vertical): return \.maxY;
		}
	}
}

/* public */ extension CGAffineTransform {
	public init (scaling source: CGRect, toFit bounds: CGRect, alignment: OtherAxisAlignmment = .mid) {
		if (source.aspectRatio < bounds.aspectRatio) {
			self.init (scaling: source, toFitHeightOf: bounds, horizontalAlignment: alignment);
		} else {
			self.init (scaling: source, toFitWidthOf: bounds, verticalAlignment: alignment);
		}
	}

	public init (scaling source: CGRect, toFitWidthOf bounds: CGRect, verticalAlignment: OtherAxisAlignmment = .mid) {
		let scale = bounds.width / source.width, keyPath = verticalAlignment.alignedKeyPath (forAxis: .vertical);
		self.init (a: scale, b: 0.0, c: 0.0, d: scale, tx: bounds.midX - source.midX * scale, ty: bounds [keyPath: keyPath] - source [keyPath: keyPath] * scale);
	}

	public init (scaling source: CGRect, toFitHeightOf bounds: CGRect, horizontalAlignment: OtherAxisAlignmment = .mid) {
		let scale = bounds.height / source.height, keyPath = horizontalAlignment.alignedKeyPath (forAxis: .horizontal);
		self.init (a: scale, b: 0.0, c: 0.0, d: scale, tx: bounds [keyPath: keyPath] - source [keyPath: keyPath] * scale, ty: bounds.midY - source.midY * scale);
	}
}

/* public */ extension CGRect {
	public var bounds: CGRect { self.offsetBy (dx: -self.minX, dy: -self.minY) }

	public func scaledToFit (_ other: CGRect, alignment: OtherAxisAlignmment = .mid) -> CGRect { self.applying (.init (scaling: self, toFit: other, alignment: alignment)) }
	public func scaledToFitWidthOf (_ other: CGRect, verticalAlignment: OtherAxisAlignmment = .mid) -> CGRect { self.applying (.init (scaling: self, toFitWidthOf: other, verticalAlignment: verticalAlignment)) }
	public func scaledToFitHeighOf (_ other: CGRect, horizontalAlignment: OtherAxisAlignmment = .mid) -> CGRect { self.applying (.init (scaling: self, toFitHeightOf: other, horizontalAlignment: horizontalAlignment)) }
}

/* fileprivate */ extension CGRect {
	fileprivate var aspectRatio: CGFloat { self.width / self.height }
}
