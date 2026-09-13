import AppKit
import CoreGraphics
import ThreeFingerSwitchCore

final class ApplicationSwitcher {
  private var applications: [NSRunningApplication]
  private var history: ApplicationHistory
  private var activationTracker = SwitcherActivationTracker()
  private var excludedBundleIdentifiers = Set<String>()
  private var activationObserver: NSObjectProtocol?

  init() {
    let initialApplications = Self.initialApplicationHistory()
    applications = initialApplications
    history = ApplicationHistory(
      processIdentifiers: initialApplications.map(\.processIdentifier)
    )
    activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      self?.recordActivation(from: notification)
    }
  }

  deinit {
    if let activationObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
    }
  }

  @discardableResult
  func switchApplication(_ direction: SwipeDirection) -> NSRunningApplication? {
    refreshApplications()
    let timestamp = ProcessInfo.processInfo.systemUptime
    guard let destination = destination(for: direction, timestamp: timestamp) else { return nil }
    guard activate(destination, timestamp: timestamp) else { return nil }
    return destination
  }

  private func destination(
    for direction: SwipeDirection,
    timestamp: TimeInterval
  ) -> NSRunningApplication? {
    let destinationProcessIdentifier = history.destination(
      actualProcessIdentifier: NSWorkspace.shared.frontmostApplication?.processIdentifier,
      direction: direction,
      timestamp: timestamp
    )
    return applications.first { $0.processIdentifier == destinationProcessIdentifier }
  }

  private func activate(
    _ destination: NSRunningApplication,
    timestamp: TimeInterval
  ) -> Bool {
    activationTracker.record(
      processIdentifier: destination.processIdentifier,
      timestamp: timestamp
    )
    guard destination.activate(options: [.activateAllWindows]) else {
      activationTracker.cancel(processIdentifier: destination.processIdentifier)
      return false
    }
    history.recordNavigation(
      processIdentifier: destination.processIdentifier,
      timestamp: timestamp
    )
    return true
  }

  func updateExclusions(_ excludedBundleIdentifiers: Set<String>) {
    self.excludedBundleIdentifiers = excludedBundleIdentifiers
    refreshApplications()
  }

  private func recordActivation(from notification: Notification) {
    guard
      let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
        as? NSRunningApplication,
      isEligible(application)
    else { return }

    addIfNeeded(application)
    let timestamp = ProcessInfo.processInfo.systemUptime
    activationTracker.discardExpired(before: timestamp)
    recordObservedActivation(application, timestamp: timestamp)
    activationTracker.cancel(processIdentifier: application.processIdentifier)
  }

  private func addIfNeeded(_ application: NSRunningApplication) {
    let isKnown = applications.contains {
      $0.processIdentifier == application.processIdentifier
    }
    if !isKnown {
      applications.append(application)
    }
  }

  private func recordObservedActivation(
    _ application: NSRunningApplication,
    timestamp: TimeInterval
  ) {
    if activationTracker.isPending(processIdentifier: application.processIdentifier) {
      history.recordNavigation(
        processIdentifier: application.processIdentifier,
        timestamp: timestamp
      )
    } else {
      history.recordExternalActivation(processIdentifier: application.processIdentifier)
    }
  }

  private func refreshApplications() {
    applications.removeAll(where: { !isEligible($0) })
    let knownProcessIdentifiers = Set(applications.map(\.processIdentifier))
    let newlyDiscovered = NSWorkspace.shared.runningApplications.filter {
      isEligible($0) && !knownProcessIdentifiers.contains($0.processIdentifier)
    }
    applications.insert(contentsOf: newlyDiscovered, at: 0)
    history.synchronize(
      availableProcessIdentifiers: applications.map(\.processIdentifier)
    )
  }

  private func isEligible(_ application: NSRunningApplication) -> Bool {
    guard application.activationPolicy == .regular, !application.isTerminated else { return false }
    guard let bundleIdentifier = application.bundleIdentifier else { return true }
    return !excludedBundleIdentifiers.contains(bundleIdentifier)
  }

  private static func initialApplicationHistory() -> [NSRunningApplication] {
    let running = NSWorkspace.shared.runningApplications
    let byProcessIdentifier = Dictionary(
      uniqueKeysWithValues: running.map { ($0.processIdentifier, $0) }
    )
    let frontToBack = uniqueApplications(
      windowOwnerProcessIdentifiers().compactMap { byProcessIdentifier[$0] }
    )
    let visibleProcessIdentifiers = Set(frontToBack.map(\.processIdentifier))
    let background = running.filter {
      $0.activationPolicy == .regular
        && !visibleProcessIdentifiers.contains($0.processIdentifier)
    }
    var oldestToNewest = background + frontToBack.reversed()

    if let frontmost = NSWorkspace.shared.frontmostApplication {
      oldestToNewest.removeAll { $0.processIdentifier == frontmost.processIdentifier }
      oldestToNewest.append(frontmost)
    }
    return uniqueApplications(oldestToNewest)
  }

  private static func uniqueApplications(
    _ applications: some Sequence<NSRunningApplication>
  ) -> [NSRunningApplication] {
    var seen = Set<pid_t>()
    return applications.filter { seen.insert($0.processIdentifier).inserted }
  }

  private static func windowOwnerProcessIdentifiers() -> [pid_t] {
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
        let ownerProcessIdentifier = window[kCGWindowOwnerPID] as? NSNumber
      else { return nil }
      return ownerProcessIdentifier.int32Value
    }
  }
}
