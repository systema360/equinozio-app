//
//  DiarioView.swift
//  Equinozio · Features · Diario
//
//  Lista delle pagine del diario · filtro per quadrante · FAB · composer modale.
//

import SwiftUI
import SwiftData

struct DiarioView: View {

    @Environment(\.modelContext) private var contesto
    @Query(filter: #Predicate<Pagina> { !$0.isCancellata }, sort: \Pagina.dataCreazione, order: .reverse)
    private var pagine: [Pagina]

    @State private var filtro: TipoCerchio? = nil
    @State private var composerAperto = false
    @State private var paginaSelezionata: Pagina?
    @State private var ricerca = ""

    private var pagineFiltrate: [Pagina] {
        RicercaDiario.filtra(pagine, cerchio: filtro, ricerca: ricerca)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Diario")
                        .font(.equinozio(.occhiello))
                        .tracking(2.4)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.salvia)
                        .padding(.bottom, S.x2)

                    (Text("Le tue ") + Text("riflessioni").foregroundColor(.salvia))
                        .font(.equinozio(.titoloMedio))
                        .foregroundStyle(Color.inchiostro)
                        .padding(.bottom, S.x4)

                    if !pagine.isEmpty {
                        ShareLink(item: EsportaDiario.testo(da: pagine)) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 12, weight: .medium))
                                Text("ESPORTA")
                                    .font(.equinozio(.etichetta))
                                    .tracking(1.6)
                            }
                            .foregroundStyle(Color.salvia)
                        }
                        .padding(.bottom, S.x4)
                    }

                    campoRicerca
                        .padding(.bottom, S.x3)

                    filtroChips
                        .padding(.bottom, S.x4)

                    if pagineFiltrate.isEmpty {
                        statoVuoto
                    } else {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(pagineFiltrate) { pagina in
                                Button {
                                    paginaSelezionata = pagina
                                } label: {
                                    PaginaCella(pagina: pagina)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        cancella(pagina)
                                    } label: {
                                        Label("Cancella", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        cancella(pagina)
                                    } label: {
                                        Label("Cancella pagina", systemImage: "trash")
                                    }
                                }
                                Divider().background(Color.lineaSottile)
                            }
                        }
                    }
                }
                .padding(.horizontal, S.x5)
                .padding(.top, S.x7)
                .padding(.bottom, 100)
            }
            .background(Color.sfondo)

            FabAggiunta(accessibilityLabelTesto: "Aggiungi una pagina al diario") {
                composerAperto = true
            }
            .padding(.trailing, S.x5)
            .padding(.bottom, S.x5)
        }
        .sheet(isPresented: $composerAperto) {
            ComposerPagina()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $paginaSelezionata) { pagina in
            DettaglioPaginaView(pagina: pagina)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var filtroChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: S.x2) {
                FiltroChip(titolo: "Tutte", attivo: filtro == nil) {
                    filtro = nil
                }
                ForEach(TipoCerchio.allCases) { tipo in
                    FiltroChip(titolo: tipo.titolo, attivo: filtro == tipo, colore: tipo.colore) {
                        filtro = (filtro == tipo) ? nil : tipo
                    }
                }
            }
        }
    }

    private var campoRicerca: some View {
        HStack(spacing: S.x2) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color.attenuato)
            TextField("Cerca nel diario", text: $ricerca)
                .font(.equinozio(.corpoMedio))
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            if !ricerca.isEmpty {
                Button {
                    ricerca = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.attenuato)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancella ricerca")
            }
        }
        .padding(.horizontal, S.x3)
        .padding(.vertical, S.x2)
        .background(Color.superficie)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.lineaSottile, lineWidth: 1))
    }

    private func cancella(_ pagina: Pagina) {
        withAnimation {
            pagina.isCancellata = true
            try? contesto.save()
        }
    }

    private var statoVuoto: some View {
        VStack(alignment: .leading, spacing: S.x3) {
            Text("Niente ancora.")
                .font(.equinozio(.titoloPiccolo))
                .foregroundStyle(Color.inchiostroTenue)
            Text("Tocca il + in basso per scrivere la tua prima riflessione.")
                .font(.equinozio(.corpoMedio))
                .foregroundStyle(Color.attenuato)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, S.x6)
    }
}

// MARK: - Chip filtro

private struct FiltroChip: View {
    let titolo: String
    let attivo: Bool
    var colore: Color = .salvia
    let azione: () -> Void

