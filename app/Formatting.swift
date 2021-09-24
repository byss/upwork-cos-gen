import ext
import Foundation

internal protocol FormatterProtocol: Formatter {
	var locale: Locale! { get set }
	init ();
}

/* fileprivate */ extension FormatterProtocol {
	fileprivate init (locale: Locale) {
		self.init ();
		self.locale = locale;
	}
}

/* fileprivate */ extension DateFormatter: FormatterProtocol {
	internal static let filename: DateFormatter = {
		let result = DateFormatter.formatter (locale: .en);
		result.dateFormat = DateFormatter.dateFormat (fromTemplate: "MMMyyyy", options: 0, locale: result.locale)?.replacingOccurrences (of: " ", with: "\u{00A0}");
		return result;
	} ();
	
	internal static func documentDate (locale: Locale) -> Self {
		let result = self.formatter (locale: locale);
		result.dateStyle = .long;
		result.timeStyle = .none;
		return result;
	}
	
	private static func formatter (locale: Locale) -> Self {
		let result = self.init (locale: locale);
		result.formattingContext = .standalone;
		result.calendar = .utc;
		result.timeZone = result.calendar.timeZone;
		return result;
	}
}

/* internal */ extension Calendar {
	internal static let utc: Calendar = {
		var result = Calendar (identifier: .gregorian);
		result.timeZone = .init (secondsFromGMT: 0) !! "Cannot instantiate UTC timezone";
		return result;
	} ();
}

extension NumberFormatter: FormatterProtocol {
	internal static func documentAmount (locale: Locale) -> Self {
		let result = self.init (locale: locale);
		result.numberStyle = .currency;
		result.currencySymbol = "";
		return result;
	}
}

/* fileprivate */ extension DefaultStringInterpolation {
	internal mutating func appendInterpolation <T> (_ value: T, width: Int) {
		self.appendInterpolation (value, width: width, padding: " ");
	}
	
	internal mutating func appendInterpolation <T> (_ value: T, width: Int) where T: BinaryInteger, T: SignedNumeric {
		self.appendInterpolation (value, width: width, padding: " ");
	}
	
	internal mutating func appendInterpolation <T, S> (_ value: T, width: Int, padding: S) where S: StringProtocol {
		self.appendInterpolation (Self.padded (value, width: width, padding: padding, useNumericPadding: false));
	}
	
	internal mutating func appendInterpolation <T, S> (_ value: T, width: Int, padding: S) where T: BinaryInteger, T: SignedNumeric, S: StringProtocol {
		self.appendInterpolation (value, width: width, padding: padding,useNumericPadding: (width < 0) && padding.allSatisfy (\.isNumber));
	}
	
	internal mutating func appendInterpolation <T, S> (_ value: T, width: Int, padding: S, useNumericPadding: Bool) where T: BinaryInteger, T: SignedNumeric, S: StringProtocol {
		let description = String (describing: value);
		if (-width > description.count) {
			let prefixEnd = description.firstIndex (where: \.isNumber) ?? description.endIndex;
			if (prefixEnd > description.startIndex) {
				self.appendInterpolation (description [..<prefixEnd]);
				self.appendInterpolation (description [prefixEnd...], width: width + description.distance (from: description.startIndex, to: prefixEnd), padding: padding);
				return;
			}
		}
		
		self.appendInterpolation (description, width: width, padding: padding);
	}
	
	private static func padded <T, S> (_ value: T, width: Int, padding: S, useNumericPadding: Bool) -> String where S: StringProtocol {
		precondition (!padding.isEmpty, "Padding must not be empty");
		let description = String (describing: value), paddingCharCount = abs (width) - description.count;
		guard paddingCharCount > 0 else {
			return description;
		}
		let paddingLength = padding.utf16.count, repetitions = paddingCharCount.quotientAndRemainder (dividingBy: padding.count);
		let fullPaddingLength = paddingLength * repetitions.quotient + padding [..<padding.index (padding.startIndex, offsetBy: repetitions.remainder)].utf16.count * repetitions.remainder;
		let fullPadding = "".padding (toLength: fullPaddingLength, withPad: padding, startingAt: 0);
		let paddingIndex = (width > 0) ? description.endIndex : (useNumericPadding ? (description.firstIndex (where: \.isNumber) ?? description.endIndex) : description.startIndex);
		return description.replacingCharacters (in: paddingIndex ..< paddingIndex, with: fullPadding);
	}
}
