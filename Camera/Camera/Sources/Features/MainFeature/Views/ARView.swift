import SwiftUI
import RealityKit
import ARKit

struct ARSheetView: View {
  @State var modelName: String = "coffee"
  
  var body: some View {
    ZStack {
      ARViewContainer(modelName: $modelName)
        .ignoresSafeArea(edges: .all)
    }
  }
}

struct ARViewContainer: UIViewRepresentable {
  @Binding var modelName: String
  
  func makeUIView(context: Context) -> ARView {
    let arView = ARView(frame: .zero)
    
    let config = ARWorldTrackingConfiguration()
    
    config.planeDetection = [.horizontal, .vertical]
    config.environmentTexturing = .automatic
    
    arView.session.run(config)
    
    return arView
  }
  
  func updateUIView(_ uiView: ARView, context: Context) {
    // Load the coffee model and anchor it in the real world.
    let anchorEntity = AnchorEntity(plane: .any)
    
    guard let modelEntity = try? Entity.loadModel(named: .coffee)
    else { return }
    
    anchorEntity.addChild(modelEntity)
    
    uiView.scene.addAnchor(anchorEntity)
  }
}

enum RealityKitResource: String {
  case coffee
}

extension Entity {
  @MainActor @preconcurrency
  static func loadModel(
    named resource: RealityKitResource,
    in bundle: Bundle? = nil
  ) throws -> ModelEntity {
    try Self.loadModel(named: resource.rawValue, in: bundle)
  }
}
