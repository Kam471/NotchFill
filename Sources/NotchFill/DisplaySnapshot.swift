import AppKit
import ScreenCaptureKit

/// Diagnostics: one screenshot of the built-in display through ScreenCaptureKit.
enum DisplaySnapshot {
    static func write(to path: String) async -> Bool {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            let id = NotchGeometry.notchedScreen()?.displayID ?? CGMainDisplayID()
            guard let display = content.displays.first(where: { $0.displayID == id }) else { return false }
            let me = content.applications.filter { $0.processID == getpid() }
            let filter = SCContentFilter(display: display, excludingApplications: me, exceptingWindows: [])
            let cfg = SCStreamConfiguration()
            cfg.width = display.width
            cfg.height = display.height
            cfg.showsCursor = false
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: cfg)
            let rep = NSBitmapImageRep(cgImage: image)
            guard let data = rep.representation(using: .png, properties: [:]) else { return false }
            return FileManager.default.createFile(atPath: path, contents: data)
        } catch {
            NSLog("NotchFill diagnostics: snapshot failed: %@", error.localizedDescription)
            return false
        }
    }
}
