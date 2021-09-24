import ext
import lib
import Foundation

internal struct TemplateData {
	internal static let ru = NSAttributedString (html: .templatePageRU, options: .staticHTML) !! "Cannot instantiate \(#function)";
	internal static let en = NSAttributedString (html: .templatePageEN, options: .staticHTML) !! "Cannot instantiate \(#function)";
}

/* internal */ extension String {
	internal static let documentTitle = "Confirmation of Services";
	internal static let outputFilenameTemplate = "${title}\u{00A0}\u{2014} ${date}\u{2060}-\u{2060}${index}";
}

/* fileprivate */ extension NSAttributedString {
	fileprivate convenience init? (html data: Data, options: [DocumentReadingOptionKey: Any]) { self.init (html: data, options: options, documentAttributes: nil) }
}

/* fileprivate */ extension Dictionary where Key == NSAttributedString.DocumentReadingOptionKey, Value == Any {
	fileprivate static let staticHTML = [
		.characterEncoding: String.Encoding.utf8.rawValue,
		.documentType: NSAttributedString.DocumentType.html.rawValue,
	] as Self;
}

/* fileprivate */ extension Data {
	fileprivate static let templatePageRU = Self.renderedData (template: .templatePageRU);
	fileprivate static let templatePageEN = Self.renderedData (template: .templatePageEN);

	private static func renderedData (template: Template) -> Self {
		let rendered = template.renderedValue;
		precondition (!rendered.isAttributed, "Template data must be plain text");
		return (rendered.plainValue as String).data (using: .utf8) !! "Cannot convert result to UTF-8";
	}
}

/* fileprivate */ extension Template {
	fileprivate static let templatePageRU = Self.templatePage (body: .templatePageBodyRU);
	fileprivate static let templatePageEN = Self.templatePage (body: .templatePageBodyEN);

	private static func templatePage (body: String) -> Self { self.init ("<html><head><style>${styles}</style></head><body>${body}</body></html>" as NSString, variables: .templatePage (body: body)) }
}

/* fileprivate */ extension Dictionary where Key == String, Value == Template.Variable {
	fileprivate static func templatePage (body: String) -> Self { ["styles": String.templatePageStyles, "body": body] }
}

/* fileprivate */ extension String {
	fileprivate static let templatePageStyles = """
		*      { font-family: "Times New Roman"; font-size: 9pt; }
		body   { margin: 1.15in 0.91in 1.15in 1.0in; }
		h1     { font-family: Times; text-align: center; margin: 0 0 20pt 0; }
		h2     { text-align: natural; margin: 0 0 11pt 0; font-weight: normal; }
		p      { text-align: justify; margin: 0 0 11pt 0; }
		em     { font-family: Times; font-weight: bold; font-style: normal; }
		table  { width: 100%; margin: 0.23in 0 0 0; }
		td     { padding: 0; width: 50%; vertical-align: top; }
		td.n22 { padding: 0.55in 0 0 0; }
		""";
	
	fileprivate static let templatePageBodyRU = """
		<h1>Подтверждение оказания услуг</h1>
		<h2><em>Дата:</em>&nbsp;${date}</h2>
		<h2><em>Касательно:</em>&nbsp;Договора Upwork о Предоставлении Услуг (как определено в Пользовательском Соглашении Upwork)</h2>
		<h2><em>"Подрядчик"</em> (как определено в Пользовательском Соглашении Upwork) в лице</h2>
		<h2>${fullName}, и</h2>
		<h2><em>"Заказчик"</em> (как определено в Пользовательском Соглашении Upwork)</h2>
		<p>Подрядчик и компания Upwork Global Inc. («Апворк Глобал Инк.»), зарегистрированная за номером C2498116 в соответствии с законодательством штата Калифорния, США, подтверждают посредством подписания настоящего документа, что работы (услуги) были выполнены (оказаны) Подрядчиком и приняты Заказчиком в соответствии с Договором, указанным выше. Оплата за соответствующие услуги (работы) осуществляется Заказчиком посредством перечисления и размещения денежных средств на условно-депозитный счет, управляемый компанией Upwork Escrow Inc. («Эскроу Агент») и данные средства будут перечислены Подрядчику с такого счета не позднее 14 дней с даты настоящего подтверждения Заказчиком выполнения работ/оказания услуг в соответствии с поставленной задачей.</p>
		<p>Стоимость выполненных работ (оказанных услуг) составляет ${amount} долларов США.</p>
		<table>
			<tr>
				<td>Подрядчик</td>
				<td>Заказчик<br/>Корпорация Upwork</td>
			</tr>
			<tr>
				<td>${signature}</td>
				<td class="n22">Подписано<br/>Директор, Служба поддержки клиентов, Мишель&nbsp;Эпплберг</td>
			</tr>
		</table>
		""";
	
		fileprivate static let templatePageBodyEN = """
			<h1>Confirmation of Services</h1>
			<h2><em>Date:</em>&nbsp;${date}</h2>
			<h2><em>Re:</em>&nbsp;Upwork Service Contract (as defined in the Upwork User Agreement)</h2>
			<h2>The <em>"Contractor"</em> (as defined in the Upwork User Agreement) is</h2>
			<h2>${fullName}</h2>
			<h2>the <em>“Client”</em> (as defined in the Upwork User Agreement).</h2>
			<p>Contractor and Upwork Global Inc. No. C2498116 established under the laws of the State of California, USA, confirm by signing hereafter that works (services) were rendered by the Contractor to the Client, under the contract referenced above. The remuneration for the relevant Works shall be paid and deposited by Client into an escrow account held by Upwork Escrow Inc. (“Escrow Agent”), and released from the escrow account and remitted by Escrow Agent to Contractor no later than 14 days from the date of this confirmation of services specified above, the Client confirms that the Works have been duly completed in accordance with the assignment.</p>
			<p>The cost of the works (services) rendered is US Dollars ${amount}.</p>
			<table>
				<tr>
					<td>For the Contractor:</td>
					<td>For the Client:<br/>Upwork Global Inc.</td>
				</tr>
				<tr>
					<td>${signature}</td>
					<td class="n22">By:&nbsp________________________<br/>Director, Customer&nbsp;Support, Michelle&nbsp;Appleberg</td>
				</tr>
			</table>
			""";
}
