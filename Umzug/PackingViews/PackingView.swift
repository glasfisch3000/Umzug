//
//  PackingView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 11.12.24.
//

import SwiftUI

struct PackingView: View {
    @Environment(\.dismiss) private var dismiss
    
    var packing: Packing
    var api: UmzugAPI
    
    var onSuccess: (() async -> Void)? = nil
    
    @State private var amountOffset = 0
    
    @State private var loading = false
    @State private var apiError: UmzugAPI.APIError?
    @State private var failure: PackingsUpdateFailure?
    
    var body: some View {
        Form {
            Section {
                ItemPreview(item: packing.item)
                
                Label(packing.box.title, systemImage: "shippingbox")
            }
            
            let valueBinding = Binding {
                packing.amount + amountOffset
            } set: {
                amountOffset = max($0 - packing.amount, -packing.amount+1) // sum shouldn't go below 1
            }
            
            Section {
                Stepper(value: valueBinding) {
                    TextField("Amount", value: valueBinding, format: .number.sign(strategy: .never))
                }
            } header: {
                Text("Amount")
            } footer: {
                if let error = apiError {
                    APIErrorLabel(error: error)
                } else if let failure = failure {
                    APIFailureLabel(failure: failure, describe: \.description)
                }
            }
            
            Button("Unpack item", systemImage: "trash", role: .destructive) {
                Task { await deleteItem() }
            }
            .symbolRenderingMode(.multicolor)
        }
        .navigationTitle("Edit Packing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if loading {
                    ProgressView()
                } else {
                    Button("Save") {
                        Task { await save() }
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
    }
    
    func save() async {
        loading = true
        defer { loading = false }
        
        do throws(UmzugAPI.APIError) {
            switch try await api.makeRequest(.updatePacking(packing.id, amount: packing.amount+amountOffset), success: Packing.DTO.self, failure: PackingsUpdateFailure.self) {
            case .failure(let error): self.failure = error
            case .success(_):
                await onSuccess?()
                dismiss()
            }
        } catch let error {
            self.apiError = error
        }
    }
    
    func deleteItem() async {
        do throws(UmzugAPI.APIError) {
            switch try await packing.delete(on: self.api) {
            case .failure(let failure):
                print(failure)
            case .success(_):
                await onSuccess?()
                dismiss()
            }
        } catch {
            self.apiError = error
        }
    }
}
