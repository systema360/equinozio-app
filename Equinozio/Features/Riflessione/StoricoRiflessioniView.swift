//
//  StoricoRiflessioniView.swift
//  Equinozio · Features · Riflessione
//
//  Storico delle riflessioni settimanali con grafico trend equilibrio.
//

import SwiftUI
import SwiftData
import Charts

struct StoricoRiflessioniView: View {

    @Environment(\.dismiss) private var chiudi
    @Query(sort: \Riflessione.data, order: .reverse) private var riflessioni: [Riflessione]
    @AppStorage("storicoIntroLetta") private var introLetta: Bool = false

    private var equilibrioMedio: Int {
        guard !riflessioni.isEmpty else { return 0 }
        return riflessioni.map(\.equilibrio).reduce(0, +) / riflessioni.count
    }

    private var equilibrioMassimo: Int {
        riflessioni.map(\.equilibrio).max() ?? 0
    }

    private var equilibrioMinimo: Int {
        riflessioni.map(\.equilibrio).min() ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: S.x5) {

                    if !introLetta && !riflessioni.isEmpty {
                        bannerIntro
                    }
                    sintesi
                    grafico
                    lista
                }
                .padding(.horizontal, S.x5)
                .padding(.top, S.x4)
                .padding(.bottom, S.x6)
            }
            .background(Color.sfondo)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Chiudi") { chiudi() }
                        .tint(.attenuato)
                }
                ToolbarItem(placement: .principal) {
                    Text("STORICO RIFLESSIONI")
                        .font(.equinozio(.etichetta))
                        .tracking(2.2)
                        .foregroundStyle(Color.salvia)
                }
            }
        }
    }

    // MARK: - Banner introduttivo

    private var bannerIntro: some View {
        VStack(alignment: .leading, spacing: S.x2) {
            HStack(spacing: S.x2) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color.salvia)
                Text("LO STORICO · COSA TROVI QUI")
                    .font(.equinozio(.etichetta))
                    .tracking(2.0)
                    .foregroundStyle(Color.salvia)
            }

            Text("Ogni riflessione che salvi entra qui. Nel tempo il grafico ti mostra il **pattern reale** della tua vita.")
                .font(.equinozio(.corpoMedio))
                .foregroundStyle(Color.inchiostro)

            Text("Hai dichiarato cosa ami, cosa sei bravo, cosa serve, per cosa ti pagano. La riflessione settimanale misura **dove va davvero il tuo tempo**. Lo storico misura la **distanza** tra le due cose.")
                .font(.equinozio(.corpoMedio))
                .foregroundStyle(Color.inchiostroTenue)

            Text("Più la linea sta vicino al 100% di equilibrio, più la tua vita riflette i quattro cerchi che hai dichiarato di volere. Se vedi una serie di valori bassi su una dimensione, è un campanello — qualcosa che ami o che ti dà valore sta scomparendo dal calendario.")
                .font(.equinozio(.corpoMedio))
                .foregroundStyle(Color.inchiostroTenue)

            Button {
                withAnimation { introLetta = true }
            } label: {
                HStack(spacing: 6) {
                    Text("HO CAPITO")
                        .font(.equinozio(.etichetta))
                        .tracking(2.0)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color.salvia)
            }
            .buttonStyle(.plain)
            .padding(.top, S.x1)
        }
        .padding(S.x4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.salviaTenue)
        .clipShape(RoundedRectangle(cornerRadius: R.r2))
    }

    // MARK: - Sintesi

    private var sintesi: some View {
        HStack(spacing: S.x4) {
            statCella(valore: "\(riflessioni.count)", etichetta: "Settimane", colore: .salvia)
            statCella(valore: "\(equilibrioMedio)%", etichetta: "Media", colore: .salvia)
            statCella(valore: "\(equilibrioMassimo)%", etichetta: "Massimo", colore: .missione)
            statCella(valore: "\(equilibrioMinimo)%", etichetta: "Minimo", colore: .passione)
        }
    }

    private func statCella(valore: String, etichetta: String, colore: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(valore)
                .font(.system(size: 28, weight: .thin))
                .monospacedDigit()
                .foregroundStyle(colore)
                .tracking(-1)
            Text(etichetta.uppercased())
                .font(.equinozio(.etichetta))
                .tracking(1.4)
                .foregroundStyle(Color.attenuato)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Grafico

    @ViewBuilder
    private var grafico: some View {
        if riflessioni.count >= 2 {
            VStack(alignment: .leading, spacing: S.x3) {
                Text("EQUILIBRIO NEL TEMPO")
                    .font(.equinozio(.etichetta))
                    .tracking(2.0)
                    .foregroundStyle(Color.attenuato)

                Chart(riflessioni.reversed()) { riflessione in
                    AreaMark(
                        x: .value("Data", riflessione.data),
                        y: .value("Equilibrio", riflessione.equilibrio)
                    )
                    .foregroundStyle(Color.salvia.opacity(0.18))
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Data", riflessione.data),
                        y: .value("Equilibrio", riflessione.equilibrio)
                    )
                    .foregroundStyle(Color.salvia)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Data", riflessione.data),
                        y: .value("Equilibrio", riflessione.equilibrio)
                    )
                    .foregroundStyle(Color.salvia)
                    .symbolSize(20)
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) {
                        AxisGridLine()
                            .foregroundStyle(Color.lineaSottile)
                        AxisValueLabel()
                            .font(.equinozio(.etichetta))
                            .foregroundStyle(Color.attenuato)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(Color.lineaSottile)
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated).locale(.init(identifier: "it_IT")))
                            .font(.equinozio(.etichetta))
                            .foregroundStyle(Color.attenuato)
                    }
                }
                .padding(S.x4)
                .background(Color.superficie)
                .clipShape(RoundedRectangle(cornerRadius: R.r2))
                .overlay(
                    RoundedRectangle(cornerRadius: R.r2)
                        .stroke(Color.lineaSottile, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Lista

    @ViewBuilder
    private var lista: some View {
        VStack(alignment: .leading, spacing: S.x3) {
            Text("TUTTE LE RIFLESSIONI")
                .font(.equinozio(.etichetta))
                .tracking(2.0)
                .foregroundStyle(Color.attenuato)

            if riflessioni.isEmpty {
                Text("Niente ancora.")
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.attenuato)
                    .padding(.vertical, S.x4)
            } else {
                LazyVStack(spacing: S.x2) {
                    ForEach(riflessioni) { r in
                        rigaRiflessione(r)
                    }
                }
            }
        }
    }

    private func rigaRiflessione(_ r: Riflessione) -> some View {
        VStack(alignment: .leading, spacing: S.x2) {
            HStack(alignment: .firstTextBaseline) {
                Text(dataFormattata(r.data).uppercased())
                    .font(.equinozio(.etichetta))
                    .tracking(1.6)
                    .foregroundStyle(Color.attenuato)
                Spacer()
                Text("\(r.equilibrio)%")
                    .font(.system(size: 22, weight: .thin))
                    .monospacedDigit()
                    .foregroundStyle(Color.salvia)
                    .tracking(-0.5)
            }

            HStack(spacing: 6) {
                quotaPill(.passione, r.quotaPassione)
                quotaPill(.talento, r.quotaTalento)
                quotaPill(.missione, r.quotaMissione)
                quotaPill(.professione, r.quotaProfessione)
            }

            if !r.pensiero.isEmpty {
                Text(r.pensiero)
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.inchiostroTenue)
                    .padding(.top, S.x1)
            }
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

    private func quotaPill(_ tipo: TipoCerchio, _ quota: Int) -> some View {
        HStack(spacing: 4) {
            Circle().fill(tipo.colore).frame(width: 6, height: 6)
            Text("\(quota)%")
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Color.inchiostroTenue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(tipo.colore.opacity(0.12))
        .clipShape(Capsule())
    }

    private func dataFormattata(_ data: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "EEEE d MMMM"
        return f.string(from: data)
    }
}

#Preview {
    StoricoRiflessioniView()
        .modelContainer(for: [
            Profilo.self, Cerchio.self, Elemento.self,
            Pagina.self, Riflessione.self, Decisione.self, Insight.self,
        ], inMemory: true)
}
