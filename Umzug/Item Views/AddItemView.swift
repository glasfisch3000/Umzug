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
                switch failure {
                case .success(let failure): APIFailureLabel(failure: failure, describe: \.description)
                case .failure(let error): APIErrorView(error: error)
                case nil: EmptyView()
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
    
    @ToolbarContentBuilder
    func toolbarView() -> some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if loading {
                ProgressView()
            } else {
                Button("Create") {
                    Task { await addItem() }
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
    
    func addItem() async {
        loading = true
        defer { self.loading = false }
        
        do throws(UmzugAPI.APIError) {
            let response = try await api.makeRequest(.createItem(title: title, priority: priority), success: Item.self, failure: ItemsCreateFailure.self)
            switch response {
            case .success(let item):
                await self.onSuccess?(item)
                dismiss()
            case .failure(let error):
                self.failure = .success(error)
            }
        } catch {
            self.failure = .failure(error)
        }
    }
}
