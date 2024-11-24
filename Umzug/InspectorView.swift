//
//  InspectorView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 24.11.24.
//

import SwiftUI

struct InspectorView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var api: UmzugAPI
    
    var body: some View {
        GeometryReader { geo in
            if geo.size.width > geo.size.height {
                HStack(alignment: .center, spacing: 20) {
                    navigationLinks
                }
                .padding()
            } else {
                VStack(alignment: .center, spacing: 20) {
                    navigationLinks
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private var navigationLinks: some View {
        Group {
            ZStack {
                RoundedRectangle(cornerRadius: 40)
                    .foregroundStyle(.red)
                    .opacity(0.3)
                
                VStack(alignment: .center, spacing: 15) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 60))
                    
                    HStack(alignment: .center) {
                        Text("Boxes")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "chevron.forward")
                            .font(.title)
                    }
                }
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 40)
                    .foregroundStyle(.blue)
                    .opacity(0.3)
                
                VStack(alignment: .center, spacing: 15) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 60))
                    
                    HStack(alignment: .center) {
                        Text("Items")
                            .fontWeight(.semibold)
                            .font(.title)
                        
                        Image(systemName: "chevron.forward")
                            .font(.title)
                    }
                }
            }
        }
    }
}
