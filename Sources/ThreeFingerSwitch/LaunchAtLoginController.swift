import Combine
import ServiceManagement

final class LaunchAtLoginController: ObservableObject {
  @Published private(set) var isEnabled = SMAppService.mainApp.status == .enabled
  @Published var errorMessage: String?

  func setEnabled(_ shouldEnable: Bool) {
    do {
      if shouldEnable {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
      refresh()
    } catch {
      errorMessage =
        "Open System Settings → General → Login Items if macOS requires approval.\n\n\(error.localizedDescription)"
      refresh()
    }
  }

  func toggle() {
    setEnabled(!isEnabled)
  }

  func refresh() {
    isEnabled = SMAppService.mainApp.status == .enabled
  }
}
