import AppKit

/// Hides the menu bar and the Dock (auto-hide) and puts back the user's own settings.
///
/// The original values are stored in UserDefaults before any change, so a crash or
/// force-quit can still be undone on the next launch (`restoreIfNeeded`).
final class SystemChrome {
    private enum Key {
        static let saved = "chrome.saved"            // Bool: we changed something
        static let menu = "chrome.savedMenuAutoHide" // Bool
        static let dock = "chrome.savedDockAutoHide" // Bool
    }

    private let defaults = UserDefaults.standard

    var isHidden: Bool { defaults.bool(forKey: Key.saved) }

    func hide() {
        if !isHidden {
            // nil = the user never set the key; restore then removes it again.
            if let menu = Self.menuBarAutoHide {
                defaults.set(menu, forKey: Key.menu)
            } else {
                defaults.removeObject(forKey: Key.menu)
            }
            defaults.set(Self.dockAutoHide, forKey: Key.dock)
            defaults.set(true, forKey: Key.saved)
        }
        Self.setMenuBarAutoHide(true)
        Self.setDockAutoHide(true)
    }

    func restore() {
        guard isHidden else { return }
        Self.setMenuBarAutoHide(defaults.object(forKey: Key.menu) as? Bool)
        Self.setDockAutoHide(defaults.bool(forKey: Key.dock))
        defaults.set(false, forKey: Key.saved)
    }

    /// Call on launch: if the last run ended without restoring, restore now.
    func restoreIfNeeded() { restore() }

    // MARK: Menu bar ("Automatically hide and show the menu bar: Always")

    private static let menuKey = "_HIHideMenuBar" as CFString

    /// nil when the user has never changed the setting.
    static var menuBarAutoHide: Bool? {
        CFPreferencesCopyValue(menuKey, kCFPreferencesAnyApplication,
                               kCFPreferencesCurrentUser, kCFPreferencesAnyHost) as? Bool
    }

    /// nil removes the key (macOS default: menu bar always visible).
    static func setMenuBarAutoHide(_ on: Bool?) {
        CFPreferencesSetValue(menuKey, on.map { $0 as CFBoolean }, kCFPreferencesAnyApplication,
                              kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("AppleInterfaceMenuBarHidingChangedNotification"),
            object: nil, userInfo: nil, deliverImmediately: true)
    }

    // MARK: Dock (private CoreDock calls, no Dock restart needed)

    private typealias GetFn = @convention(c) () -> Bool
    private typealias SetFn = @convention(c) (Bool) -> Void

    private static let services = dlopen("/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices", RTLD_NOW)
    private static let getDock: GetFn? = services.flatMap { dlsym($0, "CoreDockGetAutoHideEnabled") }.map { unsafeBitCast($0, to: GetFn.self) }
    private static let setDock: SetFn? = services.flatMap { dlsym($0, "CoreDockSetAutoHideEnabled") }.map { unsafeBitCast($0, to: SetFn.self) }

    static var dockAutoHide: Bool {
        if let getDock { return getDock() }
        return UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") ?? false
    }

    static func setDockAutoHide(_ on: Bool) {
        guard dockAutoHide != on else { return }
        setDock?(on)
    }
}
