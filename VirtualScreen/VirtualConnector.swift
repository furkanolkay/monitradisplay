import Foundation
import CoreGraphics

class VirtualConnector {
    // Store displays by their ID
    internal var virtualDisplays: [CGDirectDisplayID: CGVirtualDisplay] = [:]
    private let queue = DispatchQueue(label: "com.virtualdisplay.queue")
    
    // Returns the displayID if successful, nil otherwise
    func createVirtualDisplay(width: UInt32 = 1920, height: UInt32 = 1080, hiDPI: Bool = true) -> CGDirectDisplayID? {
        let descriptor = CGVirtualDisplayDescriptor()
        
        descriptor.dispatchQueue = queue
        descriptor.name = "Monitra Display"
        descriptor.maxPixelsWide = width * (hiDPI ? 2 : 1)
        descriptor.maxPixelsHigh = height * (hiDPI ? 2 : 1)
        // Physical size: roughly 24 inch monitor size
        descriptor.sizeInMillimeters = CGSize(width: 530, height: 300) 
        descriptor.productID = UInt32(0x1234 + virtualDisplays.count) 
        descriptor.vendorID = 0x5678
        descriptor.serialNum = UInt32(0x0001 + virtualDisplays.count)
        
        descriptor.terminationHandler = { [weak self] (display, error) in
            print("Virtual Display Terminated: \(String(describing: error))")
            if let display = display as? CGVirtualDisplay {
                 self?.virtualDisplays.removeValue(forKey: display.displayID)
            }
        }

        guard let display = CGVirtualDisplay(descriptor: descriptor) else {
            print("Failed to instantiate CGVirtualDisplay")
            return nil
        }
        
        // Settings for HiDPI
        let pixelWidth = width * (hiDPI ? 2 : 1)
        let pixelHeight = height * (hiDPI ? 2 : 1)
        
        let mode = CGVirtualDisplayMode(width: pixelWidth, height: pixelHeight, refreshRate: 60.0)
        let settings = CGVirtualDisplaySettings()
        settings.modes = [mode]
        settings.hiDPI = hiDPI ? 1 : 0

        if display.apply(settings) {
            print("Settings applied. Display ID: \(display.displayID)")
            virtualDisplays[display.displayID] = display
            return display.displayID
        } else {
            print("Failed to apply settings")
            return nil
        }
    }
    
    func removeDisplay(displayID: CGDirectDisplayID) {
        if virtualDisplays[displayID] != nil {
            // Releasing the reference should trigger dealloc in our setup if termination handler handles it or we can try to force it, 
            // but effectively setting to nil is the way.
            virtualDisplays.removeValue(forKey: displayID)
            print("Display \(displayID) removed.")
        }
    }
    
    func removeAllDisplays() {
        virtualDisplays.removeAll()
    }
    
    deinit {
        print("VirtualConnector deinit - cleaning up all displays")
        removeAllDisplays()
    }
}
