import AppKit

final class AppSwitchHUD {
  private let panel: NSPanel
  private let iconView = NSImageView()
  private let nameLabel = NSTextField(labelWithString: "")
  private var hideWorkItem: DispatchWorkItem?
  private var displayGeneration = 0

  init() {
    panel = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 240, height: 108),
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
    nameLabel.stringValue = application.localizedName ?? "Application"
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
    panel.hasShadow = true
    panel.ignoresMouseEvents = true
    panel.level = .floating
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
  }

  private func configureContents() {
    let effectView = NSVisualEffectView(frame: panel.contentView?.bounds ?? .zero)
    effectView.material = .hudWindow
    effectView.blendingMode = .behindWindow
    effectView.state = .active
    effectView.wantsLayer = true
    effectView.layer?.cornerRadius = 22
    effectView.layer?.masksToBounds = true
    panel.contentView = effectView

    iconView.imageScaling = .scaleProportionallyUpOrDown
    iconView.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    nameLabel.alignment = .center
    nameLabel.lineBreakMode = .byTruncatingTail
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    effectView.addSubview(iconView)
    effectView.addSubview(nameLabel)
    activateContentConstraints(in: effectView)
  }

  private func activateContentConstraints(in effectView: NSVisualEffectView) {
    NSLayoutConstraint.activate([
      iconView.centerXAnchor.constraint(equalTo: effectView.centerXAnchor),
      iconView.topAnchor.constraint(equalTo: effectView.topAnchor, constant: 15),
      iconView.widthAnchor.constraint(equalToConstant: 52),
      iconView.heightAnchor.constraint(equalToConstant: 52),
      nameLabel.leadingAnchor.constraint(equalTo: effectView.leadingAnchor, constant: 16),
      nameLabel.trailingAnchor.constraint(equalTo: effectView.trailingAnchor, constant: -16),
      nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
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
