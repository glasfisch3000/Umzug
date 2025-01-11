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
        case .failure(let failure): failureView(failure)
        case nil:
            if let error = $items.apiError {
                apiErrorView(error)
            } else {
                loadingView()
            }
        }
    }
    
    @ViewBuilder
    func valueView(_ items: [Item]) -> some View {
        NavigationStack(path: $selection) {
            List(items) { item in
                itemView(item: item)
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
    
    @ViewBuilder
    func loadingView() -> some View {
        if $items.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            Button("Load Value") {
                Task {
                    await $items.reload()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    @ViewBuilder
    func failureView(_ error: ItemsListFailure) -> some View {
        VStack(alignment: .center) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.multicolor)
                .font(.largeTitle)
            
            switch error {
            case .serverError:
                Text("An internal API error occurred.")
            case .noContent, .invalidContent:
                Text("Received an invalid or empty API response.")
            }
            
            Spacer()
            
            Button {
                Task {
                    await $items.reload()
                }
            } label: {
                HStack {
                    Spacer()
                    
                    if $items.isLoading {
                        ProgressView()
                    } else {
                        Text("Reload")
                    }
                    
                    Spacer()
                }
            }
            .buttonBorderShape(.roundedRectangle)
            .buttonStyle(.bordered)
            .disabled($items.isLoading)
        }
        .padding()
    }
    
    @ViewBuilder
    func apiErrorView(_ error: UmzugAPI.APIError) -> some View {
        VStack(alignment: .center) {
            Image(systemName: "exclamationmark.octagon.fill")
                .symbolRenderingMode(.multicolor)
                .font(.largeTitle)
            
            Text("An error occurred while connecting to the API.")
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
}
