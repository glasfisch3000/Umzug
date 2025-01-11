//
//  ItemView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 11.01.25.
//

import SwiftUI

struct ItemView: View {
    var api: UmzugAPI
    var item: Item
    
    @UmzugFetched var packings: Result<[Packing], PackingsListFailure>?
    
    @State private var packingsToDelete: Set<Packing> = []
    
    var body: some View {
        Group {
            switch packings {
            case .success(let packings): valueView(packings)
            case nil:
                if let error = $packings.apiError {
                    apiErrorView(error)
                } else {
                    loadingView()
                }
            case .failure(let failure): failureView(failure)
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
                        Text(packing.item.title)
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
        .confirmationDialog("Unpack from \(packingsToDelete.count) box\(packingsToDelete.count == 1 ? "" : "es")?", isPresented: Binding {
            !packingsToDelete.isEmpty
        } set: {
            packingsToDelete = $0 ? packingsToDelete : []
        }) {
            Button("Unpack Item", role: .destructive) {
                deletePackings(packingsToDelete)
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

extension ItemView {
    @ViewBuilder
    func loadingView() -> some View {
        if $packings.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            Button("Load Value") {
                Task { await $packings.reload() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    @ViewBuilder
    func failureView(_ error: PackingsListFailure) -> some View {
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
