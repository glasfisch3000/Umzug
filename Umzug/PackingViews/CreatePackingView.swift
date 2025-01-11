//
//  CreatePackingView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 23.12.24.
//

import SwiftUI

struct CreatePackingView: View {
    @Environment(\.dismiss) private var dismiss
    
    var api: UmzugAPI
    var item: Item
    var box: Box
    
    @State private var amount = 1
    
    @State private var loading = false
    @State private var apiError: UmzugAPI.APIError? = nil
    @State private var failure: PackingsCreateFailure? = nil
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                    
                    Group {
                        switch item.priority {
                        case .immediate: Text("Immediate Priority").foregroundStyle(.red)
                        case .standard: Text("Standard Priority").foregroundStyle(.yellow)
                        case .longTerm: Text("Long Term Priority").foregroundStyle(.green)
                        }
                    }
                    .font(.caption)
                    .bold()
                }
                
                Label(box.title, systemImage: "shippingbox")
            }
            
            Section {
                Stepper(value: Binding { amount } set: {
                    amount = max($0, 0)
                }) {
                    TextField("Amount", value: $amount, format: .number.sign(strategy: .never))
                }
            } header: {
                Text("Amount")
            } footer: {
                failureView()
            }
        }
        .navigationTitle("Pack item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: toolbarView)
    }
    
    @ViewBuilder
    func failureView() -> some View {
        if self.apiError != nil {
            Label("Unable to connect to the API.", systemImage: "exclamationmark.octagon.fill")
        } else if let failure = failure {
            Label {
                switch failure {
                case .invalidContent: Text("The API responded with invalid content.")
                case .noContent: Text("The API responded with empty content.")
                case .constraintViolation(.packing_unique(item: _, box: _)): Text("This item is already packed.")
                case .constraintViolation(.packing_nonzero(amount: _)): Text("Invalid amount.")
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
            }
        }
    }
    
    @ToolbarContentBuilder
    func toolbarView() -> some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if loading {
                ProgressView()
            } else {
                Button("Pack") {
                    Task {
                        loading = true
                        defer { loading = false }
                        
                        do throws(UmzugAPI.APIError) {
                            // load item, don't throw failures because that doesn't work so we unwrap them instead
                            switch try await api.makeRequest(.createPacking(item: item.id, box: box.id, amount: amount), success: Packing.self, failure: PackingsCreateFailure.self) {
                            case .failure(let error): self.failure = error
                            case .success(_): dismiss()
                            }
                        } catch let error {
                            self.apiError = error
                            return
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(amount <= 0)
            }
        }
        
        if !loading {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
    }
}
