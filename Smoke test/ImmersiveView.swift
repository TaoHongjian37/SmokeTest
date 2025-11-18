//
//  ImmersiveView.swift
//  Smoke test
//
//  Created by Tao on 2025/11/15.
//


import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {

    init(){
        VerticalBillboardSystem.registerSystem()
        VerticalBillboardComponent.registerComponent()
    }
    
    var body: some View {
        RealityView { content in
            if let immersive = try? await Entity(named: "Immersive",in: realityKitContentBundle
            ) {
                content.add(immersive)
                if let candle = immersive.findEntity(named: "candle") {
                    if let smoke = candle.findEntity(named: "Cube") {
                        
                        smoke.components.set(VerticalBillboardComponent())
                    }
                }
            }
        }
    }
}


#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
