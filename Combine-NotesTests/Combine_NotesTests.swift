//
//  Combine_NotesTests.swift
//  Combine-NotesTests
//
//  Created by V, Kalaivani V. (623-Extern) on 16/11/21.
//

import XCTest
import Combine

@testable import Combine_Notes

class Combine_NotesTests: XCTestCase {
    
    let testUrlString = "https://jsonplaceholder.typicode.com/todos/1"

    var testURL: URL?
    
    override func setUpWithError() throws {
        self.testURL = URL(string: testUrlString)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testDataTaskPublisher() {
        
        let expectation = XCTestExpectation(description: "Fetching from url \(String(describing: testUrlString))")
        
        let remoteDataPublisher = URLSession.shared.dataTaskPublisher(for: self.testURL!)
            .sink(receiveCompletion: { compln in
                switch compln {
                    case .finished:
                        expectation.fulfill()
                    case .failure:
                        XCTFail()
                }
                
            }, receiveValue: { (data,response) in
                XCTAssertNotNil(data)
            })
    
        XCTAssertNotNil(remoteDataPublisher)
        wait(for: [expectation], timeout: 5.0)
    }

}
