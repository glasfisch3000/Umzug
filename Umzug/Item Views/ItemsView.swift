//
//  ItemsView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 11.01.25.
//

import SwiftUI
import APIInterface

struct ItemsView: View {
    @UmzugFetched var items: Result<[Item], ItemsListFailure>?
    
    @State private var selection: [Item] = []
    @State private var addItemSheetPresented = false
    
    var body: some View {
        switch items {
        case .success(let items): valueView(items)
        case .failure(let failure): APIFailureView(failure: failure, fetched: $items, describe: \.description)
        case nil:
            if let error = $items.apiError {
                APIErrorView(error: error)
            } else {
                FetchedLoadingView(fetched: $items)
            }
        }
    }
    
    @ViewBuilder
    func valueView(_ items: [Item]) -> some View {
        NavigationStack(path: $selection) {
            List {
                let grouped = items.grouped(by: \.priority)
                
                ForEach(Item.Priority.allCases) { priority in
                    Section {
                        if let group = grouped[priority] {
                            ForEach(group.sorted { $0.title < $1.title }) { item in
                                itemView(item: item)
                            }
                        }
                    } header: {
                        switch priority {
                        case .immediate: Text("Immediate Priority").foregroundStyle(.red)
                        case .standard: Text("Standard Priority").foregroundStyle(.yellow)
                        case .longTerm: Text("Long Term Priority").foregroundStyle(.green)
                        }
                    }
                }
            }
            .refreshable {
                await $items.reload()
            }
            .navigationTitle("Items")
            .toolbar(content: toolbarView)
            .sheet(isPresented: $addItemSheetPresented, content: addItemSheet)
            .navigationDestination(for: Item.self) { item in
                ItemView(api: $items.api, item: item, packings: $items.api.fetched(for: .packings(item: item.id)))
            }
        }
    }
    
    @ViewBuilder
    func itemView(item: Item) -> some View {
        NavigationLink(item.title, value: item)
            .contextMenu {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    Task {
                        do {
                            _ = try await item.delete(on: $items.api).get()
                            await $items.reload()
                        } catch {
                            print(error)
                        }
                    }
                }
                .keyboardShortcut(.delete)
            }
    }
    
    @ToolbarContentBuilder
    func toolbarView() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Add Item", systemImage: "plus") {
                addItemSheetPresented = true
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
    
    @ViewBuilder
    func addItemSheet() -> some View {
        NavigationStack {
            AddItemView(api: $items.api) { item in
                await $items.reload()
                self.selection.append(item)
            }
        }
    }
}
