import Foundation
import CoreGraphics

/* public */ extension CGPath {
	public func encodeAsData () -> Data {
		let elements = self.elements, byteCount = elements.reduce (into: 0) { $0 += $1.byteCount };
		var result = Data (repeating: 0, count: byteCount), byteOffset = 0;
		for element in elements {
			element.writeBytes (at: byteOffset, data: &result);
			byteOffset += element.byteCount;
		}
		return result;
	}
}

public func CGPathCreateWithData (_ data: Data) -> CGPath? {
	let result = CGMutablePath ();
	var reader = data.makeReader ();
	while (!reader.isAtEnd) {
		result.add (.init (reader: &reader));
	}
	return result.copy ();
}

/* fileprivate */ extension CGPath {
	fileprivate enum Element {
		case moveToPoint (CGPoint);
		case addLineToPoint (CGPoint);
		case addQuadCurveToPoint (CGPoint, control: CGPoint);
		case addCurveToPoint  (CGPoint, control1: CGPoint, control2: CGPoint);
		case closeSubpath;
		
		fileprivate var byteCount: Int { 8 * (self.pathElementType.pointCount + 1) }
		
		private var pathElementType: CGPathElementType {
			switch (self) {
			case .moveToPoint: return .moveToPoint;
			case .addLineToPoint: return .addLineToPoint;
			case .addQuadCurveToPoint: return .addQuadCurveToPoint;
			case .addCurveToPoint: return .addCurveToPoint;
			case .closeSubpath: return .closeSubpath;
			}
		}
		
		fileprivate init (reader: inout Data.Reader) {
			let type = reader.read (CGPathElementType.self);
			let count = Int (reader.read (Int32.self));
			guard count == type.pointCount else {
				fatalError ("Invalid point count (\(count)) for type (\(type.rawValue))");
			}
			var points = [CGPoint] ();
			points.reserveCapacity (count);
			for _ in 0 ..< count {
				let x = reader.read (Float.self), y = reader.read (Float.self);
				points.append (.init (x: CGFloat (x), y: CGFloat (y)));
			}
			switch (type) {
			case .moveToPoint: self = .moveToPoint (points [0]);
			case .addLineToPoint: self = .addLineToPoint (points [0]);
			case .addQuadCurveToPoint: self = .addQuadCurveToPoint (points [1], control: points [0]);
			case .addCurveToPoint: self = .addCurveToPoint (points [2], control1: points [0], control2: points [1]);
			case .closeSubpath: self = .closeSubpath;
			@unknown default: fatalError ("Unknown type \(type.rawValue)");
			}
		}
		
		fileprivate func writeBytes (at byteOffset: Int, data: inout Data) {
			let elementType = self.pathElementType;
			var byteOffset = byteOffset;
			data.write (bytesOf: elementType.rawValue, at: &byteOffset);
			data.write (bytesOf: Int32 (elementType.pointCount), at: &byteOffset);
			switch (self) {
			case .addCurveToPoint (let point, let control1, let control2):
				data.write (bytesOf: Float (control1.x), at: &byteOffset);
				data.write (bytesOf: Float (control1.y), at: &byteOffset);
				fallthrough;
			case .addQuadCurveToPoint (let point, let control2):
				data.write (bytesOf: Float (control2.x), at: &byteOffset);
				data.write (bytesOf: Float (control2.y), at: &byteOffset);
				fallthrough;
			case .moveToPoint (let point), .addLineToPoint (let point):
				data.write (bytesOf: Float (point.x), at: &byteOffset);
				data.write (bytesOf: Float (point.y), at: &byteOffset);
			case .closeSubpath: break;
			}
		}
	}
	
	fileprivate var elements: [Element] {
		var result = [Element] ();
		self.applyWithBlock {
			let srcElem = $0.pointee;
			let dstElem: Element;
			switch (srcElem.type) {
			case .moveToPoint: dstElem = .moveToPoint (srcElem.points.pointee);
			case .addLineToPoint: dstElem = .addLineToPoint (srcElem.points.pointee);
			case .addQuadCurveToPoint: dstElem = .addQuadCurveToPoint (srcElem.points.advanced (by: 1).pointee, control: srcElem.points.pointee);
			case .addCurveToPoint: dstElem = .addCurveToPoint (srcElem.points.advanced (by: 2).pointee, control1: srcElem.points.pointee, control2: srcElem.points.advanced (by: 1).pointee);
			case .closeSubpath: dstElem = .closeSubpath;
			@unknown default: fatalError ("Unknown path element type \(srcElem.type.rawValue)");
			}
			result.append (dstElem);
		}
		return result;
	}
}

/* fileprivate */ extension CGMutablePath {
	fileprivate func add (_ element: Element) {
		switch (element) {
		case .moveToPoint (let point): self.move (to: point);
		case .addLineToPoint (let point): self.addLine (to: point);
		case .addQuadCurveToPoint (let point, let control): self.addQuadCurve (to: point, control: control);
		case .addCurveToPoint (let point, let control1, let control2): self.addCurve (to: point, control1: control1, control2: control2);
		case .closeSubpath: self.closeSubpath ();
		}
	}
}

/* fileprivate */ extension Data {
	fileprivate struct Reader {
		fileprivate var isAtEnd: Bool { self.offset >= self.data.count }
		
		private let data: Data;
		private var offset = 0;
		
		fileprivate init (data: Data) {
			self.data = data;
		}
		
		fileprivate mutating func read <T> (_ type: T.Type = T.self) -> T {
			let size = MemoryLayout <T>.stride;
			guard self.offset + size <= self.data.count else {
				fatalError ("Out of bounds");
			}
			defer { self.offset += size }
			return data.withUnsafeBytes {
				$0.load (fromByteOffset: self.offset, as: T.self);
			}
		}
	}
	
	fileprivate func makeReader () -> Reader { .init (data: self) }
	
	fileprivate mutating func write <T> (bytesOf value: T, at offset: inout Int) {
		let byteCount = MemoryLayout <T>.stride;
		guard offset + byteCount <= self.count else {
			fatalError ("Out of bounds");
		}
		self.withUnsafeMutableBytes {
			$0.storeBytes (of: value, toByteOffset: offset, as: T.self);
		}
		offset += byteCount;
	}
}

/* fileprivate */ extension CGPathElementType {
	fileprivate var pointCount: Int {
		switch (self) {
		case .moveToPoint: return 1;
		case .addLineToPoint: return 1;
		case .addQuadCurveToPoint: return 2;
		case .addCurveToPoint: return 3;
		case .closeSubpath: return 0;
		@unknown default: fatalError ("Unknown path element type \(self.rawValue)");
		}
	}
}
