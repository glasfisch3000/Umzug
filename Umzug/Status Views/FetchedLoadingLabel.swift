//
//  FetchedLoadingLabel.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 12.01.25.
//

import SwiftUI
import APIInterface

struct FetchedLoadingLabel<each Value: Sendable>: View {
    var fetched: (repeat UmzugFetched<each Value>)
    
    var body: some View {
        if fetchedIsLoading {
            Label {
                Text("Loading…")
            } icon: {
                ProgressView()
            }
        } else {
            Button("Load Value", systemImage: "arrow.clockwise") {
                for f in repeat each fetched {
                    Task { await f.reload() }
                }
            }
        }
    }
    
    var fetchedIsLoading: Bool {
        for f in repeat each fetched {
            if f.isLoading { return true }
        }
        
        return false
    }
}
