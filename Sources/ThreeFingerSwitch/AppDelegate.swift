import AppKit
import Combine
import ThreeFingerSwitchCore

final class AppDelegate: NSObject, NSApplicationDelegate {
  private let settings = SettingsStore()
  private let gestureEngine = GestureEngine()
  private let device = MultitouchDevice.shared
  private let applicationSwitcher = ApplicationSwitcher()
  private let hud = AppSwitchHUD()
  private let launchAtLogin = LaunchAtLoginController()
  private lazy var applicationPreferences = ApplicationPreferencesModel(settings: settings)
  private lazy var settingsWindow = SettingsWindowController(
    settings: settings,
    applications: applicationPreferences,
    launchAtLogin: launchAtLogin
  )
  private var subscriptions = Set<AnyCancellable>()
  private var statusItem: NSStatusItem!
  private var enabledItem: NSMenuItem!
  private var launchAtLoginItem: NSMenuItem!
  private var errorMessage: String?
  private var deviceRetryTimer: Timer?

  func applicationDidFinishLaunching(_ notification: Notification) {
    configureMainMenu()
    configureStatusItem()
    configureSettingsBindings()
    configureGestureInput()
    configureWakeRecovery()
    updateMenuState()
  }

  func applicationWillTerminate(_ notification: Notification) {
    device.stop()
  }

  func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    showSettings()
    return true
  }

  private func configureGestureInput() {
    gestureEngine.onSwipe = { [weak self] direction in
      guard let self else { return }
      guard let destination = self.applicationSwitcher.switchApplication(direction) else { return }
      if self.settings.showsHUD {
        self.hud.show(application: destination)
      }
    }
    device.onFrame = { [weak gestureEngine] count, centroid, timestamp in
      gestureEngine?.receive(touchCount: count, centroid: centroid, timestamp: timestamp)
    }
    device.onError = { [weak self] error in
      DispatchQueue.main.async { self?.showDeviceError(error) }
    }
    startGestureInput()
  }

  private func configureSettingsBindings() {
    Publishers.CombineLatest3(
      settings.$isEnabled, settings.$reversesDirection, settings.$sensitivity
    )
    .sink { [weak self] isEnabled, reversesDirection, sensitivity in
      guard let self else { return }
      self.gestureEngine.update(
        isEnabled: isEnabled,
        reversesDirection: reversesDirection,
        horizontalThreshold: SettingsStore.horizontalThreshold(for: sensitivity)
      )
      DispatchQueue.main.async { self.updateMenuState() }
    }
    .store(in: &subscriptions)

    settings.$excludedBundleIdentifiers
      .sink { [weak applicationSwitcher] exclusions in
        applicationSwitcher?.updateExclusions(exclusions)
      }
      .store(in: &subscriptions)
  }

  private func configureWakeRecovery() {
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(workspaceDidWake),
      name: NSWorkspace.didWakeNotification,
      object: nil
    )
  }

  private func startGestureInput() {
    do {
      try device.start()
      errorMessage = nil
      deviceRetryTimer?.invalidate()
      deviceRetryTimer = nil
    } catch {
      errorMessage = error.localizedDescription
      scheduleDeviceRetryIfUseful(for: error)
    }
  }

  private func scheduleDeviceRetryIfUseful(for error: Error) {
    guard let deviceError = error as? MultitouchDevice.DeviceError else { return }
    guard deviceError == .trackpadUnavailable || deviceError == .startFailed else { return }
    guard deviceRetryTimer == nil else { return }
    deviceRetryTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
      self?.startGestureInput()
      self?.updateMenuState()
    }
  }

  @objc private func workspaceDidWake() {
    device.stop()
    startGestureInput()
    updateMenuState()
  }

  private func showDeviceError(_ error: MultitouchDevice.DeviceError) {
    device.stop()
    errorMessage = error.localizedDescription
    updateMenuState()
  }

  private func configureStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.image = NSImage(
      systemSymbolName: "arrow.left.arrow.right",
      accessibilityDescription: "Three Finger Switch"
    )
    statusItem.button?.image?.isTemplate = true
    statusItem.menu = makeStatusMenu()
  }

  private func makeStatusMenu() -> NSMenu {
    let menu = NSMenu()
    enabledItem = menu.addItem(
      withTitle: "Gestures Enabled",
      action: #selector(toggleEnabled),
      keyEquivalent: ""
    )
    enabledItem.target = self
    addSettingsItems(to: menu)
    addQuitItem(to: menu)
    return menu
  }

  private func addSettingsItems(to menu: NSMenu) {
    launchAtLoginItem = menu.addItem(
      withTitle: "Launch at Login",
      action: #selector(toggleLaunchAtLogin),
      keyEquivalent: ""
    )
    launchAtLoginItem.target = self
    menu.addItem(.separator())
    let settingsItem = menu.addItem(
      withTitle: "Settings…",
      action: #selector(showSettings),
      keyEquivalent: ","
    )
    settingsItem.target = self
    let setupItem = menu.addItem(
      withTitle: "Trackpad Setup…",
      action: #selector(showTrackpadSetup),
      keyEquivalent: ""
    )
    setupItem.target = self
  }

  private func addQuitItem(to menu: NSMenu) {
    menu.addItem(.separator())
    let quitItem = menu.addItem(
      withTitle: "Quit Three Finger Switch",
      action: #selector(quit),
      keyEquivalent: "q"
    )
    quitItem.target = self
  }

  @objc private func toggleEnabled() {
    guard errorMessage == nil else { return }
    settings.isEnabled.toggle()
  }

  @objc private func toggleLaunchAtLogin() {
    launchAtLogin.toggle()
    if let errorMessage = launchAtLogin.errorMessage {
      showAlert(title: "Couldn’t change Launch at Login", message: errorMessage)
      launchAtLogin.errorMessage = nil
    }
    updateMenuState()
  }

  @objc private func showSettings() {
    applicationPreferences.reload()
    launchAtLogin.refresh()
    settingsWindow.show()
  }

  @objc private func showTrackpadSetup() {
    let message =
      "In System Settings → Trackpad → More Gestures, set “Swipe between full-screen applications” to four fingers (or turn it off). This leaves three-finger horizontal swipes exclusively for this utility."
    showAlert(title: "Recommended Trackpad Setting", message: message)
  }

  @objc private func quit() {
    NSApplication.shared.terminate(nil)
  }

  private func updateMenuState() {
    if let errorMessage {
      enabledItem.title = "Unavailable: \(errorMessage)"
      enabledItem.state = .off
      enabledItem.isEnabled = false
    } else {
      enabledItem.title = "Gestures Enabled"
      enabledItem.state = settings.isEnabled ? .on : .off
      enabledItem.isEnabled = true
    }
    launchAtLoginItem.state = launchAtLogin.isEnabled ? .on : .off
  }

  private func configureMainMenu() {
    let mainMenu = NSMenu()
    let editRoot = NSMenuItem()
    let editMenu = NSMenu(title: "Edit")
    editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
    editMenu.addItem(.separator())
    editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    editMenu.addItem(
      withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    editRoot.submenu = editMenu
    mainMenu.addItem(editRoot)
    NSApplication.shared.mainMenu = mainMenu
  }

  private func showAlert(title: String, message: String) {
    NSApplication.shared.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }
}
