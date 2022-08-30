//
//  AuthenticationTest.swift
//  xcodeinstallTests
//
//  Created by Stormacq, Sebastien on 21/07/2022.
//

import XCTest
@testable import xcodeinstall


class AuthenticationTest: NetworkAgentTestCase {
    
    // test get apple service key
    func testAppleServiceKey() async {

        do {
            let url = "https://dummy"
            session.nextData     = try JSONEncoder().encode(AppleServiceKey(authServiceUrl: "url", authServiceKey: "key"))
            session.nextResponse = HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: nil, headerFields: nil)

            let authenticator = getAppleAuthenticator()
            let serviceKey = try await authenticator.getAppleServicekey()
                        
            XCTAssertEqual(serviceKey.authServiceKey, "key")

        } catch AuthenticationError.unableToRetrieveAppleServiceKey {
            XCTAssert(false, "unableToRetrieveAppleServiceKey")
        } catch {
            XCTAssert(false, "Invalid exception thrown")
        }

    }
    
    // test get apple service key
    func testAppleServiceKeyWithError() async {

        do {
            let url = "https://dummy"
            session.nextData     = try JSONEncoder().encode(AppleServiceKey(authServiceUrl: "url", authServiceKey: "key"))
            session.nextResponse = HTTPURLResponse(url: URL(string: url)!, statusCode: 500, httpVersion: nil, headerFields: nil)

            let authenticator = getAppleAuthenticator()
            _ = try await authenticator.getAppleServicekey()
                        
            XCTAssert(false, "No exception thrown")

        } catch URLError.badServerResponse {
            
        } catch {
            XCTAssert(false, "Invalid exception thrown")
        }

    }


    // test authentication returns 401
    func testAuthenticationInvalidUsernamePassword401() async  {

        let url = "https://dummy"

        session.nextData     = Data()
        session.nextResponse = HTTPURLResponse(url: URL(string: url)!, statusCode: 401, httpVersion: nil, headerFields: nil)

        do {
            let authenticator     = getAppleAuthenticator()
            authenticator.session = getAppleSession()

            _ = try await authenticator.startAuthentication(username: "username", password: "password")
            XCTAssert(false, "No exception thrown")

        } catch AuthenticationError.invalidUsernamePassword {
            
        } catch {
            XCTAssert(false, "Invalid exception thrown")
        }
    }

    
    // test authentication returns 200
    func testAuthentication200() async  {
        let url = "https://dummy"
        var header = [String:String]()
        header["Set-Cookie"]            = getCookieString()
        header["X-Apple-ID-Session-Id"] = "x-apple-id"
        header["scnt"]                  = "scnt"

        session.nextData     = Data()
        session.nextResponse = HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: nil, headerFields: header)

        do {
            let authenticator     = getAppleAuthenticator()
            authenticator.session = getAppleSession()

            try await authenticator.startAuthentication(username: "username", password: "password")
            
            XCTAssertNotNil(authenticator.session)
            //XCTAssertNotNil(authenticator.cookies)
            
            // test apple session
            XCTAssertEqual(authenticator.session.scnt, "scnt")
            XCTAssertEqual(authenticator.session.xAppleIdSessionId, "x-apple-id")
            XCTAssertEqual(authenticator.session.itcServiceKey?.authServiceKey, "key")
            XCTAssertEqual(authenticator.session.itcServiceKey?.authServiceUrl, "url")
            
            // test cookie
            //XCTAssertEqual(cookies, getCookieString())

        } catch {
            XCTAssert(false, "Exception thrown : \(error)")
        }
    }

    // test authentication with No Apple Service Key
    func testAuthenticationWithNoAppleServiceKey() async  {
        let url = "https://dummy"
        var header = [String:String]()
        header["Set-Cookie"]            = getCookieString()
        header["X-Apple-ID-Session-Id"] = "x-apple-id"
        header["scnt"]                  = "scnt"

        session.nextData     = Data()
        session.nextResponse = HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: nil, headerFields: header)

        do {
            let authenticator = getAppleAuthenticator()
            authenticator.session = getAppleSession()
            authenticator.session.itcServiceKey = nil 

            try await authenticator.startAuthentication(username: "username", password: "password")
            
            XCTAssert(false, "An exception must be thrown)")
            
        } catch AuthenticationError.unableToRetrieveAppleServiceKey {
            // success
        } catch {
            XCTAssert(false, "Unknown Exception thrown")
        }
    }


    // test authentication throws an error
    func testAuthenticationWithError() async  {
        let url = "https://dummy"

        session.nextData     = Data()
        session.nextResponse = HTTPURLResponse(url: URL(string: url)!, statusCode: 500, httpVersion: nil, headerFields: nil)

        do {
            let authenticator     = getAppleAuthenticator()
            authenticator.session = getAppleSession()

            _ = try await authenticator.startAuthentication(username: "username", password: "password")
            XCTAssert(false, "No exception thrown")

        } catch let error as URLError {
            // verify it returns an error code
            XCTAssertNotNil(error)
            XCTAssert(error.code == URLError.badServerResponse)
            
        } catch {
            XCTAssert(false, "Invalid exception thrown : \(error)")
        }
    }

    // test authentication returns 401
    func testAuthenticationInvalidUsernamePassword403() async  {

        let url = "https://dummy"

        session.nextData     = Data()
        session.nextResponse = HTTPURLResponse(url: URL(string: url)!, statusCode: 403, httpVersion: nil, headerFields: nil)

        do {
            let authenticator     = getAppleAuthenticator()
            authenticator.session = getAppleSession()

            _ = try await authenticator.startAuthentication(username: "username", password: "password")
            XCTAssert(false, "No exception thrown")

        } catch AuthenticationError.invalidUsernamePassword {
            
        } catch {
            XCTAssert(false, "Invalid exception thrown")
        }
    
    }
    
    // test authentication returns unhandled http sttaus code
    func testAuthenticationUnknownStatusCode() async  {

        let url = "https://dummy"

        session.nextData     = Data()
        session.nextResponse = HTTPURLResponse(url: URL(string: url)!, statusCode: 100, httpVersion: nil, headerFields: nil)

        do {
            let authenticator     = getAppleAuthenticator()
            authenticator.session = getAppleSession()

            _ = try await authenticator.startAuthentication(username: "username", password: "password")
            XCTAssert(false, "No exception thrown")

        } catch AuthenticationError.unexpectedHTTPReturnCode(let code) {
            XCTAssertEqual(code, 100)
        } catch {
            XCTAssert(false, "Invalid exception thrown")
        }
    
    }
    
    // test signout
    func testSignout() async  {
        let url = "https://dummy"
        session.nextData     = Data()
        session.nextResponse = HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: nil, headerFields: nil)

        do {
            let authenticator     = getAppleAuthenticator()
            authenticator.session = getAppleSession()

            try await authenticator.signout()
            

        } catch {
            XCTAssert(false, "Exception thrown")
        }
    }

    
    private func getCookieString() -> String {
        return "dslang=GB-EN; Domain=apple.com; Path=/; Secure; HttpOnly, site=GBR; Domain=apple.com; Path=/; Secure; HttpOnly, acn01=tP...QTb; Max-Age=31536000; Expires=Fri, 21-Jul-2023 13:14:09 GMT; Domain=apple.com; Path=/; Secure; HttpOnly, myacinfo=DAWTKN....a47V3; Domain=apple.com; Path=/; Secure; HttpOnly, aasp=DAA5DA...4EAE46; Domain=idmsa.apple.com; Path=/; Secure; HttpOnly"
    }

}
