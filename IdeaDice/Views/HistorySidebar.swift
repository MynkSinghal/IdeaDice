import SwiftUI
import AppKit

struct HistorySidebar: View {
    @ObservedObject private var historyManager = HistoryManager.shared
    @ObservedObject private var settings = AppSettings.shared
    @Binding var showSidebar: Bool
    @Binding var noteText: String
    @Binding var isLocked: Bool
    
    // Callback functions
    var onRollDice: () -> Void
    var onResetWritingTimer: () -> Void
    var onStartWritingTimer: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Writing History")
                    .font(Font(settings.selectedFont.uiFont(size: 18)))
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
                            onResetWritingTimer()
                            
                            // Handle locked entry differently
                            if entry.isLocked {
                                historyManager.currentlyEditingEntry = nil
                                historyManager.currentlyViewingLockedEntryId = entry.id
                            } else {
                                historyManager.setCurrentEntry(entry)
                                historyManager.currentlyViewingLockedEntryId = nil
                                
                                // Only start timer for unlocked entries
                                onStartWritingTimer()
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
                                        .font(Font(settings.selectedFont.uiFont(size: 16)))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                    
                                    HStack {
                                        Text(formatDate(entry.date))
                                            .font(Font(settings.selectedFont.uiFont(size: 12)))
                                            .foregroundColor(.black.opacity(0.6))
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 6) {
                                            if entry.isLocked {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.black.opacity(0.5))
                                            }
                                            
                                            Text("\(entry.wordCount) words")
                                                .font(Font(settings.selectedFont.uiFont(size: 12)))
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
                onRollDice()
                // Reset lock state
                isLocked = false
                // Reset writing timer
                onResetWritingTimer()
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
                        .font(Font(settings.selectedFont.uiFont(size: 14)))
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
    
    // Helper function to format dates
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    HistorySidebar(
        showSidebar: .constant(true),
        noteText: .constant("Preview text..."),
        isLocked: .constant(false),
        onRollDice: {},
        onResetWritingTimer: {},
        onStartWritingTimer: {}
    )
    .frame(width: 250)
} 