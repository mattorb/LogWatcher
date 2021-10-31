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
