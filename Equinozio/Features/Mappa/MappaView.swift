//
//  MappaView.swift
//  Equinozio · Features · Mappa
//
//  Dashboard principale · saluto, equilibrio, diagramma, sintesi attività.
//

import SwiftUI
import SwiftData

struct MappaView: View {

    @Query private var profili: [Profilo]
    @Query(sort: \Cerchio.tipoRaw) private var cerchi: [Cerchio]
    @Query private var elementi: [Elemento]
    @Query(sort: \Riflessione.data, order: .reverse) private var riflessioni: [Riflessione]
    @Query(filter: #Predicate<Pagina> { !$0.isCancellata },
           sort: \Pagina.dataCreazione, order: .reverse) private var pagine: [Pagina]
    @Query(sort: \Decisione.dataAggiunta, order: .reverse) private var decisioni: [Decisione]
    // Pochi Insight (potati a 8 in SpuntoStore): filtro la settimana corrente in Swift.
    @Query(sort: \Insight.dataGenerazione, order: .reverse) private var insightCache: [Insight]

    @Environment(AppRouter.self) private var router
    @State private var impostazioniAperte = false

    private var nome: String { profili.first?.nome ?? "" }
    private var elementiTotali: Int { elementi.count }
    private var equilibrio: Int { riflessioni.first?.equilibrio ?? 50 }
    private var deltaEquilibrio: Int {
        guard riflessioni.count >= 2 else { return 0 }
        return riflessioni[0].equilibrio - riflessioni[1].equilibrio
    }
    private var decisioniAperte: [Decisione] {
        decisioni.filter { $0.decisione?.isEmpty != false }.prefix(2).map { $0 }
    }
    private var insight: [InsightGenerato] {
        let regole = GeneratoreInsight.genera(riflessioni: riflessioni, decisioni: decisioni, adesso: .now)
        let sid = Settimana.id(per: .now)
        let cache = insightCache.first { $0.settimanaID == sid }
        let principale = cache.map { InsightGenerato(tipo: $0.tipo, testo: $0.testo) }
        return MotoreSpunti.spuntiMappa(principale: principale, regole: regole)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: S.x5) {
                intestazione
                bloccoEquilibrio
                BloccoInsight(insight: insight) { tipo in router.scheda = Scheda.perInsight(tipo) }
                bloccoDiagramma
                bloccoAttività
            }
            .padding(.horizontal, S.x5)
            .padding(.top, S.x6)
            .padding(.bottom, S.x6)
        }
        .background(Color.sfondo)
        .sheet(isPresented: $impostazioniAperte) {
            ImpostazioniView()
        }
    }

    // MARK: - Intestazione

    private var intestazione: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text(dataFormattata)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.salvia)
                    .padding(.bottom, S.x2)

                (Text("Buongiorno") +
                 (nome.isEmpty ? Text("") : Text(", ") + Text(nome).foregroundColor(.salvia)))
                    .font(.equinozio(.titoloPiccolo))
                    .foregroundStyle(Color.inchiostro)
            }

            Spacer()

            BottoneImpostazioni { impostazioniAperte = true }
        }
    }

    // MARK: - Equilibrio

    @ViewBuilder
    private var bloccoEquilibrio: some View {
        if riflessioni.isEmpty {
            VStack(alignment: .leading, spacing: S.x2) {
                Text("EQUILIBRIO SETTIMANALE")
                    .font(.equinozio(.etichetta))
                    .tracking(2.2)
                    .foregroundStyle(Color.attenuato)
                Text("Non hai ancora riflettuto")
                    .font(.equinozio(.titoloPiccolo))
                    .foregroundStyle(Color.inchiostroTenue)
                Text("Vai a **Riflessione** domenica sera per cominciare a misurarti.")
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.attenuato)
            }
            .padding(S.x5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.superficie)
            .clipShape(RoundedRectangle(cornerRadius: R.r2))
            .overlay(
                RoundedRectangle(cornerRadius: R.r2)
                    .stroke(Color.lineaSottile, lineWidth: 1)
            )
        } else {
            HStack(alignment: .firstTextBaseline, spacing: S.x4) {
                Text("\(equilibrio)")
                    .font(.system(size: 88, weight: .thin))
                    .monospacedDigit()
                    .tracking(-3)
                    .foregroundStyle(Color.salvia)
                    .frame(height: 88, alignment: .bottom)

                VStack(alignment: .leading, spacing: 4) {
                    Text("PERCENTO")
                        .font(.equinozio(.etichetta))
                        .tracking(2.0)
                        .foregroundStyle(Color.attenuato)
                    Text("Equilibrio")
                        .font(.equinozio(.corpoGrande))
                        .foregroundStyle(Color.inchiostro)
                    if deltaEquilibrio != 0 {
                        Text("\(deltaEquilibrio > 0 ? "↑ +" : "↓ ")\(abs(deltaEquilibrio)) settimana scorsa")
                            .font(.equinozio(.corpoMedio))
                            .foregroundStyle(deltaEquilibrio > 0 ? Color.salvia : Color.attenuato)
                    } else {
                        Text("Settimana corrente")
                            .font(.equinozio(.corpoMedio))
                            .foregroundStyle(Color.attenuato)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Diagramma

    private var bloccoDiagramma: some View {
        VStack(spacing: S.x4) {
            // L'emblema · fisso, identico al logo
            QuattroCerchi()
                .frame(height: 240)
                .padding(.vertical, S.x2)
                .frame(maxWidth: .infinity)

            // I quattro contatori · qui vive lo stato
            QuattroCerchiContatori(cerchi: cerchi)
        }
    }

    // MARK: - Attività recenti

    private var bloccoAttività: some View {
        VStack(alignment: .leading, spacing: S.x3) {
            Text("ATTIVITÀ RECENTE")
                .font(.equinozio(.etichetta))
                .tracking(2.2)
                .foregroundStyle(Color.attenuato)

            VStack(spacing: S.x2) {
                Button { router.scheda = .diario } label: {
                    rigaAttività(
                        titolo: "Diario",
                        valore: "\(pagine.count) \(pagine.count == 1 ? "pagina" : "pagine")",
                        sottoTitolo: pagine.first?.testo.prefix(60).description,
                        icona: "book.closed"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Apri il Diario")

                Button { router.scheda = .riflessione } label: {
                    rigaAttività(
                        titolo: "Riflessioni",
                        valore: "\(riflessioni.count) settiman\(riflessioni.count == 1 ? "a" : "e")",
                        sottoTitolo: riflessioni.first.map { ultimaRiflessioneFormattata($0) },
                        icona: "moon.stars"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Apri la Riflessione")

                Button { router.scheda = .decisione } label: {
                    rigaAttività(
                        titolo: "Decisioni aperte",
                        valore: "\(decisioniAperte.count) in sospeso",
                        sottoTitolo: decisioniAperte.first?.titolo,
                        icona: "scale.3d"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Apri le Decisioni")
            }
        }
    }

    private func rigaAttività(titolo: String, valore: String, sottoTitolo: String?, icona: String) -> some View {
        HStack(alignment: .top, spacing: S.x3) {
            Image(systemName: icona)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Color.salvia)
                .frame(width: 24, height: 24, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(titolo)
                        .font(.equinozio(.corpoMedio))
                        .foregroundStyle(Color.inchiostro)
                    Spacer()
                    Text(valore)
                        .font(.equinozio(.corpoMedio))
                        .foregroundStyle(Color.attenuato)
                }

                if let s = sottoTitolo, !s.isEmpty {
                    Text(s)
                        .font(.equinozio(.corpoMedio))
                        .foregroundStyle(Color.attenuato)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
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

    // MARK: - Helper

    private func ultimaRiflessioneFormattata(_ r: Riflessione) -> String {
        "Ultima · \(Formattazione.giornoMeseBreve.string(from: r.data))"
    }

    private var dataFormattata: String {
        Formattazione.giornoMese.string(from: .now)
    }
}

#Preview {
    MappaView()
        .environment(AppRouter())
        .modelContainer(for: [
            Profilo.self, Cerchio.self, Elemento.self,
            Pagina.self, Riflessione.self, Decisione.self, Insight.self,
        ], inMemory: true)
}
