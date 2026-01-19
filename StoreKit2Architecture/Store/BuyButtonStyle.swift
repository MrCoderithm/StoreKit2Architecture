//
//  BuyButton.swift
//  StoreKit2Architecture
//
//  Created by Ali Muhammad on 2026-01-18.
//

import SwiftUI

struct BuyButtonStyle: ButtonStyle {
    let isPurchased: Bool

    func makeBody(configuration: Configuration) -> some View {
        let base = isPurchased ? Color.green : Color.accentColor

        return configuration.label
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(base.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 4)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}


#Preview("Buy")  {
    Button(action: {}, label: {
        Text("Buy")
            .foregroundColor(.white)
            .bold()
    })
    .buttonStyle(BuyButtonStyle(isPurchased: false))
}

#Preview("Purchase") {
    Button(action: {}, label: {
        Image(systemName: "checkmark")
            .foregroundColor(.white)
            .bold()
    })
    .buttonStyle(BuyButtonStyle(isPurchased: true))
}

//#Preview("Buy") {
//    BuyButton(isPurchased: false)
//        .previewDisplayName("Buy")
//}
