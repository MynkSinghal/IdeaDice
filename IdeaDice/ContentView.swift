import SwiftUI
import AppKit
import Foundation

// Model for storing writing entries
struct WritingEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var title: String
    var content: String
    var wordCount: Int
    var isLocked: Bool = false
    
    static func createFromText(_ text: String) -> WritingEntry {
        let firstLine = text.split(separator: "\n").first ?? ""
        let title = String(firstLine.prefix(30))
        let wordCount = text.split(separator: " ").count
        
        return WritingEntry(
            date: Date(),
            title: title,
            content: text,
            wordCount: wordCount
        )
    }
    
    static func == (lhs: WritingEntry, rhs: WritingEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// History manager to persist and retrieve writing entries
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var entries: [WritingEntry] = []
    @Published var currentlyEditingEntry: WritingEntry?
    private let entriesKey = "writingEntries"
    private var saveTimer: Timer?
    
    init() {
        loadEntries()
    }
    
    func saveEntry(_ text: String) {
        guard !text.isEmpty else { return }
        
        // If we're currently editing an entry, update it instead of creating a new one
        if let currentEntry = currentlyEditingEntry, !currentEntry.isLocked {
            if let index = entries.firstIndex(where: { $0.id == currentEntry.id }) {
                // Update the existing entry
                var updatedEntry = currentEntry
                updatedEntry.title = String(text.split(separator: "\n").first?.prefix(30) ?? "")
                updatedEntry.content = text
                updatedEntry.wordCount = text.split(separator: " ").count
                
                entries[index] = updatedEntry
                currentlyEditingEntry = updatedEntry
                saveEntries()
            }
        } else if currentlyViewingLockedEntryId == nil {
            // Only create a new entry if we're not viewing a locked entry
            // and not editing an existing entry
            
            // Check if there's already an identical entry to prevent duplication
            let existingEntryIndex = entries.firstIndex { 
                $0.content == text || ($0.title == getTitle(from: text) && $0.wordCount == getWordCount(from: text)) 
            }
            
            if let index = existingEntryIndex {
                // If there's an identical entry, just update its timestamp
                var existingEntry = entries[index]
                existingEntry.date = Date()
                entries[index] = existingEntry
                currentlyEditingEntry = existingEntry
                
                // Move to the top
                if index > 0 {
                    entries.remove(at: index)
                    entries.insert(existingEntry, at: 0)
                }
            } else {
                // Create a new entry
                let entry = WritingEntry.createFromText(text)
                entries.insert(entry, at: 0) // Add to the beginning for newest first
                currentlyEditingEntry = entry
            }
            
            saveEntries()
        }
    }
    
    // Helper to get title from text
    private func getTitle(from text: String) -> String {
        let firstLine = text.split(separator: "\n").first ?? ""
        return String(firstLine.prefix(30))
    }
    
    // Helper to get word count from text
    private func getWordCount(from text: String) -> Int {
        return text.split(separator: " ").count
    }
    
    // Set the currently editing entry without creating a duplicate
    func setCurrentEntry(_ entry: WritingEntry) {
        currentlyEditingEntry = entry
    }
    
    // Lock an entry to prevent further edits
    func lockEntry(_ entryId: UUID) {
        if let index = entries.firstIndex(where: { $0.id == entryId }) {
            entries[index].isLocked = true
            
            // If this is the current entry, clear the current editing state
            if currentlyEditingEntry?.id == entryId {
                currentlyEditingEntry = nil
            }
            
            saveEntries()
        }
    }
    
    // Toggle lock status for the current entry
    func toggleLockStatus() -> Bool {
        // First check if we have a locked entry being viewed
        if let entryId = currentlyViewingLockedEntryId,
           let index = entries.firstIndex(where: { $0.id == entryId }) {
            // Unlocking a locked entry
            entries[index].isLocked = false
            currentlyEditingEntry = entries[index]
            currentlyViewingLockedEntryId = nil
            saveEntries()
            return false
        }
        
        // Then check regular entry being edited
        if let currentEntry = currentlyEditingEntry,
           let index = entries.firstIndex(where: { $0.id == currentEntry.id }) {
            // Toggle lock status
            entries[index].isLocked.toggle()
            
            // Update current entry reference
            if entries[index].isLocked {
                // If we're locking, clear the editing reference
                let entryId = entries[index].id
                currentlyEditingEntry = nil
                
                // But keep a reference to which entry is being viewed
                // by creating a special reference
                currentlyViewingLockedEntryId = entryId
            } else {
                // If we're unlocking, update the reference
                currentlyEditingEntry = entries[index]
                currentlyViewingLockedEntryId = nil
            }
            
            saveEntries()
            return entries[index].isLocked
        }
        
        return false
    }
    
    // A reference to the locked entry being viewed (not edited)
    @Published var currentlyViewingLockedEntryId: UUID?
    
    // Check if the current content is locked
    func isCurrentContentLocked() -> Bool {
        // First check if we have a locked entry being viewed
        if let entryId = currentlyViewingLockedEntryId,
           let entry = entries.first(where: { $0.id == entryId }) {
            return entry.isLocked
        }
        
        // Then check the current editing entry
        if let entryId = currentlyEditingEntry?.id,
           let entry = entries.first(where: { $0.id == entryId }) {
            return entry.isLocked
        }
        
        return false
    }
    
    // Auto-save with debounce
    func autoSave(_ text: String) {
        // Cancel existing timer
        saveTimer?.invalidate()
        
        // Only proceed if text isn't empty
        guard !text.isEmpty else { return }
        
        // Set new timer for 2 seconds after typing stops
        saveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.saveEntry(text)
        }
    }
    
    func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey) {
            if let decodedEntries = try? JSONDecoder().decode([WritingEntry].self, from: data) {
                entries = decodedEntries
            }
        }
    }
    
    private func saveEntries() {
        if let encodedData = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encodedData, forKey: entriesKey)
        }
    }
    
    func deleteEntry(at indexSet: IndexSet) {
        // If we're deleting the current entry, clear references
        for index in indexSet {
            let entryId = entries[index].id
            if currentlyEditingEntry?.id == entryId {
                currentlyEditingEntry = nil
            }
            if currentlyViewingLockedEntryId == entryId {
                currentlyViewingLockedEntryId = nil
            }
        }
        
        // Remove the entries
        entries.remove(atOffsets: indexSet)
        saveEntries()
    }
}

