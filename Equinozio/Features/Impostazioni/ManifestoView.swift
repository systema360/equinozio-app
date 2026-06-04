//
//  ManifestoView.swift
//  Equinozio · Features · Impostazioni
//
//  Storia e filosofia di Equinozio · accessibile dalle Impostazioni.
//

import SwiftUI

struct ManifestoView: View {

    @Environment(\.dismiss) private var chiudi

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: S.x7) {

                    hero
                    sezione(numero: "01", titolo: "Da dove nasce", paragrafi: [
                        "Equinozio nasce da un'osservazione semplice. Molte persone incontrano il diagramma a quattro cerchi della filosofia *ikigai* su un'infografica condivisa, lo trovano illuminante per dieci minuti, poi lo dimenticano.",
                        "Il problema non è il framework — è la mancanza di uno strumento operativo che lo accompagni nel tempo. Un quiz una-tantum non cambia una vita. Un compagno discreto, presente quando serve, può farlo.",
                    ])

                    sezione(numero: "02", titolo: "Le radici", paragrafi: [
                        "Quello che chiamiamo \"ikigai\" — il diagramma a quattro cerchi — non è il vero concetto giapponese. È una sintesi recente.",
                        "Nel **1966** la psichiatra giapponese **Mieko Kamiya** pubblica *Ikigai-ni-tsuite*: parla di piccoli motivi quotidiani, non di cerchi.",
                        "Nel **2011** lo spagnolo **Andrés Zuzunaga** pubblica il diagramma a quattro cerchi col nome \"Propósito\".",
                        "Nel **2014** il blogger britannico **Marc Winn** sovrappone il diagramma di Zuzunaga al concetto di ikigai. L'opera viene rilasciata in pubblico dominio.",
                        "Nel **2016** il libro *Ikigai. Il metodo giapponese* di **García & Miralles** porta tutto nel mainstream.",
                    ])

                    sezione(numero: "03", titolo: "Il metodo", paragrafi: [
                        "Quattro cerchi, quattro domande:",
                        "**Passione** — Cosa ami fare, anche quando sei stanco?",
                        "**Talento** — In cosa sei naturalmente bravo?",
                        "**Missione** — Di cosa c'è bisogno intorno a te?",
                        "**Professione** — Per cosa ti pagano oggi?",
                        "Quando le risposte si sovrappongono, trovi l'equilibrio.",
                    ])

                    sezione(numero: "04", titolo: "Perché Equinozio", paragrafi: [
                        "Equinozio è il momento dell'anno in cui giorno e notte si equivalgono — il punto in cui due forze opposte trovano la stessa misura. È la stessa cosa che accade quando i quattro cerchi si bilanciano nella tua vita.",
                        "L'anno ha quattro momenti cardine — due equinozi e due solstizi — che dividono il ciclo in quattro stagioni. Quattro momenti, quattro stagioni, quattro cerchi. La simmetria non è casuale.",
                    ])

                    sezione(numero: "05", titolo: "Sempre gratuita", paragrafi: [
                        "Equinozio è un dono al pubblico italiano da parte di **Systema360**. È il nostro modo di mostrare cosa sappiamo costruire — non a parole, ma in un prodotto vero.",
                        "Niente account, niente pubblicità, niente vendita di dati. I tuoi dati restano sul tuo dispositivo e nel tuo iCloud privato.",
                    ])

                    sezione(numero: "06", titolo: "Diritti e attribuzioni", paragrafi: [
                        "**Mieko Kamiya** · per il concetto originale (1966)",
                        "**Andrés Zuzunaga** · per il diagramma a quattro cerchi (2011)",
                        "**Marc Winn** · per la sintesi e il pubblico dominio (2014)",
                        "**García & Miralles** · per la diffusione internazionale (2016)",
                        "*Ikigai* è una parola della lingua giapponese, non un marchio. Il diagramma è in pubblico dominio. Le quattro categorie sono espressione di un'idea generale.",
                    ])

                    sezione(numero: "07", titolo: "Da chi", paragrafi: [
                        "**Systema360** è uno studio italiano di consulenza e progettazione di sistemi digitali, a Potenza. Equinozio è il nostro biglietto da visita.",
                        "Per scriverci o per collaborare: [systema360.it](https://systema360.it)",
                    ])

                    Text("Fatto con cura da Systema360 · 2026")
                        .font(.equinozio(.etichetta))
                        .tracking(2.0)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.attenuato)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, S.x6)
                }
                .padding(.horizontal, S.x5)
                .padding(.top, S.x4)
                .padding(.bottom, S.x6)
            }
            .background(Color.sfondo)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { chiudi() }
                        .tint(.salvia)
                }
                ToolbarItem(placement: .principal) {
                    Text("MANIFESTO")
                        .font(.equinozio(.etichetta))
                        .tracking(2.2)
                        .foregroundStyle(Color.salvia)
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: S.x3) {
            Text("Equinozio")
                .font(.system(size: 48, weight: .thin))
                .tracking(-1.5)
                .foregroundStyle(Color.inchiostro)

            Text("Il tuo equilibrio")
                .font(.system(size: 22, weight: .light))
                .tracking(-0.5)
                .foregroundStyle(Color.salvia)

            Text("Come l'equinozio bilancia giorno e notte, uno strumento sobrio per bilanciare i quattro cerchi della tua vita.")
                .font(.equinozio(.corpoGrande))
                .foregroundStyle(Color.inchiostroTenue)
                .padding(.top, S.x2)
        }
    }

    private func sezione(numero: String, titolo: String, paragrafi: [String]) -> some View {
        VStack(alignment: .leading, spacing: S.x3) {
            Text("\(numero) · \(titolo.uppercased())")
                .font(.equinozio(.etichetta))
                .tracking(2.2)
                .foregroundStyle(Color.salvia)

            Text(titolo)
                .font(.equinozio(.titoloPiccolo))
                .foregroundStyle(Color.inchiostro)

            ForEach(paragrafi, id: \.self) { p in
                Text(LocalizedStringKey(p))
                    .font(.equinozio(.corpo))
                    .foregroundStyle(Color.inchiostroTenue)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ManifestoView()
}
