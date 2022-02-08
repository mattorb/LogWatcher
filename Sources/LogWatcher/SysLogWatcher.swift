//
//  File.swift
//  
//
//  Created by Matthew Smith on 10/31/21.
//

import Foundation

public class SysLogWatcher : LogWatcher {
    // pass your own pipe in for testing
    convenience public init<T:EventProducer>(predicates: [String], eventProducer:T, pipe: Pipe? = nil, onLine:@escaping (Result<T.SuccessResultType, LogWatchError>)->Void) {
        if let overridePipe = pipe {
            self.init(source: overridePipe, eventProducer: eventProducer, onLine:onLine)
        } else {
            let process = Process()
            let pipe = Pipe()
            process.launchPath = "/usr/bin/log"
            process.arguments = ["stream", "--predicate", predicates.joined(separator: " OR ")]
            process.standardOutput = pipe
            process.launch()
            self.init(source: pipe, eventProducer: eventProducer, onLine:onLine)
        }
    }
}

public enum CameraEvent {
    case Start
    case Stop
}

struct BigSurCameraEventProducer: EventProducer {
    public typealias SuccessResultType = CameraEvent

    public static let sysLogPredicate = "eventMessage contains \"Post event kCameraStream\""

    public func transformToEvent(line: String) -> CameraEvent? {
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

struct MontereyCameraEventProducer: EventProducer {
    typealias SuccessResultType = CameraEvent

    static let sysLogPredicate = "subsystem contains \"com.apple.UVCExtension\" and composedMessage contains \"Post PowerLog\""
    
    public func transformToEvent(line: String) -> CameraEvent? {
        switch(line) {
        case _ where line.contains("\"VDCAssistant_Power_State\" = On;"):
            return .Start
        case _ where line.contains("\"VDCAssistant_Power_State\" = Off;"):
            return .Stop
        default:
            break
        }
        
        return nil  // ignored
    }
}

public struct CameraEventProducer: EventProducer {
    public typealias SuccessResultType = CameraEvent

    public var predicates: [String] {
        [BigSurCameraEventProducer.sysLogPredicate, MontereyCameraEventProducer.sysLogPredicate]
    }
    
    let montereyExternal = MontereyCameraEventProducer()
    let bigSurExternal = BigSurCameraEventProducer()
    
    public init() {
        // make it accessible outside the module
    }
    
    public func transformToEvent(line: String) -> CameraEvent? {
        if let event = montereyExternal.transformToEvent(line: line) {
            return event
        } else if let event = bigSurExternal.transformToEvent(line: line) {
            return event
        } else {
            return nil // ignored
        }
    }
}
