//
//  BottoneImpostazioni.swift
//  Equinozio · DesignSystem · Components
//
//  Bottone circolare con ingranaggio per aprire le Impostazioni.
//  Stesso aspetto in tutte le schede.
//

import SwiftUI

public struct BottoneImpostazioni: View {

    public let azione: () -> Void

    public init(azione: @escaping () -> Void) {
        self.azione = azione
    }

    public var body: some View {
        Button(action: azione) {
            Image(systemName: "gearshape")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color.attenuato)
                .frame(width: 36, height: 36)
                .background(Color.superficie)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.lineaSottile, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Apri impostazioni")
    }
}
