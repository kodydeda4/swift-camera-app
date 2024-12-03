import Foundation

extension URL {
  static func shared(_ path: String) -> URL {
    URL.documentsDirectory
      .appendingPathComponent(".shared-state")
      .appending(path: path)
  }
}
