//
//  CreateNewItemPackingView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 23.12.24.
//

import SwiftUI

struct CreateNewItemPackingView: View {
    @Environment(\.dismiss) private var dismiss
    
    var api: UmzugAPI
    var box: Box
    
    @State var title: String
    
    var onSuccess: (() async -> Void)? = nil
    
    @State private var amount = 1
    @State private var priority: Item.Priority = .standard
    
    @State private var loading = false
    @State private var apiError: UmzugAPI.APIError? = nil
    @State private var itemFailure: ItemsCreateFailure? = nil
    @State private var packingFailure: PackingsCreateFailure? = nil
    
    @FocusState private var textFieldSelected: Bool
    
    var body: some View {
        Form {
            Section("Item") {
                LabeledContent("Title") {
                    TextField("Insert title", text: $title)
                        .focused($textFieldSelected)
                        .multilineTextAlignment(.trailing)
                }
                
                Picker("Priority", selection: $priority) {
                    ForEach(Umzug.Item.Priority.allCases) { priority in
                        Group {
                            switch priority {
                            case .immediate: Text("Immediate")
                            case .standard: Text("Standard")
                            case .longTerm: Text("Long Term")
                            }
                        }
                        .tag(priority)
                    }
                }
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
        .navigationTitle("Pack Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: toolbarView)
        .onAppear {
            textFieldSelected = true
        }
    }
    
    @ViewBuilder
    func failureView() -> some View {
        if self.apiError != nil {
            Label("Unable to connect to the API.", systemImage: "exclamationmark.octagon.fill")
        } else if let itemFailure = itemFailure {
            Label {
                switch itemFailure {
                case .invalidContent: Text("The API responded with invalid content.")
                case .noContent: Text("The API responded with empty content.")
                case .constraintViolation(.item_unique(title: _)): Text("An item with this title already exists.")
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
            }
        } else if let packingFailure = packingFailure {
            Label {
                switch packingFailure {
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
                    Task { await pack() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(amount <= 0)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    func pack() async {
        loading = true
        defer { loading = false }
        
        do throws(UmzugAPI.APIError) {
            // create item and packing, don't throw failures because that doesn't work so we unwrap them instead
            switch try await api.makeRequest(.createItem(title: title, priority: priority), success: Item.self, failure: ItemsCreateFailure.self) {
            case .failure(let error): self.itemFailure = error
            case .success(let item):
                switch try await api.makeRequest(.createPacking(item: item.id, box: box.id, amount: amount), success: Packing.DTO.self, failure: PackingsCreateFailure.self) {
                case .failure(let error): self.packingFailure = error
                case .success(_):
                    await onSuccess?()
                    dismiss()
                }
            }
        } catch let error {
            self.apiError = error
        }
    }
}