// Add this class above the ContentView struct definition
class KeyMonitorController {
    static let shared = KeyMonitorController()
    
    private var keyDownMonitor: Any?
    var isMonitoringActive = false
    
    // Function called by ContentView to register key events
    func startMonitoring(isLocked: @escaping () -> Bool, 
                        isNoBackspaceMode: @escaping () -> Bool, 
                        isTextFieldFocused: @escaping () -> Bool,
                        onBackspaceAttempted: @escaping () -> Void) {
        // First clean up any existing monitors
        stopMonitoring()
        
        // Guard against repeated initialization attempts
        if isMonitoringActive {
            print("Warning: Monitoring is already active, skipping initialization")
            return
        }
        
        // Mark as active before attempting to create the monitor
        isMonitoringActive = true
        
        // Create new monitor for key events without capture specifiers
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Log key events for debugging
            print("Key event received: \(event.keyCode), focused: \(isTextFieldFocused())")
            
            // Check if locked mode is on - block all keypresses
            if isLocked() {
                // Cancel all key events when locked
                return nil
            }
            
            // Only intercept backspace/delete if no-backspace mode is on and we're focused
            let deleteKey: UInt16 = 51 // Backspace/delete key code
            
            if event.keyCode == deleteKey && isNoBackspaceMode() {
                print("Backspace key detected with no-backspace mode on")
                
                // Only block if we're focused on the text editor
                if isTextFieldFocused() {
                    print("Blocking backspace - editor has focus")
                    // Show visual feedback that backspace was attempted
                    onBackspaceAttempted()
                    
                    // Prevent the backspace by consuming the event
                    return nil
                }
            }
            
            // Let all other events through
            return event
        }
        
        if keyDownMonitor != nil {
            print("Key monitor initialized successfully")
        } else {
            // Failed to create the monitor
            isMonitoringActive = false
            print("Failed to create key event monitor")
        }
    }
    
    func stopMonitoring() {
        // Safety cleanup for event monitor
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
            keyDownMonitor = nil
            print("Key monitor stopped and cleaned up")
        }
        isMonitoringActive = false
    }
}

