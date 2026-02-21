import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    // Windows mapped by Display ID
    var windows: [CGDirectDisplayID: NSWindow] = [:]
    var streamViews: [CGDirectDisplayID: StreamView] = [:]
    
    // Mapping DisplayID to Friendly Number (1, 2, 3...)
    var displayFriendlyNames: [CGDirectDisplayID: Int] = [:]
    var nextFriendlyIndex = 1
    
    var connector: VirtualConnector!
    var statusItem: NSStatusItem!
    
    // Onboarding
    var onboardingWindowController: OnboardingWindow?
    
    // local fileLog removed, using global one

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Enforce Menu Bar app behavior (no Dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        fileLog("App Launched - Monitra Virtual")
        
        // Setup Status Bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let imageURL = Bundle.main.url(forResource: "monitra_virtual", withExtension: "svg"),
               let image = NSImage(contentsOf: imageURL) {
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "VD Manager"
            }
        }
        
        // Init Connector
        connector = VirtualConnector()
        
        updateMenu()
        
        // Show Onboarding if needed
        let defaults = UserDefaults.standard
        // Reset for testing if needed, or use a new key for the 'refined' onboarding
        if !defaults.bool(forKey: "didShowWelcomeRefined_v2") {
            showOnboarding()
            defaults.set(true, forKey: "didShowWelcomeRefined_v2")
        }
    }
    
    func showOnboarding() {
        onboardingWindowController = OnboardingWindow()
        onboardingWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    func updateMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Virtual Displays: \(connector.virtualDisplays.count)", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Create New Display", action: #selector(createNewDisplay), keyEquivalent: "n"))
        
        if !connector.virtualDisplays.isEmpty {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Active Displays:", action: nil, keyEquivalent: ""))
            
            for (displayID, _) in connector.virtualDisplays {
                let displayMenu = NSMenu()
                
                let showMirrorItem = NSMenuItem(title: "Show Mirror Window", action: #selector(showMirror(_:)), keyEquivalent: "")
                showMirrorItem.tag = Int(displayID)
                displayMenu.addItem(showMirrorItem)
                
                let snapLeftItem = NSMenuItem(title: "Snap Left (Split)", action: #selector(snapWindowLeft(_:)), keyEquivalent: "")
                snapLeftItem.tag = Int(displayID)
                displayMenu.addItem(snapLeftItem)
                
                let snapRightItem = NSMenuItem(title: "Snap Right (Split)", action: #selector(snapWindowRight(_:)), keyEquivalent: "")
                snapRightItem.tag = Int(displayID)
                displayMenu.addItem(snapRightItem)
                
                let closeMirrorItem = NSMenuItem(title: "Close Mirror", action: #selector(closeMirror(_:)), keyEquivalent: "")
                closeMirrorItem.tag = Int(displayID)
                displayMenu.addItem(closeMirrorItem)
                
                displayMenu.addItem(NSMenuItem.separator())
                
                let disconnectItem = NSMenuItem(title: "Disconnect", action: #selector(disconnectDisplay(_:)), keyEquivalent: "")
                disconnectItem.tag = Int(displayID)
                displayMenu.addItem(disconnectItem)
                
                let friendlyIndex = displayFriendlyNames[displayID] ?? 0
                let menuItem = NSMenuItem(title: "Display \(friendlyIndex)", action: nil, keyEquivalent: "")
                menuItem.submenu = displayMenu
                menu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Show Welcome Guide", action: #selector(openOnboarding), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Fix Empty Screen (Permissions)", action: #selector(openPermissionsHelp), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Monitra Virtual", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func createNewDisplay() {
        // High Quality by default (HiDPI)
        if let id = connector.createVirtualDisplay(width: 1920, height: 1080, hiDPI: true) {
            fileLog("Created display \(id)")
            print("Created display \(id)")
            
            // Assign friendly name
            displayFriendlyNames[id] = nextFriendlyIndex
            nextFriendlyIndex += 1
            
            // Auto open mirror for convenience
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.openMirrorWindow(for: id)
            }
        } else {
             fileLog("Failed to create display")
        }
        updateMenu()
    }
    
    @objc func disconnectDisplay(_ sender: NSMenuItem) {
        let displayID = CGDirectDisplayID(sender.tag)
        fileLog("Disconnecting display \(displayID)")
        closeMirrorInternal(displayID)
        connector.removeDisplay(displayID: displayID)
        
        // We keep the friendly index incrementing to avoid confusion (Display 1, deleted, created -> Display 2)
        displayFriendlyNames.removeValue(forKey: displayID)
        
        updateMenu()
    }
    
    @objc func showMirror(_ sender: NSMenuItem) {
        let displayID = CGDirectDisplayID(sender.tag)
        openMirrorWindow(for: displayID)
    }
    
    @objc func closeMirror(_ sender: NSMenuItem) {
        let displayID = CGDirectDisplayID(sender.tag)
        closeMirrorInternal(displayID)
    }
    
    func closeMirrorInternal(_ displayID: CGDirectDisplayID) {
        if let win = windows[displayID] {
            win.close()
            windows.removeValue(forKey: displayID)
        }
        if let view = streamViews[displayID] {
            view.stop()
            streamViews.removeValue(forKey: displayID)
        }
    }
    
    func openMirrorWindow(for displayID: CGDirectDisplayID) {
        if windows[displayID] != nil {
            windows[displayID]?.makeKeyAndOrderFront(nil)
            return
        }
        
        fileLog("Setting up mirror for display \(displayID)")
        print("Setting up mirror for display \(displayID)")
        
        // Window size (match display or smaller)
        let windowRect = NSRect(x: 100, y: 100, width: 960, height: 540) // Half size for preview
        let window = NSWindow(contentRect: windowRect,
                          styleMask: [.titled, .closable, .resizable, .miniaturizable],
                          backing: .buffered, defer: false)
        let friendlyIndex = displayFriendlyNames[displayID] ?? 0
        window.title = "Monitra Virtual Display \(friendlyIndex)"
        window.level = .floating // Keep it floating
        window.isReleasedWhenClosed = false
        window.acceptsMouseMovedEvents = true // Critical for tracking mouse position
        
        let streamView = StreamView(frame: window.contentView!.bounds, displayID: displayID)
        streamView.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(streamView)
        streamView.start()
        
        windows[displayID] = window
        streamViews[displayID] = streamView
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func snapWindowLeft(_ sender: NSMenuItem) {
        let displayID = CGDirectDisplayID(sender.tag)
        snapWindow(displayID, side: .left)
    }
    
    @objc func snapWindowRight(_ sender: NSMenuItem) {
        let displayID = CGDirectDisplayID(sender.tag)
        snapWindow(displayID, side: .right)
    }
    
    enum SnapSide { case left, right }
    
    func snapWindow(_ displayID: CGDirectDisplayID, side: SnapSide) {
        // Ensure window exists
        openMirrorWindow(for: displayID)
        guard let window = windows[displayID] else { return }
        
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        
        let newWidth = visibleFrame.width / 2
        let newHeight = visibleFrame.height
        
        var newX = visibleFrame.origin.x
        if side == .right {
            newX += newWidth
        }
        
        let newFrame = NSRect(x: newX, y: visibleFrame.origin.y, width: newWidth, height: newHeight)
        
        // Remove title bar for seamless look (optional)
        // window.styleMask = [.borderless] 
        // Keeping title bar for now so user can move it if they want
        
        window.setFrame(newFrame, display: true, animate: true)
    }

    @objc func openOnboarding() {
        showOnboarding()
    }
    
    @objc func openPermissionsHelp() {
        let alert = NSAlert()
        alert.messageText = "Fixing Empty/Black Screen"
        alert.informativeText = "If you see a black screen, macOS is likely blocking Screen Recording.\n\n1. Open System Settings.\n2. Go to Privacy & Security > Screen Recording.\n3. Remove 'Monitra Virtual' (- button).\n4. Restart this app and click 'Allow' when asked."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        for (_, view) in streamViews {
            view.stop()
        }
    }
}
