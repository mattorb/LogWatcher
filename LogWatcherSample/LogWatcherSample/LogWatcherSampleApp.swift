//
//  LogWatcherSampleApp.swift
//  LogWatcherSample
//
//  Created by Matthew Smith on 10/31/21.
//

import SwiftUI

@main
struct LogWatcherSampleApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  /*  via https://stackoverflow.com/a/65789202/827681 */
  var body: some Scene {
    Settings {
      EmptyView()
    }
  }
}
