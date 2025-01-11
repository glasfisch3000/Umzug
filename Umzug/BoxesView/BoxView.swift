//
//  BoxView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 24.11.24.
//

import SwiftUI

struct BoxView: View {
    var api: UmzugAPI
    var box: Box
    
    @State private var textInput = ""
    @State private var newItemSheetPresented = false
    
    @UmzugFetched var items: Result<[Item], ItemsListFailure>?
    @UmzugFetched var packings: Result<[Packing], PackingsListFailure>?
    
    @State private var packingsToDelete: Set<Packing> = []
    
    var body: some View {
        Group {
            switch (items, packings) {
            case (.success(let items), .success(let packings)): valueView(items, packings: packings)
            case (nil, _), (_, nil):
                if let error = $items.apiError {
                    apiErrorView(error)
                } else if let error = $packings.apiError {
                    apiErrorView(error)
                } else {
                    loadingView()
                }
            case (.failure(let failure), _): itemsFailureView(failure)
            case (_, .failure(let failure)): packingsFailureView(failure)
            }
        }
        .navigationTitle(box.title)
        .navigationBarTitleDisplayMode(.large)
    }
    
    @ViewBuilder
    func valueView(_ items: [Item], packings: [Packing]) -> some View {
        List {
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
        .searchable(text: $textInput, placement: .toolbar, prompt: "Search Items")
        .refreshable {
            await $items.reload()
            await $packings.reload()
        }
        .confirmationDialog("Delete \(packingsToDelete.count) item\(packingsToDelete.count == 1 ? "" : "s")?", isPresented: Binding {
            !packingsToDelete.isEmpty
        } set: {
            packingsToDelete = $0 ? packingsToDelete : []
        }) {
            Button("Unpack Item\(packingsToDelete.count == 1 ? "" : "s")", role: .destructive) {
                deletePackings(packingsToDelete)
            }
        }
        .sheet(isPresented: $newItemSheetPresented) {
            NavigationStack {
                CreateNewItemPackingView(api: api, box: box, title: textInput) {
                    await $items.reload()
                    await $items.reload()
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

extension BoxView {
    @ViewBuilder
    func loadingView() -> some View {
        if $items.isLoading || $packings.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            Button("Load Value") {
                Task { await $items.reload() }
                Task { await $packings.reload() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    @ViewBuilder
    func itemsFailureView(_ error: ItemsListFailure) -> some View {
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
    func packingsFailureView(_ error: PackingsListFailure) -> some View {
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
                    await $packings.reload()
                }
            } label: {
                HStack {
                    Spacer()
                    
                    if $packings.isLoading {
                        ProgressView()
                    } else {
                        Text("Reload")
                    }
                    
                    Spacer()
                }
            }
            .buttonBorderShape(.roundedRectangle)
            .buttonStyle(.bordered)
            .disabled($packings.isLoading)
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
