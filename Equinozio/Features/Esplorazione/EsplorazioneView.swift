//
//  EsplorazioneView.swift
//  Equinozio · Features · Esplorazione
//
//  Onboarding di scoperta · quattro tappe sequenziali, una per cerchio.
//  Modale al primo avvio · riapribile da Impostazioni per rifare la scoperta.
//

import SwiftUI
import SwiftData

struct EsplorazioneView: View {

    @Environment(\.modelContext) private var contesto
    @Environment(\.dismiss) private var chiudi
    @Query(sort: \Cerchio.tipoRaw) private var cerchi: [Cerchio]

    let modale: Bool
    let onCompletato: () -> Void

    @State private var tappa: Int = 0
    @State private var sceltePerCerchio: [TipoCerchio: Set<String>] = [:]
    @State private var aggiunte: [TipoCerchio: String] = [:]
    @State private var mostraIntro: Bool = true

    init(modale: Bool = false, onCompletato: @escaping () -> Void = {}) {
        self.modale = modale
        self.onCompletato = onCompletato
    }

    var body: some View {
        NavigationStack {
            Group {
                if mostraIntro {
                    introBenvenuto
                } else {
                    tappaCorrenteView
                }
            }
            .background(Color.sfondo)
            .toolbar {
                if modale {
                    ToolbarItem(placement: .principal) {
                        Text("ESPLORAZIONE")
                            .font(.equinozio(.etichetta))
                            .tracking(2.2)
                            .foregroundStyle(Color.salvia)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if haCompletatoAlmenoUnCerchio {
                            Button("Chiudi") { chiudi() }
                                .tint(.attenuato)
                        }
                    }
                }
            }
            .task(id: cerchi.count) {
                caricaScelteIniziali()
            }
        }
    }

    // MARK: - Schermata di benvenuto (prima tappa)

    private var introBenvenuto: some View {
        // Su schermi capienti il contenuto entra senza scroll; sui più piccoli
        // (o con testo molto ingrandito) ViewThatFits ricade sullo ScrollView
        // invece di forzare sempre lo scroll come faceva prima.
        ViewThatFits(in: .vertical) {
            introContenuto
            ScrollView { introContenuto }
        }
    }

