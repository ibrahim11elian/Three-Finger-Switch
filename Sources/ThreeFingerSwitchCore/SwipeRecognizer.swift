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
  private let verticalTolerance: Float = 0.10
  private let horizontalDominanceRatio: Float = 1.25
  private let maximumDuration: TimeInterval = 1.0
  private let contactMismatchGracePeriod: TimeInterval = 0.10
  private var lastPoint: SIMD2<Float>?
  private var accumulatedMovement = SIMD2<Float>.zero
  private var startTime: TimeInterval = 0
  private var contactMismatchStartTime: TimeInterval?
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
    guard let centroid else {
      reset()
      return nil
    }
    guard touchCount == requiredTouchCount else {
      tolerateContactMismatch(touchCount: touchCount, timestamp: timestamp)
      return nil
    }
    guard reconnectAfterContactMismatch(at: centroid, timestamp: timestamp) else { return nil }
    return recognizeThreeFingerMovement(at: centroid, timestamp: timestamp)
  }

  private func recognizeThreeFingerMovement(
    at point: SIMD2<Float>, timestamp: TimeInterval
  ) -> SwipeDirection? {
    guard let lastPoint else {
      begin(at: point, timestamp: timestamp)
      return nil
    }
    guard !hasTriggered else { return nil }
    if timestamp - startTime > maximumDuration {
      begin(at: point, timestamp: timestamp)
      return nil
    }
    accumulatedMovement += point - lastPoint
    self.lastPoint = point
    guard let direction = direction(for: accumulatedMovement) else { return nil }
    hasTriggered = true
    return direction
  }

  private func direction(for movement: SIMD2<Float>) -> SwipeDirection? {
    guard abs(movement.y) <= verticalTolerance,
      abs(movement.x) >= horizontalThreshold,
      abs(movement.x) > abs(movement.y) * horizontalDominanceRatio
    else { return nil }
    return movement.x > 0 ? .right : .left
  }

  private func tolerateContactMismatch(touchCount: Int, timestamp: TimeInterval) {
    guard lastPoint != nil, touchCount == 2 || touchCount == 4 else {
      reset()
      return
    }
    guard let contactMismatchStartTime else {
      self.contactMismatchStartTime = timestamp
      return
    }
    if timestamp - contactMismatchStartTime > contactMismatchGracePeriod {
      reset()
    }
  }

  private func reconnectAfterContactMismatch(
    at point: SIMD2<Float>, timestamp: TimeInterval
  ) -> Bool {
    guard let contactMismatchStartTime else { return true }
    self.contactMismatchStartTime = nil
    guard timestamp - contactMismatchStartTime <= contactMismatchGracePeriod else {
      begin(at: point, timestamp: timestamp)
      return false
    }
    lastPoint = point
    return false
  }

  private func begin(at point: SIMD2<Float>, timestamp: TimeInterval) {
    lastPoint = point
    accumulatedMovement = .zero
    startTime = timestamp
    hasTriggered = false
  }

  private func reset() {
    lastPoint = nil
    accumulatedMovement = .zero
    startTime = 0
    contactMismatchStartTime = nil
    hasTriggered = false
  }
}
