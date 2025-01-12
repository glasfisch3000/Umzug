//
//  EditItemView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 12.01.25.
//

import SwiftUI

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    
    var item: Item
    var api: UmzugAPI
    
    var onSuccess: ((Item) async -> ())?
    
    init(item: Item, api: UmzugAPI, onSuccess: ((Item) async -> Void)? = nil) {
        self.item = item
        self.api = api
        self.onSuccess = onSuccess
        
        self.title = item.title
        self.priority = item.priority
    }
    
    @State private var title: String
    @State private var priority: Item.Priority
    
    @State private var loading = false
    @State private var failure: Result<ItemsUpdateFailure, UmzugAPI.APIError>? = nil
    
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
        .navigationTitle("Edit Item")
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
                Button("Save") {
                    Task { await save() }
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
    
    func save() async {
        loading = true
        defer { self.loading = false }
        
        do throws(UmzugAPI.APIError) {
            let response = try await api.makeRequest(.updateItem(item.id, title: title, priority: priority), success: Item.self, failure: ItemsUpdateFailure.self)
            switch response {
            case .failure(let error): self.failure = .success(error)
            case .success(let item):
                await self.onSuccess?(item)
                dismiss()
            }
        } catch {
            self.failure = .failure(error)
        }
    }
}
