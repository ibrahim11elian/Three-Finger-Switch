import Foundation

public struct CarouselCursor {
  private let continuationInterval: TimeInterval
  private var virtualProcessIdentifier: Int32?
  private var continuationDeadline: TimeInterval = 0

  public init(continuationInterval: TimeInterval = 1.25) {
    self.continuationInterval = continuationInterval
  }

  public mutating func sourceIndex(
    actualProcessIdentifier: Int32?,
    processIdentifiers: [Int32],
    timestamp: TimeInterval
  ) -> Int? {
    if timestamp <= continuationDeadline,
      let virtualProcessIdentifier,
      let virtualIndex = processIdentifiers.firstIndex(of: virtualProcessIdentifier)
    {
      return virtualIndex
    }
    virtualProcessIdentifier = actualProcessIdentifier
    return actualProcessIdentifier.flatMap(processIdentifiers.firstIndex)
  }

  public mutating func recordDestination(
    processIdentifier: Int32,
    timestamp: TimeInterval
  ) {
    virtualProcessIdentifier = processIdentifier
    continuationDeadline = timestamp + continuationInterval
  }

  public mutating func reset() {
    virtualProcessIdentifier = nil
    continuationDeadline = 0
  }
}
