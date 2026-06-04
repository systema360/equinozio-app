//
//  AzioneSecondaria.swift
//  Equinozio · DesignSystem · Components
//
//  Bottone testuale tenue, senza sfondo.
//

import SwiftUI

public struct AzioneSecondaria: View {

    public let titolo: String
    public let azione: () -> Void

    public init(_ titolo: String, azione: @escaping () -> Void) {
        self.titolo = titolo
        self.azione = azione
    }

    public var body: some View {
        Button(action: azione) {
            Text(titolo.uppercased())
                .font(.system(size: 12, weight: .light))
                .tracking(1.0)
                .foregroundStyle(Color.attenuato)
                .padding(.horizontal, S.x3)
                .padding(.vertical, S.x2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(titolo)
    }
}

#Preview {
    AzioneSecondaria("Più tardi") { }
        .padding()
}
