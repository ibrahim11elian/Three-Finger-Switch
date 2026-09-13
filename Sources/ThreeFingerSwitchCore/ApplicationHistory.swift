import Foundation

public struct ApplicationHistory {
  public private(set) var processIdentifiers: [Int32]

  private let continuationInterval: TimeInterval
  private var virtualProcessIdentifier: Int32?
  private var continuationDeadline: TimeInterval = 0

  public init(
    processIdentifiers: [Int32] = [],
    continuationInterval: TimeInterval = 1.25
  ) {
    self.processIdentifiers = Self.unique(processIdentifiers)
    self.continuationInterval = continuationInterval
  }

  public mutating func synchronize(availableProcessIdentifiers: [Int32]) {
    let available = Set(availableProcessIdentifiers)
    processIdentifiers.removeAll { !available.contains($0) }

    let known = Set(processIdentifiers)
    let newlyDiscovered = Self.unique(availableProcessIdentifiers).filter { !known.contains($0) }
    processIdentifiers.insert(contentsOf: newlyDiscovered, at: 0)

    if let virtualProcessIdentifier, !available.contains(virtualProcessIdentifier) {
      self.virtualProcessIdentifier = nil
      continuationDeadline = 0
    }
  }

  public mutating func recordExternalTransition(
    previousProcessIdentifier: Int32?,
    activatedProcessIdentifier: Int32
  ) {
    if let previousProcessIdentifier,
      previousProcessIdentifier != activatedProcessIdentifier
    {
      moveToNewest(previousProcessIdentifier)
    }
    moveToNewest(activatedProcessIdentifier)
    virtualProcessIdentifier = activatedProcessIdentifier
    continuationDeadline = 0
  }

  public func destination(
    actualProcessIdentifier: Int32?,
    direction: SwipeDirection,
    timestamp: TimeInterval
  ) -> Int32? {
    guard processIdentifiers.count > 1 else { return nil }

    let sourceProcessIdentifier = activeSource(
      actualProcessIdentifier: actualProcessIdentifier,
      timestamp: timestamp
    )
    guard
      let sourceProcessIdentifier,
      let sourceIndex = processIdentifiers.firstIndex(of: sourceProcessIdentifier),
      let destinationIndex = CarouselIndex.destination(
        from: sourceIndex,
        count: processIdentifiers.count,
        direction: direction
      )
    else {
      return direction == .left ? processIdentifiers.last : processIdentifiers.first
    }
    return processIdentifiers[destinationIndex]
  }

  public mutating func recordNavigation(
    processIdentifier: Int32,
    timestamp: TimeInterval
  ) {
    virtualProcessIdentifier = processIdentifier
    continuationDeadline = timestamp + continuationInterval
  }

  private func activeSource(
    actualProcessIdentifier: Int32?,
    timestamp: TimeInterval
  ) -> Int32? {
    if timestamp <= continuationDeadline,
      let virtualProcessIdentifier,
      processIdentifiers.contains(virtualProcessIdentifier)
    {
      return virtualProcessIdentifier
    }
    return actualProcessIdentifier
  }

  private static func unique(_ processIdentifiers: [Int32]) -> [Int32] {
    var seen = Set<Int32>()
    return processIdentifiers.filter { seen.insert($0).inserted }
  }

  private mutating func moveToNewest(_ processIdentifier: Int32) {
    processIdentifiers.removeAll { $0 == processIdentifier }
    processIdentifiers.append(processIdentifier)
  }
}
