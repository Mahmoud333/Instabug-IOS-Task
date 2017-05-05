import UIKit
import XCTest

class Bug {
    enum State {
        case open
        case closed
    }
    
    let state: State
    let timestamp: Date
    let comment: String
    
    init(state: State, timestamp: Date, comment: String) {
        // To be implemented
        self.state = state
        self.timestamp = timestamp
        self.comment = comment
    }
    
    enum InvalidBugDataErro: Error {
        case EmptyState
        case EmptyStateContainSomethingElse
        case EmptyTimestamp
        case EmptyComment
        case ErrorJSONData
    }
    
    init(jsonString: String) throws {
        // To be implemented
        if let data = jsonString.data(using: .utf8) {
            
            do {
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

                guard let state = dict?["state"] as? String else {
                    throw InvalidBugDataErro.EmptyState
                }
                
                switch state {
                case "open": self.state = State.open
                case "closed": self.state = State.closed
                default:
                    throw InvalidBugDataErro.EmptyStateContainSomethingElse
                }
                
                
                if let timestamp = dict?["timestamp"] as? Double {
                    let date = Date(timeIntervalSince1970: timestamp)
                    self.timestamp = date
                } else {
                    throw InvalidBugDataErro.EmptyTimestamp
                }
                
                if let comment = dict?["comment"] as? String {
                    self.comment = comment
                } else {
                    throw InvalidBugDataErro.EmptyComment
                }

                
            } catch let error as NSError {
                throw error
            }
            
        } else {
            throw InvalidBugDataErro.ErrorJSONData
        }
    }
    
}

enum TimeRange {
    case pastDay
    case pastWeek
    case pastMonth
}

class Application {
    var bugs: [Bug]
    
    init(bugs: [Bug]) {
        self.bugs = bugs
    }
    
    func findBugs(state: Bug.State?, timeRange: TimeRange) -> [Bug] {
        // To be implemented
        var filtered = [Bug]()
        
        for bug in bugs {
            if bug.state == state {
                
                let now = Date()
                let diff = now.timeIntervalSince(bug.timestamp) / 60 / 60
                
                if diff < 24, timeRange == .pastDay{ // to 24 hours
                    filtered.append(bug)
                    break
                } else if diff < 168, timeRange == .pastWeek { // to 7 days
                    filtered.append(bug)
                    break
                } else if diff < 730, timeRange == .pastMonth { //to 30 days
                    filtered.append(bug)
                    break
                }
            }
        }
        return filtered
    }
}

class UnitTests : XCTestCase {
    
    lazy var bugs: [Bug] = {
        var date26HoursAgo = Date()
        date26HoursAgo.addTimeInterval(-1 * (26 * 60 * 60))
        
        var date2WeeksAgo = Date()
        date2WeeksAgo.addTimeInterval(-1 * (14 * 24 * 60 * 60))
        
        let bug1 = Bug(state: .open, timestamp: Date(), comment: "Bug 1")
        let bug2 = Bug(state: .open, timestamp: date26HoursAgo, comment: "Bug 2")
        let bug3 = Bug(state: .closed, timestamp: date2WeeksAgo, comment: "Bug 2")
        
        return [bug1, bug2, bug3]
    }()
    
    lazy var application: Application = {
        let application = Application(bugs: self.bugs)
        return application
    }()

    func testFindOpenBugsInThePastDay() {
        let bugs = application.findBugs(state: .open, timeRange: .pastDay)
        XCTAssertTrue(bugs.count == 1, "Invalid number of bugs")
        XCTAssertEqual(bugs[0].comment, "Bug 1", "Invalid bug order")
    }
    
    func testFindClosedBugsInThePastMonth() {
        let bugs = application.findBugs(state: .closed, timeRange: .pastMonth)
        
        XCTAssertTrue(bugs.count == 1, "Invalid number of bugs")
    }
    
    func testFindClosedBugsInThePastWeek() {
        let bugs = application.findBugs(state: .closed, timeRange: .pastWeek)
        
        XCTAssertTrue(bugs.count == 0, "Invalid number of bugs")
    }
    
    func testInitializeBugWithJSON() {
        do {
            let json = "{\"state\": \"open\",\"timestamp\": 1493393946,\"comment\": \"Bug via JSON\"}"

            let bug = try Bug(jsonString: json)
            
            XCTAssertEqual(bug.comment, "Bug via JSON")
            XCTAssertEqual(bug.state, .open)
            XCTAssertEqual(bug.timestamp, Date(timeIntervalSince1970: 1493393946))
        } catch {
            print(error)
        }
    }
}

class PlaygroundTestObserver : NSObject, XCTestObservation {
    @objc func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: UInt) {
        print("Test failed on line \(lineNumber): \(String(describing: testCase.name)), \(description)")
    }
}

let observer = PlaygroundTestObserver()
let center = XCTestObservationCenter.shared()
center.addTestObserver(observer)

TestRunner().runTests(testClass: UnitTests.self)
