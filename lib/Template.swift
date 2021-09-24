import ext
import Foundation

public protocol RenderedValue {
	var isAttributed: Bool { get }
	var plainValue: NSString { get }
	var attributedValue: NSAttributedString { get }
	
	var length: Int { get }
	func substring (with range: NSRange) -> String;
}

/* public */ extension RenderedValue {
	public var length: Int { self.isAttributed ? self.attributedValue.length : self.plainValue.length }

	public func substring (with range: NSRange) -> String { self.plainValue.substring (with: range) }
}

public protocol TemplateVariable {
	var renderedValue: RenderedValue & NSObjectProtocol { get }
}

public struct Template: TemplateVariable {
	public typealias Variable = TemplateVariable;

	public var renderedValue: RenderedValue & NSObjectProtocol {
		var isAttributed = self.template.isAttributed
		let result = NSMutableAttributedString (attributedString: self.template.attributedValue);
		result.beginEditing ();
		for substitution in self.substitutions {
			let replacement = substitution.variable.renderedValue;
			let attributedReplacement: NSAttributedString;
			let attributes = result.attributes (at: substitution.range.location, effectiveRange: nil);
			if (replacement.isAttributed) {
				isAttributed = true;
				let mutableReplacement = NSMutableAttributedString (attributedString: replacement.attributedValue);
				mutableReplacement.enumerateAttributes (in: .init (location: 0, length: mutableReplacement.length), options: .longestEffectiveRangeNotRequired) { newAttrs, range, _ in
					for (key, value) in attributes where newAttrs [key] == nil {
						mutableReplacement.addAttribute (key, value: value, range: range);
					}
				};
				attributedReplacement = mutableReplacement;
			} else {
				attributedReplacement = .init (string: replacement.plainValue as String, attributes: attributes);
			}
			result.replaceCharacters (in: substitution.range, with: attributedReplacement);
		}
		result.endEditing ();
		return isAttributed ? NSAttributedString (attributedString: result) : result.string as NSString;
	}

	private struct Substitution {
		fileprivate let variable: Variable;
		fileprivate let range: NSRange;
	}
	
	private static let variableRE = try NSRegularExpression (pattern: "(?<!\\\\)\\$\\{([^}]+)\\}") !! "Cannot create variable regex";
	private let template: RenderedValue & NSObjectProtocol;
	private let substitutions: [Substitution];
	
	public init (_ template: RenderedValue & NSObjectProtocol, variables: [String: Variable]) {
		self.template = template;
		
		let string = template.plainValue;
		var substitutions = [Substitution] ();
		for match in Self.variableRE.matches (in: string as String, range: NSRange (location: 0, length: string.length)) {
			let variableName = string.substring (with: match.range (at: 1));
			let variable = variables [variableName] !! "Unknown variable: \(variableName)";
			substitutions.append (.init (variable: variable, range: match.range));
		}
		self.substitutions = substitutions.reversed ();
	}
}

public protocol Formattable {
	associatedtype Formatter where Formatter: Foundation.Formatter;
	
	func localizedValue (using formatter: Formatter) -> String;
}

public struct FormattedVariable <Value>: TemplateVariable where Value: Formattable {
	private let value: Value;
	private let formatter: Value.Formatter;
	
	public var renderedValue: RenderedValue & NSObjectProtocol { self.value.localizedValue (using: self.formatter) as NSString }
	
	public init (_ value: Value, formatter: Value.Formatter = .init ()) {
		(self.value, self.formatter) = (value, formatter);
	}
}

private protocol PlainRenderedValue: RenderedValue {}
/* public */ extension PlainRenderedValue {
	public var isAttributed: Bool { false }
	public var attributedValue: NSAttributedString { NSAttributedString (string: self.plainValue as String) }
}

private protocol AttributedRenderedValue: RenderedValue {}
/* public */ extension AttributedRenderedValue {
	public var isAttributed: Bool { true }
	public var plainValue: NSString { self.attributedValue.string as NSString }
}

extension String: PlainRenderedValue {
	public var plainValue: NSString { self as NSString }
}

extension NSString: PlainRenderedValue {
	public var plainValue: NSString { self }
}

extension NSAttributedString: AttributedRenderedValue {
	public var attributedValue: NSAttributedString { self }
}

extension Date: Formattable {
	public typealias Formatter = DateFormatter;
	
	public func localizedValue (using formatter: DateFormatter) -> String { formatter.string (from: self) }
}

extension Decimal: Formattable {
	public typealias Formatter = NumberFormatter;
	
	public func localizedValue (using formatter: NumberFormatter) -> String {
		(formatter.string (from: NSDecimalNumber (decimal: self)) !! "Cannot format \(self) using \(formatter)").trimmingCharacters (in: .whitespacesAndNewlines)
	}
}

extension Int: TemplateVariable {
	public var renderedValue: RenderedValue & NSObjectProtocol { NSString (format: "%lu", UInt64 (self)) }
}

extension String: TemplateVariable {
	public var renderedValue: RenderedValue & NSObjectProtocol { self as NSString }
}

extension NSAttributedString: TemplateVariable {
	public var renderedValue: RenderedValue & NSObjectProtocol { self }
}
