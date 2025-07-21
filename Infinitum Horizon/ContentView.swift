//
//  ContentView.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//  Updated 7/21/2025 by @jrftw
//
//  Main content view for displaying and managing Item entities
//  Provides a split view interface with navigation sidebar and detail panel
//  Demonstrates SwiftData integration with CRUD operations and platform-specific UI
//

import SwiftUI
import SwiftData

// MARK: - Main Content View
/// Primary content view that displays a list of Item entities with navigation capabilities
/// Uses NavigationSplitView for optimal cross-platform layout and SwiftData for persistence
struct ContentView: View {
    // MARK: - Environment and Data
    /// SwiftData model context for performing data operations
    @Environment(\.modelContext) private var modelContext
    /// Query that automatically fetches all Item entities from the database
    /// Updates automatically when data changes due to SwiftData's reactive nature
    @Query private var items: [Item]

    // MARK: - Main View Body
    /// NavigationSplitView provides a master-detail interface with sidebar navigation
    /// Adapts to different screen sizes and platforms automatically
    var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar Content
            List {
                // Iterate through all items and create navigation links
                ForEach(items) { item in
                    NavigationLink {
                        // Detail view for selected item
                        // Shows timestamp in a formatted display
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                            .font(.title2)
                            .fontWeight(.medium)
                    } label: {
                        // Custom row layout for each item
                        HStack {
                            // Item icon with gradient styling
                            Image(systemName: "doc.text.fill")
                                .font(.title3)
                                .foregroundStyle(.linearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            
                            // Item information stack
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Item")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                // Formatted timestamp display
                                Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                // Enable swipe-to-delete functionality
                .onDelete(perform: deleteItems)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
            #if os(macOS)
            // Platform-specific sidebar width configuration
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            #endif
            .toolbar {
                #if os(iOS)
                // iOS-specific edit button for list management
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .fontWeight(.medium)
                }
                #endif
                // Add item button available on all platforms
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus.circle.fill")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        } detail: {
            // MARK: - Detail Panel
            /// Default detail view shown when no item is selected
            /// Provides visual guidance and maintains consistent layout
            VStack(spacing: 20) {
                // Placeholder icon with gradient styling
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                // Instructional text
                Text("Select an item")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Helpful description
                Text("Choose an item from the sidebar to view its details")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ultraThinMaterial)
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - Data Operations
    /// Creates a new Item entity with current timestamp and inserts it into the database
    /// Uses spring animation for smooth visual feedback
    private func addItem() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            // Create new item with current timestamp
            let newItem = Item(timestamp: Date())
            // Insert into SwiftData context for persistence
            modelContext.insert(newItem)
        }
    }

    /// Deletes multiple items from the database based on provided index offsets
    /// Handles batch deletion with smooth animations
    /// POTENTIAL ISSUE: No confirmation dialog before deletion
    private func deleteItems(offsets: IndexSet) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            // Iterate through selected indices and delete corresponding items
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

// MARK: - Preview
/// SwiftUI preview for development and testing
/// Uses in-memory container to avoid affecting production data
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
