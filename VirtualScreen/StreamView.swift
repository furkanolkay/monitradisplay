import Cocoa
import CoreGraphics

class StreamView: NSView {
    private var streamWrapper: DisplayStreamWrapper?
    private var displayID: CGDirectDisplayID
    
    private var cursorLayer: CALayer?
    private var trackingTimer: Timer?
    
    init(frame frameRect: NSRect, displayID: CGDirectDisplayID) {
        self.displayID = displayID
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.contentsGravity = .resizeAspect
        
        // Setup software cursor layer (Standard Arrow)
        let cursor = CAShapeLayer()
        let path = CGMutablePath()
        
        // Draw arrow pointing DOWN-RIGHT (Standard macOS pointer)
        // In NSView (Bottom-Left origin), "Down" is negative Y.
        // Tip at (0,0)
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -16))       // Left edge down
        path.addLine(to: CGPoint(x: 4.5, y: -12.5))    // Base cut
        path.addLine(to: CGPoint(x: 7, y: -18))        // Tail left
        path.addLine(to: CGPoint(x: 9, y: -17))        // Tail bottom
        path.addLine(to: CGPoint(x: 6.5, y: -11.5))    // Tail right
        path.addLine(to: CGPoint(x: 11, y: -11.5))     // Right edge
        path.closeSubpath()
        
        cursor.path = path
        cursor.fillColor = NSColor.white.cgColor
        cursor.strokeColor = NSColor.black.cgColor
        cursor.lineWidth = 1.0
        
        // Shadow for better visibility
        cursor.shadowOpacity = 0.3
        cursor.shadowRadius = 1
        cursor.shadowOffset = CGSize(width: 0.5, height: -0.5)
        
        cursor.bounds = CGRect(x: 0, y: -20, width: 15, height: 20) // Bounds cover the shape
        cursor.anchorPoint = CGPoint(x: 0, y: 1) // Anchor at Top-Left of the bounds?
        // Actually, since we draw starting at 0,0 and go negative, the shape is in the IV quadrant.
        // Let's stick to (0,0) anchor and bounds (0,0,0,0) to blindly trust path relative to position?
        // CAShapeLayer ignores bounds for path drawing usually, but hit testing uses it.
        // Let's set anchor to (0,0) and not mess with bounds offset.
        cursor.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
        cursor.anchorPoint = CGPoint(x: 0, y: 0) 
        
        cursor.zPosition = 999
        cursor.isHidden = true
        self.layer?.addSublayer(cursor)
        self.cursorLayer = cursor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func start() {
        // Request the stream at the Native Resolution of the display
        let mode = CGDisplayCopyDisplayMode(displayID)
        let pixelWidth = mode?.pixelWidth ?? Int(CGDisplayPixelsWide(displayID))
        let pixelHeight = mode?.pixelHeight ?? Int(CGDisplayPixelsHigh(displayID))
        
        fileLog("StreamView: Requesting stream at \(pixelWidth)x\(pixelHeight) for display \(displayID)")
        
        // Use the ObjC wrapper
        self.streamWrapper = DisplayStreamWrapper(displayID: displayID, width: pixelWidth, height: pixelHeight) { [weak self] (status, displayTime, frameSurface, updateRef) in
            guard let self = self, let surface = frameSurface else { return }
            
            if status == .frameComplete {
                DispatchQueue.main.async {
                    self.layer?.contents = surface
                    if let scale = self.window?.backingScaleFactor {
                        self.layer?.contentsScale = scale
                    }
                }
            }
        }
        
        if let wrapper = self.streamWrapper {
            wrapper.start()
            fileLog("StreamView: Display stream started for display \(displayID)")
        } else {
            fileLog("StreamView: Failed to create DisplayStreamWrapper for \(displayID)")
        }
        
        // Start polling for mouse position
        self.trackingTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updateCursor()
        }
    }
    
    func stop() {
        self.streamWrapper?.stop()
        self.streamWrapper = nil
        self.trackingTimer?.invalidate()
        self.trackingTimer = nil
    }
    
    private func updateCursor() {
        // Get global mouse location (screen coordinates, bottom-left origin)
        let mouseLoc = NSEvent.mouseLocation
        
        // Get Virtual Display Bounds
        let displayBounds = CGDisplayBounds(displayID) // Top-left origin usually in CG, but let's check
        // NSEvent.mouseLocation is in Cocoa Screen Coordinates (Bottom-Left origin of MAIN screen 0,0)
        // CGDisplayBounds is in Global Display Coordinates (Top-Left origin of MAIN screen 0,0)
        
        // We need to convert NSEvent.mouseLocation to CG Coordinates
        // In Cocoa, (0,0) is bottom-left of primary screen.
        // In CG, (0,0) is top-left of primary screen.
        // And y axis is flipped.
        
        guard let mainScreenHeight = NSScreen.screens.first?.frame.height else { return }
        let cgMouseY = mainScreenHeight - mouseLoc.y
        let cgMousePt = CGPoint(x: mouseLoc.x, y: cgMouseY)
        
        // Check if point is inside our virtual display
        if displayBounds.contains(cgMousePt) {
            // Calculate relative position (0.0 to 1.0)
            let relativeX = (cgMousePt.x - displayBounds.minX) / displayBounds.width
            let relativeY = (cgMousePt.y - displayBounds.minY) / displayBounds.height
            
            // Map to View
            let viewWidth = self.bounds.width
            let viewHeight = self.bounds.height
            
            // View is using CALayer which is bottom-up (Cocoa) or top-down?
            // NSView layer backed usually matches NSView coordinates (Bottom-Up)
            
            let targetX = viewWidth * relativeX
            // In NSView (Bottom-Up), Y=0 is bottom.
            // relativeY is 0 (top of screen) to 1 (bottom of screen) because CG is Top-Down.
            // So ViewY = viewHeight * (1 - relativeY)
             let targetY = viewHeight * (1.0 - relativeY)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            // Cursor hotpoint is (0,0) (Tip)
            // Position is set to targetX, targetY (Mouse Location)
            // Path is drawn (0,0) -> Negative Y (Down)
            // So tip aligns perfectly with position.
            
            self.cursorLayer?.position = CGPoint(x: targetX, y: targetY)
            self.cursorLayer?.isHidden = false
            CATransaction.commit()
        } else {
             // Hide cursor if not on this display
             self.cursorLayer?.isHidden = true
        }
    }
    
    // Disable manual forwarding/handling
    override var acceptsFirstResponder: Bool { return false }
}
