//
//  ImmersiveView.swift
//  HandJointsDemo_visionOS
//
//  Created by Dikey King on 2024/3/12.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct ImmersiveView: View {
    
    @StateObject private var handSessionModel = HandSessionModel()

    var body: some View {
        RealityView { content in
            if let scene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(scene)
            }
            addChildEntityWithallHandJoints(content: content)
        }update: { updateContent in
            
        }
        .task {
            await handSessionModel.start()
        }
        .task {
            await handSessionModel.publishHandTrackingUpdates()
        }
        .task {
            await handSessionModel.monitorSessionEvents()
        }
    }
    
    func addChildEntityWithallHandJoints(content: RealityViewContent){
        handSessionModel.handGestureModel.prepareJointsEntities()
        
        let leftJointAnchorEntities:[HandSkeleton.JointName:AnchorEntity] = handSessionModel.handGestureModel.leftJointAnchorEntities
        for (_ , anchorEntity) in leftJointAnchorEntities{
            content.add(anchorEntity)
        }

        let rightJointAnchorEntities:[HandSkeleton.JointName:AnchorEntity] = handSessionModel.handGestureModel.rightJointAnchorEntities
        for (_ , anchorEntity) in rightJointAnchorEntities{
            content.add(anchorEntity)
        }
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
