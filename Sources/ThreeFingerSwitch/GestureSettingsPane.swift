import SwiftUI

struct GestureSettingsPane: View {
  @ObservedObject var settings: SettingsStore

  var body: some View {
    SettingsPage(
      title: "Gesture",
      subtitle: "Tune the swipe without making accidental switches easier."
    ) {
      sensitivitySection
      directionSection
      protectionSection
      Spacer(minLength: 8)
    }
  }

  private var sensitivitySection: some View {
    SettingsSection(title: "Sensitivity") {
      HStack(alignment: .firstTextBaseline) {
        Text("Swipe distance")
        Spacer()
        Text(sensitivityName)
          .font(.callout.weight(.medium))
          .foregroundStyle(.secondary)
      }
      Slider(value: $settings.sensitivity, in: 0...1)
        .accessibilityLabel("Swipe sensitivity")
        .accessibilityValue(sensitivityName)
      sensitivityRange
    }
  }

  private var sensitivityRange: some View {
    HStack {
      Text("Longer swipe")
      Spacer()
      Text("Shorter swipe")
    }
    .font(.caption)
    .foregroundStyle(.tertiary)
  }

  private var directionSection: some View {
    SettingsSection(title: "Direction") {
      SettingsToggleRow(
        title: "Reverse directions",
        detail: "Swap which side moves forward and backward through the carousel.",
        isOn: $settings.reversesDirection
      )
      DirectionSummary(
        leftLabel: settings.reversesDirection ? "Next app" : "Previous app",
        rightLabel: settings.reversesDirection ? "Previous app" : "Next app"
      )
    }
  }

  private var protectionSection: some View {
    SettingsSection(title: "Accidental-swipe protection") {
      Label("Requires exactly three trackpad contacts", systemImage: "checkmark.circle.fill")
      Label("Ignores mostly vertical or slow movement", systemImage: "checkmark.circle.fill")
    }
    .font(.callout)
    .foregroundStyle(.secondary)
  }

  private var sensitivityName: String {
    switch settings.sensitivity {
    case ..<0.34: return "Low"
    case ..<0.67: return "Balanced"
    default: return "High"
    }
  }
}
