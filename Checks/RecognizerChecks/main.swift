import Foundation
import ThreeFingerSwitchCore

private func require(
  _ condition: @autoclosure () -> Bool,
  _ message: String,
  file: StaticString = #file,
  line: UInt = #line
) {
  guard condition() else {
    fatalError("Check failed: \(message)", file: file, line: line)
  }
}

do {
  let recognizer = SwipeRecognizer()
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.20, 0.50], timestamp: 1.0) == nil,
    "right swipe should begin")
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.34, 0.51], timestamp: 1.2) == .right,
    "right swipe should trigger")
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.50, 0.50], timestamp: 1.3) == nil,
    "a held swipe should trigger only once")
}

do {
  let recognizer = SwipeRecognizer(horizontalThreshold: 0.18)
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.20, 0.50], timestamp: 1.0) == nil,
    "custom sensitivity should begin a gesture"
  )
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.34, 0.50], timestamp: 1.2) == nil,
    "a gesture below the custom threshold should not trigger"
  )
  recognizer.updateHorizontalThreshold(0.10)
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.20, 0.50], timestamp: 2.0) == nil,
    "updating sensitivity should reset the gesture"
  )
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.31, 0.50], timestamp: 2.2) == .right,
    "the updated threshold should apply"
  )
  require(SwipeDirection.left.opposite == .right, "left should reverse to right")
}

do {
  let recognizer = SwipeRecognizer()
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.70, 0.50], timestamp: 2.0) == nil,
    "left swipe should begin")
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.55, 0.49], timestamp: 2.2) == .left,
    "left swipe should trigger")
}

do {
  let recognizer = SwipeRecognizer()
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.20, 0.30], timestamp: 3.0) == nil,
    "vertical gesture should begin")
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.36, 0.45], timestamp: 3.2) == nil,
    "vertical gesture should not trigger")
}

do {
  let recognizer = SwipeRecognizer()
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.20, 0.50], timestamp: 4.0) == nil,
    "three-finger gesture should begin")
  require(
    recognizer.recognize(touchCount: 4, centroid: [0.25, 0.50], timestamp: 4.1) == nil,
    "four fingers should cancel")
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.36, 0.50], timestamp: 4.2) == nil,
    "gesture should restart after cancellation")
}

do {
  let recognizer = SwipeRecognizer()
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.20, 0.50], timestamp: 5.0) == nil,
    "slow gesture should begin")
  require(
    recognizer.recognize(touchCount: 3, centroid: [0.34, 0.50], timestamp: 6.0) == nil,
    "slow gesture should restart instead of trigger")
}

print("Recognizer checks passed")

require(
  CarouselIndex.destination(from: 0, count: 4, direction: .right) == 1,
  "right should advance"
)
require(
  CarouselIndex.destination(from: 3, count: 4, direction: .right) == 0,
  "right should wrap"
)
require(
  CarouselIndex.destination(from: 0, count: 4, direction: .left) == 3,
  "left should wrap"
)
require(
  CarouselIndex.destination(from: 0, count: 1, direction: .right) == nil,
  "a single app has no destination"
)
require(
  CarouselIndex.destination(from: -1, count: 4, direction: .right) == nil,
  "an invalid current index has no destination"
)

print("Carousel checks passed")

do {
  var cursor = CarouselCursor()
  let processIdentifiers: [Int32] = [10, 20, 30]
  require(
    cursor.sourceIndex(
      actualProcessIdentifier: 10,
      processIdentifiers: processIdentifiers,
      timestamp: 1.0
    ) == 0,
    "the carousel should start from the frontmost app"
  )
  cursor.recordDestination(processIdentifier: 20, timestamp: 1.0)
  require(
    cursor.sourceIndex(
      actualProcessIdentifier: 10,
      processIdentifiers: processIdentifiers,
      timestamp: 1.1
    ) == 1,
    "a rapid swipe should continue from the virtual destination"
  )
  require(
    cursor.sourceIndex(
      actualProcessIdentifier: 30,
      processIdentifiers: processIdentifiers,
      timestamp: 3.0
    ) == 2,
    "the cursor should reconcile with the frontmost app after a pause"
  )
}

print("Carousel cursor checks passed")
