//
//  PromiseTests.swift
//  PromiseTests
//
//  Created by xiaohui on 2018/12/27.
//  Copyright © 2018 simple4. All rights reserved.
//

import XCTest
@testable import Promise



class PromiseTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func testInitWithValue() {
        let p = Promise(value: 2)
        XCTAssertNotNil(p)
        
        XCTAssertEqual(p.debugValue()!, 2)
    }
    
    func testFullfillReject() {
        let p = Promise<String>()
        XCTAssertNil(p.debugValue())
        
        p.fullfill(with: "3x")
        XCTAssertEqual(p.debugValue()!, "3x")
        
        let err1 = NSError(domain: "cd", code: 12, userInfo: nil)
        p.reject(with: err1)
        
        let e1 = p.debugError()! as NSError
        XCTAssertEqual(e1.domain, "cd")
        XCTAssertEqual(e1.code, 12)
    }
    
    

}
