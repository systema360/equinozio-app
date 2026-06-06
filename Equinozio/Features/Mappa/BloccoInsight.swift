//
//  BloccoInsight.swift
//  Equinozio · Features · Mappa
//
//  Mostra gli insight generati (compagno discreto) nella dashboard.
//

import SwiftUI

struct BloccoInsight: View {
    let insight: [InsightGenerato]
    var onTap: ((TipoInsight) -> Void)? = nil

    var body: some View {
        if !insight.isEmpty {
            VStack(alignment: .leading, spacing: S.x3) {
                Text("SPUNTI")
                    .font(.equinozio(.etichetta))
                    .tracking(2.2)
                    .foregroundStyle(Color.attenuato)

                VStack(spacing: S.x2) {
                    ForEach(insight) { spunto in
                        Button {
                            onTap?(spunto.tipo)
                        } label: {
                            HStack(alignment: .top, spacing: S.x3) {
                                Image(systemName: icona(spunto.tipo))
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundStyle(Color.salvia)
                                    .frame(width: 24, height: 24, alignment: .center)
                                    .padding(.top, 2)

                                Text(spunto.testo)
                                    .font(.equinozio(.corpoMedio))
                                    .foregroundStyle(Color.inchiostro)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(S.x4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.superficie)
                            .clipShape(RoundedRectangle(cornerRadius: R.r2))
                            .overlay(
                                RoundedRectangle(cornerRadius: R.r2)
                                    .stroke(Color.lineaSottile, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Apri la scheda relativa")
                    }
                }
            }
        }
    }

    private func icona(_ tipo: TipoInsight) -> String {
        switch tipo {
        case .bilanciamentoBasso: return "exclamationmark.circle"
        case .dominanzaCerchio:   return "circle.lefthalf.filled"
        case .crescitaTrend:      return "chart.line.uptrend.xyaxis"
        case .decisioneStorica:   return "scale.3d"
        }
    }
}
