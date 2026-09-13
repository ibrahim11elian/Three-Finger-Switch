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
    applications = uniqueChoices.values.sorted {
      $0.name.localizedStandardCompare($1.name) == .orderedAscending
    }
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
