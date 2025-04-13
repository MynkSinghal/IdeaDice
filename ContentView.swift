// Setup key monitor to prevent backspace
func setupKeyMonitor() {
    // First clean up any existing monitors
    cleanupKeyMonitor()
    
    // Guard against repeated initialization attempts
    if isMonitoringActive {
        print("Warning: Monitoring is already active, skipping initialization")
        return
    }
    
    // Use a safer implementation with try-catch for error handling
    do {
        // Mark as active before attempting to create the monitor
        isMonitoringActive = true
        
        // Create new monitor for key events - use weak capture to avoid memory issues
        if let newMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check if self still exists
            guard let self = self else { return event }
            
            // Check if locked mode is on - block all keypresses
            if self.isLocked {
                // Cancel all key events when locked
                return nil
            }
            
            // Only intercept backspace if no-backspace mode is on and we're focused
            if self.noBackspaceMode && self.isTextFieldFocused {
                let deleteKey: UInt16 = 51 // Backspace/delete key code
                
                // Check if backspace/delete key is pressed
                if event.keyCode == deleteKey {
                    // Show visual feedback that backspace was attempted
                    self.showBackspaceAttemptFeedback()
                    
                    // Prevent the backspace by consuming the event
                    return nil
                }
            }
            
            // Let all other events through
            return event
        } {
            // Successfully created the monitor
            keyDownMonitor = newMonitor
            print("Key monitor initialized successfully")
        } else {
            // Failed to create the monitor
            isMonitoringActive = false
            print("Failed to create key event monitor")
        }
    } catch {
        // Something went wrong
        isMonitoringActive = false
        print("Error setting up key monitor: \(error)")
        
        // Try to clean up just in case
        cleanupKeyMonitor()
    }
} 