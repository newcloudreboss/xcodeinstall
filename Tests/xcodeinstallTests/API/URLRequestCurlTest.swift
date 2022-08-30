//
//  URLRequestCurlTest.swift
//  xcodeinstallTests
//
//  Created by Stormacq, Sebastien on 04/08/2022.
//

import XCTest
@testable import xcodeinstall


class URLRequestCurlTest: XCTestCase {
    
    var subject: HTTPClient!
    var agent  : NetworkAgent!
    let session = MockURLSession()
    
    var log     : Log!
    var secrets : FileSecretsHandler!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        self.log     = Log(logLevel: .debug)
        self.secrets = FileSecretsHandler.init(logger: log.defaultLogger)
        self.subject = HTTPClient(session: session)
        self.agent   = NetworkAgent(client: subject, secrets: secrets, logger: log.defaultLogger)
    }

    func testRequestToCurl() throws {
        
        //given
        let url = "https://dummy.com"
        var headers  = [ "header1" : "value1",
                         "header2" : "value2"]
        let data = "test data".data(using: .utf8)
        let cookie = HTTPCookie(properties: [.name : "cookieName", .value: "cookieValue", .path: "/", .originURL: url])
        if let c = cookie {
            headers.merge(HTTPCookie.requestHeaderFields(with: [c])) { (current, _) in current }
        }

        // when
        let request = agent.request(for: url, method: .GET, withBody: data, withHeaders: headers)
        let curl = request.cURL(pretty: false)
        
        // then
        XCTAssertNotNil(curl)
        XCTAssert(curl.starts(with: "curl "))
        XCTAssert(curl.contains("-H 'header1: value1'"))
        XCTAssert(curl.contains("-H 'header2: value2'"))
        XCTAssert(curl.contains("-H 'Cookie: cookieName=cookieValue'"))
        XCTAssert(curl.contains("-X GET 'https://dummy.com'"))
        XCTAssert(curl.contains("--data 'test data'"))

    }
    
    func testRequestToCurlPrettyPrint() throws {
        
        //given
        let url = "https://dummy.com"
        var headers  = [ "header1" : "value1",
                         "header2" : "value2"]
        let data = "test data".data(using: .utf8)
        let cookie = HTTPCookie(properties: [.name : "cookieName", .value: "cookieValue", .path: "/", .originURL: url])
        if let c = cookie {
            headers.merge(HTTPCookie.requestHeaderFields(with: [c])) { (current, _) in current }
        }

        // when
        let request = agent.request(for: url, method: .GET, withBody: data, withHeaders: headers)
        let curl = request.cURL(pretty: true)
        
        // then
        XCTAssertNotNil(curl)
        XCTAssert(curl.starts(with: "curl "))
        XCTAssert(curl.contains("--header 'header1: value1'"))
        XCTAssert(curl.contains("--header 'header2: value2'"))
        XCTAssert(curl.contains("--header 'Cookie: cookieName=cookieValue'"))
        XCTAssert(curl.contains("--request GET"))
        XCTAssert(curl.contains("--url 'https://dummy.com'"))
        XCTAssert(curl.contains("--data 'test data'"))

    }

}
