import ext
import lib
import UniformTypeIdentifiers

internal struct COSGenerator {
	private static let locale = PageData <Locale> ().wrappedValue;

	private let fullNameRU: String;
	private let fullNameEN: String;
	private let signature: NSTextAttachment;
	private let date: Date;
	private let amount: Decimal;
	
	@PageData (TemplateData.self)
	private var templateData: PageData <NSAttributedString>.Value;
	@PageData
	private var fullName: PageData <String>.Value;
	@PageData ({ .documentDate (locale: Self.locale [$0]) })
	private var dateFormatter: PageData <DateFormatter>.Value;
	@PageData ({ .documentAmount (locale: Self.locale [$0]) })
	private var amountFormatter: PageData <NumberFormatter>.Value;
	
	private init (fullNameRU: String, fullNameEN: String, signature: NSTextAttachment, date: Date, amount: Decimal) {
		(self.fullNameRU, self.fullNameEN, self.signature, self.date, self.amount) = (fullNameRU, fullNameEN, signature, date, amount);
		self._fullName = .init (values: self.fullNameRU, self.fullNameEN);
	}
}

/* fileprivate */ extension COSGenerator {
	internal static func main () { self.init ().run () }
	
	internal init (config: Config = .init ()) {
		let fullNameRU = config.fullNameRU;
		let fullNameEN = config.fullNameEN;
		let signature = config.signature;
		let date = config.date;
		let amount = config.amount;
		self.init (fullNameRU: fullNameRU, fullNameEN: fullNameEN, signature: signature, date: date, amount: amount);
	}

	private func run () {
		let comps = Calendar.utc.dateComponents ([.month, .year], from: self.date) !! "Cannot get date components";
		let year = comps.year !! "Cannot get year", month = comps.month !! "Cannot get month";
		let defaults = UserDefaults.standard, documentIndexKey = "doc-index-\(year, width: -4, padding: "0")-\(month, width: -2, padding: "0")";
		let documentIndex = max (defaults.integer (forKey: documentIndexKey), 1);
		defer { defaults.set (documentIndex + 1, forKey: documentIndexKey) }
		
		let documentName = Template (String.outputFilenameTemplate as NSString, variables: [
			"title": String.documentTitle,
			"date": FormattedVariable (self.date, formatter: .filename),
			"index": documentIndex,
		]).renderedValue.plainValue as String;
		
		let documentURL = URL (fileURLWithPath: documentName, isDirectory: false).appendingPathExtension (UTType.pdf.preferredFilenameExtension ?? "pdf");
		let writer = PDFWriter (target: documentURL);
		writer.documentOptions = [
			.author ("\(self.fullNameEN) (\(self.fullNameRU))"),
			.title (.documentTitle),
			.creator (Bundle.main.creatorInfo),
		];
		for page in Page.allCases {
			writer.addPage (self.renderedPage (page) , margins: .page);
		}
	}
	
	private func renderedPage (_ page: Page) -> NSAttributedString {
		Template (self.templateData [page], variables: [
			"fullName": self.fullName [page],
			"signature": NSAttributedString (attachment: self.signature),
			"date": FormattedVariable (self.date, formatter: self.dateFormatter [page]),
			"amount": FormattedVariable (self.amount, formatter: self.amountFormatter [page]),
		]).renderedValue.attributedValue
	}
}

private protocol StringConvertible {
	var stringValue: String { get }
}

extension String: StringConvertible {
	fileprivate var stringValue: String { self }
}

extension CFString: StringConvertible {
	fileprivate var stringValue: String { self as String }
}

/* fileprivate */ extension Bundle {
	fileprivate var creatorInfo: String { self [infoDictionaryKeys: "CFBundleDisplayName", kCFBundleVersionKey].compactMap { $0 }.joined (separator: " ") }
	
	private subscript <T> (infoDictionaryKey key: StringConvertible) -> T? { self.object (forInfoDictionaryKey: key.stringValue) as? T }
	private subscript <T> (infoDictionaryKeys keys: StringConvertible...) -> [T?] { keys.map { self [infoDictionaryKey: $0] } }
}
