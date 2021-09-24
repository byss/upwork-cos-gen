import ext
import Foundation
import AppKit.NSTextAttachment

public typealias NSAttributedString = AppKit.NSAttributedString;
public typealias NSTextAttachment = AppKit.NSTextAttachment;

public final class Config {
	@StoredUserInput (key: "full-name-ru", prompt: "Full Name (Russian)", envKey: "COS_FULL_NAME_RU")
	public var fullNameRU: String;
	@StoredUserInput (key: "full-name-en", prompt: "Full Name (English)", envKey: "COS_FULL_NAME_EN")
	public var fullNameEN: String;
	public var signature: NSTextAttachment { self._signature.makeTextAttachment () }
	@StoredUserInput (key: "signature", prompt: "Signature")
	private var _signature: AnySignature;
	@UserInput (prompt: "Date (YYYYMMDD)", envKey: "COS_DATE", default: .init ())
	public var date: Date;
	@UserInput (prompt: "Amount (USD)", envKey: "COS_AMOUNT")
	public var amount: Decimal;
	
	public init () {}
}

/* fileprivate */ extension Config {
	fileprivate struct AnySignature {
		fileprivate enum Kind: String, CaseIterable {
			case preview;
			case image;
			
			fileprivate func withIdentifier (_ identifier: String) -> Signature? {
				switch (self) {
				case .preview: return PreviewSignature (identifier: identifier);
				case .image: return ImageSignature (identifier: identifier);
				}
			}
		}
		
		private static let none = Self ();
		
		private let storage: (kind: Kind, value: Signature)?;
		
		private init () { self.storage = nil }
		private init (_ value: Signature, kind: Kind) { self.storage = (kind, value) }
	}
}

extension Config.AnySignature: UserDefaultsCodable {
	private struct Stored {
		fileprivate let kind: Kind;
		fileprivate let signature: Signature;
		
		fileprivate init? (_ dictionary: [String: String]) {
			guard let identifier = dictionary ["id"], !identifier.isEmpty else {
				return nil;
			}
			if let rawKind = dictionary ["kind"] {
				guard let kind = Kind (rawValue: rawKind) else {
					return nil;
				}
				self.init (kind, identifier: identifier);
			} else {
				self.init (identifier: identifier);
			}
		}
		
		fileprivate init? (identifier: String) {
			for kind in Kind.allCases {
				if let result = Self (kind, identifier: identifier) {
					self = result;
					return;
				}
			}
			return nil;
		}
		
		private init? (_ kind: Kind, identifier: String) {
			guard let signature = kind.withIdentifier (identifier) else {
				return nil;
			}
			(self.kind, self.signature) = (kind, signature);
		}
	}
	
	fileprivate init (from defaults: UserDefaults, key: String) {
		self = (defaults.dictionary (forKey: key) as? [String: String]).flatMap (Stored.init).flatMap { Self ($0.signature, kind: $0.kind) } ?? .none;
	}
	
	fileprivate func encode (to defaults: UserDefaults, key: String) {
		self.storage.map { defaults.set (["kind": $0.kind.rawValue, "id": $0.value.identifier], forKey: key) } ?? defaults.removeObject (forKey: key);
	}
}

extension Config.AnySignature: UserInputCodable {
	private struct Input {
		fileprivate let kind: Kind;
		fileprivate let signature: Signature;
		
		fileprivate init? () {
			enum Choice: Int, UserInputCodable {
				case `import` = 1;
				case stored = 2;
				case imageFile = 3;
			}
			
			var choiceInput = UserInput <Choice> (prompt: "Signature source [1 - import from Preview.app; 2 - previously imported; 3 - image file]");
			switch (choiceInput.wrappedValue) {
			case .import:
				guard let signature = PreviewSignature (pasteboard: .general) else {
					return nil;
				}
				(self.kind, self.signature) = (.preview, signature);
			case .stored:
				var identifierInput = UserInput <String> (prompt: "Signature identifier:");
				guard let signature = PreviewSignature (identifier: identifierInput.wrappedValue) else {
					return nil;
				}
				(self.kind, self.signature) = (.preview, signature);
			case .imageFile:
				var pathInput = UserInput <String> (prompt: "Signature image path:");
				guard let signature = ImageSignature (identifier: pathInput.wrappedValue) else {
					return nil;
				}
				(self.kind, self.signature) = (.image, signature);
			}
		}
	}

	fileprivate init? (userInput: String) {
		guard !userInput.isEmpty, let input = Input () else {
			return nil;
		}
		self.init (input.signature, kind: input.kind);
	}
}

extension Config.AnySignature: Signature {
	fileprivate var identifier: String { self.storage?.value.identifier ?? "" }

	fileprivate init? (identifier: String) {
		self = Stored (identifier: identifier).flatMap { Self ($0.signature, kind: $0.kind) } ?? .none;
	}
	
	fileprivate func encodeAsUserInput () -> String { { $0.isEmpty ? "" : "Reuse last (\($0))" } (self.identifier) }
	
	fileprivate func makeTextAttachment () -> NSTextAttachment { self.storage?.value.makeTextAttachment () ?? .init () }
}
