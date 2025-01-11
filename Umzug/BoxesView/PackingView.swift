//
//  PackingView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 11.12.24.
//

import SwiftUI

struct PackingView: View {
    @Environment(\.dismiss) private var dismiss
    
    var item: Item
    var packing: Packing?
    var api: UmzugAPI
    var box: Box
    
    init(item: Item, api: UmzugAPI, box: Box) {
        self.item = item
        self.packing = nil
        self.api = api
        self.box = box
        self.amount = 1
    }
    
    init(packing: Packing, api: UmzugAPI, box: Box) {
        self.item = packing.item
        self.packing = nil
        self.api = api
        self.box = box
        self.amount = packing.amount
    }
    
    @State var amount: Int
    
    @State private var loading = false
    @State private var apiError: UmzugAPI.APIError?
    @State private var updateFailure: PackingsUpdateFailure?
    @State private var createFailure: PackingsCreateFailure?
    
    var body: some View {
        Form {
            Section("Item") {
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                    
                    Text(item.id.uuidString)
                        .font(.caption)
                }
            }
            
            Stepper(value: $amount) {
                TextField("Amount", value: $amount, format: .number.sign(strategy: .never))
            }
        }
        .navigationTitle("Pack item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Pack") {
                    Task {
                        loading = true
                        defer { loading = false }
                        
                        do throws(UmzugAPI.APIError) {
                            if let packing = packing {
                                switch try await updatePacking(packing.id) {
                                case .success(_): dismiss()
                                case .failure(let error): self.updateFailure = error
                                }
                            } else {
                                switch try await createPacking() {
                                case .success(_): dismiss()
                                case .failure(let error): self.createFailure = error
                                }
                            }
                        } catch let error {
                            self.apiError = error
                            return
                        }
                    }
                }
            }
        }
    }
    
    func updatePacking(_ packing: UUID) async throws(UmzugAPI.APIError) -> Result<Packing, PackingsUpdateFailure> {
        try await api.makeRequest(.updatePacking(packing, amount: amount), success: Packing.self, failure: PackingsUpdateFailure.self)
    }
    
    func createPacking() async throws(UmzugAPI.APIError) -> Result<Packing, PackingsCreateFailure> {
        try await api.makeRequest(.createPacking(item: item.id, box: box.id, amount: amount), success: Packing.self, failure: PackingsCreateFailure.self)
    }
}
