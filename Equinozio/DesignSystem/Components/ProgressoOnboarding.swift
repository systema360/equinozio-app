//
//  ProgressoOnboarding.swift
//  Equinozio · DesignSystem · Components
//
//  Barra di progresso a step per l'onboarding (quattro tappe).
//

import SwiftUI

public struct ProgressoOnboarding: View {

    public let totale: Int
    public let corrente: Int  // 0-based

    public init(totale: Int, corrente: Int) {
        self.totale = totale
        self.corrente = corrente
    }

    public var body: some View {
        HStack(spacing: S.x1) {
            ForEach(0..<totale, id: \.self) { i in
                Capsule()
                    .fill(coloreStep(i))
                    .frame(height: 3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tappa \(corrente + 1) di \(totale)")
    }

    private func coloreStep(_ i: Int) -> Color {
        if i < corrente { return .salvia }
        if i == corrente { return .salvia.opacity(0.45) }
        return .lineaSottile
    }
}

#Preview {
    VStack(spacing: 16) {
        ProgressoOnboarding(totale: 4, corrente: 0)
        ProgressoOnboarding(totale: 4, corrente: 1)
        ProgressoOnboarding(totale: 4, corrente: 2)
        ProgressoOnboarding(totale: 4, corrente: 3)
    }
    .padding()
}
