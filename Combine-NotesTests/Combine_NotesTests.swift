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
    
    let testUrlString = "https://jsonplaceholder.typicode.com/todos/10"
    
    var testURL: URL?
    
    var myBackgroundQueue: DispatchQueue?
    
    let test404UrlString = "https://barkshin.herokuapp.com/missing"
    
    
    fileprivate struct TodoTask: Decodable,Hashable {
        let userId: Int
        let id: Int
        let title: String
        let completed: Bool
    }
    
    enum TestFailureCondition: Error {
        case invalidServerResponse
    }
    
    
    override func setUpWithError() throws {
        self.testURL = URL(string: testUrlString)
        self.myBackgroundQueue = DispatchQueue(label: "UsingCombineNotes")
        
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
    
    func testDataDecodePipeline() {
        let expectation = XCTestExpectation(description: testUrlString)
        
        let dataPublisher = URLSession.shared.dataTaskPublisher(for: testURL!)
            .map{$0.data}
            .decode(type: TodoTask.self, decoder: JSONDecoder())
            .subscribe(on: self.myBackgroundQueue!)
            .eraseToAnyPublisher()
        
        XCTAssertNotNil(dataPublisher)
        
        let cancellable = dataPublisher.sink(receiveCompletion: { compln in
            print(".sink() received the completion", String(describing: compln))
            switch compln {
                case .finished:
                    expectation.fulfill()
                case .failure:
                    XCTFail()
            }
            
        }, receiveValue: { data in
            XCTAssertNotNil(data)
            print(".sink received some value: \(data)")
            
        })
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(cancellable)
        
    }
    
    func testFailingURLDecodePipeline_URLError() {
        let myURL = URL(string: "https://urldonoexist.com")
        let expectation = XCTestExpectation(description: "Download from \(String(describing: myURL))")
        
        let taskPub = URLSession.shared.dataTaskPublisher(for: myURL!)
            .map {$0.data}
            .decode(type: TodoTask.self, decoder: JSONDecoder())
            .subscribe(on: self.myBackgroundQueue!)
            .eraseToAnyPublisher()
        
        XCTAssertNotNil(taskPub)
        
        let cancellable = taskPub.sink(receiveCompletion: { compln in
            switch compln {
                case .finished:
                    XCTFail()
                case .failure:
                    expectation.fulfill()
            }
            
        }, receiveValue: { vsl in
            XCTFail("should not have received value with the failed url")
            print("sink received some val \(vsl)")
        })
        
        XCTAssertNotNil(cancellable)
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDataTaskPublisherWithTryMap() {
        
        let expectation = XCTestExpectation(description: "Download from \(testUrlString)")
        
        let taskpub = URLSession.shared.dataTaskPublisher(for: self.testURL!)
            .tryMap { data,response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,httpResponse.statusCode == 200 else {
                    throw TestFailureCondition.invalidServerResponse
                }
                return data
            }
            .decode(type: TodoTask.self, decoder: JSONDecoder())
            .subscribe(on: self.myBackgroundQueue!)
            .eraseToAnyPublisher()
        
        XCTAssertNotNil(taskpub)
        
        let cancellable = taskpub.sink(receiveCompletion: { compln in
            switch compln {
                case .finished:
                    expectation.fulfill()
                case .failure(let msg):
                    XCTFail(msg.localizedDescription)
            }
            
        }, receiveValue: { decodedResponse in
            XCTAssertNotNil(decodedResponse)
            XCTAssertTrue(decodedResponse.completed)
        })
        XCTAssertNotNil(cancellable)
        wait(for: [expectation], timeout: 5.0)
        
    }
    
    func testURL404NotFound() {
        
        let expectation = XCTestExpectation(description: "URL not found")
        let taskPublisher = URLSession.shared.dataTaskPublisher(for: URL(string: test404UrlString)!)
            .sink(receiveCompletion: {compln in
                switch compln {
                    case .finished:
                        break
                    case .failure(let error):
                        print("Received error \(error)")
                }
                expectation.fulfill()
            }, receiveValue: { data , response in
                guard let response = response as? HTTPURLResponse else{
                    XCTFail("unable to parse response")
                    return
                }
                
                let stringData = String(data: data, encoding: .utf8)
                print(".sink data received \(data) as \(String(describing: stringData))")
                print("http response received \(response)")
            })
        XCTAssertNotNil(taskPublisher)
        wait(for: [expectation], timeout: 5.0)
        
    }
    
    func testMax() {
        
        let passSubj = PassthroughSubject<Int,Error>()
        var latestReceivedValue: Int?
        let cancellable = passSubj
            .max()
            .sink(receiveCompletion: { compln in
                switch compln {
                    case .finished:
                        break
                    case .failure(let anError):
                        print("Received Error \(anError)")
                        break
                }
                
            }, receiveValue: { responseValue in
                print(".sink() data received \(responseValue)")
                latestReceivedValue = responseValue
            })
        passSubj.send(1)
        XCTAssertNil(latestReceivedValue)
        passSubj.send(2)
        XCTAssertNil(latestReceivedValue)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(latestReceivedValue, 2)
        passSubj.send(3)
        print("latest value \(latestReceivedValue!)")
        XCTAssertEqual(latestReceivedValue, 2)
        XCTAssertNotNil(cancellable)

    }
    
    struct ExampleStruct{
        var property1: Int
        var property2: Int?
    }
    
    func testMaxWithClosure() {
        
        let passSubj = PassthroughSubject<ExampleStruct,Error>()
        var latestValue: ExampleStruct?
        
        let cancellable = passSubj
            .max{ (struct1, struct2) -> Bool in 
                return struct1.property1 < struct2.property1
            }
            .sink(receiveCompletion: { compln in 
                switch compln {
                    case .finished:
                        break
                    case .failure(let err):
                        print("Error caused \(err)")
                        break
                }
            }, receiveValue: { value in
                print(".sink received value")
                latestValue = value
            })
        
        passSubj.send(ExampleStruct(property1: 12, property2: 2))
        XCTAssertNil(latestValue)
        passSubj.send(ExampleStruct(property1: 2, property2: 23))
        XCTAssertNil(latestValue)
        passSubj.send(completion: Subscribers.Completion.finished)
        XCTAssertEqual(latestValue?.property1, 12)
        XCTAssertEqual(latestValue?.property2, 2)
        XCTAssertNotNil(cancellable)

    }
    
    
}
