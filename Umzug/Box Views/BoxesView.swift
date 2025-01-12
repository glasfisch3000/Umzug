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
        case .failure(let failure): APIFailureView(failure: failure, fetched: $boxes, describe: \.description)
        case nil:
            if let error = $boxes.apiError {
                APIErrorView(error: error)
            } else {
                FetchedLoadingView(fetched: $boxes)
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
}
