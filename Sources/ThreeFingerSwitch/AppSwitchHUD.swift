import AppKit

final class AppSwitchHUD {
  private let panel: NSPanel
  private let iconView = NSImageView()
  private var hideWorkItem: DispatchWorkItem?
  private var displayGeneration = 0

  init() {
    panel = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 80, height: 80),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    configurePanel()
    configureContents()
  }

  func show(application: NSRunningApplication) {
    hideWorkItem?.cancel()
    displayGeneration += 1
    let generation = displayGeneration
    iconView.image = application.icon
    positionOnActiveScreen()
    panel.alphaValue = 1
    panel.orderFrontRegardless()

    let hideWorkItem = DispatchWorkItem { [weak self] in self?.hide(generation: generation) }
    self.hideWorkItem = hideWorkItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: hideWorkItem)
  }

  private func configurePanel() {
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.ignoresMouseEvents = true
    panel.level = .floating
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
  }

  private func configureContents() {
    let contentView = NSView(frame: panel.contentView?.bounds ?? .zero)
    panel.contentView = contentView

    iconView.imageScaling = .scaleProportionallyUpOrDown
    iconView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(iconView)
    NSLayoutConstraint.activate([
      iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 64),
      iconView.heightAnchor.constraint(equalToConstant: 64),
    ])
  }

  private func positionOnActiveScreen() {
    guard let screen = NSScreen.main else { return }
    let visibleFrame = screen.visibleFrame
    let origin = NSPoint(
      x: visibleFrame.midX - panel.frame.width / 2,
      y: visibleFrame.minY + visibleFrame.height * 0.22
    )
    panel.setFrameOrigin(origin)
  }

  private func hide(generation: Int) {
    guard generation == displayGeneration else { return }
    guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
      panel.orderOut(nil)
      return
    }
    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.18
      panel.animator().alphaValue = 0
    } completionHandler: { [weak self] in
      guard let self, generation == self.displayGeneration else { return }
      self.panel.orderOut(nil)
    }
  }
}
