import AppKit

/// Short message near the top of the screen. Needs no notification permission.
enum Toast {
    private static var panel: NSPanel?
    private static var hideWork: DispatchWorkItem?

    static func show(_ text: String, seconds: TimeInterval = 3) {
        let screen = NotchGeometry.notchedScreen()?.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white
        label.alignment = .center
        label.preferredMaxLayoutWidth = 420
        let textSize = label.fittingSize
        let size = CGSize(width: min(max(textSize.width, 120), 420) + 32, height: textSize.height + 20)
        let origin = CGPoint(x: screen.frame.midX - size.width / 2,
                             y: screen.frame.maxY - screen.safeAreaInsets.top - 90 - size.height)

        let p = panel ?? makePanel()
        p.setFrame(CGRect(origin: origin, size: size), display: false)
        let content = p.contentView!
        content.subviews.forEach { $0.removeFromSuperview() }
        label.frame = CGRect(x: 16, y: 10, width: size.width - 32, height: textSize.height)
        content.addSubview(label)
        p.alphaValue = 1
        p.orderFrontRegardless()
        panel = p

        hideWork?.cancel()
        let work = DispatchWorkItem { p.orderOut(nil) }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private static func makePanel() -> NSPanel {
        let p = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.ignoresMouseEvents = true
        p.hidesOnDeactivate = false
        p.isReleasedWhenClosed = false
        p.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) + 1)
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        let v = NSVisualEffectView()
        v.material = .hudWindow
        v.blendingMode = .behindWindow
        v.state = .active
        v.wantsLayer = true
        v.layer?.cornerRadius = 12
        v.layer?.masksToBounds = true
        p.contentView = v
        return p
    }
}
