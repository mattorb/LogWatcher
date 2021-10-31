//
//  AppDelegate.swift
//  LogWatcherSample
//
//  Created by Matthew Smith on 10/31/21.
//

import Cocoa
import SwiftUI
import LogWatcher

class AppDelegate: NSObject, NSApplicationDelegate {
    var popover : NSPopover!
    var statusBar: StatusBarController?
    var camTracker : SysLogWatcher?
    let cameraState = CurrentCameraState()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentView = PopOverContentView(cameraState: cameraState)

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 240, height:100)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
        statusBar = StatusBarController.init(popover)
        
        camTracker = SysLogWatcher(sysLogText: CameraEventProducer.sysLogText, eventProducer: CameraEventProducer()) { result in
            switch(result) {
            case .success(let event):
                switch(event) {
                case .Start:
                    DispatchQueue.main.async {
                        self.cameraState.state = .on
                    }
                case .Stop:
                    DispatchQueue.main.async {
                        self.cameraState.state = .off
                    }
                }
            case .failure(let data):
                print("Error decoding data \(data)")
            
        }
      }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

class CurrentCameraState: ObservableObject {
    @Published var state : CameraState = .unknown
}
    
enum CameraState: String {
    case on
    case off
    case unknown
}

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
