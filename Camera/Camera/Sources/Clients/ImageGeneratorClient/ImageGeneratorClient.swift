import AVFoundation
import Dependencies
import DependenciesMacros
import SwiftUI

@DependencyClient
struct ImageGeneratorClient: Sendable {
  var image: @Sendable (AVAsset) async throws -> GenerateImageResponse?

  typealias GenerateImageResponse = (
    image: CGImage,
    actualTime: CMTime
  )
}

extension DependencyValues {
  var imageGenerator: ImageGeneratorClient {
    get { self[ImageGeneratorClient.self] }
    set { self[ImageGeneratorClient.self] = newValue }
  }
}

extension ImageGeneratorClient: DependencyKey {
  static var liveValue = Self { asset in
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    return try await generator.image(at: .zero)
  }
}
