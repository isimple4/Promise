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
        
        let p = Promise<Int>()
        XCTAssertNotNil(p)
        
        p.fullfill(with: 2)
        XCTAssertEqual(p.debugValue()!, 2)
    }
    
    func testFullfill() {
        let p = Promise<String>()
        XCTAssertNil(p.debugValue())
        
        p.fullfill(with: "3x")
        XCTAssertEqual(p.debugValue()!, "3x")
        
       
    }
    
    func testReject() {
        let p = Promise<String>()

        let err1 = NSError(domain: "cd", code: 12, userInfo: nil)
        p.reject(with: err1)
        
        let e1 = p.debugError()! as NSError
        XCTAssertEqual(e1.domain, "cd")
        XCTAssertEqual(e1.code, 12)
    }
    
    func testMap() {
        let p = Promise<String>()
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
        let p = Promise<Int>()
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
        let p = Promise<Int>()
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
        let p = Promise<Int>()
        XCTAssertNotNil(p)
        
        p.fullfill(with: 2)
        p.fullfill(with: 3)

        XCTAssertEqual(p.debugValue()!, 2)
    }
    
    func testMultiFail() {
        let p = Promise<Int>()
        XCTAssertNotNil(p)
        
        p.reject(with: TestError.e1)
        p.reject(with: TestError.e2)
        
        XCTAssertEqual(p.debugError() as! TestError, TestError.e1)
    }
    
    func testDoneCatch() {
        let p = Promise<Int>()
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
        let p = Promise<Int>()
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
    
    func testAlways() {
        var i = 1
        let p1 = Promise<Int>()
        p1.always {
            i += 1
        }
        
        
        let p2 = Promise<String>()
        p2.always {
            i *= 3
        }
        
        p1.fullfill(with: 123)
        p2.reject(with: TestError.e1)
        
        XCTAssertEqual(i, 6)
        
    }
    
    func testDelay() {
        let exp = expectation(description: "delay not working")
        
        let p1 = Promise<Int>()
        
        var d1: Date?
        p1.delay(0.2, on: .main).onFullfill { _ in
            d1 = Date()
            
            XCTAssertTrue(Thread.isMainThread)
            exp.fulfill()
        }
        
        let d2 = Date()
        p1.fullfill(with: 4)
        
        waitForExpectations(timeout: 0.5, handler: nil)
        
        XCTAssertNotNil(d1)
        XCTAssertGreaterThan(d1!.timeIntervalSince(d2), 0.2)
    }
    
    func testValidate() {
        let exp1 = expectation(description: "validate not working")
        
        let p1 = Promise<Int>()
        
        
        p1.validate { $0 > 12 }
            .onReject { _ in exp1.fulfill() }
        
        p1.fullfill(with: 11)
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testRecover() {
        let exp1 = expectation(description: "recover not working")
        
        let p1 = Promise<Int>()
        
        p1.recover { _ in return 2 }
            .get {
                XCTAssertEqual($0, 2)
                
                exp1.fulfill()
        }
        
        p1.reject(with: TestError.e2)
        
        wait(for: [exp1], timeout: 1.0)
        
    }
    
    func testOn() {
        let testQueueLabel = "com.simple4"
        let testQueue = DispatchQueue(label: testQueueLabel, attributes: [])
        let testQueueKey = DispatchSpecificKey<Void>()
        testQueue.setSpecific(key: testQueueKey, value: ())

        let exp1 = expectation(description: "on queue not working")

        let p1 = Promise<Int>()
        
        p1.on(testQueue).onFullfill { _ in
            XCTAssertNotNil(DispatchQueue.getSpecific(key: testQueueKey), "callback should switch to queue")
            
            exp1.fulfill()
        }
        
        p1.fullfill(with: 3)
        
        wait(for: [exp1], timeout: 1.0)

    }

}
