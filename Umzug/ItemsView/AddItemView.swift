//
//  AddItemView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 11.01.25.
//

import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    
    var api: UmzugAPI
    var onSuccess: ((Item) async -> ())?
    
    @State private var title = ""
    @State private var priority: Item.Priority = .standard
    
    @State private var loading = false
    @State private var failure: Result<ItemsCreateFailure, UmzugAPI.APIError>? = nil
    
    @FocusState private var titleFieldSelected: Bool
    
    var body: some View {
        Form {
            Section {
                TextField("Item Title", text: $title)
                    .focused($titleFieldSelected)
                
                Picker("Priority", selection: $priority) {
                    ForEach(Item.Priority.allCases) { priority in
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
            } footer: {
                if let failure = self.failure {
                    failureView(failure: failure)
                }
            }
        }
        .navigationTitle("Add Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: toolbarView)
        .onAppear {
            titleFieldSelected = true
        }
    }
    
    @ViewBuilder
    func failureView(failure: Result<ItemsCreateFailure, UmzugAPI.APIError>) -> some View {
        Label {
            switch failure {
            case .success(.invalidContent): Text("The API responded with invalid content.")
            case .success(.noContent): Text("The API responded with empty content.")
            case .success(.constraintViolation(.item_unique(title: _))): Text("An item with this title already exists.")
            case .failure(_): Text("Unable to connect to the API.")
            }
        } icon: {
            switch failure {
            case .success(_): Image(systemName: "exclamationmark.triangle.fill")
            case .failure(_): Image(systemName: "exclamationmark.octagon.fill")
            }
        }
        .foregroundStyle(.red)
        .symbolRenderingMode(.multicolor)
    }
    
    @ToolbarContentBuilder
    func toolbarView() -> some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if loading {
                ProgressView()
            } else {
                Button("Create") {
                    Task {
                        loading = true
                        defer { self.loading = false }
                        
                        do throws(UmzugAPI.APIError) {
                            let response = try await api.makeRequest(.createItem(title: title, priority: priority), success: Item.self, failure: ItemsCreateFailure.self)
                            switch response {
                            case .success(let item):
                                dismiss()
                                await self.onSuccess?(item)
                            case .failure(let error):
                                self.failure = .success(error)
                            }
                        } catch {
                            self.failure = .failure(error)
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
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
