//
//  APIFailureLabel.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 12.01.25.
//

import SwiftUI
import APIInterface

struct APIFailureLabel<Failure: UmzugAPIFailure>: View {
    var failure: Failure
    
    var describe: (Failure) -> String
    
    var body: some View {
        Label(describe(failure), systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
            .symbolRenderingMode(.multicolor)
    }
}
