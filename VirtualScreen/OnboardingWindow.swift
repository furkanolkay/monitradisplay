import Cocoa

class OnboardingWindow: NSWindowController {
    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                              styleMask: [.titled, .closable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.center()
        window.title = "Welcome to Monitra Virtual"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        
        let visualEffect = NSVisualEffectView(frame: window.contentView!.bounds)
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(visualEffect)
        
        let label = NSTextField(labelWithString: "Welcome to Monitra Virtual!")
        label.font = NSFont.systemFont(ofSize: 32, weight: .bold)
        label.alignment = .center
        label.frame = NSRect(x: 0, y: 300, width: 600, height: 50)
        visualEffect.addSubview(label)
        
        let instructions = """
        Monitra allows you to create virtual displays and mirror them.
        
        1. Click the "VD" / Logo in the Menu Bar.
        2. Select "Create New Display".
        3. A mirror window will appear.
        
        black screen?
        use the "Fix Empty Screen" menu item to reset permissions.
        """
        
        let instructionsLabel = NSTextField(labelWithString: instructions)
        instructionsLabel.font = NSFont.systemFont(ofSize: 14)
        instructionsLabel.alignment = .center
        instructionsLabel.textColor = .white
        instructionsLabel.frame = NSRect(x: 50, y: 100, width: 500, height: 180)
        visualEffect.addSubview(instructionsLabel)
        
        let button = NSButton(title: "Get Started", target: nil, action: nil)
        button.bezelStyle = .rounded
        button.frame = NSRect(x: 250, y: 50, width: 100, height: 30)
        visualEffect.addSubview(button)
        
        self.init(window: window)
        
        button.target = self
        button.action = #selector(closeWindow)
    }
    
    @objc func closeWindow() {
        self.window?.close()
    }
}
