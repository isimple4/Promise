//
//  PromiseTests.swift
//  PromiseTests
//
//  Created by xiaohui on 2018/12/27.
//  Copyright © 2018 simple4. All rights reserved.
//

import XCTest
@testable import Promise

enum TestError: Swift.Error {
    case e1
    case e2
}

class PromiseTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func testInitWithValue() {
        
        let p = Promise<Int, Never>()
        XCTAssertNotNil(p)
        
        p.fullfill(with: 2)
        XCTAssertEqual(p.debugValue()!, 2)
    }
    
    func testFullfill() {
        let p = Promise<String, Error>()
        XCTAssertNil(p.debugValue())
        
        p.fullfill(with: "3x")
        XCTAssertEqual(p.debugValue()!, "3x")
        
       
    }
    
    func testReject() {
        let p = Promise<String, Error>()

        let err1 = NSError(domain: "cd", code: 12, userInfo: nil)
        p.reject(with: err1)
        
        let e1 = p.debugError()! as NSError
        XCTAssertEqual(e1.domain, "cd")
        XCTAssertEqual(e1.code, 12)
    }
    
    func testMap() {
        let p = Promise<String, Never>()
        let exp = expectation(description: "map not working")
        
        let s1 = "hi xx"
        _ = p.map { value in
            exp.fulfill()
            XCTAssertEqual(value, s1)
        }
        p.fullfill(with: s1)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testMap2() {
        let p = Promise<Int, Never>()
        let exp = expectation(description: "map not working")
        
        _ = p
            .map { return String($0) }
            .done {
                exp.fulfill()
                XCTAssertEqual($0, "1245")
            }
        
        let s1 = 1245
        p.fullfill(with: s1)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testCatch() {
        let p = Promise<Int, Error>()
        let exp = expectation(description: "catch not working")
        
        _ = p
            .map { v -> String in
                XCTFail()
                return String(v)
            }
            .catch {
                exp.fulfill()
                
                let e1 = $0 as NSError
                XCTAssertEqual(e1.domain, "cd")
                XCTAssertEqual(e1.code, 12)
            }
        
        let err1 = NSError(domain: "cd", code: 12, userInfo: nil)
        p.reject(with: err1)
        wait(for: [exp], timeout: 1.0)
    }
    
    
    func testMultiSuccess() {
        let p = Promise<Int, Never>()
        XCTAssertNotNil(p)
        
        p.fullfill(with: 2)
        p.fullfill(with: 3)

        XCTAssertEqual(p.debugValue()!, 2)
    }
    
    func testMultiFail() {
        let p = Promise<Int, TestError>()
        XCTAssertNotNil(p)
        
        p.reject(with: TestError.e1)
        p.reject(with: TestError.e2)
        
        XCTAssertEqual(p.debugError() as! TestError, TestError.e1)
    }
    
    func testDoneCatch() {
        let p = Promise<Int, TestError>()
        let exp = expectation(description: "done catch not working")
        
        _ = p
            .map { return String($0) }
            .done { _ in
                XCTFail()
            }
            .catch {
                XCTAssertEqual($0 as! TestError, TestError.e1)
                exp.fulfill()
            }
        
        p.reject(with: TestError.e1)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testGet() {
        let p = Promise<Int, TestError>()
        let exp = expectation(description: "get not working")
        
        _ = p
            .get {
                XCTAssertEqual($0, 2)
                exp.fulfill()
            }
            .done {
                XCTAssertEqual($0, 2)
            }
        
        
        
        p.fullfill(with: 2)
        wait(for: [exp], timeout: 1.0)
    }

}
