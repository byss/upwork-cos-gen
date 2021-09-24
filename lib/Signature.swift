import ext
import Foundation
import CoreGraphics
import AppKit.NSPasteboard

internal protocol Signature {
	var identifier: String { get }

	init? (identifier: String);
	func makeTextAttachment () -> NSTextAttachment;
}

internal struct PreviewSignature: Signature {
	internal let identifier: String;
	
	internal var bounds: CGRect { self.path.boundingBoxOfPath.bounds }
	internal var imageData: Data { self.path.encodeAsData () }
	
	private let path: CGPath;
	
	internal private (set) static var identifiers: Set <String> {
		get { Set (UserDefaults.standard.array (forKey: "preview-signatures")?.compactMap { $0 as? String } ?? []) }
		set { UserDefaults.standard.set (newValue.sorted (), forKey: "preview-signatures") }
	}
	
	private static func defaultsKey (for identifier: String) -> String { "preview-signature-\(identifier)" }

	internal init? (identifier: String) {
		guard let signatureData = UserDefaults.standard.data (forKey: Self.defaultsKey (for: identifier)) else {
			return nil;
		}
		self.init (data: signatureData);
	}
	
	internal init? (pasteboard: NSPasteboard = .general) {
		guard let data = pasteboard.data (forType: .signatureAnnotation) else {
			return nil;
		}
		self.init (data: data);
	}
	
	private init? (data: Data) {
		self.init (decodingData: data);
		let defaultsKey = Self.defaultsKey (for: self.identifier);
		UserDefaults.standard.set (data, forKey: defaultsKey);
		Self.identifiers.insert (defaultsKey);
	}
	
	internal func makeTextAttachment () -> NSTextAttachment { TextAttachment (self) }
	
	private func draw (in rect: CGRect, context: CGContext) {
		context.saveGState ();
		context.concatenate (.init (scaling: self.path.boundingBoxOfPath, toFit: rect));
		context.addPath (self.path);
		context.fillPath ();
		context.restoreGState ();
	}
}

internal struct ImageSignature: Signature {
	internal let identifier: String;
	
	internal var bounds: CGRect { .init (origin: .zero, size: self.image.size) }
	
	private let image: NSImage;
	private let attachment: NSTextAttachment;
	
	internal init? (identifier: String) {
		let url = URL (fileURLWithPath: identifier);
		guard
			let image = NSImage (contentsOf: url),
			let fileWrapper = try? FileWrapper (url: url) else {
			return nil;
		}
		self.identifier = identifier;
		self.image = image;
		self.attachment = .init (fileWrapper: fileWrapper);
	}
	
	internal func makeTextAttachment () -> NSTextAttachment { self.attachment }
}

/* fileprivate */ extension PreviewSignature {
	fileprivate final class TextAttachment: NSTextAttachment {
		private let signature: PreviewSignature;
		
		fileprivate init (_ signature: PreviewSignature) {
			self.signature = signature;
			super.init (data: nil, ofType: nil);
			self.bounds = signature.bounds;
			self.image = .init (size: self.bounds.size, flipped: false) { bounds in
				NSGraphicsContext.current.map { signature.draw (in: bounds, context: $0.cgContext) } != nil
			}
		}
		
		@available (*, unavailable)
		fileprivate required init? (coder: NSCoder) { unavailable () }
		
		fileprivate override func attachmentBounds (for textContainer: NSTextContainer?, proposedLineFragment lineFrag: NSRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> NSRect {
			self.signature.bounds.scaledToFitWidthOf (lineFrag.insetBy (dx: lineFrag.width / 4.0, dy: 0.0), verticalAlignment: .max)
		}
	}
}

/* fileprivate */ extension PreviewSignature {
	@objc (KBDummy_AKSignatureAnnotation)
	private final class Annotation: NSObject, NSSecureCoding {
		fileprivate class var supportsSecureCoding: Bool { true }
		
		fileprivate let identifier: UUID;
		fileprivate let signature: Signature;
		
		fileprivate required init? (coder: NSCoder) {
			guard
				let uuidString = coder.decodeObject (of: NSString.self, forKey: "UUID"),
				let identifier = UUID (uuidString: uuidString as String),
				let signature = coder.decodeObject (of: Signature.self, forKey: "signature") else {
				return nil;
			}
			(self.identifier, self.signature) = (identifier, signature);
		}
		
		fileprivate func encode (with coder: NSCoder) {
			coder.encode (self.identifier, forKey: "UUID");
			coder.encode (self.signature, forKey: "signature");
		}
	}
	
	@objc (KBDummy_AKSignature)
	private final class Signature: NSObject, NSSecureCoding {
		fileprivate let creationDate: Date;
		fileprivate let path: CGPath;
		
		fileprivate class var supportsSecureCoding: Bool { true };
		
		fileprivate init? (coder: NSCoder) {
			guard
				let creationDate = coder.decodeObject (of: NSDate.self, forKey: "creationDate") as Date?,
				let pathData = coder.decodeObject (of: NSData.self, forKey: "path") as Data? else {
				return nil;
			}
			
			self.creationDate = creationDate;
			guard let path = CGPathCreateWithData (pathData) else {
				return nil;
			}
			self.path = path;
		}
		
		fileprivate func encode (with coder: NSCoder) {
			coder.encode (self.creationDate, forKey: "creationDate");
			coder.encode (self.path.encodeAsData (), forKey: "path");
		}
	}
	
	private init? (decodingData data: Data) {
		guard let decoder = try? NSKeyedUnarchiver (forReadingFrom: data) else {
			return nil;
		}
		
		decoder.setClass (Annotation.self, forClassName: "AKSignatureAnnotation");
		decoder.setClass (Signature.self, forClassName: "AKSignature");
		let signatureInfo = (try decoder.decodeTopLevelObject (of: Annotation.self, forKey: NSKeyedArchiveRootObjectKey) !! "Cannot decode signature");
		self.identifier = signatureInfo.identifier.uuidString;
		self.path = signatureInfo.signature.path;
	}
}

/* fileprivate */ extension NSPasteboard.PasteboardType {
	fileprivate static let signatureAnnotation = Self (rawValue: "com.apple.AnnotationKit.AnnotationItem");
}
