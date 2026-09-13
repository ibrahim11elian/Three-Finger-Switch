import SwiftUI

struct SettingsPage<Content: View>: View {
  let title: String
  let subtitle: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(title)
        .font(.system(size: 24, weight: .semibold))
      Text(subtitle)
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.top, 4)
      VStack(alignment: .leading, spacing: 22) {
        content
      }
      .padding(.top, 25)
    }
    .padding(.horizontal, 30)
    .padding(.vertical, 26)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

struct SettingsSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 11) {
      Text(title)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.secondary)
      VStack(alignment: .leading, spacing: 13) {
        content
      }
    }
  }
}

struct SettingsToggleRow: View {
  let title: String
  let detail: String
  @Binding var isOn: Bool

  var body: some View {
    HStack(alignment: .top, spacing: 18) {
      VStack(alignment: .leading, spacing: 3) {
        Text(title)
        Text(detail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 12)
      Toggle(title, isOn: $isOn)
        .labelsHidden()
        .toggleStyle(.switch)
        .padding(.top, 2)
    }
  }
}

struct DirectionSummary: View {
  let leftLabel: String
  let rightLabel: String

  var body: some View {
    HStack(spacing: 0) {
      direction(image: "arrow.left", label: leftLabel)
      Divider()
        .padding(.vertical, 7)
      direction(image: "arrow.right", label: rightLabel)
    }
    .frame(height: 42)
    .background(Color(nsColor: .controlBackgroundColor))
    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
  }

  private func direction(image: String, label: String) -> some View {
    HStack(spacing: 8) {
      Image(systemName: image)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.secondary)
      Text(label)
        .font(.callout.weight(.medium))
    }
    .frame(maxWidth: .infinity)
  }
}
