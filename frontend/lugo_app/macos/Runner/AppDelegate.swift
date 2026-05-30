import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    NSApp.setActivationPolicy(.regular)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      NSApp.activate(ignoringOtherApps: true)
      NSApp.windows.forEach { window in
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
      }
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
