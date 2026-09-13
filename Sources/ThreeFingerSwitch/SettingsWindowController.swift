import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
  init(
    settings: SettingsStore,
    applications: ApplicationPreferencesModel,
    launchAtLogin: LaunchAtLoginController
  ) {
    let rootView = SettingsView(
      settings: settings,
      applications: applications,
      launchAtLogin: launchAtLogin
    )
    let window = NSWindow(contentViewController: NSHostingController(rootView: rootView))
    window.title = "Three Finger Switch"
    window.styleMask = [.titled, .closable, .miniaturizable]
    window.setContentSize(NSSize(width: 700, height: 540))
    window.contentMinSize = NSSize(width: 700, height: 540)
    window.contentMaxSize = NSSize(width: 700, height: 540)
    window.isReleasedWhenClosed = false
    window.sharingType = .readOnly
    window.center()
    super.init(window: window)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) is unavailable")
  }

  func show() {
    NSApplication.shared.activate(ignoringOtherApps: true)
    window?.center()
    window?.makeKeyAndOrderFront(nil)
  }
}
