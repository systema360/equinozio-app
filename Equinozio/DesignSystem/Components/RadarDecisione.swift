//
//  RadarDecisione.swift
//  Equinozio · DesignSystem · Components
//
//  Grafico radar per la matrice decisionale.
//  Mostra i quattro punteggi (1-5) come un quadrilatero deformato.
//

import SwiftUI

public struct RadarDecisione: View {

    public let passione: Int
    public let talento: Int
    public let missione: Int
    public let professione: Int
    public let mostraEtichette: Bool

    public init(
        passione: Int,
        talento: Int,
        missione: Int,
        professione: Int,
        mostraEtichette: Bool = true
    ) {
        self.passione = passione
        self.talento = talento
        self.missione = missione
        self.professione = professione
        self.mostraEtichette = mostraEtichette
    }

    public var body: some View {
        GeometryReader { proxy in
            let lato = min(proxy.size.width, proxy.size.height)
            let centro = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let raggioMax = lato * 0.4

            ZStack {
                // Griglia · tre rombi concentrici
                ForEach(1...3, id: \.self) { livello in
                    let r = raggioMax * CGFloat(livello) / 3.0
                    Path { p in
                        p.move(to: CGPoint(x: centro.x, y: centro.y - r))
                        p.addLine(to: CGPoint(x: centro.x + r, y: centro.y))
                        p.addLine(to: CGPoint(x: centro.x, y: centro.y + r))
                        p.addLine(to: CGPoint(x: centro.x - r, y: centro.y))
                        p.closeSubpath()
                    }
                    .stroke(Color.lineaSottile, lineWidth: 0.5)
                }

                // Assi orizzontale + verticale
                Path { p in
                    p.move(to: CGPoint(x: centro.x - raggioMax, y: centro.y))
                    p.addLine(to: CGPoint(x: centro.x + raggioMax, y: centro.y))
                    p.move(to: CGPoint(x: centro.x, y: centro.y - raggioMax))
                    p.addLine(to: CGPoint(x: centro.x, y: centro.y + raggioMax))
                }
                .stroke(Color.lineaSottile.opacity(0.5), lineWidth: 0.5)

                // Poligono punteggi
                let pP = CGPoint(x: centro.x, y: centro.y - r(passione, max: raggioMax))
                let pT = CGPoint(x: centro.x + r(talento, max: raggioMax), y: centro.y)
                let pM = CGPoint(x: centro.x, y: centro.y + r(missione, max: raggioMax))
                let pS = CGPoint(x: centro.x - r(professione, max: raggioMax), y: centro.y)

                Path { p in
                    p.move(to: pP)
                    p.addLine(to: pT)
                    p.addLine(to: pM)
                    p.addLine(to: pS)
                    p.closeSubpath()
                }
                .fill(Color.salvia.opacity(0.18))
                .overlay(
                    Path { p in
                        p.move(to: pP)
                        p.addLine(to: pT)
                        p.addLine(to: pM)
                        p.addLine(to: pS)
                        p.closeSubpath()
                    }
                    .stroke(Color.salvia, lineWidth: 1.5)
                )

                // Pallini ai vertici
                Circle().fill(Color.passione).frame(width: 8, height: 8).position(pP)
                Circle().fill(Color.talento).frame(width: 8, height: 8).position(pT)
                Circle().fill(Color.missione).frame(width: 8, height: 8).position(pM)
                Circle().fill(Color.professione).frame(width: 8, height: 8).position(pS)

                if mostraEtichette {
                    Text("PASSIONE")
                        .radarLabel(.passione)
                        .position(x: centro.x, y: centro.y - raggioMax - 14)

                    Text("TALENTO")
                        .radarLabel(.talento)
                        .position(x: centro.x + raggioMax + 32, y: centro.y)

                    Text("MISSIONE")
                        .radarLabel(.missione)
                        .position(x: centro.x, y: centro.y + raggioMax + 14)

                    Text("PROF.")
                        .radarLabel(.professione)
                        .position(x: centro.x - raggioMax - 22, y: centro.y)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Radar punteggi · passione \(passione), talento \(talento), missione \(missione), professione \(professione)")
    }

    private func r(_ valore: Int, max: CGFloat) -> CGFloat {
        max * CGFloat(min(valore, 5)) / 5.0
    }
}

private extension Text {
    func radarLabel(_ tipo: TipoCerchio) -> some View {
        self
            .font(.system(size: 9, weight: .medium))
            .tracking(1.4)
            .foregroundStyle(tipo.colore.opacity(0.9))
            .fixedSize()
    }
}

#Preview {
    VStack {
        RadarDecisione(passione: 2, talento: 5, missione: 3, professione: 5)
            .frame(width: 280, height: 280)
    }
    .padding()
}
