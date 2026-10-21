import Foundation
import Testing

@testable import SnapboltUpload

@Suite("S3 error response")
struct S3ErrorResponseTests {
    @Test("Parses the code and message of an S3 XML error")
    func parsesS3ErrorXML() {
        let xml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <Error><Code>NoSuchBucket</Code><Message>The specified bucket does not exist.</Message></Error>
            """

        let parsed = S3ErrorResponse.parse(Data(xml.utf8))

        #expect(parsed.code == "NoSuchBucket")
        #expect(parsed.message == "The specified bucket does not exist.")
    }

    @Test("Tolerates a body that is not XML")
    func toleratesNonXMLBody() {
        let parsed = S3ErrorResponse.parse(Data("<html>Bad gateway".utf8))

        #expect(parsed.code == nil)
        #expect(parsed.message == nil)
    }
}
