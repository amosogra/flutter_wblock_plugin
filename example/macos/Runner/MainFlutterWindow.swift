import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Force light appearance
    self.appearance = NSAppearance(named: .aqua)
    self.backgroundColor = NSColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1.0) // #F5F5F7
    
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
