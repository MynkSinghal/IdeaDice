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

struct ContentView: View {
    @State private var noun = WordData.randomNoun()
    @State private var verb = WordData.randomVerb()
    @State private var emotion = WordData.randomEmotion()
    @State private var noteText = ""
    @State private var isRolling = false
    @State private var showSettings = false
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
    @State private var writingTimer: Timer?
    @State private var noBackspaceMode: Bool = false
    @State private var keyDownMonitor: Any?
    
    // References to card views for animation
    @State private var nounCard: WordCardView?
    @State private var verbCard: WordCardView?
    @State private var emotionCard: WordCardView?
    
    // Ivory color - using Color.white with opacity for better compatibility
    private let backgroundColor = Color.white
    
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
    
    var body: some View {
        ZStack {
            // Background - explicitly use Color.white which is more reliable
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
                        historySidebar
                            .frame(width: 250)
                            .transition(.move(edge: .trailing))
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            print("ContentView appeared with isShowingWelcome: \(isShowingWelcome)")
            
            // Force new word generation on launch
            if !isInitialized {
                let newWords = WordData.rollDice()
                self.noun = newWords.noun
                self.verb = newWords.verb
                self.emotion = newWords.emotion
                isInitialized = true
                
                print("Words initialized: \(noun), \(verb), \(emotion)")
            }
            
            // Setup selection change notification observer
            setupSelectionObserver()
            
            // Setup key monitor for backspace prevention
            setupKeyMonitor()
        }
        .onDisappear {
            // Clean up observers and timers
            if let observer = selectionObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            
            if let keyMonitor = keyDownMonitor {
                NSEvent.removeMonitor(keyMonitor)
            }
            
            writingTimer?.invalidate()
        }
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
            stopWritingTimer()
        } else {
            // Restart timer if unlocked
            startWritingTimer()
        }
    }
    
    // Stop the writing timer without resetting
    func stopWritingTimer() {
        writingTimer?.invalidate()
        writingTimer = nil
    }
    
    var mainContent: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Word Cards in a discreet horizontal row
                HStack(spacing: 16) {
                    Spacer()
                    
                    // Word cards side by side at the top
                    WordCardView(word: noun, label: "NOUN", color: .primary)
                        .frame(width: 120)
                        .overlay(GeometryReader { geometry in
                            Color.clear.onAppear {
                                nounCard = WordCardView(word: noun, label: "NOUN", color: .primary)
                            }
                        })
                    
                    WordCardView(word: verb, label: "VERB", color: .primary)
                        .frame(width: 120)
                        .overlay(GeometryReader { geometry in
                            Color.clear.onAppear {
                                verbCard = WordCardView(word: verb, label: "VERB", color: .primary)
                            }
                        })
                    
                    WordCardView(word: emotion, label: "EMOTION", color: .primary)
                        .frame(width: 120)
                        .overlay(GeometryReader { geometry in
                            Color.clear.onAppear {
                                emotionCard = WordCardView(word: emotion, label: "EMOTION", color: .primary)
                            }
                        })
                    
                    Button {
                        rollDice()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.secondary)
                            .opacity(0.6)
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
                            .foregroundColor(.secondary)
                            .opacity(0.4)
                    }
                    .buttonStyle(.plain)
                    .help("Toggle History")
                    .padding(.trailing, 8)
                    
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.secondary)
                            .opacity(0.4)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 16)
                    .help("Settings")
                }
                .padding(.vertical, 16)
                .opacity(opacity)
                .animation(.easeInOut(duration: 0.4), value: opacity)
                
                // Enhanced Writing Area
                ZStack(alignment: .top) {
                    TextEditor(text: $noteText)
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .lineSpacing(6)
                        .focused($isTextFieldFocused)
                        .scrollContentBackground(.hidden)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(30)
                        .scrollIndicators(.hidden)
                        .disabled(isLocked)
                        .onTapGesture {
                            if !isLocked {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    opacity = opacity == 1.0 ? 0.0 : 1.0
                                }
                            }
                        }
                        .onChange(of: noteText) { _, newValue in
                            if !isLocked {
                                historyManager.autoSave(newValue)
                                
                                // Use dispatchQueue to avoid modifying state during view update
                                DispatchQueue.main.async {
                                    // Start the writing timer if it's not already running
                                    if writingStartTime == nil && !newValue.isEmpty {
                                        startWritingTimer()
                                    }
                                }
                            } else {
                                // If locked, revert any changes by restoring content from history
                                if let entryId = historyManager.currentlyViewingLockedEntryId ?? historyManager.currentlyEditingEntry?.id,
                                   let entry = historyManager.entries.first(where: { $0.id == entryId }) {
                                    DispatchQueue.main.async {
                                        // Only revert if the content was changed
                                        if noteText != entry.content {
                                            noteText = entry.content
                                        }
                                    }
                                }
                            }
                        }
                        .overlay(
                            Group {
                                if noteText.isEmpty && !isTextFieldFocused {
                                    Text("Begin typing based on the words above...")
                                        .font(.system(size: 18, weight: .regular, design: .serif))
                                        .foregroundColor(.secondary.opacity(0.6))
                                        .padding(.top, 30)
                                        .padding(.leading, 30)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                        .allowsHitTesting(false)
                                }
                                
                                // Lock overlay when content is locked
                                if isLocked {
                                    ZStack {
                                        Color.black.opacity(0.02)
                                        VStack {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.black.opacity(0.3))
                                            Text("This writing is locked")
                                                .font(.system(size: 14, design: .serif))
                                                .foregroundColor(.black.opacity(0.5))
                                        }
                                        .padding(20)
                                        .background(Color.white.opacity(0.7))
                                        .cornerRadius(12)
                                    }
                                    .allowsHitTesting(false)
                                }
                            }
                        )
                    
                    // Formatting toolbar overlay when text is selected
                    if showFormatToolbar && !selectedText.isEmpty {
                        GeometryReader { geometry in
                            FormatToolbar(onBold: { formatSelectedText(style: .bold) },
                                       onItalic: { formatSelectedText(style: .italic) },
                                       onUnderline: { formatSelectedText(style: .underline) })
                                .opacity(0.95)
                                .position(x: geometry.size.width / 2, y: 50)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.2), value: showFormatToolbar)
                        }
                    }
                }
                
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
                            .background(noBackspaceMode ? Color.black.opacity(0.12) : Color.black.opacity(0.06))
                            .foregroundColor(.black.opacity(0.7))
                            .cornerRadius(12)
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
                                .foregroundColor(.secondary)
                                .opacity(0.5)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLocked)
                        
                        Button {
                            // Clear text and roll new words
                            noteText = ""
                            // Clear current entry reference
                            historyManager.currentlyEditingEntry = nil
                            rollDice()
                            // Reset lock state
                            isLocked = false
                            // Reset writing timer
                            resetWritingTimer()
                            // Close sidebar
                            withAnimation(.spring()) {
                                showSidebar = false
                            }
                        } label: {
                            Text("Save & New")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.secondary)
                                .opacity(0.5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.8))
                .opacity(opacity)
                .animation(.easeInOut(duration: 0.4), value: opacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // Focus the text editor when the main view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                    print("Main content appeared, focusing text field")
                }
            }
            
            // Show small sidebar toggle button when sidebar is hidden
            if !showSidebar {
                sidebarToggleButton
                    .padding(.top, 70)
                    .padding(.trailing, 16)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var wordCount: Int {
        noteText.split(separator: " ").count
    }
    
    func rollDice() {
        // Play animation
        isRolling = true
        
        // Animate card flips using optional chaining to handle potential nil values
        nounCard?.animate()
        verbCard?.animate()
        emotionCard?.animate()
        
        // Play sound effect if enabled
        if settings.soundEnabled {
            SoundManager.shared.playDiceRollSound()
        }
        
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
    
    // History sidebar view
    var historySidebar: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Writing History")
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button {
                    withAnimation(.spring()) {
                        showSidebar = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.black.opacity(0.1)),
                alignment: .bottom
            )
            
            // List of entries
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(historyManager.entries) { entry in
                        Button {
                            // Load this entry without creating a duplicate
                            noteText = entry.content
                            
                            // Reset timer when loading a new entry
                            resetWritingTimer()
                            
                            // Handle locked entry differently
                            if entry.isLocked {
                                historyManager.currentlyEditingEntry = nil
                                historyManager.currentlyViewingLockedEntryId = entry.id
                            } else {
                                historyManager.setCurrentEntry(entry)
                                historyManager.currentlyViewingLockedEntryId = nil
                                
                                // Only start timer for unlocked entries
                                startWritingTimer()
                            }
                            
                            // Update lock state for this entry
                            isLocked = entry.isLocked
                            
                            // Close the sidebar after selection
                            withAnimation(.spring()) {
                                showSidebar = false
                            }
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(entry.title)
                                        .font(.system(size: 16, weight: .medium, design: .serif))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                    
                                    HStack {
                                        Text(formatDate(entry.date))
                                            .font(.system(size: 12, design: .serif))
                                            .foregroundColor(.black.opacity(0.6))
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 6) {
                                            if entry.isLocked {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.black.opacity(0.5))
                                            }
                                            
                                            Text("\(entry.wordCount) words")
                                                .font(.system(size: 12, design: .serif))
                                                .foregroundColor(.black.opacity(0.6))
                                        }
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                                
                                // Delete button in top right
                                Button {
                                    if let index = historyManager.entries.firstIndex(where: { $0.id == entry.id }) {
                                        // If this is the currently viewed entry, clear it
                                        if historyManager.currentlyEditingEntry?.id == entry.id ||
                                           historyManager.currentlyViewingLockedEntryId == entry.id {
                                            historyManager.currentlyEditingEntry = nil
                                            historyManager.currentlyViewingLockedEntryId = nil
                                        }
                                        
                                        // Then delete the entry
                                        historyManager.deleteEntry(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.black.opacity(0.5))
                                        .padding(4)
                                        .background(Circle().fill(Color.gray.opacity(0.15)))
                                }
                                .buttonStyle(.plain)
                                .padding(4)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if !entry.isLocked {
                                Button {
                                    historyManager.lockEntry(entry.id)
                                } label: {
                                    Label("Lock Entry", systemImage: "lock")
                                }
                            }
                            
                            Button {
                                if let index = historyManager.entries.firstIndex(where: { $0.id == entry.id }) {
                                    // If this is the currently viewed entry, clear it
                                    if historyManager.currentlyEditingEntry?.id == entry.id ||
                                       historyManager.currentlyViewingLockedEntryId == entry.id {
                                        historyManager.currentlyEditingEntry = nil
                                        historyManager.currentlyViewingLockedEntryId = nil
                                    }
                                    
                                    // Then delete the entry
                                    historyManager.deleteEntry(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(white: 0.98))
            
            // New Writing button
            Button {
                // Clear text and roll new words
                noteText = ""
                // Clear current entry reference
                historyManager.currentlyEditingEntry = nil
                rollDice()
                // Reset lock state
                isLocked = false
                // Reset writing timer
                resetWritingTimer()
                // Close sidebar
                withAnimation(.spring()) {
                    showSidebar = false
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    Text("New Writing")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.black.opacity(0.1)),
                alignment: .top
            )
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.black.opacity(0.1)), 
            alignment: .leading
        )
    }
    
    // Small sidebar toggle button that stays visible
    var sidebarToggleButton: some View {
        Button {
            withAnimation(.spring()) {
                showSidebar.toggle()
            }
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 16))
                .foregroundColor(.black)
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .help("Show History")
    }
    
    // Helper function to format dates
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper function to format time interval
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
        // Remove existing monitor if any
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // Create new monitor
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Only intercept if no-backspace mode is on, we're focused, and not locked
            if self.noBackspaceMode && self.isTextFieldFocused && !self.isLocked {
                let deleteKey: UInt16 = 51 // Backspace/delete key code
                
                // Check if backspace/delete key is pressed
                if event.keyCode == deleteKey {
                    // Prevent the backspace by consuming the event
                    return nil
                }
            }
            
            // Let all other events through
            return event
        }
    }
}

// Separate formatting toolbar component
struct FormatToolbar: View {
    var onBold: () -> Void
    var onItalic: () -> Void
    var onUnderline: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onBold) {
                Image(systemName: "bold")
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
            }
            .buttonStyle(FormatButtonStyle())
            .help("Bold")
            
            Button(action: onUnderline) {
                Image(systemName: "underline")
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
            }
            .buttonStyle(FormatButtonStyle())
            .help("Underline")
            
            Button(action: onItalic) {
                Image(systemName: "italic")
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
            }
            .buttonStyle(FormatButtonStyle())
            .help("Italic")
        }
        .padding(8)
        .background(Color(white: 0.98))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// Custom button style for format buttons
struct FormatButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(configuration.isPressed ? Color.gray.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
} 