    var body: some View {
        Button(action: azione) {
            Text(titolo.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(attivo ? Color.white : Color.inchiostroTenue)
                .padding(.horizontal, S.x3)
                .padding(.vertical, 6)
                .background(attivo ? colore : Color.superficie)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(attivo ? colore : Color.lineaSottile, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cella pagina

private struct PaginaCella: View {
    let pagina: Pagina

    var body: some View {
        VStack(alignment: .leading, spacing: S.x2) {
            Text(dataFormattata)
                .font(.equinozio(.etichetta))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Color.attenuato)

            Text(pagina.testo)
                .font(.equinozio(.corpo))
                .foregroundStyle(Color.inchiostro)

            if !pagina.etichette.isEmpty {
                HStack(spacing: S.x1) {
                    ForEach(Array(pagina.etichette).sorted(by: { $0.rawValue < $1.rawValue })) { tipo in
                        Text(tipo.titolo.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1.0)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(tipo.colore.opacity(0.18))
                            .foregroundStyle(tipo.colore)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, S.x4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dataFormattata: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "EEEE d MMM · HH:mm"
        return f.string(from: pagina.dataCreazione)
    }
}

// MARK: - Composer

private struct ComposerPagina: View {

    @Environment(\.modelContext) private var contesto
    @Environment(\.dismiss) private var chiudi

    @State private var testo: String = ""
    @State private var etichetteScelte: Set<TipoCerchio> = []
    @State private var suggerendo: Bool = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: S.x4) {
                TextEditor(text: $testo)
                    .font(.equinozio(.corpo))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .overlay(alignment: .topLeading) {
                        if testo.isEmpty {
                            Text("Cosa ti gira in testa adesso?")
                                .font(.equinozio(.corpo))
                                .foregroundStyle(Color.attenuato)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }

                VStack(alignment: .leading, spacing: S.x2) {
                    HStack {
                        Text("A quali cerchi appartiene?")
                            .font(.equinozio(.etichetta))
                            .tracking(1.8)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.attenuato)

                        Spacer()

                        Button {
                            Task { await suggerisciEtichette() }
                        } label: {
                            HStack(spacing: 4) {
                                if suggerendo {
                                    ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                Text("SUGGERISCI")
                                    .font(.equinozio(.etichetta))
                                    .tracking(1.2)
                            }
                            .foregroundStyle(Color.salvia)
                        }
                        .buttonStyle(.plain)
                        .disabled(suggerendo || testo.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(testo.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                    }

                    FlowLayout(spacing: S.x2) {
                        ForEach(TipoCerchio.allCases) { tipo in
                            TagPickerChip(tipo: tipo, attivo: etichetteScelte.contains(tipo)) {
                                if etichetteScelte.contains(tipo) {
                                    etichetteScelte.remove(tipo)
                                } else {
                                    etichetteScelte.insert(tipo)
                                }
                            }
                        }
                    }
                }

                AzionePrimaria("Salva la pagina") { salva() }
                    .opacity(testo.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                    .disabled(testo.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, S.x5)
            .padding(.top, S.x4)
            .background(Color.sfondo)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { chiudi() }
                        .tint(.attenuato)
                }
                ToolbarItem(placement: .principal) {
                    Text("NUOVA PAGINA")
                        .font(.equinozio(.etichetta))
                        .tracking(2.2)
                        .foregroundStyle(Color.salvia)
                }
            }
        }
    }

    private func suggerisciEtichette() async {
        suggerendo = true
        defer { suggerendo = false }
        let suggerite = await TagSuggestionService.shared.suggerisci(per: testo)
        etichetteScelte = Set(suggerite)
    }

    private func salva() {
        let testoPulito = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !testoPulito.isEmpty else { return }

        let pagina = Pagina(
            testo: testoPulito,
            etichette: etichetteScelte
        )
        contesto.insert(pagina)
        try? contesto.save()
        chiudi()
    }
}

private struct TagPickerChip: View {
    let tipo: TipoCerchio
    let attivo: Bool
    let azione: () -> Void

    var body: some View {
        Button(action: azione) {
            Text(tipo.titolo.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(attivo ? Color.white : tipo.colore)
                .padding(.horizontal, S.x3)
                .padding(.vertical, 6)
                .background(attivo ? tipo.colore : tipo.colore.opacity(0.15))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dettaglio pagina · vista a tutto schermo per leggere/modificare

private struct DettaglioPaginaView: View {

    @Environment(\.modelContext) private var contesto
    @Environment(\.dismiss) private var chiudi
    @Bindable var pagina: Pagina

    @State private var inModifica = false
    @State private var testoEditabile = ""
    @State private var etichetteEditabili: Set<TipoCerchio> = []
    @State private var mostraConfermaCancella = false
    @State private var suggerendo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: S.x5) {

                    // Header con data
                    Text(dataFormattata.uppercased())
                        .font(.equinozio(.etichetta))
                        .tracking(2.0)
                        .foregroundStyle(Color.attenuato)

                    // Testo (editor in modifica, plain in lettura)
                    if inModifica {
                        TextEditor(text: $testoEditabile)
                            .font(.equinozio(.corpoGrande))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                    } else {
                        Text(pagina.testo)
                            .font(.equinozio(.corpoGrande))
                            .foregroundStyle(Color.inchiostro)
                            .lineSpacing(4)
                    }

                    // Etichette
                    VStack(alignment: .leading, spacing: S.x2) {
                        HStack {
                            Text("CERCHI ASSOCIATI")
                                .font(.equinozio(.etichetta))
                                .tracking(1.8)
                                .foregroundStyle(Color.attenuato)

                            Spacer()

                            if inModifica {
                                Button {
                                    Task { await suggerisciEtichette() }
                                } label: {
                                    HStack(spacing: 4) {
                                        if suggerendo {
                                            ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
                                        } else {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 11, weight: .medium))
                                        }
                                        Text("SUGGERISCI")
                                            .font(.equinozio(.etichetta))
                                            .tracking(1.2)
                                    }
                                    .foregroundStyle(Color.salvia)
                                }
                                .buttonStyle(.plain)
                                .disabled(suggerendo || testoEditabile.trimmingCharacters(in: .whitespaces).isEmpty)
                                .opacity(testoEditabile.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                            }
                        }

                        FlowLayout(spacing: S.x2) {
                            ForEach(TipoCerchio.allCases) { tipo in
                                etichettaChip(tipo)
                            }
                        }
                    }
                }
                .padding(.horizontal, S.x5)
                .padding(.top, S.x4)
                .padding(.bottom, S.x6)
            }
            .background(Color.sfondo)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(inModifica ? "Annulla" : "Chiudi") {
                        if inModifica {
                            inModifica = false
                        } else {
                            chiudi()
                        }
                    }
                    .tint(.attenuato)
                }
                ToolbarItem(placement: .principal) {
                    Text("PAGINA DEL DIARIO")
                        .font(.equinozio(.etichetta))
                        .tracking(2.2)
                        .foregroundStyle(Color.salvia)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if inModifica {
                        Button("Salva", action: salva)
                            .tint(.salvia)
                            .fontWeight(.medium)
                    } else {
                        Menu {
                            Button {
                                avviaModifica()
                            } label: {
                                Label("Modifica", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                mostraConfermaCancella = true
                            } label: {
                                Label("Cancella", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.salvia)
                        }
                    }
                }
            }
            .confirmationDialog(
                "Vuoi davvero cancellare questa pagina?",
                isPresented: $mostraConfermaCancella,
                titleVisibility: .visible
            ) {
                Button("Cancella", role: .destructive, action: cancella)
                Button("Annulla", role: .cancel) {}
            }
        }
    }

    private func etichettaChip(_ tipo: TipoCerchio) -> some View {
        let attivo = inModifica
            ? etichetteEditabili.contains(tipo)
            : pagina.etichette.contains(tipo)

        return Button {
            guard inModifica else { return }
            if etichetteEditabili.contains(tipo) {
                etichetteEditabili.remove(tipo)
            } else {
                etichetteEditabili.insert(tipo)
            }
        } label: {
            Text(tipo.titolo.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(1.2)
                .padding(.horizontal, S.x3)
                .padding(.vertical, 6)
                .foregroundStyle(attivo ? Color.white : tipo.colore)
                .background(attivo ? tipo.colore : tipo.colore.opacity(0.15))
                .clipShape(Capsule())
                .opacity(inModifica || attivo ? 1.0 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!inModifica)
    }

    private var dataFormattata: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "EEEE d MMMM · HH:mm"
        return f.string(from: pagina.dataCreazione)
    }

    private func avviaModifica() {
        testoEditabile = pagina.testo
        etichetteEditabili = pagina.etichette
        inModifica = true
    }

    private func suggerisciEtichette() async {
        suggerendo = true
        defer { suggerendo = false }
        let suggerite = await TagSuggestionService.shared.suggerisci(per: testoEditabile)
        etichetteEditabili = Set(suggerite)
    }

    private func salva() {
        let pulito = testoEditabile.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pulito.isEmpty else { return }
        pagina.testo = pulito
        pagina.etichette = etichetteEditabili
        try? contesto.save()
        inModifica = false
    }

    private func cancella() {
        pagina.isCancellata = true
        try? contesto.save()
        chiudi()
    }
}

#Preview {
    DiarioView()
        .modelContainer(for: [
            Profilo.self, Cerchio.self, Elemento.self,
            Pagina.self, Riflessione.self, Decisione.self, Insight.self,
        ], inMemory: true)
}
