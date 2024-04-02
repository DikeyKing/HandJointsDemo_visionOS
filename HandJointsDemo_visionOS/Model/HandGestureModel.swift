#if targetEnvironment(simulator)
import ARKit
#else
@preconcurrency import ARKit
#endif
import SwiftUI
import RealityKit

class HandGestureModel {
    
    enum HandSide:String {
        case left
        case right
    }
    
    var latestHandTracking: HandSessionModel.HandsUpdates = .init(left: nil, right: nil)
    var leftJointAnchorEntities:[HandSkeleton.JointName:AnchorEntity] = [:]
    var rightJointAnchorEntities:[HandSkeleton.JointName:AnchorEntity] = [:]

    // 一个用于存储每个关节轴线的字典
    var leftAxisLines: [HandSkeleton.JointName: (x: ModelEntity, y: ModelEntity, z: ModelEntity)] = [:]
    var rightAxisLines: [HandSkeleton.JointName: (x: ModelEntity, y: ModelEntity, z: ModelEntity)] = [:]

    /// 准备关节实体
    func prepareJointsEntities(){
        createAnchorEntities(for: &leftJointAnchorEntities, handSide: .left)
        createAnchorEntities(for: &rightJointAnchorEntities, handSide: .right)
    }

    /// 根据手关节创建 Anchor
    func createAnchorEntities(for jointAnchorEntities: inout [HandSkeleton.JointName:AnchorEntity], 
                              handSide:HandSide) {
        for jointName in HandSkeleton.JointName.allCases {
                        
            // 画球

            let entity = ModelEntity(mesh: .generateSphere(radius: 0.003), materials: [SimpleMaterial()]) // 创建模型
            let jointAnchor = AnchorEntity(world: simd_float4x4(1)) // 使用单位矩阵创建锚点
            jointAnchor.addChild(entity) // 将球体实体添加到锚点上
            jointAnchorEntities[jointName] = jointAnchor
            
            // 画线
            
            // 创建坐标轴线并添加到 jointAnchor 上
            let xLine = createLineEntity(from: SIMD3<Float>(0, 0, 0), to: SIMD3<Float>(0.01, 0, 0), color: .red)
            let yLine = createLineEntity(from: SIMD3<Float>(0, 0, 0), to: SIMD3<Float>(0, 0.01, 0), color: .green)
            let zLine = createLineEntity(from: SIMD3<Float>(0, 0, 0), to: SIMD3<Float>(0, 0, 0.01), color: .blue)
            
            jointAnchor.addChild(xLine)
            jointAnchor.addChild(yLine)
            jointAnchor.addChild(zLine)
            
            // 存放到字典中
            if handSide == .left{
                leftAxisLines[jointName] = (xLine, yLine, zLine)
            }else{
                rightAxisLines[jointName] = (xLine, yLine, zLine)
            }

        }
    }
    
    /// 更新手关键 Anchor 的位置
    func updateHandTrackingUpdates(_ handTracking:HandSessionModel.HandsUpdates){
        latestHandTracking.left = handTracking.left
        latestHandTracking.right = handTracking.right
        
        updateHandTrackingFor(&leftJointAnchorEntities, handAnchor: latestHandTracking.left, handSide: .left)
        updateHandTrackingFor(&rightJointAnchorEntities, handAnchor: latestHandTracking.right, handSide: .right)
    }

    /// 更新关节位置
    func updateHandTrackingFor(_ jointAnchorEntities: inout [HandSkeleton.JointName:AnchorEntity],
                               handAnchor: HandAnchor?,
                               handSide: HandSide) {
        
        if let handAnchor = handAnchor {
            for jointName in HandSkeleton.JointName.allCases {
                // print("Dikey:gesture:1:jointName = \(jointName)")
                if let handThumbKnuckle =  handAnchor.handSkeleton?.joint(jointName),
                   let jointAnchor = jointAnchorEntities[jointName]
                {
                    // 左手的关节到原点的位置
                    // 两个变换矩阵的乘法。
                    // 首先是从手部锚点（leftHandAnchor）到原点的变换
                    // 然后是从关节（leftHandThumbKnuckle）到手部锚点的变换
                    let originFromHandThumbKnuckleMatrix = matrix_multiply(
                        handAnchor.originFromAnchorTransform, handThumbKnuckle.anchorFromJointTransform
                    )
                    
                    // 更新 jointAnchor 位置
                    jointAnchor.transform = Transform(matrix: originFromHandThumbKnuckleMatrix)
                    
                    // .columns.3.xyz 这部分代码提取了变换矩阵中的某一部分，表示从拇指关节到原点的相对位置在3D坐标空间中的 (x, y, z) 坐标。
                    let position = originFromHandThumbKnuckleMatrix.columns.3.xyz
                    if handSide == .left{
                        for (_, (xLine, yLine, zLine)) in leftAxisLines {
                            xLine.scale = SIMD3<Float>(position.x, xLine.scale.y, xLine.scale.z)
                            yLine.scale = SIMD3<Float>(yLine.scale.x, position.y, yLine.scale.z)
                            zLine.scale = SIMD3<Float>(zLine.scale.x, zLine.scale.y, position.z)
                        }
                    }else if handSide == .right{
                        for (_, (xLine, yLine, zLine)) in rightAxisLines {
                            xLine.scale = SIMD3<Float>(position.x, xLine.scale.y, xLine.scale.z)
                            yLine.scale = SIMD3<Float>(yLine.scale.x, position.y, yLine.scale.z)
                            zLine.scale = SIMD3<Float>(zLine.scale.x, zLine.scale.y, position.z)
                        }
                    }

                }
            }
        } else {
            print("warning:Dikey:updateHandTrackingUpdates:\(handSide) HandAnchor = nil")
        }
    }
  
    // 画线
    // 创建一条线从原点到一个给定的点
    func createLineEntity(from start: SIMD3<Float>, to end: SIMD3<Float>, color: UIColor) -> ModelEntity {
        let diff = end - start
        let length = length(diff)
        let midPoint = start + diff / 2.0
        let cylinderMesh = MeshResource.generateCylinder(height: length, radius: 0.001)
        let material = UnlitMaterial(color: color)
        let modelEntity = ModelEntity(mesh: cylinderMesh, materials: [material])
        modelEntity.position = midPoint

        let direction = normalize(diff)
        let up = SIMD3<Float>(0.0, 1.0, 0.0)
        let axis = cross(direction, up)
        let angle = acos(dot(direction, up))

        modelEntity.transform.rotation = simd_quatf(angle: angle, axis: axis)
        return modelEntity
    }

    // 创建并添加坐标轴线条
    func addAxisLines(to anchor: AnchorEntity) {
        let xLine = createLineEntity(from: SIMD3<Float>(0, 0, 0), to: SIMD3<Float>(0.1, 0, 0), color: .red)
        let yLine = createLineEntity(from: SIMD3<Float>(0, 0, 0), to: SIMD3<Float>(0, 0.1, 0), color: .green)
        let zLine = createLineEntity(from: SIMD3<Float>(0, 0, 0), to: SIMD3<Float>(0, 0, 0.1), color: .blue)

        anchor.addChild(xLine)
        anchor.addChild(yLine)
        anchor.addChild(zLine)
    }

}
