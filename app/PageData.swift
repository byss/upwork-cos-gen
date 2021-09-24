import ext
import lib
import Foundation

internal protocol PageDataProtocol {
	associatedtype Value;
	
	static func pageData (forPage page: Page) -> Value;
}

/* internal */ extension PageDataValuesContainer {
	internal static func pageData (forPage page: Page) -> Value {
		switch (page) {
		case .ru: return self.ru;
		case .en: return self.en;
		}
	}
}

private protocol DefaultPageData: PageDataValuesContainer where Value == Self {}

internal enum Page: CaseIterable {
	case ru;
	case en;
}

@propertyWrapper
internal struct PageData <T> {
	internal struct Value {
		private let implementation: (Page) -> T;
		
		internal subscript (page: Page) -> T { self.implementation (page) }
		
		fileprivate init (_ implementation: @escaping (Page) -> T) { self.implementation = implementation }
	}
	
	internal let wrappedValue: Value;
	
	internal init (values: T...) {
		precondition (values.count == Page.allCases.count, "Invalid number of values provided (expected \(Page.allCases.count), got \(values.count))");
		self.init { values [Page.allCases.firstIndex (of: $0) !! "\($0) is missing from Page.allCases"] }
	}
	
	internal init (values: [Page: T]) {
		precondition (values.count == Page.allCases.count, "Invalid number of values provided (expected \(Page.allCases.count), got \(values.count))");
		self.init { values [$0] !! "No value was provided for \($0)" }
	}
	
	internal init <C> (_ containerType: C.Type = C.self) where C: PageDataProtocol, C.Value == T { self.init { C.pageData (forPage: $0) } }
	
	internal init (_ providerBlock: @escaping (Page) -> T) { self.wrappedValue = .init (providerBlock) }
}

/* internal */ extension PageData where T: PageDataProtocol, T.Value == T {
	internal init () { self.init (T.self) }
}

/* internal */ extension NSEdgeInsets {
	internal static let page = NSEdgeInsets (top: 1.15.inches, left: 0.95.inches, bottom: 1.15.inches, right: 0.95.inches);
}

private protocol PageDataValuesContainer: PageDataProtocol {
	static var ru: Value { get }
	static var en: Value { get }
}

extension TemplateData: PageDataValuesContainer {
	internal typealias Value = NSAttributedString;
}

extension Locale: DefaultPageData {
	internal static let ru = Self (identifier: "ru_RU");
	internal static let en = Self (identifier: "en_US");
}
