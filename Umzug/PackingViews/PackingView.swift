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
    @State private var updateFailure: PackingsUpdateFailure?
    
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
                failureView()
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
    
    @ViewBuilder
    func failureView() -> some View {
        if self.apiError != nil {
            Label("Unable to connect to the API.", systemImage: "exclamationmark.octagon.fill")
        } else if let updateFailure = updateFailure {
            Label {
                switch updateFailure {
                case .invalidContent: Text("The API responded with invalid content.")
                case .noContent: Text("The API responded with empty content.")
                case .constraintViolation(.packing_unique(item: _, box: _)): Text("The API responded with an unexpected failure.")
                case .constraintViolation(.packing_nonzero(amount: _)): Text("Invalid amount.")
                case .modelNotFound(_): Text("The API responded with an unexpected failure.")
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
            }
        }
    }
    
    func save() async {
        loading = true
        defer { loading = false }
        
        do throws(UmzugAPI.APIError) {
            switch try await api.makeRequest(.updatePacking(packing.id, amount: packing.amount+amountOffset), success: Packing.DTO.self, failure: PackingsUpdateFailure.self) {
            case .failure(let error): self.updateFailure = error
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
