import XCTest
@testable import LogWatcher

final class SysLogWatcherUnitTests: XCTestCase {
    func testMacOsExternalCameraEvents_OneEvent() {
        let cameraStopped = expectation(description: "Camera end")
        let pipe = Pipe()

        let eventProducer = CameraEventProducer()
        
        let _ = SysLogWatcher(predicates: eventProducer.predicates, eventProducer: eventProducer, pipe: pipe) { result in
            switch(result) {
            case .success(let event):
                switch(event) {
                case .Start:
                    XCTFail("should not get start event")
                case .Stop:
                    cameraStopped.fulfill()
                }
            case .failure(let data):
                print("Error decoding data \(data)")
            }
        }
        let handle = pipe.fileHandleForWriting
        handle.writeln("default    22:14:44.040481-0500    VDCAssistant    [guid:0x14140000046d082d] Post event kCameraStreamStop")

        let result = XCTWaiter.wait(for: [cameraStopped], timeout: 2.0)
        XCTAssertEqual(result, .completed)
    }
    
    func testMacOsExternalCameraEvents_BigSur_StartAndEndSequence() {
        let cameraStarted = expectation(description: "Camera started")
        let cameraStopped = expectation(description: "Camera end")
        let pipe = Pipe()

        let eventProducer = CameraEventProducer()
        
        let _ = SysLogWatcher(predicates: eventProducer.predicates, eventProducer: eventProducer, pipe: pipe) { result in
            switch(result) {
            case .success(let event):
                switch(event) {
                case .Start:
                    cameraStarted.fulfill()
                case .Stop:
                    cameraStopped.fulfill()
                }
            case .failure(let data):
                print("Error decoding data \(data)")
            }
        }
        let handle = pipe.fileHandleForWriting
        handle.writeln("some garbarge that should be ignored")
        handle.writeln("default    22:14:44.040481-0500    VDCAssistant    [guid:0x14141234446d082d] Post event kCameraStreamStart")
        handle.writeln("other misc logging kCameraStreamChanged")
        handle.writeln("default    22:20:18.574958-0500    VDCAssistant    [guid:0x14141234446d082d] Post event kCameraStreamStop")

        let result = XCTWaiter.wait(for: [cameraStarted, cameraStopped], timeout: 30.0)
        XCTAssertEqual(result, .completed, "result was \(result)")
    }
 
    // Monterey logging changed things a bit
    func testMacOsExternalCameraEvents_Monterey_StartAndEndSequence() {
        let cameraStarted = expectation(description: "Camera started")
        let cameraStopped = expectation(description: "Camera end")
        let pipe = Pipe()
        
        let eventProducer = CameraEventProducer()
        let _ = SysLogWatcher(predicates: eventProducer.predicates, eventProducer: eventProducer, pipe: pipe) { result in
            switch(result) {
            case .success(let event):
                switch(event) {
                case .Start:
                    cameraStarted.fulfill()
                case .Stop:
                    cameraStopped.fulfill()
                }
            case .failure(let data):
                print("Error decoding data \(data)")
            }
        }
        
        let handle = pipe.fileHandleForWriting
        //TODO: check if this works on Monterey
        handle.writeln("some garbarge that should be ignored")
        handle.writeln("default    22:14:44.040481-0500    UVCAssistant    [guid:0x14141234446d082d] " + """
                       Post PowerLog {
                           "VDCAssistant_Device_GUID" = "00000000-1432-0000-1234-000022470000";
                           "VDCAssistant_Power_State" = On;
                       }
                       """)
        handle.writeln("other misc logging UVCAssistant")
        handle.writeln("default    22:20:18.574958-0500    UVCAssistant    [guid:0x14141234446d082d] " + """
                       Post PowerLog {
                           "VDCAssistant_Device_GUID" = "00000000-1432-0000-1234-000022470000";
                           "VDCAssistant_Power_State" = Off;
                       }
                       """)

        let result = XCTWaiter.wait(for: [cameraStarted, cameraStopped], timeout: 5.0)
        XCTAssertEqual(result, .completed, "result was \(result)")
    }
    
    //TODO: Built in macbook camera support
    func skip_testMacbookInternalCamera() {
        //Internal camera events look a little different, process should probably be in the query
        //AppleCameraAssistant    StartHardwareStream: creating frame receiver:  1280 x  720 (420v) [12.00,30.00]fps
        //AppleCameraAssistant    StopHardwareStream
        //process = AppleCameraAssistant
    }
}

final class SysLogWatcherManualIntegrationTests: XCTestCase {
    // a way to manually monitor log messages to see how multiline handling comes through
    func skip_testShowLiveLogs() throws {
        struct EventLogger: EventProducer {
            typealias SuccessResultType = CameraEvent

            static let sysLogPredicate = "subsystem contains \"bluetooth\""

            func transformToEvent(line: String) -> CameraEvent? {
                print("B\(line)E")
                return nil  // ignored
            }
        }
        
        let _ = SysLogWatcher(predicates: [EventLogger.sysLogPredicate], eventProducer: EventLogger()) { result in
            switch(result) {
            case .success(_):
                break
            case .failure(_):
                break
            }
        }
        
        let _ = XCTWaiter.wait(for: [expectation(description: "Hold")], timeout: 1000.0)
    }
    
    // a way to manually run, trigger video, stop video, and confirm test pass using real system log
    func skip_testManualExternalCamera_BigSur() throws {
        let cameraStarted = expectation(description: "Camera started")
        let cameraStopped = expectation(description: "Camera end")

        let eventProducer = CameraEventProducer()
        
        let _ = SysLogWatcher(predicates: eventProducer.predicates, eventProducer: eventProducer) { result in
            switch(result) {
            case .success(let event):
                switch(event) {
                case .Start:
                    cameraStarted.fulfill()
                case .Stop:
                    cameraStopped.fulfill()
                }
            case .failure(let data):
                print("Error decoding data \(data)")
            }
        }
        
        let result = XCTWaiter.wait(for: [cameraStarted, cameraStopped], timeout: 5.0)
        XCTAssertEqual(result, .completed, "result was \(result)")
    }
}

fileprivate extension FileHandle {
    func writeln(_ line : String) {
        self.write((line + "\n").data(using: .utf8)!)
        usleep(2000) // .002 seconds... a poor proxy for mirroring the line based buffering that comes from the stdout of a running process... this gives the the pipe time to flush each line
    }
}
