//
//  FetchedLoadingView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 12.01.25.
//

import SwiftUI
import APIInterface

struct FetchedLoadingView<each Value: Sendable>: View {
    var fetched: (repeat UmzugFetched<each Value>)
    
    var body: some View {
        if fetchedIsLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            Button("Load Value") {
                for f in repeat each fetched {
                    Task { await f.reload() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    var fetchedIsLoading: Bool {
        for f in repeat each fetched {
            if f.isLoading { return true }
        }
        
        return false
    }
}
