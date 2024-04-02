//
//  HandJointsDemo_visionOSApp.swift
//  HandJointsDemo_visionOS
//
//  Created by Dikey King on 2024/3/12.
//

import SwiftUI

@main
struct HandJointsDemo_visionOSApp: App {
    
    @State private var immersionState: ImmersionStyle = .mixed

    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
        .immersionStyle(selection: $immersionState, in: .mixed)
    }
}
