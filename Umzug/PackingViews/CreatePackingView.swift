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
    
    var onSuccess: (() async -> Void)? = nil
    
    @State private var amount = 1
    
    @State private var loading = false
    @State private var apiError: UmzugAPI.APIError? = nil
    @State private var failure: PackingsCreateFailure? = nil
    
    var body: some View {
        Form {
            Section {
                ItemPreview(item: item)
                
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
                if let error = apiError {
                    APIErrorLabel(error: error)
                } else if let failure = failure {
                    APIFailureLabel(failure: failure, describe: \.description)
                }
            }
        }
        .navigationTitle("Pack Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: toolbarView)
    }
    
    @ToolbarContentBuilder
    func toolbarView() -> some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if loading {
                ProgressView()
            } else {
                Button("Pack") {
                    Task { await pack() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(amount <= 0)
            }
        }
    }
    
    func pack() async {
        loading = true
        defer { loading = false }
        
        do throws(UmzugAPI.APIError) {
            // load item, don't throw failures because that doesn't work so we unwrap them instead
            switch try await api.makeRequest(.createPacking(item: item.id, box: box.id, amount: amount), success: Packing.DTO.self, failure: PackingsCreateFailure.self) {
            case .failure(let error): self.failure = error
            case .success(_):
                await onSuccess?()
                dismiss()
            }
        } catch let error {
            self.apiError = error
        }
    }
}
