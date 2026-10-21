import Foundation

/// The `Code` and `Message` of an S3 XML error body.
struct S3ErrorResponse: Equatable {
    let code: String?
    let message: String?

    /// Parses `<Error><Code>…</Code><Message>…</Message></Error>`; fields are nil when absent or the
    /// body is not XML.
    static func parse(_ data: Data) -> S3ErrorResponse {
        let delegate = ErrorBodyParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse() else { return S3ErrorResponse(code: nil, message: nil) }
        return S3ErrorResponse(code: delegate.fields["Code"], message: delegate.fields["Message"])
    }
}

private final class ErrorBodyParser: NSObject, XMLParserDelegate {
    private static let wanted: Set = ["Code", "Message"]
    private(set) var fields: [String: String] = [:]
    private var currentElement: String?
    private var text = ""

    func parser(
        _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = Self.wanted.contains(elementName) ? elementName : nil
        text = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement != nil { text += string }
    }

    func parser(
        _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?
    ) {
        if elementName == currentElement { fields[elementName] = text }
        currentElement = nil
    }
}
