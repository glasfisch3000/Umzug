//
//  APIFailureView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 12.01.25.
//

import SwiftUI
import APIInterface

struct APIFailureView<Value: Sendable, Failure: UmzugAPIFailure>: View {
    var failure: Failure
    var fetched: UmzugFetched<Result<Value, Failure>>
    
    var describe: (Failure) -> String
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.multicolor)
                .font(.largeTitle)
            
            Text(describe(failure))
            
            Spacer()
            
            Button {
                Task {
                    await fetched.reload()
                }
            } label: {
                HStack {
                    Spacer()
                    
                    if fetched.isLoading {
                        ProgressView()
                    } else {
                        Text("Reload")
                    }
                    
                    Spacer()
                }
            }
            .buttonBorderShape(.roundedRectangle)
            .buttonStyle(.bordered)
            .disabled(fetched.isLoading)
        }
        .padding()
    }
}
