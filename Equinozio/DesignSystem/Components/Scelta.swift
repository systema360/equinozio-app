//
//  Scelta.swift
//  Equinozio · DesignSystem · Components
//
//  Pillola selezionabile. Usata nell'onboarding e nei filtri del diario.
//

import SwiftUI

public struct Scelta: View {

    public let testo: String
    @Binding public var attiva: Bool

    public init(_ testo: String, attiva: Binding<Bool>) {
        self.testo = testo
        self._attiva = attiva
    }

    public var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                attiva.toggle()
            }
        } label: {
            Text(testo)
                .font(.equinozio(.corpoMedio))
                .padding(.horizontal, S.x4)
                .padding(.vertical, 11)
                .background(attiva ? Color.salvia : Color.superficie)
                .foregroundStyle(attiva ? Color.white : Color.inchiostroTenue)
                .overlay(
                    Capsule().stroke(
                        attiva ? Color.salvia : Color.lineaSottile,
                        lineWidth: 1
                    )
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .accessibilityLabel("\(testo)")
        .accessibilityValue(attiva ? "selezionato" : "non selezionato")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    struct ProvaScelta: View {
        @State private var a = true
        @State private var b = false
        var body: some View {
            HStack {
                Scelta("Scrivere", attiva: $a)
                Scelta("Cucinare", attiva: $b)
            }
            .padding()
        }
    }
    return ProvaScelta()
}
