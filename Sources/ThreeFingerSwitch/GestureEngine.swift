import CoreGraphics
import Foundation
import ThreeFingerSwitchCore

final class GestureEngine {
  var onSwipe: ((SwipeDirection) -> Void)?

  private let lock = NSLock()
  private var recognizer = SwipeRecognizer()
  private var isEnabled = true
  private var reversesDirection = false

  func receive(touchCount: Int, centroid: SIMD2<Float>?, timestamp: TimeInterval) {
    lock.lock()
    defer { lock.unlock() }
    guard isEnabled else { return }
    guard !Self.isMouseButtonPressed else {
      recognizer.cancel()
      return
    }
    guard
      let recognizedDirection = recognizer.recognize(
        touchCount: touchCount,
        centroid: centroid,
        timestamp: timestamp
      )
    else { return }

    let direction = reversesDirection ? recognizedDirection.opposite : recognizedDirection
    DispatchQueue.main.async { [weak self] in
      self?.onSwipe?(direction)
    }
  }

  func update(isEnabled: Bool, reversesDirection: Bool, horizontalThreshold: Float) {
    lock.lock()
    defer { lock.unlock() }
    self.isEnabled = isEnabled
    self.reversesDirection = reversesDirection
    recognizer.updateHorizontalThreshold(horizontalThreshold)
  }

  private static var isMouseButtonPressed: Bool {
    CGEventSource.buttonState(.combinedSessionState, button: .left)
      || CGEventSource.buttonState(.combinedSessionState, button: .right)
      || CGEventSource.buttonState(.combinedSessionState, button: .center)
  }
}
