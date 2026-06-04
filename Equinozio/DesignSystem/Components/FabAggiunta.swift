//
//  FabAggiunta.swift
//  Equinozio · DesignSystem · Components
//
//  Pulsante flottante "+" tipografico (Helvetica Thin, non SF Symbol).
//

import SwiftUI

public struct FabAggiunta: View {

    public let azione: () -> Void
    public let accessibilityLabelTesto: String

    public init(
        accessibilityLabelTesto: String = "Aggiungi",
        azione: @escaping () -> Void
    ) {
        self.accessibilityLabelTesto = accessibilityLabelTesto
        self.azione = azione
    }

    public var body: some View {
        Button(action: azione) {
            Text("+")
                .font(.system(size: 26, weight: .thin))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.salvia)
                .clipShape(Circle())
                .shadow(color: Color.salvia.opacity(0.25), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabelTesto)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    FabAggiunta { }
        .padding()
}
