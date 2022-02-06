//
//  File.swift
//  
//
//  Created by Matthew Smith on 10/31/21.
//

import Foundation

public class SysLogWatcher : LogWatcher {
    // pass your own pipe in for testing
    convenience public init<T:EventProducer>(sysLogPredicate: String, eventProducer:T, pipe: Pipe? = nil, onLine:@escaping (Result<T.SuccessResultType, LogWatchError>)->Void) {
        if let overridePipe = pipe {
            self.init(source: overridePipe, eventProducer: eventProducer, onLine:onLine)
        } else {
            let process = Process()
            let pipe = Pipe()
            process.launchPath = "/usr/bin/log"
            process.arguments = ["stream", "--predicate", sysLogPredicate]
            process.standardOutput = pipe
            process.launch()
            self.init(source: pipe, eventProducer: eventProducer, onLine:onLine)
        }
    }
}
