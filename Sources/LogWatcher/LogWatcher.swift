import Foundation
import XCTest

public enum LogWatchError: Error {
    case decodingError(Data)
}

public protocol EventProducer {
    associatedtype SuccessResultType
    func transformToEvent(line: String) -> SuccessResultType?  // produce nothing to not emit
}

public class LogWatcher {
    public init<T:EventProducer>(source: Pipe, eventProducer:T, onLine:@escaping (Result<T.SuccessResultType, LogWatchError>)->Void) {
        let outHandle = source.fileHandleForReading
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: .utf8) {
                
                if let event = eventProducer.transformToEvent(line: line) {
                    print("Converted line \(line) to event \(event)")
                    onLine(.success(event))
                }
            } else {
                onLine(.failure(.decodingError(pipe.availableData)))
            }
        }
    }
}

public class SysLogWatcher : LogWatcher {
    // pass your own pipe in for testing
    convenience public init<T:EventProducer>(sysLogText: String, eventProducer:T, pipe: Pipe? = nil, onLine:@escaping (Result<T.SuccessResultType, LogWatchError>)->Void) {
        if let overridePipe = pipe {
            self.init(source: overridePipe, eventProducer: eventProducer, onLine:onLine)
        } else {
            let process = Process()
            let pipe = Pipe()
            process.launchPath = "/usr/bin/log"
            process.arguments = ["stream", "--predicate", "eventMessage contains \"\(sysLogText)\""]
            process.standardOutput = pipe
            process.launch()
            self.init(source: pipe , eventProducer: eventProducer, onLine:onLine)
        }
    }
}
