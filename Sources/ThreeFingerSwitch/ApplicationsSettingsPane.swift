import SwiftUI

struct ApplicationsSettingsPane: View {
  @ObservedObject var applications: ApplicationPreferencesModel

  var body: some View {
    SettingsPage(
      title: "Applications",
      subtitle: "Choose which open apps appear and arrange their carousel order."
    ) {
      listHeader
      applicationList
    }
  }

  private var listHeader: some View {
    HStack {
      Text("Included: \(includedApplicationCount) of \(applications.applications.count)")
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
      Button {
        applications.reload()
      } label: {
        Label("Refresh", systemImage: "arrow.clockwise")
      }
    }
  }

  @ViewBuilder
  private var applicationList: some View {
    if applications.applications.isEmpty {
      emptyState
    } else {
      List(applications.applications) { application in
        applicationRow(application)
      }
      .listStyle(.inset)
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      .overlay { listBorder }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 9) {
      Image(systemName: "square.stack.3d.up.slash")
        .font(.system(size: 30, weight: .light))
        .foregroundStyle(.tertiary)
      Text("No Open Applications")
        .font(.headline)
      Text("Open another app, then refresh this list.")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var listBorder: some View {
    RoundedRectangle(cornerRadius: 8, style: .continuous)
      .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
      .allowsHitTesting(false)
  }

  private func applicationRow(_ application: ApplicationChoice) -> some View {
    HStack(spacing: 10) {
      inclusionToggle(for: application)
      Image(nsImage: application.icon)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 28, height: 28)
      applicationName(application)
      Spacer()
      reorderControls(for: application)
    }
    .padding(.vertical, 3)
  }

  private func inclusionToggle(for application: ApplicationChoice) -> some View {
    Toggle(
      "Include \(application.name)",
      isOn: Binding(
        get: { applications.isIncluded(application.id) },
        set: { applications.setIncluded($0, bundleIdentifier: application.id) }
      )
    )
    .labelsHidden()
  }

  private func applicationName(_ application: ApplicationChoice) -> some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(application.name)
        .lineLimit(1)
      Text(applications.isIncluded(application.id) ? "Included" : "Skipped")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private func reorderControls(for application: ApplicationChoice) -> some View {
    ControlGroup {
      reorderButton(for: application, offset: -1, symbol: "chevron.up", label: "earlier")
      reorderButton(for: application, offset: 1, symbol: "chevron.down", label: "later")
    }
    .controlSize(.small)
  }

  private func reorderButton(
    for application: ApplicationChoice,
    offset: Int,
    symbol: String,
    label: String
  ) -> some View {
    Button {
      applications.move(application.id, offset: offset)
    } label: {
      Image(systemName: symbol)
    }
    .disabled(!applications.canMove(application.id, offset: offset))
    .accessibilityLabel("Move \(application.name) \(label)")
  }

  private var includedApplicationCount: Int {
    applications.applications.filter { applications.isIncluded($0.id) }.count
  }
}
