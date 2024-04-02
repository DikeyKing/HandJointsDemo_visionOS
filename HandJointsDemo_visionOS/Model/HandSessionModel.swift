/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Hand tracking updates.
*/

#if targetEnvironment(simulator)
import ARKit
import RealityKit
#else
@preconcurrency import ARKit
@preconcurrency import RealityKit
#endif
import SwiftUI

/// A model that contains up-to-date hand coordinate information.
@MainActor
class HandSessionModel: ObservableObject, @unchecked Sendable {
    let session = ARKitSession()
    var handTracking = HandTrackingProvider()
    @Published var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
    
    // 用来存储手模型
    var handGestureModel: HandGestureModel = .init()
    
    var callbackCounterRight = -1
    var callbackCounterLeft = -1
    var startTimeLeft = Date()
    var startTimeRight = Date()

    struct HandsUpdates {
        var left: HandAnchor?
        var right: HandAnchor?
    }
    
    func start() async {
        do {
            if HandTrackingProvider.isSupported {
                print("ARKitSession starting.")
                try await session.run([handTracking])
            }
        } catch {
            print("ARKitSession error:", error)
        }
    }
    
    func publishHandTrackingUpdates() async {
        for await update in handTracking.anchorUpdates {
            switch update.event {
            case .updated:
                let anchor = update.anchor
                
                // Publish updates only if the hand and the relevant joints are tracked.
                guard anchor.isTracked else { continue }

                // Update left hand info.
                if anchor.chirality == .left {

                    latestHandTracking.left = anchor
                    if (callbackCounterLeft == -1){
                        callbackCounterLeft = 0
                        startTimeLeft = Date()
                    }
                    // Increase the counter every time the callback is fired
                    callbackCounterLeft += 1
                } else if anchor.chirality == .right { // Update right hand info.

                    latestHandTracking.right = anchor
                    if (callbackCounterRight == -1){
                        callbackCounterRight = 0
                        startTimeRight = Date()
                    }
                    // Increase the counter every time the callback is fired
                    callbackCounterRight += 1
                }
                handGestureModel.updateHandTrackingUpdates(latestHandTracking)

                // Calculate and print the average number of callbacks per second
                let elapsedTime = Date().timeIntervalSince(startTimeLeft)
                let averageCallbacksPerSecondLeft = Double(callbackCounterLeft) / elapsedTime
                let averageCallbacksPerSecondRight = Double(callbackCounterRight) / elapsedTime
                print("Average callbacks per second Left: \(averageCallbacksPerSecondLeft)")
                print("Average callbacks per second Right: \(averageCallbacksPerSecondRight)")

            default:
                break
            }
        }
    }
    
    func monitorSessionEvents() async {
        for await event in session.events {
            switch event {
            case .authorizationChanged(let type, let status):
                if type == .handTracking && status != .allowed {
                    // Stop the game, ask the user to grant hand tracking authorization again in Settings.
                }
            default:
                print("Session event \(event)")
            }
        }
    }

}
