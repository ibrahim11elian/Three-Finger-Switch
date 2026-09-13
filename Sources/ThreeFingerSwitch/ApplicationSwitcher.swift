import AppKit
import CoreGraphics
import ThreeFingerSwitchCore

final class ApplicationSwitcher {
  private var applications: [NSRunningApplication]
  private var cursor = CarouselCursor()
  private var excludedBundleIdentifiers = Set<String>()
  private var preferredBundleOrder = [String]()

  init() {
    applications = Self.initialApplicationOrder()
  }

  @discardableResult
  func switchApplication(_ direction: SwipeDirection) -> NSRunningApplication? {
    refreshApplications()
    let processIdentifiers = applications.map(\.processIdentifier)
    let timestamp = ProcessInfo.processInfo.systemUptime
    let sourceIndex = cursor.sourceIndex(
      actualProcessIdentifier: NSWorkspace.shared.frontmostApplication?.processIdentifier,
      processIdentifiers: processIdentifiers,
      timestamp: timestamp
    )
    guard let destinationIndex = destinationIndex(from: sourceIndex, direction: direction) else {
      return nil
    }

    let destination = applications[destinationIndex]
    guard destination.activate(options: [.activateAllWindows]) else { return nil }
    cursor.recordDestination(processIdentifier: destination.processIdentifier, timestamp: timestamp)
    return destination
  }

  func updatePreferences(excludedBundleIdentifiers: Set<String>, preferredOrder: [String]) {
    self.excludedBundleIdentifiers = excludedBundleIdentifiers
    preferredBundleOrder = preferredOrder
    applications = Self.initialApplicationOrder()
    cursor.reset()
    refreshApplications()
  }

  private func destinationIndex(from sourceIndex: Int?, direction: SwipeDirection) -> Int? {
    guard !applications.isEmpty else { return nil }
    guard let sourceIndex else {
      return direction == .right
        ? applications.startIndex : applications.index(before: applications.endIndex)
    }
    return CarouselIndex.destination(
      from: sourceIndex,
      count: applications.count,
      direction: direction
    )
  }

  private func refreshApplications() {
    applications.removeAll(where: { !isEligible($0) })
    let knownPIDs = Set(applications.map(\.processIdentifier))
    let newlyOpened = Self.initialApplicationOrder().filter {
      isEligible($0) && !knownPIDs.contains($0.processIdentifier)
    }
    applications.append(contentsOf: newlyOpened)
    applyPreferredOrder()
  }

  private func applyPreferredOrder() {
    guard !preferredBundleOrder.isEmpty else { return }
    let preferred = preferredBundleOrder.flatMap { bundleIdentifier in
      applications.filter { $0.bundleIdentifier == bundleIdentifier }
    }
    let preferredSet = Set(preferredBundleOrder)
    applications =
      preferred
      + applications.filter {
        guard let bundleIdentifier = $0.bundleIdentifier else { return true }
        return !preferredSet.contains(bundleIdentifier)
      }
  }

  private func isEligible(_ application: NSRunningApplication) -> Bool {
    guard application.activationPolicy == .regular, !application.isTerminated else { return false }
    guard let bundleIdentifier = application.bundleIdentifier else { return true }
    return !excludedBundleIdentifiers.contains(bundleIdentifier)
  }

  private static func initialApplicationOrder() -> [NSRunningApplication] {
    let running = NSWorkspace.shared.runningApplications
    let byPID = Dictionary(uniqueKeysWithValues: running.map { ($0.processIdentifier, $0) })
    let windowOrdered = windowOwnerPIDs().compactMap { byPID[$0] }
    let candidates =
      [NSWorkspace.shared.frontmostApplication].compactMap { $0 }
      + windowOrdered + running

    var seenPIDs = Set<pid_t>()
    return candidates.filter {
      $0.activationPolicy == .regular && seenPIDs.insert($0.processIdentifier).inserted
    }
  }

  private static func windowOwnerPIDs() -> [pid_t] {
    guard
      let windows = CGWindowListCopyWindowInfo(
        [.optionOnScreenOnly, .excludeDesktopElements],
        .zero
      ) as? [[CFString: Any]]
    else { return [] }

    return windows.compactMap { window in
      guard
        let layer = window[kCGWindowLayer] as? NSNumber,
        layer.intValue == 0,
        let ownerPID = window[kCGWindowOwnerPID] as? NSNumber
      else { return nil }
      return ownerPID.int32Value
    }
  }
}
