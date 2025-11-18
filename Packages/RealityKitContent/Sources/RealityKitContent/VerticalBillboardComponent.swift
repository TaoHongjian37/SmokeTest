//import RealityKit
//import ARKit
//import OSLog
//import QuartzCore
//
//// 标记“要竖直朝向用户”的组件
//public struct VerticalBillboardComponent: Component, Codable {
//    public init() {}
//}
//
//public struct VerticalBillboardSystem: System {
//
//    // 查询所有挂了 VerticalBillboardComponent 的实体
//    public static let query = EntityQuery(where: .has(VerticalBillboardComponent.self))
//
//    // visionOS 的 ARKit 会话 + 世界追踪
//    private let arkitSession = ARKitSession()
//    private let worldTracking = WorldTrackingProvider()
//
//    // MARK: - 初始化（⚠️ 这里一定要启动 Session）
//    public init(scene: RealityKit.Scene) {
//        runSession()
//    }
//
//    @MainActor
//    private func runSession() {
//        Task {
//            do {
//                try await arkitSession.run([worldTracking])
//            } catch {
//                Logger().error("ARKitSession error: \(String(describing: error))")
//            }
//        }
//    }
//
//    // MARK: - 每帧更新
//
//    public func update(context: SceneUpdateContext) {
//        // 0. worldTracking 还没 running 就先不算
//        guard worldTracking.state == .running else { return }
//
//        // 1. 拿当前设备（Vision Pro）相机的 transform
//        guard let deviceAnchor = worldTracking.queryDeviceAnchor(
//            atTimestamp: CACurrentMediaTime()
//        ) else {
//            return
//        }
//
//        let cameraTransform = Transform(matrix: deviceAnchor.originFromAnchorTransform)
//        let cameraPos = cameraTransform.translation
//
//        // 2. 找到所有带 VerticalBillboardComponent 的实体
//        let entities = context.scene.performQuery(Self.query)
//
//        for entity in entities {
//            let entityPos = entity.position(relativeTo: nil)
//
//            // 3. 忽略高度差，只用水平向量
//            var target = cameraPos
//            target.y = entityPos.y
//
//            // 4. 让实体只绕 Y 轴旋转去面对相机
//            entity.look(
//                at: target,
//                from: entityPos,
//                upVector: [0, 1, 0],
//                relativeTo: nil
//            )
//        }
//    }
//}



import RealityKit
import ARKit
import OSLog
import QuartzCore

public struct VerticalBillboardComponent: Component, Codable {
    public init() {}
}

public struct VerticalBillboardSystem: System {

    // 查询所有挂了 VerticalBillboardComponent 的实体
    public static let query = EntityQuery(where: .has(VerticalBillboardComponent.self))

    // visionOS 的 ARKit 会话 + 世界追踪
    private let arkitSession = ARKitSession()
    private let worldTracking = WorldTrackingProvider()

    // 用 static 变量做调试计数，避免去改 self
    private  var debugFrameCounter: Int = 0

    // MARK: - 初始化

    public init(scene: RealityKit.Scene) {
        print("🧭 VerticalBillboardSystem init")
        runSession()
    }

    @MainActor
    private func runSession() {
        print("🧭 VerticalBillboardSystem: start ARKitSession with WorldTrackingProvider")
        Task {
            do {
                try await arkitSession.run([worldTracking])
                print("✅ VerticalBillboardSystem: ARKitSession running")
            } catch {
                Logger().error("ARKitSession error: \(String(describing: error))")
            }
        }
    }

    // MARK: - 每帧更新

    public mutating func update(context: SceneUpdateContext) {
        // 每次先自增一帧计数
        self.debugFrameCounter += 1

        // 0. 检查 tracking 状态
        guard worldTracking.state == .running else {

            return
        }

        let now = CACurrentMediaTime()

        // 1. 拿当前设备（Vision Pro）相机的 transform
        guard let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: now) else {
            
            return
        }

        let cameraTransform = Transform(matrix: deviceAnchor.originFromAnchorTransform)
        let cameraPos = cameraTransform.translation

        // 2. ⭐ 关键优化：用 context.entities(..., updatingSystemWhen: .rendering)
        //    而不是 context.scene.performQuery(...)
        let entities = context.entities(
            matching: Self.query,
            updatingSystemWhen: .rendering
        )

       // let flipRotation = simd_quatf(angle: .pi, axis: [0, 1, 0])


        // 3. 更新所有 billboard 实体，使它们“竖直地”朝向用户
        for entity in entities {
            let entityPos = entity.position(relativeTo: nil)

            // 忽略高度差，只用水平向量
            var target = cameraPos
            target.y = entityPos.y

            entity.look(
                at: target,
                from: entityPos,
                upVector: [0, 1, 0],
                relativeTo: nil
            )
            
           // entity.transform.rotation = flipRotation * entity.transform.rotation
        }
    }
}
