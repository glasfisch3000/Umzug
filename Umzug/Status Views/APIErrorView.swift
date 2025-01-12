//
//  APIErrorView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 12.01.25.
//

import SwiftUI

struct APIErrorView: View {
    var error: UmzugAPI.APIError
    
    var body: some View {
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
