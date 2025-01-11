//
//  ItemPreview.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 11.01.25.
//

import SwiftUI

struct ItemPreview: View {
    var item: Item
    
    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(item.title)
                
                Group {
                    switch item.priority {
                    case .immediate: Text("Immediate Priority").foregroundStyle(.red)
                    case .standard: Text("Standard Priority").foregroundStyle(.yellow)
                    case .longTerm: Text("Long Term Priority").foregroundStyle(.green)
                    }
                }
                .font(.caption)
            }
        } icon: {
            Image(systemName: "list.bullet")
        }
    }
}