struct ContentView: View {
    @State private var noun = WordData.randomNoun()
    @State private var verb = WordData.randomVerb()
    @State private var emotion = WordData.randomEmotion()
    @State private var noteText = ""
    @State private var isRolling = false
    @State private var isShowingWelcome = true
    @State private var isInitialized = false
    @ObservedObject private var settings = AppSettings.shared
    @FocusState private var isTextFieldFocused: Bool
    @State private var opacity: Double = 1.0
    @State private var selectedText: String = ""
    @State private var showFormatToolbar: Bool = false
    @State private var selectionObserver: Any?
    @State private var showSidebar: Bool = false
    @ObservedObject private var historyManager = HistoryManager.shared
    @State private var isLocked: Bool = false
    @State private var writingStartTime: Date?
    @State private var elapsedWritingTime: TimeInterval = 0
    @State private var pausedWritingTime: TimeInterval = 0
    @State private var writingTimer: Timer?
    @State private var noBackspaceMode: Bool = false
    @State private var keyDownMonitor: Any?
    @State private var backspaceAttempted: Bool = false
    
    // References to card views for animation
    @State private var nounCard: WordCardView?
    @State private var verbCard: WordCardView?
    @State private var emotionCard: WordCardView?
    
    // Add this property to track if editor has focus
    @State private var isEditorFocused: Bool = false
    
    // Add sound player instance
    @ObservedObject private var soundPlayer = AmbientSoundPlayer.shared
    
    // State for popover
    @State private var showingSoundPicker: Bool = false
    
