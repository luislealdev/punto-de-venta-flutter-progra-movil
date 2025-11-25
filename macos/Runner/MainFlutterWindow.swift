import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    
    // Configurar tamaño y límites de la ventana
    self.setContentSize(NSSize(width: 1200, height: 800))
    self.minSize = NSSize(width: 800, height: 600)
    self.maxSize = NSSize(width: 1600, height: 1200)
    
    // Centrar la ventana en pantalla
    self.center()
    
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
