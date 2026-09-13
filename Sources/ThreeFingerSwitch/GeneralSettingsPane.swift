import SwiftUI

struct GeneralSettingsPane: View {
  @ObservedObject var settings: SettingsStore
  @ObservedObject var applications: ApplicationPreferencesModel
  @ObservedObject var launchAtLogin: LaunchAtLoginController

  var body: some View {
    SettingsPage(
      title: "General",
      subtitle: "Choose when switching runs and what appears onscreen."
    ) {
      switchingSection
      startupSection
      mappingSection
      Spacer(minLength: 8)
      restoreDefaults
    }
  }

  private var switchingSection: some View {
    SettingsSection(title: "Switching") {
      SettingsToggleRow(
        title: "Three-finger switching",
        detail: "Swipe horizontally with exactly three fingers to move between open apps.",
        isOn: $settings.isEnabled
      )
      SettingsToggleRow(
        title: "Switch indicator",
        detail: "Show the destination app’s icon after each switch.",
        isOn: $settings.showsHUD
      )
    }
  }

  private var startupSection: some View {
    SettingsSection(title: "Startup") {
      SettingsToggleRow(
        title: "Launch at login",
        detail: "Keep switching available after you sign in to your Mac.",
        isOn: Binding(
          get: { launchAtLogin.isEnabled },
          set: launchAtLogin.setEnabled
        )
      )
    }
  }

  private var mappingSection: some View {
    SettingsSection(title: "Current mapping") {
      DirectionSummary(
        leftLabel: settings.reversesDirection ? "Next app" : "Previous app",
        rightLabel: settings.reversesDirection ? "Previous app" : "Next app"
      )
      Text("Clicking an app or using Command-Tab makes it the newest item in your app history.")
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var restoreDefaults: some View {
    VStack(spacing: 22) {
      Divider()
      HStack {
        Spacer()
        Button("Restore Defaults") {
          settings.reset()
          applications.reload()
        }
      }
    }
  }
}