    var body: some View {
        ZStack {
            // Background
            Color.white.edgesIgnoringSafeArea(.all)
            
            // Main content
            if isShowingWelcome {
                WelcomeView(isShowingWelcome: $isShowingWelcome)
                    .transition(.opacity)
            } else {
                HStack(spacing: 0) {
                    // Main content area
                    mainContent
                        .transition(.opacity)
                    
                    // History sidebar
                    if showSidebar {
                        HistorySidebar(
                            showSidebar: $showSidebar,
                            noteText: $noteText,
                            isLocked: $isLocked,
                            onRollDice: rollDice,
                            onResetWritingTimer: resetWritingTimer,
                            onStartWritingTimer: startWritingTimer
                        )
                        .frame(width: 250)
                        .transition(.move(edge: .trailing))
                    }
                }
            }
        }
        .onAppear {
            // Force new word generation on launch
            if !isInitialized {
                let newWords = WordData.rollDice()
                self.noun = newWords.noun
                self.verb = newWords.verb
                self.emotion = newWords.emotion
                isInitialized = true
            }
            
            // Make sure we start from a clean state
            cleanupKeyMonitor()
            
            // Setup selection change notification observer
            setupSelectionObserver()
            
            // Setup key monitor for backspace prevention - after a slight delay to ensure
            // any previous event monitors are fully cleaned up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                setupKeyMonitor()
            }
        }
        .onDisappear {
            // Clean up observers and timers
            if let observer = selectionObserver {
                NotificationCenter.default.removeObserver(observer)
                selectionObserver = nil
            }
            
            // Use our dedicated cleanup method for key monitors
            cleanupKeyMonitor()
            
            // Clean up timer
            if let timer = writingTimer {
                timer.invalidate()
                writingTimer = nil
            }
            
            // Stop any playing sounds
            soundPlayer.stopCurrentSound()
        }
    }
    
    var mainContent: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Word Cards in a discreet horizontal row
                HStack(spacing: 16) {
                    Spacer()
                    
                    // Word cards side by side at the top
                    WordCardView(word: noun, label: "NOUN")
                        .frame(width: 120)
                        .overlay(GeometryReader { geometry in
                            Color.clear.onAppear {
                                nounCard = WordCardView(word: noun, label: "NOUN")
                            }
                        })
                    
                    WordCardView(word: verb, label: "VERB")
                        .frame(width: 120)
                        .overlay(GeometryReader { geometry in
                            Color.clear.onAppear {
                                verbCard = WordCardView(word: verb, label: "VERB")
                            }
                        })
                    
                    WordCardView(word: emotion, label: "EMOTION")
                        .frame(width: 120)
                        .overlay(GeometryReader { geometry in
                            Color.clear.onAppear {
                                emotionCard = WordCardView(word: emotion, label: "EMOTION")
                            }
                        })
                    
                    Button {
                        rollDice()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Roll new words")
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    // History toggle button
                    Button {
                        withAnimation(.spring()) {
                            showSidebar.toggle()
                        }
                    } label: {
                        Image(systemName: showSidebar ? "sidebar.right" : "sidebar.left")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.gray)
                            .opacity(0.4)
                    }
                    .buttonStyle(.plain)
                    .help("Toggle History")
                    .padding(.trailing, 16)
                }
                .padding(.vertical, 16)
                .opacity(opacity)
                .animation(.easeInOut(duration: 0.4), value: opacity)
                
                // Enhanced Writing Area
                WritingEditor(
                    noteText: $noteText,
                    isLocked: $isLocked,
                    opacity: $opacity,
                    selectedText: $selectedText,
                    showFormatToolbar: $showFormatToolbar,
                    isEditorFocused: $isEditorFocused,  // Pass the binding to track focus
                    onFormatBold: { formatSelectedText(style: .bold) },
                    onFormatItalic: { formatSelectedText(style: .italic) },
                    onFormatUnderline: { formatSelectedText(style: .underline) },
                    onTimerStart: startWritingTimer
                )
                
                // Word count in footer
                HStack {
                    // Left side stats
                    HStack(spacing: 16) {
                        // Time tracking
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                                .foregroundColor(.black.opacity(0.7))
                            Text(formatTimeInterval(elapsedWritingTime))
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.black.opacity(0.7))
                        }
                        
                        // Word count
                        HStack(spacing: 4) {
                            Image(systemName: "text.word.count")
                                .font(.system(size: 11))
                                .foregroundColor(.black.opacity(0.7))
                            Text("\(wordCount) words")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }
                    .frame(minWidth: 170, alignment: .leading)
                    
                    Spacer()
                    
                    // Center - Tools row
                    HStack(spacing: 15) {
                        // Font selector
                        Button {
                            settings.cycleToNextFont()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "textformat")
                                    .font(.system(size: 10))
                                Text(settings.selectedFont.rawValue)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.06))
                            .foregroundColor(.black.opacity(0.7))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .help("Change text font")
                        
                        // Ambient sound / focus mode selector
                        Button {
                            showingSoundPicker.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                // Dynamic icon based on selected sound
                                Image(systemName: soundPlayer.currentSound == .none ? "speaker.wave.2" : soundPlayer.currentSound.iconName)
                                    .font(.system(size: 10))
                                
                                // Text changes based on if sound is playing
                                Text(soundPlayer.currentSound == .none ? "Focus Mode" : soundPlayer.currentSound.rawValue)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                
                                // Play/pause indicator
                                if soundPlayer.currentSound != .none {
                                    Image(systemName: soundPlayer.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.black.opacity(0.5))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                soundPlayer.currentSound != .none 
                                ? Color.blue.opacity(0.15) 
                                : Color.black.opacity(0.06)
                            )
                            .foregroundColor(soundPlayer.currentSound != .none ? .blue.opacity(0.8) : .black.opacity(0.7))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .help("Ambient sounds for focus")
                        .popover(isPresented: $showingSoundPicker, arrowEdge: .bottom) {
                            AmbientSoundPicker(isPresented: $showingSoundPicker)
                        }
                        .contextMenu {
                            // Quick menu to toggle current sound
                            if soundPlayer.currentSound != .none {
                                Button {
                                    soundPlayer.toggleSound()
                                } label: {
                                    Label(soundPlayer.isPlaying ? "Pause" : "Play", systemImage: soundPlayer.isPlaying ? "pause" : "play")
                                }
                                
                                Divider()
                            }
                            
                            // Menu to pick sounds quickly
                            ForEach(AmbientSound.allCases) { sound in
                                Button {
                                    soundPlayer.currentSound = sound
                                } label: {
                                    Label(sound.rawValue, systemImage: sound.iconName)
                                }
                            }
                        }
                        .onTapGesture {
                            // Quick toggle play/pause on main button tap
                            if soundPlayer.currentSound != .none {
                                soundPlayer.toggleSound()
                            } else {
                                showingSoundPicker.toggle()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Right side actions
                    HStack(spacing: 12) {
                        // No backspace mode toggle
                        Button {
                            noBackspaceMode.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: noBackspaceMode ? "delete.left.fill" : "delete.left")
                                    .font(.system(size: 10))
                                    .symbolVariant(noBackspaceMode ? .slash : .none)
                                Text("Backspace")
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Group {
                                    if backspaceAttempted && noBackspaceMode {
                                        Color.red.opacity(0.15)
                                    } else {
                                        noBackspaceMode ? Color.black.opacity(0.12) : Color.black.opacity(0.06)
                                    }
                                }
                            )
                            .foregroundColor(backspaceAttempted && noBackspaceMode ? .red : .black.opacity(0.7))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(backspaceAttempted && noBackspaceMode ? Color.red.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                            .shadow(color: backspaceAttempted && noBackspaceMode ? Color.red.opacity(0.2) : Color.clear, radius: 3, x: 0, y: 0)
                        }
                        .buttonStyle(.plain)
                        .help(noBackspaceMode ? "Enable backspace" : "Disable backspace for flow writing")
                        
                        Button {
                            toggleLockStatus()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                                    .font(.system(size: 10))
                                Text(isLocked ? "Unlock" : "Lock")
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(isLocked ? Color.gray.opacity(0.2) : Color.black.opacity(0.08))
                            .foregroundColor(isLocked ? .black.opacity(0.7) : .black.opacity(0.6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .help(isLocked ? "Unlock to enable editing" : "Lock to prevent further edits")
                        
                        Button {
                            noteText = ""
                        } label: {
                            Text("Clear")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.black.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .disabled(isLocked)
                    }
                    .frame(alignment: .trailing)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.8))
                .opacity(opacity)
                .animation(.easeInOut(duration: 0.4), value: opacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var wordCount: Int {
        noteText.split(separator: " ").count
    }
    
    // Helper function to format time interval
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func setupSelectionObserver() {
        // Remove existing observer if any
        if let observer = selectionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Add notification observer for selection changes
        selectionObserver = NotificationCenter.default.addObserver(
            forName: NSTextView.didChangeSelectionNotification,
            object: nil,
            queue: .main
        ) { [self] notification in
            guard let textView = notification.object as? NSTextView else { return }
            
            let selectedRange = textView.selectedRange()
            if selectedRange.length > 0 && !isLocked {
                let selectedText = (textView.string as NSString).substring(with: selectedRange)
                self.selectedText = selectedText
                self.showFormatToolbar = true
            } else {
                self.selectedText = ""
                self.showFormatToolbar = false
            }
        }
    }
    
    // Function to toggle lock status
    func toggleLockStatus() {
        // Check if we have content to lock
        guard !noteText.isEmpty else { return }
        
        // If we don't have a current entry yet, save one first
        if historyManager.currentlyEditingEntry == nil {
            historyManager.saveEntry(noteText)
        }
        
        // Toggle lock status in history manager
        isLocked = historyManager.toggleLockStatus()
        
        // Stop timer if content is locked
        if isLocked {
            pauseWritingTimer()
        } else {
            // Resume timer if unlocked
            resumeWritingTimer()
        }
    }
    
    // Pause the writing timer and save the current elapsed time
    func pauseWritingTimer() {
        // Save the current elapsed time
        if writingStartTime != nil {
            pausedWritingTime = elapsedWritingTime
        }
        
        // Stop the timer
        writingTimer?.invalidate()
        writingTimer = nil
        writingStartTime = nil
    }
    
    // Resume the writing timer from where it left off
    func resumeWritingTimer() {
        // Only resume if we have a paused time
        guard pausedWritingTime > 0 else {
            // If no paused time, just start fresh
            startWritingTimer()
            return
        }
        
        // Initialize the timer with the paused time
        writingStartTime = Date().addingTimeInterval(-pausedWritingTime)
        elapsedWritingTime = pausedWritingTime
        
        // Create a timer that updates every second
        writingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = writingStartTime {
                elapsedWritingTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    // Stop the writing timer without resetting
    func stopWritingTimer() {
        pauseWritingTimer()
    }
    
    func rollDice() {
        // Play animation
        isRolling = true
        
        // Animate card flips using optional chaining to handle potential nil values
        nounCard?.animate()
        verbCard?.animate()
        emotionCard?.animate()
        
        // Update the words after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let newWords = WordData.rollDice()
            self.noun = newWords.noun
            self.verb = newWords.verb
            self.emotion = newWords.emotion
            
            // Reset rolling state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isRolling = false
            }
        }
    }
    
    // Start the writing timer
    func startWritingTimer() {
        // Only start if not already tracking
        guard writingStartTime == nil else { return }
        
        // Initialize the timer
        writingStartTime = Date()
        elapsedWritingTime = 0
        
        // Create a timer that updates every second
        writingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = writingStartTime {
                elapsedWritingTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    // Reset the writing timer
    func resetWritingTimer() {
        writingTimer?.invalidate()
        writingTimer = nil
        writingStartTime = nil
        elapsedWritingTime = 0
    }
    
    // Setup key monitor to prevent backspace
    func setupKeyMonitor() {
        // Use the shared controller to start monitoring with proper closures
        KeyMonitorController.shared.startMonitoring(
            isLocked: { self.isLocked },
            isNoBackspaceMode: { self.noBackspaceMode },
            isTextFieldFocused: { self.isEditorFocused },  // Use our new focus state
            onBackspaceAttempted: { self.showBackspaceAttemptFeedback() }
        )
    }
    
    // Show visual feedback when backspace is attempted in no-backspace mode
    func showBackspaceAttemptFeedback() {
        // Set flag to show visual feedback
        DispatchQueue.main.async {
            // Play a system alert sound to provide audio feedback
            NSSound.beep()
            
            // Show visual feedback
            self.backspaceAttempted = true
            
            // Double pulse effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.backspaceAttempted = false
                
                // Second pulse after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.backspaceAttempted = true
                    
                    // End the effect
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.backspaceAttempted = false
                    }
                }
            }
        }
    }
    
    // Text formatting functions
    func formatSelectedText(style: TextStyle) {
        guard !selectedText.isEmpty else { return }
        
        // Get the selected range from the current first responder
        guard let currentEditor = NSApp.keyWindow?.firstResponder as? NSTextView else { return }
        let selectedRange = currentEditor.selectedRange()
        
        // Get existing attributes from the current selection if possible
        let attributedString = NSMutableAttributedString(attributedString: currentEditor.attributedString())
        
        // Apply the appropriate style to the selected range, preserving existing attributes
        switch style {
        case .bold:
            // Get existing font or use system font
            let existingFont = attributedString.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? NSFont ?? NSFont.systemFont(ofSize: 18)
            
            // Create bold font with same size and other traits
            let fontDescriptor = existingFont.fontDescriptor
            let traits = fontDescriptor.symbolicTraits.union(.bold)
            let boldFontDescriptor = fontDescriptor.withSymbolicTraits(traits)
            
            if let boldFont = NSFont(descriptor: boldFontDescriptor, size: 0) {
                attributedString.addAttribute(.font, value: boldFont, range: selectedRange)
            } else {
                // Fallback to regular bold if we can't combine traits
                attributedString.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 18), range: selectedRange)
            }
            
        case .italic:
            // Get existing font or use system font
            let existingFont = attributedString.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? NSFont ?? NSFont.systemFont(ofSize: 18)
            
            // Create italic font with same size and other traits
            let fontDescriptor = existingFont.fontDescriptor
            let traits = fontDescriptor.symbolicTraits.union(.italic)
            let italicFontDescriptor = fontDescriptor.withSymbolicTraits(traits)
            
            if let italicFont = NSFont(descriptor: italicFontDescriptor, size: 0) {
                attributedString.addAttribute(.font, value: italicFont, range: selectedRange)
            }
            
        case .underline:
            // Add underline attribute (can coexist with other attributes)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
        }
        
        // Apply the attributed string to the text view
        currentEditor.textStorage?.setAttributedString(attributedString)
        
        // Update the binding - convert to plain string for the binding
        noteText = currentEditor.string
        
        // Keep selection and toolbar visible to allow applying multiple formats
        currentEditor.setSelectedRange(selectedRange)
    }
    
    enum TextStyle {
        case bold, italic, underline
    }
    
    // Add a dedicated cleanup method for the key monitor
    func cleanupKeyMonitor() {
        KeyMonitorController.shared.stopMonitoring()
    }
}

#Preview {
    ContentView()
}