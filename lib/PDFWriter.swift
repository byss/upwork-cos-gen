import ext
import Foundation
import CoreGraphics

public final class PDFWriter {
	public var documentOptions = Set <DocumentOption> ()
	public var pageSize: CGSize = .letterUS;
	public var target: URL;
	
	private var pdfDocumentOptions: CFDictionary { Dictionary (uniqueKeysWithValues: self.documentOptions.map (\.pdfDocumentOption)) as CFDictionary }
	
	private var pages = [PageData] ();
	
	public init (target url: URL) {
		self.target = url;
	}
	
	deinit {
		let pageBounds = CGRect (origin: .zero, size: self.pageSize);
		let context = NSGraphicsContext (cgContext: withUnsafePointer (to: pageBounds) {
			let dataConsumer = CGDataConsumer (url: self.target as CFURL) !! "Cannot write output file \(self.target.absoluteString)";
			return CGContext (consumer: dataConsumer, mediaBox: $0, self.pdfDocumentOptions) !! "Cannot create PDF context";
		}, flipped: false);
		
		for page in self.pages {
			context.setCurrentAndPerform {
				let context = $0.cgContext;
				context.beginPDFPage (nil);
				page.content.draw (in: pageBounds.inset (by: page.margins));
				page.additionalActions? (context);
				context.endPDFPage ();
			};
		}

		context.cgContext.closePDF ();
	}
	
	public func addPage (_ content: NSAttributedString, margins: NSEdgeInsets = .init (), additionalActions: ((CGContext) -> ())? = nil) {
		self.pages.append (.init (content: content, margins: margins, additionalActions: additionalActions));
	}
}

/* public */ extension PDFWriter {
	public enum DocumentOption: Hashable {
		case title (String);
		case author (String);
		case subject (String);
		case creator (String);
		
		public static func == (lhs: Self, rhs: Self) -> Bool { lhs.kind == rhs.kind }
		public func hash (into hasher: inout Hasher) { self.kind.hash (into: &hasher) }
		
		fileprivate var pdfDocumentOption: (CFString, CFTypeRef) {
			switch (self) {
			case .title (let value): return (kCGPDFContextTitle, value as CFTypeRef);
			case .author (let value): return (kCGPDFContextAuthor, value as CFTypeRef);
			case .subject (let value): return (kCGPDFContextSubject, value as CFTypeRef);
			case .creator (let value): return (kCGPDFContextCreator, value as CFTypeRef);
			}
		}
		
		private var kind: Int {
			switch (self) {
			case .title: return 1;
			case .author: return 2;
			case .subject: return 3;
			case .creator: return 4;
			}
		}
	}
}

/* private */ extension PDFWriter {
	private struct PageData {
		fileprivate let content: NSAttributedString;
		fileprivate let margins: NSEdgeInsets;
		fileprivate let additionalActions: ((CGContext) -> ())?;
	}
}

/* public */ extension BinaryFloatingPoint {
	public var inches: CGFloat { CGFloat (CGFloat.NativeType (self) * 72.0 as CGFloat.NativeType) }
}

/* fileprivate */ extension CGRect {
	fileprivate static let letterUS = CGRect (origin: .zero, size: .letterUS);
	
	fileprivate func inset (by margins: NSEdgeInsets) -> CGRect {
		.init (x: self.minX + margins.left, y: self.minY + margins.top, width: self.width - margins.left - margins.right, height: self.height - margins.top - margins.bottom)
	}
}

/* fileprivate */ extension CGSize {
	fileprivate static let letterUS = CGSize (width: 612.0, height: 792.0);
}
