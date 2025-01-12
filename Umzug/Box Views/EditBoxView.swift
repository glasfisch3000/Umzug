//
//  EditBoxView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 12.01.25.
//

import SwiftUI

struct EditBoxView: View {
    @Environment(\.dismiss) private var dismiss
    
    var box: Box
    var api: UmzugAPI
    
    var onSuccess: ((Box) async -> ())?
    
    init(box: Box, api: UmzugAPI, onSuccess: ((Box) async -> Void)? = nil) {
        self.box = box
        self.api = api
        self.onSuccess = onSuccess
        
        self.title = box.title
    }
    
    @State private var title: String
    
    @State private var loading = false
    @State private var failure: Result<BoxesUpdateFailure, UmzugAPI.APIError>? = nil
    
    @FocusState private var titleFieldSelected: Bool
    
    var body: some View {
        Form {
            Section {
                TextField("Box Title", text: $title)
                    .focused($titleFieldSelected)
            } footer: {
                switch failure {
                case .success(let failure): APIFailureLabel(failure: failure, describe: \.description)
                case .failure(let error): APIErrorView(error: error)
                case nil: EmptyView()
                }
            }
        }
        .navigationTitle("Edit Box")
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
            let response = try await api.makeRequest(.updateBox(box.id, title: title), success: Box.self, failure: BoxesUpdateFailure.self)
            switch response {
            case .failure(let error): self.failure = .success(error)
            case .success(let box):
                await self.onSuccess?(box)
                dismiss()
            }
        } catch {
            self.failure = .failure(error)
        }
    }
}
