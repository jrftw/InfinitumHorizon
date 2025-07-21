//
//  ContentView.swift
//  Infinitum Horizon
//
//  Created by Kevin Doyle Jr. on 7/20/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                            .font(.title2)
                            .fontWeight(.medium)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.title3)
                                .foregroundStyle(.linearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Item")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .fontWeight(.medium)
                }
#endif
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
            VStack(spacing: 20) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("Select an item")
                    .font(.title2)
                    .fontWeight(.semibold)
                
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

    private func addItem() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
