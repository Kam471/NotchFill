// Test app: enters native full screen, prints the window frame, exits.
// Build: swiftc -O tools/fullscreen-probe.swift -o build/fullscreen-probe
// Env: HOLD=<seconds in full screen> (default 1).

import AppKit
class D: NSObject, NSApplicationDelegate, NSWindowDelegate {
  var w: NSWindow!
  func applicationDidFinishLaunching(_ n: Notification) {
    let sel = NSSelectorFromString("_safeApertureCompatibilityMode"); if NSApp.responds(to: sel) { typealias F = @convention(c) (AnyObject, Selector) -> Int; print("mode:", unsafeBitCast(NSApp.method(for: sel), to: F.self)(NSApp, sel), "env:", ProcessInfo.processInfo.environment["_NS_SAFE_APERTURE_COMPATIBILITY_MODES"] ?? "-", ProcessInfo.processInfo.environment["APPLE_DISPLAY_SAFE_AREA_COMPATIBILITY_MODE"] ?? "-") }
    w = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 600, height: 400), styleMask: [.titled, .resizable, .closable], backing: .buffered, defer: false)
    w.collectionBehavior = [.fullScreenPrimary]
    w.backgroundColor = .systemRed
    w.contentView = Pattern()
    w.delegate = self
    w.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.w.toggleFullScreen(nil) }
  }
  func windowDidEnterFullScreen(_ n: Notification) {
    DispatchQueue.main.asyncAfter(deadline: .now() + (Double(ProcessInfo.processInfo.environment["HOLD"] ?? "1") ?? 1)) {
      print("FULLSCREEN frame:", self.w.frame, "screen:", self.w.screen!.frame, "safe:", self.w.screen!.safeAreaInsets.top, "backing:", self.w.convertToBacking(self.w.contentView!.bounds).size, "scale:", self.w.backingScaleFactor)
      let wid = CGWindowID(self.w.windowNumber)
      if let info = CGWindowListCopyWindowInfo([.optionIncludingWindow], wid) as? [[String: Any]] { print("CG bounds:", info.first?[kCGWindowBounds as String] ?? "-") }
      self.w.toggleFullScreen(nil)
    }
  }
  func windowDidExitFullScreen(_ n: Notification) { NSApp.terminate(nil) }
}
let app = NSApplication.shared
app.setActivationPolicy(.regular)
let d = D(); app.delegate = d
DispatchQueue.main.asyncAfter(deadline: .now() + 600) { print("timeout"); exit(1) }
app.run()
final class Pattern: NSView {
  override func draw(_ r: NSRect) {
    NSGradient(starting: .systemIndigo, ending: .systemTeal)!.draw(in: bounds, angle: 90)
    NSColor.systemRed.setFill(); NSRect(x: 0, y: bounds.height - 40, width: bounds.width, height: 40).fill()
    NSColor.systemYellow.setFill(); NSRect(x: 0, y: bounds.height - 4, width: bounds.width, height: 4).fill()
    ("TOP STRIP — window height \(Int(bounds.height)) pt" as NSString).draw(at: NSPoint(x: 40, y: bounds.height - 34), withAttributes: [.font: NSFont.boldSystemFont(ofSize: 22), .foregroundColor: NSColor.white])
  }
}
