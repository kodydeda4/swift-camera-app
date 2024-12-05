import Foundation

extension Result where Failure == Swift.Error {
  /// Creates a new result by evaluating a throwing closure, capturing the returned value as
  /// a success, or any thrown error as a failure.
  ///
  /// - Parameter body: A throwing closure to evaluate.
  @_transparent
  public init(catching body: () throws -> Success) {
    do {
      self = .success(try body())
    } catch {
      self = .failure(error)
    }
  }
}
