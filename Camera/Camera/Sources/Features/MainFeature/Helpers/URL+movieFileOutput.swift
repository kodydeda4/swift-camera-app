import Foundation

extension URL {
  /// A unique output location to write a movie.
  internal static func movieFileOutput(id: UUID) -> URL {
    URL.temporaryDirectory
      .appending(component: id.uuidString)
      .appendingPathExtension(for: .quickTimeMovie)
  }
}
