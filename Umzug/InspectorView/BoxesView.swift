//
//  BoxesView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 25.11.24.
//

import NIOHTTP1
import SwiftUI
import APIInterface

struct BoxesView: View {
    @UmzugFetched var boxes: Result<[Box], BoxesListFailure>?
    
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
        List {
            ForEach(boxes) { box in
                Label {
                    Text(box.title)
                } icon: {
                    Image(systemName: "shippingbox")
                }
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
                    try await $boxes.reload()
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
                    try await $boxes.reload()
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
