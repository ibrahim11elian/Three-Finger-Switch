import Foundation

public enum SwipeDirection: Equatable {
  case left
  case right
}

extension SwipeDirection {
  public var opposite: SwipeDirection {
    self == .left ? .right : .left
  }
}

public final class SwipeRecognizer {
  private let requiredTouchCount = 3
  private var horizontalThreshold: Float
  private let verticalTolerance: Float = 0.08
  private let maximumDuration: TimeInterval = 0.85
  private var startPoint: SIMD2<Float>?
  private var startTime: TimeInterval = 0
  private var hasTriggered = false

  public init(horizontalThreshold: Float = 0.12) {
    self.horizontalThreshold = horizontalThreshold
  }

  public func updateHorizontalThreshold(_ threshold: Float) {
    horizontalThreshold = threshold
    reset()
  }

  public func cancel() {
    reset()
  }

  public func recognize(
    touchCount: Int,
    centroid: SIMD2<Float>?,
    timestamp: TimeInterval
  ) -> SwipeDirection? {
    guard touchCount == requiredTouchCount, let centroid else {
      reset()
      return nil
    }

    guard let startPoint else {
      self.startPoint = centroid
      startTime = timestamp
      hasTriggered = false
      return nil
    }

    guard !hasTriggered else { return nil }

    if timestamp - startTime > maximumDuration {
      self.startPoint = centroid
      startTime = timestamp
      return nil
    }

    let delta = centroid - startPoint
    guard abs(delta.y) <= verticalTolerance,
      abs(delta.x) >= horizontalThreshold,
      abs(delta.x) > abs(delta.y) * 1.5
    else {
      return nil
    }

    hasTriggered = true
    return delta.x > 0 ? .right : .left
  }

  private func reset() {
    startPoint = nil
    startTime = 0
    hasTriggered = false
  }
}
