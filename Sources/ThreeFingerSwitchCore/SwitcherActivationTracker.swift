import Foundation

public struct SwitcherActivationTracker {
  private let notificationInterval: TimeInterval
  private var deadlines = [Int32: TimeInterval]()

  public init(notificationInterval: TimeInterval = 2) {
    self.notificationInterval = notificationInterval
  }

  public mutating func record(processIdentifier: Int32, timestamp: TimeInterval) {
    deadlines[processIdentifier] = timestamp + notificationInterval
  }

  public mutating func discardExpired(before timestamp: TimeInterval) {
    deadlines = deadlines.filter { $0.value >= timestamp }
  }

  public func isPending(processIdentifier: Int32) -> Bool {
    deadlines[processIdentifier] != nil
  }

  public mutating func cancel(processIdentifier: Int32) {
    deadlines.removeValue(forKey: processIdentifier)
  }
}
