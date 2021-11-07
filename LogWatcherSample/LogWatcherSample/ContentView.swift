//
//  ContentView.swift
//  LogWatcherSample
//
//  Created by Matthew Smith on 10/31/21.
//

import SwiftUI

struct PopOverContentView: View {
    @ObservedObject var cameraState : CurrentCameraState
    
    var body: some View {
        VStack {
            Text("Camera is \(cameraState.state.rawValue)")
                .padding(30)
                .truncationMode(.middle)
            Button("Quit") {
                NSApp.terminate(nil)
            }.padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PopOverContentView(cameraState: CurrentCameraState())
     }
 }