    private var introContenuto: some View {
        VStack(alignment: .leading, spacing: S.x4) {

            QuattroCerchi(mostraEtichette: false, respira: false)
                .frame(height: 150)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: S.x3) {
                Text("L'ESPLORAZIONE · UNA VOLTA SOLA")
                    .font(.equinozio(.etichetta))
                    .tracking(2.2)
                    .foregroundStyle(Color.salvia)

                (Text("Stai per definire i ") +
                 Text("quattro cerchi").foregroundColor(.salvia) +
                 Text(" della tua vita."))
                    .font(.equinozio(.titoloMedio))
                    .foregroundStyle(Color.inchiostro)

                Text("Quindici minuti, quattro domande. Al termine avrai la tua mappa personale. Potrai sempre tornare a rivederla e cambiarla quando ti sentirai cambiato.")
                    .font(.equinozio(.corpoGrande))
                    .foregroundStyle(Color.inchiostroTenue)
                    .padding(.top, S.x2)
            }

            VStack(alignment: .leading, spacing: S.x3) {
                rigaSpiegazione(tipo: .passione, descr: "Le cose che ami fare, anche quando sei stanco.")
                rigaSpiegazione(tipo: .talento, descr: "In cui sei naturalmente bravo.")
                rigaSpiegazione(tipo: .missione, descr: "Di cui c'è bisogno intorno a te.")
                rigaSpiegazione(tipo: .professione, descr: "Per cui ti pagano oggi.")
            }
            .padding(.top, S.x2)

            AzionePrimaria("Cominciamo") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    mostraIntro = false
                }
            }
            .padding(.top, S.x3)
        }
        .padding(.horizontal, S.x5)
        .padding(.top, S.x4)
        .padding(.bottom, S.x5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rigaSpiegazione(tipo: TipoCerchio, descr: String) -> some View {
        HStack(alignment: .top, spacing: S.x3) {
            Circle()
                .fill(tipo.colore)
                .frame(width: 12, height: 12)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(tipo.titolo)
                    .font(.equinozio(.corpoGrande))
                    .foregroundStyle(Color.inchiostro)
                Text(descr)
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.attenuato)
            }
        }
    }

    // MARK: - Vista della tappa corrente

    private var tappaCorrenteView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                progresso
                    .padding(.bottom, S.x5)

                Text("Tappa \(String(format: "%02d", tappa + 1)) di 04")
                    .font(.equinozio(.occhiello))
                    .tracking(2.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.salvia)
                    .padding(.bottom, S.x3)

                domandaConEvidenza
                    .padding(.bottom, S.x3)

                Text(spiegazione)
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.inchiostroTenue)
                    .padding(.bottom, S.x5)
                    .frame(maxWidth: 320, alignment: .leading)

                FlowLayout(spacing: S.x2) {
                    ForEach(opzioniCorrenti, id: \.self) { opzione in
                        Scelta(opzione, attiva: bindingFor(opzione))
                    }
                    ForEach(scelteCustom, id: \.self) { opzione in
                        Scelta(opzione, attiva: bindingFor(opzione))
                            .contextMenu {
                                Button(role: .destructive) {
                                    rimuoviCustom(opzione)
                                } label: {
                                    Label("Rimuovi", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.bottom, S.x4)

                aggiungiCustomField

                stato
                    .padding(.top, S.x3)

                barraAzioni
                    .padding(.top, S.x6)
            }
            .padding(.horizontal, S.x5)
            .padding(.top, modale ? S.x4 : S.x7)
            .padding(.bottom, S.x6)
        }
    }

    // MARK: - Progresso

    private var progresso: some View {
        HStack(spacing: S.x1) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(coloreProgresso(i))
                    .frame(height: 3)
            }
        }
    }

    private func coloreProgresso(_ i: Int) -> Color {
        if i < tappa { return .salvia }
        if i == tappa { return .salvia.opacity(0.45) }
        return .lineaSottile
    }

    // MARK: - Titolo evidenziato

    private var domandaConEvidenza: some View {
        let parolaChiave = parolaChiavePerTipo(tipoCorrente)
        let domanda = tipoCorrente.titoloEsplorazione
        let parti = domanda.components(separatedBy: parolaChiave)

        return Group {
            if parti.count == 2 {
                (Text(parti[0])
                 + Text(parolaChiave).foregroundColor(.salvia)
                 + Text(parti[1]))
                    .font(.equinozio(.titoloMedio))
                    .foregroundStyle(Color.inchiostro)
            } else {
                Text(domanda)
                    .font(.equinozio(.titoloMedio))
                    .foregroundStyle(Color.inchiostro)
            }
        }
    }

    // MARK: - Campo aggiungi custom

    private var aggiungiCustomField: some View {
        HStack {
            TextField("aggiungi qualcosa di tuo…", text: bindingAggiunta)
                .font(.equinozio(.corpoMedio))
                .padding(.vertical, S.x3)
                .submitLabel(.done)
                .onSubmit { aggiungiCustom() }
                .textFieldStyle(.plain)

            if !(aggiunte[tipoCorrente] ?? "").trimmingCharacters(in: .whitespaces).isEmpty {
                Button("Aggiungi") { aggiungiCustom() }
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.salvia)
                    .buttonStyle(.plain)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.lineaSottile)
        }
    }

    // MARK: - Stato (contatore scelte)

    private var stato: some View {
        let n = sceltePerCerchio[tipoCorrente]?.count ?? 0
        let testo = n == 0
            ? "Scegline almeno una per continuare."
            : "\(n) scelt\(n == 1 ? "a" : "e")"

        return Text(testo)
            .font(.equinozio(.corpoMedio))
            .foregroundStyle(n == 0 ? Color.attenuato : tipoCorrente.colore)
    }

    // MARK: - Barra azioni

    private var barraAzioni: some View {
        HStack(spacing: S.x3) {
            if tappa > 0 {
                AzioneSecondaria("← Indietro") { indietro() }
            } else {
                AzioneSecondaria("Più tardi") { piuTardi() }
            }

            AzionePrimaria(tappa < 3 ? "Continua" : "Conferma e chiudi") {
                continua()
            }
            .opacity((sceltePerCerchio[tipoCorrente]?.isEmpty ?? true) ? 0.4 : 1)
            .disabled(sceltePerCerchio[tipoCorrente]?.isEmpty ?? true)
        }
    }

    // MARK: - Stato derivato

    private var tipoCorrente: TipoCerchio {
        TipoCerchio.allCases[min(tappa, 3)]
    }

    private var cerchioCorrente: Cerchio? {
        cerchi.first(where: { $0.tipo == tipoCorrente })
    }

    private var scelteCorrenti: Set<String> {
        sceltePerCerchio[tipoCorrente] ?? []
    }

    private var opzioniCorrenti: [String] {
        Self.suggerimenti[tipoCorrente] ?? []
    }

    private var scelteCustom: [String] {
        scelteCorrenti.subtracting(Set(opzioniCorrenti)).sorted()
    }

    private var haCompletatoAlmenoUnCerchio: Bool {
        cerchi.contains(where: { !($0.elementi?.isEmpty ?? true) })
    }

    private var spiegazione: String {
        switch tipoCorrente {
        case .passione:
            return "Scegli ciò che ti dà energia anche quando sei stanco. Non ciò che pensi di dover amare."
        case .talento:
            return "Le cose che ti riescono naturalmente, in cui gli altri ti chiedono aiuto."
        case .missione:
            return "Le cose di cui c’è bisogno: nella tua famiglia, comunità, mondo."
        case .professione:
            return "Le cose per cui ti pagano oggi. Un dato di realtà, non un giudizio."
        }
    }

    private func parolaChiavePerTipo(_ tipo: TipoCerchio) -> String {
        switch tipo {
        case .passione:    return "ami"
        case .talento:     return "bravo"
        case .missione:    return "bisogno"
        case .professione: return "pagano"
        }
    }

    // MARK: - Bindings

    private func bindingFor(_ opzione: String) -> Binding<Bool> {
        Binding(
            get: { scelteCorrenti.contains(opzione) },
            set: { nuova in
                var s = sceltePerCerchio[tipoCorrente] ?? []
                if nuova { s.insert(opzione) } else { s.remove(opzione) }
                sceltePerCerchio[tipoCorrente] = s
            }
        )
    }

    private var bindingAggiunta: Binding<String> {
        Binding(
            get: { aggiunte[tipoCorrente] ?? "" },
            set: { aggiunte[tipoCorrente] = $0 }
        )
    }

    // MARK: - Azioni

    private func rimuoviCustom(_ opzione: String) {
        var s = sceltePerCerchio[tipoCorrente] ?? []
        s.remove(opzione)
        sceltePerCerchio[tipoCorrente] = s
    }

    private func aggiungiCustom() {
        let testo = (aggiunte[tipoCorrente] ?? "").trimmingCharacters(in: .whitespaces)
        guard !testo.isEmpty else { return }

        var s = sceltePerCerchio[tipoCorrente] ?? []
        s.insert(testo)
        sceltePerCerchio[tipoCorrente] = s
        aggiunte[tipoCorrente] = ""
    }

    private func continua() {
        salvaTappaCorrente()
        if tappa < 3 {
            withAnimation(.easeInOut(duration: 0.25)) { tappa += 1 }
        } else {
            onCompletato()
        }
    }

    private func indietro() {
        guard tappa > 0 else { return }
        withAnimation(.easeInOut(duration: 0.25)) { tappa -= 1 }
    }

    private func piuTardi() {
        salvaTappaCorrente()
        onCompletato()
    }

    private func salvaTappaCorrente() {
        guard let cerchio = cerchioCorrente else { return }
        let scelte = sceltePerCerchio[tipoCorrente] ?? []

        if let elementi = cerchio.elementi {
            for e in elementi { contesto.delete(e) }
        }

        for testo in scelte {
            let elemento = Elemento(testo: testo, cerchio: cerchio)
            contesto.insert(elemento)
        }

        try? contesto.save()
    }

    private func caricaScelteIniziali() {
        guard sceltePerCerchio.isEmpty else { return }
        for cerchio in cerchi {
            sceltePerCerchio[cerchio.tipo] = Set((cerchio.elementi ?? []).map(\.testo))
        }
    }

    // MARK: - Pool di suggerimenti curati

    private static let suggerimenti: [TipoCerchio: [String]] = [
        .passione: [
            "Scrivere", "Cucinare", "Insegnare", "Programmare", "Suonare",
            "Camminare", "Leggere", "Disegnare", "Parlare in pubblico",
            "Costruire cose", "Affiancare i giovani", "Viaggiare",
            "Coltivare l'orto", "Conversazioni profonde", "Fotografare",
        ],
        .talento: [
            "Analizzare dati", "Scrivere bene", "Comunicare", "Risolvere problemi",
            "Disegnare", "Programmare", "Vendere", "Negoziare",
            "Ascoltare", "Organizzare", "Coordinare", "Insegnare",
        ],
        .missione: [
            "Ambiente", "Educazione", "Salute mentale", "Comunità locale",
            "Cultura", "Anziani", "Bambini", "Disabilità",
            "Sostenibilità", "Diritti", "Innovazione", "Tradizioni",
        ],
        .professione: [
            "Consulenza", "Sviluppo software", "Insegnamento", "Vendita",
            "Design", "Gestione progetti", "Marketing", "Ricerca",
            "Manutenzione", "Sanità", "Logistica", "Finanza",
        ],
    ]
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let larghezzaMax = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, altRiga: CGFloat = 0, larghezzaTot: CGFloat = 0
        for sub in subviews {
            let dim = sub.sizeThatFits(.unspecified)
            if x + dim.width > larghezzaMax && x > 0 {
                y += altRiga + spacing
                altRiga = 0
                x = 0
            }
            altRiga = max(altRiga, dim.height)
            x += dim.width + spacing
            larghezzaTot = max(larghezzaTot, x)
        }
        return CGSize(width: larghezzaTot, height: y + altRiga)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, altRiga: CGFloat = 0
        for sub in subviews {
            let dim = sub.sizeThatFits(.unspecified)
            if x + dim.width > bounds.maxX && x > bounds.minX {
                y += altRiga + spacing
                altRiga = 0
                x = bounds.minX
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(dim))
            altRiga = max(altRiga, dim.height)
            x += dim.width + spacing
        }
    }
}

#Preview {
    EsplorazioneView(modale: true, onCompletato: {})
        .modelContainer(for: [
            Profilo.self, Cerchio.self, Elemento.self,
            Pagina.self, Riflessione.self, Decisione.self, Insight.self,
        ], inMemory: true)
}
