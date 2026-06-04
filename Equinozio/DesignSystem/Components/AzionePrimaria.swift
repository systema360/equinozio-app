//
//  AzionePrimaria.swift
//  Equinozio · DesignSystem · Components
//
//  Pulsante primario con sfondo salvia.
//  Maiuscoletto con tracking ampio, stile modernista.
//

import SwiftUI

public struct AzionePrimaria: View {

    public let titolo: String
    public let azione: () -> Void

    public init(_ titolo: String, azione: @escaping () -> Void) {
        self.titolo = titolo
        self.azione = azione
    }

    public var body: some View {
        Button(action: azione) {
            Text(titolo.uppercased())
                .font(.system(size: 14, weight: .medium))
                .tracking(1.1)
                .frame(maxWidth: .infinity)
                .padding(S.x4)
                .background(Color.salvia)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(titolo)
    }
}

#Preview {
    AzionePrimaria("Continua") { }
        .padding()
}
