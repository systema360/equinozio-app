//
//  QuattroCerchi.swift
//  Equinozio · DesignSystem · Components
//
//  L'emblema dell'applicazione. Diagramma a quattro cerchi a rombo (logo canonico)
//  e identico al logo · è la costante visiva che accoglie l'utente.
//
//  Lo stato dell'utente (numero elementi, equilibrio, etc.) NON è espresso
//  qui · è espresso nelle card dati che vivono accanto al diagramma.
//  Vedi QuattroCerchiContatori per la versione con i numeri.
//

import SwiftUI

public struct QuattroCerchi: View {

    public let mostraEtichette: Bool
    public let respira: Bool

    @State private var inEspirazione: Bool = false
    @Environment(\.colorScheme) private var schema

    public init(mostraEtichette: Bool = true, respira: Bool = true) {
        self.mostraEtichette = mostraEtichette
        self.respira = respira
    }

    public var body: some View {
        GeometryReader { proxy in
            let lato = min(proxy.size.width, proxy.size.height)
            let centro = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            // Logo a rombo: stessi raggi, centri ai 4 punti cardinali.
            let distanzaCentri: CGFloat = lato * 0.19
            let raggio: CGFloat = lato * 0.19

            ZStack {
                Canvas { ctx, _ in
                    // In light il `multiply` scurisce le sovrapposizioni (Venn classico).
                    // Su sfondo scuro `multiply` annerirebbe i cerchi fino a farli sparire:
                    // passiamo a `screen`, che schiarisce sul fondo scuro mantenendo la
                    // stessa logica additiva delle sovrapposizioni.
                    let scuro = schema == .dark
                    ctx.blendMode = scuro ? .screen : .multiply
                    let opacita = respira && inEspirazione
                        ? (scuro ? 0.92 : 0.86)
                        : (scuro ? 0.82 : 0.78)
                    let posizioni: [(CGPoint, Color)] = [
                        (CGPoint(x: centro.x,                    y: centro.y - distanzaCentri), .passione),
                        (CGPoint(x: centro.x - distanzaCentri,   y: centro.y),                  .talento),
                        (CGPoint(x: centro.x + distanzaCentri,   y: centro.y),                  .missione),
                        (CGPoint(x: centro.x,                    y: centro.y + distanzaCentri), .professione),
                    ]
                    for (pos, colore) in posizioni {
                        let rect = CGRect(
                            x: pos.x - raggio, y: pos.y - raggio,
                            width: raggio * 2, height: raggio * 2
                        )
                        ctx.fill(Path(ellipseIn: rect), with: .color(colore.opacity(opacita)))
                    }
                }
                .scaleEffect(respira && inEspirazione ? 1.025 : 1.0)
                .animation(
                    respira
                        ? .easeInOut(duration: 4.5).repeatForever(autoreverses: true)
                        : .default,
                    value: inEspirazione
                )

                if mostraEtichette {
                    etichetteEsterne(centro: centro, distanzaCentri: distanzaCentri, raggio: raggio)
                }
            }
            .onAppear {
                if respira { inEspirazione = true }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Il tuo equinozio · diagramma dei quattro cerchi")
    }

    @ViewBuilder
    private func etichetteEsterne(centro: CGPoint, distanzaCentri: CGFloat, raggio: CGFloat) -> some View {
        let margine: CGFloat = 6

        etichetta(.passione)
            .position(x: centro.x, y: centro.y - distanzaCentri - raggio - margine)
        etichetta(.talento)
            .position(x: centro.x - distanzaCentri - raggio - margine, y: centro.y)
        etichetta(.missione)
            .position(x: centro.x + distanzaCentri + raggio + margine, y: centro.y)
        etichetta(.professione)
            .position(x: centro.x, y: centro.y + distanzaCentri + raggio + margine)
    }

    private func etichetta(_ tipo: TipoCerchio) -> some View {
        Text("· " + tipo.titolo.lowercased())
            .font(.system(size: 9, weight: .medium))
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(tipo.colore.opacity(0.9))
            .fixedSize()
    }
}

// MARK: - Versione coi conteggi (per Mappa)

public struct QuattroCerchiContatori: View {

    public let cerchi: [Cerchio]

    public init(cerchi: [Cerchio]) {
        self.cerchi = cerchi
    }

    public var body: some View {
        HStack(spacing: S.x2) {
            ForEach(TipoCerchio.allCases) { tipo in
                cardCerchio(tipo)
            }
        }
    }

    private func cardCerchio(_ tipo: TipoCerchio) -> some View {
        let n = cerchi.first(where: { $0.tipo == tipo })?.elementi?.count ?? 0
        let attivo = n > 0

        return VStack(spacing: 6) {
            Text("\(n)")
                .font(.system(size: 28, weight: .thin))
                .monospacedDigit()
                .foregroundStyle(attivo ? tipo.colore : Color.attenuato.opacity(0.5))
                .tracking(-1)

            Text(tipo.titolo.uppercased())
                .font(.system(size: 9, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(attivo ? tipo.colore : Color.attenuato)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, S.x3)
        .background(attivo ? tipo.colore.opacity(0.12) : Color.superficie)
        .clipShape(RoundedRectangle(cornerRadius: R.r1))
        .overlay(
            RoundedRectangle(cornerRadius: R.r1)
                .stroke(attivo ? tipo.colore.opacity(0.3) : Color.lineaSottile, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tipo.titolo): \(n) element\(n == 1 ? "o" : "i")")
    }
}

#Preview {
    VStack(spacing: 24) {
        QuattroCerchi()
            .frame(width: 280, height: 280)

        QuattroCerchiContatori(cerchi: [
            Cerchio(tipo: .passione),
            Cerchio(tipo: .talento),
            Cerchio(tipo: .missione),
            Cerchio(tipo: .professione),
        ])
        .padding(.horizontal)
    }
    .padding()
    .background(Color.sfondo)
}
