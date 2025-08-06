import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // Configure window appearance before Flutter loads
    self.appearance = NSAppearance(named: .aqua)
    self.backgroundColor = NSColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1.0)
    
    // Set up Flutter view controller
    let flutterViewController = FlutterViewController()
    
    // Force light appearance on the view controller
    flutterViewController.view.appearance = NSAppearance(named: .aqua)
    
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // Ensure content view has light appearance
    if let contentView = self.contentView {
      contentView.wantsLayer = true
      contentView.layer?.backgroundColor = NSColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1.0).cgColor
      contentView.appearance = NSAppearance(named: .aqua)
    }
    
    RegisterGeneratedPlugins(registry: flutterViewController)
    
    super.awakeFromNib()
  }
  
  override var appearance: NSAppearance? {
    get {
      return NSAppearance(named: .aqua)
    }
    set {
      // Ignore any attempts to change appearance
    }
  }
}
