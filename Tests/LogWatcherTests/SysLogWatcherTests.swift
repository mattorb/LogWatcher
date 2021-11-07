import XCTest
@testable import LogWatcher

enum CameraEvent {
    case Start
    case Stop
}

struct CameraEventProducer: EventProducer {
    typealias SuccessResultType = CameraEvent
    
    static  let sysLogText = "Post event kCameraStream"
    
    func transformToEvent(line: String) -> CameraEvent? {
        switch(line) {
        case _ where line.contains("Post event kCameraStreamStart"):
            return .Start
        case _ where line.contains("Post event kCameraStreamStop"):
            return .Stop
        default:
            break
        }
        
        return nil  // ignored
    }
}

final class SysLogWatcherUnitTests: XCTestCase {
    func testMacOsExternalCameraEvents_OneEvent() {
        let cameraStopped = expectation(description: "Camera end")
        let pipe = Pipe()

        let _ = SysLogWatcher(sysLogText: CameraEventProducer.sysLogText, eventProducer: CameraEventProducer(), pipe: pipe) { result in
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
    
    func testMacOsExternalCameraEvents_StartAndEndSequence() {
        let cameraStarted = expectation(description: "Camera started")
        let cameraStopped = expectation(description: "Camera end")
        let pipe = Pipe()

        let _ = SysLogWatcher(sysLogText: CameraEventProducer.sysLogText, eventProducer: CameraEventProducer(), pipe: pipe) { result in
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
    
    //TODO:
    //Internal camera events look a little different, process should probably be in the query
    //AppleCameraAssistant    StartHardwareStream: creating frame receiver:  1280 x  720 (420v) [12.00,30.00]fps
    //AppleCameraAssistant    StopHardwareStream
}

final class SysLogWatcherManualIntegrationTests: XCTestCase {
    // a way to manually run, trigger video, stop video, and confirm test pass using real system log
    func skip_testManualExternalCamera() throws {
        let cameraStarted = expectation(description: "Camera started")
        let cameraStopped = expectation(description: "Camera end")
        
        let _ = SysLogWatcher(sysLogText: CameraEventProducer.sysLogText, eventProducer: CameraEventProducer()) { result in
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
        
        let result = XCTWaiter.wait(for: [cameraStarted, cameraStopped], timeout: 30.0)
        XCTAssertEqual(result, .completed, "result was \(result)")
    }
}

fileprivate extension FileHandle {
    func writeln(_ line : String) {
        self.write((line + "\n").data(using: .utf8)!)
        usleep(2000) // .002 seconds... a poor proxy for mirroring the line based buffering that comes from the stdout of a running process... this gives the the pipe time to flush each line
    }
}
