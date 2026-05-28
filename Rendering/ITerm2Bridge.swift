import Foundation

class ITerm2Bridge {

    private let framePath: URL
    private let absoluteFilePath: String
    private var lastUpdateTime: Double = 0.0
    private let updateInterval: Double = 1.0 / 45.0

    private let scriptQueue = DispatchQueue(label: "com.shader.iterm2bridge", qos: .utility)
    private var isUpdating = false

    init(framePath: URL) {
        self.framePath = framePath
        self.absoluteFilePath = framePath.path
        print("ITerm2Bridge initialized - Frame path: \(absoluteFilePath)")
    }

    func notifyFrameUpdate() {
        let currentTime = ProcessInfo.processInfo.systemUptime

        guard currentTime - lastUpdateTime >= updateInterval else {
            return
        }

        lastUpdateTime = currentTime

        scriptQueue.async { [weak self] in
            self?.runAppleScript()
        }
    }

    func isITerm2Running() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-x", "iTerm2"]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        try? task.run()
        task.waitUntilExit()
        return task.terminationStatus == 0
    }

    func forceUpdateViaAppleScript() {
        scriptQueue.async { [weak self] in
            self?.runAppleScript()
        }
    }

    private func runAppleScript() {
        guard !isUpdating else { return }
        isUpdating = true

        let script = """
        tell application "iTerm2"
            tell current session of current window
                set background image to "\(absoluteFilePath)"
            end tell
        end tell
        """

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            // Silently ignore — iTerm2 may not be focused
        }

        isUpdating = false
    }
}
