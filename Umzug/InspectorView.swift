//
//  InspectorView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 24.11.24.
//

import SwiftUI

struct InspectorView: View {
    enum NavigationContent: Hashable {
        case boxes
    }
    
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var api: UmzugAPI
    
    @State private var presentedPath: [NavigationContent] = []
    
    var body: some View {
        NavigationStack(path: $presentedPath) {
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
            .navigationDestination(for: NavigationContent.self) { path in
                switch path {
                case .boxes: BoxesView(boxes: UmzugFetched(api: api, request: .boxes))
                }
            }
        }
    }
    
    @ViewBuilder
    private var navigationLinks: some View {
        Group {
            NavigationLink(value: NavigationContent.boxes) {
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
            }
            .foregroundStyle(.primary)
            
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
