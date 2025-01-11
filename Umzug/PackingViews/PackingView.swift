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
    
    @State private var amountOffset = 0
    
    @State private var loading = false
    @State private var apiError: UmzugAPI.APIError?
    @State private var updateFailure: PackingsUpdateFailure?
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Text(packing.item.title)
                        .font(.headline)
                    
                    Group {
                        switch packing.item.priority {
                        case .immediate: Text("Immediate Priority").foregroundStyle(.red)
                        case .standard: Text("Standard Priority").foregroundStyle(.yellow)
                        case .longTerm: Text("Long Term Priority").foregroundStyle(.green)
                        }
                    }
                    .font(.caption)
                    .bold()
                }
                
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
        }
        .navigationTitle("Edit Packing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if loading {
                    ProgressView()
                } else {
                    Button("Save") {
                        Task {
                            loading = true
                            defer { loading = false }
                            
                            do throws(UmzugAPI.APIError) {
                                switch try await api.makeRequest(.updatePacking(packing.id, amount: packing.amount+amountOffset), success: Packing.self, failure: PackingsUpdateFailure.self) {
                                case .success(_): dismiss()
                                case .failure(let error): self.updateFailure = error
                                }
                            } catch let error {
                                self.apiError = error
                                return
                            }
                        }
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
}
