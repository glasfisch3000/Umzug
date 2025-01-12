//
//  APIErrorLabel.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 12.01.25.
//

import SwiftUI

struct APIErrorLabel: View {
    var error: UmzugAPI.APIError
    
    var body: some View {
        Label("An error occurred while connecting to the API.", systemImage: "exclamationmark.octagon.fill")
            .foregroundStyle(.red)
            .symbolRenderingMode(.multicolor)
    }
}
