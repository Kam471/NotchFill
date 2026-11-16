import Foundation

/// SDL2/SDL3 games: tell SDL to use its own borderless full screen instead of a macOS
/// full screen Space. SDL then sizes the window to the whole display, notch strip included.
///
/// `launchctl setenv` changes the environment for apps that launchd starts from now on
/// (Steam, Finder, Dock). Apps that already run must be restarted. The value does not
/// survive a reboot, so the app sets it again on launch while the option is on.
enum SDLMode {
    static let variable = "SDL_VIDEO_MAC_FULLSCREEN_SPACES"

    static var isActive: Bool { launchctl(["getenv", variable]) == "0" }

    static func set(_ on: Bool) {
        if on {
            _ = launchctl(["setenv", variable, "0"])
        } else {
            _ = launchctl(["unsetenv", variable])
        }
    }

    @discardableResult
    private static func launchctl(_ args: [String]) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = args
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        do { try p.run() } catch { return "" }
        p.waitUntilExit()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
