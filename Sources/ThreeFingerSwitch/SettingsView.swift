import SwiftUI

struct SettingsView: View {
  @ObservedObject var settings: SettingsStore
  @ObservedObject var applications: ApplicationPreferencesModel
  @ObservedObject var launchAtLogin: LaunchAtLoginController

  @State private var selection = SettingsPane.general

  var body: some View {
    HStack(spacing: 0) {
      sidebar
      Divider()
      detail
    }
    .frame(width: 700, height: 540)
    .background(Color(nsColor: .windowBackgroundColor))
    .alert(
      "Couldn’t change Launch at Login",
      isPresented: launchErrorIsPresented,
      actions: { Button("OK") { launchAtLogin.errorMessage = nil } },
      message: { Text(launchAtLogin.errorMessage ?? "Unknown error") }
    )
  }

  private var sidebar: some View {
    VStack(alignment: .leading, spacing: 2) {
      ForEach(SettingsPane.allCases) { pane in
        sidebarButton(for: pane)
      }
      Spacer()
      status
    }
    .padding(10)
    .frame(width: 168)
    .background(Color(nsColor: .controlBackgroundColor).opacity(0.55))
  }

  private func sidebarButton(for pane: SettingsPane) -> some View {
    Button {
      selection = pane
    } label: {
      Label(pane.title, systemImage: pane.symbolName)
        .font(.system(size: 13, weight: .medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .contentShape(Rectangle())
    }
    .buttonStyle(SidebarButtonStyle(isSelected: selection == pane))
    .accessibilityAddTraits(selection == pane ? .isSelected : [])
  }

  private var status: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 7) {
        Circle()
          .fill(settings.isEnabled ? Color.green : Color.secondary)
          .frame(width: 7, height: 7)
        Text(settings.isEnabled ? "Switching is on" : "Switching is paused")
      }
      if let appVersion {
        Text("Version \(appVersion)")
          .padding(.leading, 14)
      }
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding(.horizontal, 11)
    .padding(.bottom, 8)
  }

  @ViewBuilder
  private var detail: some View {
    switch selection {
    case .general:
      GeneralSettingsPane(
        settings: settings,
        applications: applications,
        launchAtLogin: launchAtLogin
      )
    case .gesture:
      GestureSettingsPane(settings: settings)
    case .applications:
      ApplicationsSettingsPane(applications: applications)
    }
  }

  private var appVersion: String? {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
  }

  private var launchErrorIsPresented: Binding<Bool> {
    Binding(
      get: { launchAtLogin.errorMessage != nil },
      set: { if !$0 { launchAtLogin.errorMessage = nil } }
    )
  }
}

private enum SettingsPane: String, CaseIterable, Identifiable {
  case general
  case gesture
  case applications

  var id: String { rawValue }

  var title: String {
    switch self {
    case .general: return "General"
    case .gesture: return "Gesture"
    case .applications: return "Applications"
    }
  }

  var symbolName: String {
    switch self {
    case .general: return "gearshape"
    case .gesture: return "hand.draw"
    case .applications: return "square.stack.3d.up"
    }
  }
}

private struct SidebarButtonStyle: ButtonStyle {
  let isSelected: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(isSelected ? Color.primary : Color.secondary)
      .background {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
          .fill(
            isSelected
              ? Color.accentColor.opacity(configuration.isPressed ? 0.22 : 0.14)
              : Color.clear
          )
      }
  }
}
