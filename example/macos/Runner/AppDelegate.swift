import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationWillFinishLaunching(_ notification: Notification) {
    // Force light appearance before any UI is created
    NSApp.appearance = NSAppearance(named: .aqua)
    super.applicationWillFinishLaunching(notification)
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Ensure light appearance persists
    NSApp.appearance = NSAppearance(named: .aqua)
    
    // Force all windows to light appearance
    for window in NSApp.windows {
      window.appearance = NSAppearance(named: .aqua)
      window.backgroundColor = NSColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1.0)
    }
    
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
