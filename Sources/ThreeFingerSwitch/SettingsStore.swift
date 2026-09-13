import Combine
import Foundation

final class SettingsStore: ObservableObject {
  @Published var isEnabled: Bool { didSet { save() } }
  @Published var sensitivity: Double { didSet { save() } }
  @Published var reversesDirection: Bool { didSet { save() } }
  @Published var showsHUD: Bool { didSet { save() } }
  @Published var excludedBundleIdentifiers: Set<String> { didSet { save() } }

  private enum Key {
    static let isEnabled = "isEnabled"
    static let sensitivity = "sensitivity"
    static let reversesDirection = "reversesDirection"
    static let showsHUD = "showsHUD"
    static let excludedBundleIdentifiers = "excludedBundleIdentifiers"
  }

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    isEnabled = defaults.object(forKey: Key.isEnabled) as? Bool ?? true
    sensitivity = Self.normalizedSensitivity(
      defaults.object(forKey: Key.sensitivity) as? Double ?? 0.6)
    reversesDirection = defaults.object(forKey: Key.reversesDirection) as? Bool ?? false
    showsHUD = defaults.object(forKey: Key.showsHUD) as? Bool ?? true
    excludedBundleIdentifiers = Set(
      Self.validBundleIdentifiers(
        defaults.stringArray(forKey: Key.excludedBundleIdentifiers) ?? []))
  }

  static func horizontalThreshold(for sensitivity: Double) -> Float {
    Float(0.20 - normalizedSensitivity(sensitivity) * 0.13)
  }

  func reset() {
    isEnabled = true
    sensitivity = 0.6
    reversesDirection = false
    showsHUD = true
    excludedBundleIdentifiers = []
  }

  private func save() {
    defaults.set(isEnabled, forKey: Key.isEnabled)
    defaults.set(sensitivity, forKey: Key.sensitivity)
    defaults.set(reversesDirection, forKey: Key.reversesDirection)
    defaults.set(showsHUD, forKey: Key.showsHUD)
    defaults.set(Array(excludedBundleIdentifiers).sorted(), forKey: Key.excludedBundleIdentifiers)
  }

  private static func normalizedSensitivity(_ sensitivity: Double) -> Double {
    min(max(sensitivity.isFinite ? sensitivity : 0.6, 0), 1)
  }

  private static func validBundleIdentifiers(_ identifiers: [String]) -> [String] {
    var seen = Set<String>()
    return identifiers.filter { !$0.isEmpty && seen.insert($0).inserted }
  }
}
