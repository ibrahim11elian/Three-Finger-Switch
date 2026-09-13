import AppKit
import Combine

struct ApplicationChoice: Identifiable {
  let id: String
  let name: String
  let icon: NSImage
}

final class ApplicationPreferencesModel: ObservableObject {
  @Published private(set) var applications = [ApplicationChoice]()

  private let settings: SettingsStore

  init(settings: SettingsStore) {
    self.settings = settings
    reload()
  }

  func reload() {
    let choices = NSWorkspace.shared.runningApplications.compactMap(Self.choice)
    let uniqueChoices = Dictionary(
      choices.map { ($0.id, $0) },
      uniquingKeysWith: { first, _ in
        first
      })
    applications = ordered(Array(uniqueChoices.values))
  }

  func isIncluded(_ bundleIdentifier: String) -> Bool {
    !settings.excludedBundleIdentifiers.contains(bundleIdentifier)
  }

  func setIncluded(_ isIncluded: Bool, bundleIdentifier: String) {
    if isIncluded {
      settings.excludedBundleIdentifiers.remove(bundleIdentifier)
    } else {
      settings.excludedBundleIdentifiers.insert(bundleIdentifier)
    }
  }

  func move(_ bundleIdentifier: String, offset: Int) {
    guard let currentIndex = applications.firstIndex(where: { $0.id == bundleIdentifier }) else {
      return
    }
    let destinationIndex = currentIndex + offset
    guard applications.indices.contains(destinationIndex) else { return }
    applications.swapAt(currentIndex, destinationIndex)
    settings.preferredBundleOrder = applications.map(\.id)
  }

  func canMove(_ bundleIdentifier: String, offset: Int) -> Bool {
    guard let currentIndex = applications.firstIndex(where: { $0.id == bundleIdentifier }) else {
      return false
    }
    return applications.indices.contains(currentIndex + offset)
  }

  private func ordered(_ choices: [ApplicationChoice]) -> [ApplicationChoice] {
    let byIdentifier = Dictionary(uniqueKeysWithValues: choices.map { ($0.id, $0) })
    let preferred = settings.preferredBundleOrder.compactMap { byIdentifier[$0] }
    let preferredSet = Set(settings.preferredBundleOrder)
    let remaining = choices.filter { !preferredSet.contains($0.id) }
      .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    return preferred + remaining
  }

  private static func choice(for application: NSRunningApplication) -> ApplicationChoice? {
    guard application.activationPolicy == .regular,
      let bundleIdentifier = application.bundleIdentifier,
      let name = application.localizedName
    else { return nil }
    return ApplicationChoice(
      id: bundleIdentifier,
      name: name,
      icon: application.icon ?? NSImage(size: NSSize(width: 32, height: 32))
    )
  }
}
