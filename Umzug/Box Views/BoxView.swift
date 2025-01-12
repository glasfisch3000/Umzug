//
//  BoxView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 24.11.24.
//

import SwiftUI

struct BoxView: View {
    var api: UmzugAPI
    @State var box: Box
    
    @State private var textInput = ""
    @State private var newItemSheetPresented = false
    
    @State private var searchIsPresented = false
    
    @UmzugFetched var items: Result<[Item], ItemsListFailure>?
    @UmzugFetched var packings: Result<[Packing], PackingsListFailure>?
    
    @State private var packingsToDelete: Set<Packing> = []
    @State private var editSheetPresented = false
    
    var body: some View {
        Group {
            switch (items, packings) {
            case (.success(let items), .success(let packings)): valueView(items, packings: packings)
            case (nil, _), (_, nil):
                if let error = $items.apiError ?? $packings.apiError {
                    APIErrorView(error: error)
                } else {
                    FetchedLoadingView(fetched: ($items, $packings))
                }
            case (.failure(let failure), _): APIFailureView(failure: failure, fetched: $items, describe: \.description)
            case (_, .failure(let failure)): APIFailureView(failure: failure, fetched: $packings, describe: \.description)
            }
        }
        .navigationTitle(box.title)
        .navigationBarTitleDisplayMode(.large)
    }
    
    @ViewBuilder
    func valueView(_ items: [Item], packings: [Packing]) -> some View {
        VStack(spacing: 0) {
            Form {
                let textInput = self.textInput.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !textInput.isEmpty {
                    Section("Create New") {
                        Button("\"" + textInput + "\"", systemImage: "plus") {
                            newItemSheetPresented = true
                        }
                    }
                }
                
                packedItems(packings: packings, search: textInput.isEmpty ? nil : textInput)
                unpackedItems(items: items, packings: packings, search: textInput.isEmpty ? nil : textInput)
            }
            .scrollClipDisabled()
            
            if !searchIsPresented {
                Button {
                    newItemSheetPresented = true
                } label: {
                    Text("Add new item…")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                }
                .buttonBorderShape(.roundedRectangle(radius: 10))
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.bottom)
                .padding(.top, -5)
                .background()
            }
        }
        .searchable(text: $textInput, isPresented: $searchIsPresented, placement: .toolbar, prompt: "Search Items")
        .refreshable {
            await $items.reload()
            await $packings.reload()
        }
        .toolbar(content: toolbarView)
        .confirmationDialog("Delete \(packingsToDelete.count) item\(packingsToDelete.count == 1 ? "" : "s")?", isPresented: Binding {
            !packingsToDelete.isEmpty
        } set: {
            packingsToDelete = $0 ? packingsToDelete : []
        }) {
            Button("Unpack \(packingsToDelete.count) item\(packingsToDelete.count == 1 ? "" : "s")", role: .destructive) {
                deletePackings(packingsToDelete)
            }
        }
        .sheet(isPresented: $newItemSheetPresented) {
            NavigationStack {
                CreateNewItemPackingView(api: api, box: box, title: textInput) {
                    await $items.reload()
                    await $packings.reload()
                }
            }
        }
        .sheet(isPresented: $editSheetPresented) {
            NavigationStack {
                EditBoxView(box: box, api: api) { box in
                    self.box.title = box.title
                }
            }
        }
    }
    
    @ViewBuilder
    func packedItems(packings: [Packing], search: String?) -> some View {
        Section {
            let filtered = packings
                .filter {
                    if let search = search {
                        $0.item.title.localizedCaseInsensitiveContains(search)
                    } else {
                        true
                    }
                }
                .sorted { $0.item.title < $1.item.title }
            
            ForEach(filtered) { packing in
                NavigationLink {
                    PackingView(packing: packing, api: api) {
                        await $packings.reload()
                    }
                } label: {
                    ItemPreview(item: packing.item)
                        .badge(packing.amount)
                }
            }
            .onDelete { indexSet in
                self.packingsToDelete = Set(indexSet.map { filtered[$0] })
            }
        } header: {
            Text("Packed Items")
        } footer: {
            if packings.isEmpty && search == nil {
                Text("No items packed")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    @ViewBuilder
    func unpackedItems(items: [Item], packings: [Packing], search: String?) -> some View {
        let filteredItems = items
            .filter { item in
                !packings.contains {
                    $0.item.id == item.id
                }
            }.filter { item in
                if let search = search {
                    item.title.localizedCaseInsensitiveContains(search)
                } else {
                    true
                }
            }
        
        Section {
            ForEach(filteredItems) { item in
                NavigationLink {
                    CreatePackingView(api: api, item: item, box: box) {
                        await $packings.reload()
                    }
                } label: {
                    ItemPreview(item: item)
                }
            }
        } header: {
            if !filteredItems.isEmpty {
                Text("Other items")
            }
        }
    }
    
    @ToolbarContentBuilder
    func toolbarView() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Edit", systemImage: "ellipsis.circle") {
                editSheetPresented = true
            }
        }
    }
    
    func deletePackings(_ packingsToDelete: Set<Packing>) {
        Task {
            for packing in packingsToDelete {
                do {
                    _ = try await packing.delete(on: self.api).get()
                } catch {
                    print(error)
                }
            }
            await $packings.reload()
        }
    }
}
