//
//  ItemView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 11.01.25.
//

import SwiftUI

struct ItemView: View {
    var api: UmzugAPI
    @State var item: Item
    
    @UmzugFetched var packings: Result<[Packing], PackingsListFailure>?
    
    @State private var packingsToDelete: Set<Packing> = []
    @State private var editSheetPresented = false
    
    var body: some View {
        Group {
            switch packings {
            case .success(let packings): valueView(packings)
            case .failure(let failure): APIFailureView(failure: failure, fetched: $packings, describe: \.description)
            case nil:
                if let error = $packings.apiError {
                    APIErrorView(error: error)
                } else {
                    FetchedLoadingView(fetched: $packings)
                }
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.large)
    }
    
    @ViewBuilder
    func valueView(_ packings: [Packing]) -> some View {
        List {
            Section {
                let sorted = packings.sorted { $0.item.title < $1.item.title }
                
                ForEach(sorted) { packing in
                    NavigationLink {
                        PackingView(packing: packing, api: api) {
                            await $packings.reload()
                        }
                    } label: {
                        Text(packing.box.title)
                            .badge(packing.amount)
                    }
                }
                .onDelete { indexSet in
                    self.packingsToDelete = Set(indexSet.map { sorted[$0] })
                }
            } header: {
                if !packings.isEmpty {
                    Text("Packed Boxes")
                }
            } footer: {
                if packings.isEmpty {
                    Text("Not packed into any boxes")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .refreshable {
            await $packings.reload()
        }
        .toolbar(content: toolbarView)
        .confirmationDialog("Unpack from \(packingsToDelete.count) box\(packingsToDelete.count == 1 ? "" : "es")?", isPresented: Binding {
            !packingsToDelete.isEmpty
        } set: {
            packingsToDelete = $0 ? packingsToDelete : []
        }) {
            Button("Unpack Item", role: .destructive) {
                deletePackings(packingsToDelete)
            }
        }
        .sheet(isPresented: $editSheetPresented) {
            NavigationStack {
                EditItemView(item: item, api: api) { item in
                    self.item.title = item.title
                    self.item.priority = item.priority
                }
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
