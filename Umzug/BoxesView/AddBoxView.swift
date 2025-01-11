//
//  AddBoxView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 05.12.24.
//

import SwiftUI

struct AddBoxView: View {
    @Environment(\.dismiss) private var dismiss
    
    var api: UmzugAPI
    var onSuccess: ((Box) async -> ())?
    
    @State private var title = ""
    @State private var loading = false
    @State private var failure: Result<BoxesCreateFailure, UmzugAPI.APIError>? = nil
    
    @FocusState private var titleFieldSelected: Bool
    
    var body: some View {
        Form {
            Section {
                TextField("Box Title", text: $title)
                    .focused($titleFieldSelected)
            } footer: {
                if let failure = self.failure {
                    failureView(failure: failure)
                }
            }
        }
        .navigationTitle("Add Box")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: toolbarView)
        .onAppear {
            titleFieldSelected = true
        }
    }
    
    @ViewBuilder
    func failureView(failure: Result<BoxesCreateFailure, UmzugAPI.APIError>) -> some View {
        Label {
            switch failure {
            case .success(.invalidContent): Text("The API responded with invalid content.")
            case .success(.noContent): Text("The API responded with empty content.")
            case .success(.constraintViolation(.box_unique(title: _))): Text("A box with this title already exists.")
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
                    Task { await addBox() }
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
    
    func addBox() async {
        loading = true
        defer { self.loading = false }
        
        do throws(UmzugAPI.APIError) {
            let response = try await api.makeRequest(.createBox(title: title), success: Box.self, failure: BoxesCreateFailure.self)
            switch response {
            case .success(let box):
                await self.onSuccess?(box)
                dismiss()
            case .failure(let error):
                self.failure = .success(error)
            }
        } catch {
            self.failure = .failure(error)
        }
    }
}
