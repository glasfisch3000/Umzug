//
//  BoxesView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 25.11.24.
//

import SwiftUI
import APIInterface

struct BoxesView: View {
    @UmzugFetched var boxes: Result<[Box], BoxesListFailure>?
    
    @State private var selection: [Box] = []
    @State private var addBoxSheetPresented = false
    
    var body: some View {
        switch boxes {
        case .success(let boxes): valueView(boxes)
        case .failure(let failure): failureView(failure)
        case nil:
            if let error = $boxes.apiError {
                apiErrorView(error)
            } else {
                loadingView()
            }
        }
    }
    
    @ViewBuilder
    func valueView(_ boxes: [Box]) -> some View {
        NavigationStack(path: $selection) {
            LazyHGrid(rows: [.init(.adaptive(minimum: 150, maximum: 200), alignment: .leading)], alignment: .top, pinnedViews: .sectionHeaders) {
                ForEach(boxes, content: boxView(box:))
            }
            .refreshable {
                await $boxes.reload()
            }
            .navigationTitle("Boxes")
            .toolbar(content: toolbarView)
            .sheet(isPresented: $addBoxSheetPresented, content: addBoxSheet)
            .navigationDestination(for: Box.self) { box in
                BoxView(api: $boxes.api, box: box, items: $boxes.api.fetched(for: .items), packings: $boxes.api.fetched(for: .packings(box: box.id)))
            }
        }
    }
    
    @ViewBuilder
    func boxView(box: Box) -> some View {
        NavigationLink(value: box) {
            ZStack {
                Circle()
                    .opacity(0)
                
                VStack(alignment: .center, spacing: 0) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 50))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    
                    Divider()
                    
                    (Text(box.title + " ") + Text(Image(systemName: "chevron.forward")))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                }
            }.background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.quaternary)
            }
        }
        .foregroundStyle(.primary)
        .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive) {
                Task {
                    do {
                        _ = try await box.delete(on: $boxes.api).get()
                        await $boxes.reload()
                    } catch {
                        print(error)
                    }
                }
            }
            .keyboardShortcut(.delete)
        }
    }
    
    @ToolbarContentBuilder
    func toolbarView() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Add Box", systemImage: "plus") {
                addBoxSheetPresented = true
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
    
    @ViewBuilder
    func addBoxSheet() -> some View {
        NavigationStack {
            AddBoxView(api: $boxes.api) { box in
                await $boxes.reload()
                self.selection.append(box)
            }
        }
    }
    
    @ViewBuilder
    func loadingView() -> some View {
        if $boxes.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            Button("Load Value") {
                Task {
                    await $boxes.reload()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    @ViewBuilder
    func failureView(_ error: BoxesListFailure) -> some View {
        VStack(alignment: .center) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.multicolor)
                .font(.largeTitle)
            
            switch error {
            case .serverError:
                Text("An internal API error occurred.")
            case .noContent, .invalidContent:
                Text("Received an invalid or empty API response.")
            }
            
            Spacer()
            
            Button {
                Task {
                    await $boxes.reload()
                }
            } label: {
                HStack {
                    Spacer()
                    
                    if $boxes.isLoading {
                        ProgressView()
                    } else {
                        Text("Reload")
                    }
                    
                    Spacer()
                }
            }
            .buttonBorderShape(.roundedRectangle)
            .buttonStyle(.bordered)
            .disabled($boxes.isLoading)
        }
        .padding()
    }
    
    @ViewBuilder
    func apiErrorView(_ error: UmzugAPI.APIError) -> some View {
        VStack(alignment: .center) {
            Image(systemName: "exclamationmark.octagon.fill")
                .symbolRenderingMode(.multicolor)
                .font(.largeTitle)
            
            Text("An error occurred while connecting to the API.")
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
}
