//
//  DecisioneView.swift
//  Equinozio · Features · Decisione
//
//  Lista decisioni + composer modale con sliders e radar live.
//

import SwiftUI
import SwiftData

struct DecisioneView: View {

    enum Modalità: String, CaseIterable {
        case aperte, archivio
        var titolo: String { self == .aperte ? "Aperte" : "Archivio" }
    }

    @Environment(\.modelContext) private var contesto
    @Query(sort: \Decisione.dataAggiunta, order: .reverse) private var decisioni: [Decisione]

    @State private var composerAperto = false
    @State private var decisioneSelezionata: Decisione?
    @State private var modalità: Modalità = .aperte

    private var decisioniAperte: [Decisione] {
        decisioni.filter { ($0.decisione ?? "").isEmpty }
    }

    private var decisioniChiuse: [Decisione] {
        decisioni.filter { !($0.decisione ?? "").isEmpty }
    }

    private var elencoCorrente: [Decisione] {
        modalità == .aperte ? decisioniAperte : decisioniChiuse
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    intestazione
                    selettoreModalita.padding(.top, S.x4)
                }
                .padding(.horizontal, S.x5)
                .padding(.top, S.x7)
                .padding(.bottom, S.x3)

                if elencoCorrente.isEmpty {
                    ScrollView { statoVuoto.padding(.horizontal, S.x5) }
                } else {
                    List {
                        ForEach(elencoCorrente) { d in
                            DecisioneCella(decisione: d)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: S.x2, leading: S.x5, bottom: S.x2, trailing: S.x5))
                                .listRowBackground(Color.sfondo)
                                .contentShape(Rectangle())
                                .onTapGesture { decisioneSelezionata = d }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { cancella(d) } label: {
                                        Label("Cancella", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    if modalità == .archivio {
                                        Button { riapri(d) } label: {
                                            Label("Riapri", systemImage: "arrow.uturn.backward")
                                        }
                                        .tint(.salvia)
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: S.x8)
                    }
                }
            }
            .background(Color.sfondo)

            if modalità == .aperte {
                FabAggiunta(accessibilityLabelTesto: "Aggiungi una decisione") {
                    composerAperto = true
                }
                .padding(.trailing, S.x5)
                .padding(.bottom, S.x5)
            }
        }
        .sheet(isPresented: $composerAperto) {
            ComposerDecisione()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $decisioneSelezionata) { d in
            DettaglioDecisione(decisione: d)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func cancella(_ d: Decisione) {
        withAnimation { contesto.delete(d); try? contesto.save() }
    }

    private func riapri(_ d: Decisione) {
        withAnimation { d.decisione = nil; try? contesto.save() }
    }

    private var intestazione: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Decisione")
                .font(.equinozio(.occhiello))
                .tracking(2.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.salvia)
                .padding(.bottom, S.x2)

            (Text(modalità == .aperte ? "Le tue " : "Le tue ") +
             Text(modalità == .aperte ? "scelte aperte" : "scelte fatte").foregroundColor(.salvia))
                .font(.equinozio(.titoloMedio))
                .foregroundStyle(Color.inchiostro)
        }
    }

    private var selettoreModalita: some View {
        HStack(spacing: S.x2) {
            ForEach(Modalità.allCases, id: \.self) { m in
                let conteggio = m == .aperte ? decisioniAperte.count : decisioniChiuse.count
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { modalità = m }
                } label: {
                    HStack(spacing: 6) {
                        Text(m.titolo.uppercased())
                            .font(.equinozio(.etichetta))
                            .tracking(1.6)
                        Text("\(conteggio)")
                            .font(.system(size: 11, weight: .semibold))
                            .monospacedDigit()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(modalità == m ? Color.white.opacity(0.25) : Color.lineaSottile)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, S.x3)
                    .padding(.vertical, 7)
                    .foregroundStyle(modalità == m ? Color.white : Color.inchiostroTenue)
                    .background(modalità == m ? Color.salvia : Color.superficie)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(modalità == m ? Color.salvia : Color.lineaSottile, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var statoVuoto: some View {
        VStack(alignment: .leading, spacing: S.x3) {
            Text(modalità == .aperte ? "Niente in sospeso." : "Nessuna decisione presa.")
                .font(.equinozio(.titoloPiccolo))
                .foregroundStyle(Color.inchiostroTenue)
            Text(modalità == .aperte
                 ? "Quando arriva un'opportunità da valutare — un lavoro, un progetto, una scelta — tocca il + per aggiungerla."
                 : "Quando decidi su un'opportunità aperta, finisce qui · pronta per rileggerla in futuro."
            )
                .font(.equinozio(.corpoMedio))
                .foregroundStyle(Color.attenuato)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, S.x6)
    }
}

// MARK: - Cella decisione (lista)

private struct DecisioneCella: View {
    let decisione: Decisione

    private var isDecisa: Bool {
        !(decisione.decisione ?? "").isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: S.x2) {
            HStack(alignment: .firstTextBaseline) {
                Text(decisione.titolo)
                    .font(.equinozio(.corpoGrande))
                    .foregroundStyle(Color.inchiostro)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isDecisa {
                    Text("DECISA")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.salvia)
                        .clipShape(Capsule())
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: S.x3) {
                Text(decisione.punteggioFormattato)
                    .font(.system(size: 32, weight: .thin))
                    .monospacedDigit()
                    .foregroundStyle(isDecisa ? Color.attenuato : Color.salvia)
                    .tracking(-1.0)

                Text("/ 5")
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.attenuato)

                Spacer()

                if isDecisa {
                    Text("ARCHIVIATA")
                        .font(.equinozio(.etichetta))
                        .tracking(1.2)
                        .foregroundStyle(Color.attenuato)
                } else if let scadenza = decisione.scadenza {
                    Text("ENTRO \(scadenza.formatted(date: .abbreviated, time: .omitted).uppercased())")
                        .font(.equinozio(.etichetta))
                        .tracking(1.2)
                        .foregroundStyle(Color.attenuato)
                }
            }

            HStack(spacing: S.x3) {
                pallino("Pass", decisione.punteggioPassione, .passione)
                pallino("Tal", decisione.punteggioTalento, .talento)
                pallino("Mis", decisione.punteggioMissione, .missione)
                pallino("Prof", decisione.punteggioProfessione, .professione)
            }

            if isDecisa, let scelta = decisione.decisione {
                Text(scelta)
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.inchiostroTenue)
                    .padding(.top, S.x1)
                    .lineLimit(2)
            }
        }
        .padding(S.x4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.superficie)
        .clipShape(RoundedRectangle(cornerRadius: R.r2))
        .overlay(
            RoundedRectangle(cornerRadius: R.r2)
                .stroke(isDecisa ? Color.salvia.opacity(0.4) : Color.lineaSottile, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .opacity(isDecisa ? 0.92 : 1.0)
    }

    private func pallino(_ label: String, _ valore: Int, _ colore: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(colore).frame(width: 6, height: 6)
            Text(label.uppercased())
                .font(.equinozio(.etichetta))
                .tracking(1.0)
                .foregroundStyle(Color.attenuato)
            Text("\(valore)")
                .font(.system(size: 13, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Color.inchiostro)
        }
    }
}

// MARK: - Composer

private struct ComposerDecisione: View {
    @Environment(\.modelContext) private var contesto
    @Environment(\.dismiss) private var chiudi

    @State private var titolo: String = ""
    @State private var scadenzaAttiva: Bool = false
    @State private var scadenza: Date = .now.addingTimeInterval(60 * 60 * 24 * 7)
    @State private var passione: Int = 3
    @State private var talento: Int = 3
    @State private var missione: Int = 3
    @State private var professione: Int = 3
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: S.x4) {
                    campoTitolo
                    campoScadenza
                    radarLive
                    sliders
                    campoNote
                    AzionePrimaria("Salva la decisione", azione: salva)
                        .opacity(titolo.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                        .disabled(titolo.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, S.x5)
                .padding(.top, S.x4)
                .padding(.bottom, S.x6)
            }
            .background(Color.sfondo)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { chiudi() }
                        .tint(.attenuato)
                }
                ToolbarItem(placement: .principal) {
                    Text("NUOVA DECISIONE")
                        .font(.equinozio(.etichetta))
                        .tracking(2.2)
                        .foregroundStyle(Color.salvia)
                }
            }
        }
    }

    private var campoTitolo: some View {
        VStack(alignment: .leading, spacing: S.x1) {
            Text("Cosa devi decidere?")
                .font(.equinozio(.etichetta))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundStyle(Color.attenuato)

            TextField("Es. Offerta da Direttore di prodotto", text: $titolo)
                .font(.equinozio(.corpoGrande))
                .padding(.vertical, S.x2)
                .textFieldStyle(.plain)
                .overlay(alignment: .bottom) {
                    Rectangle().frame(height: 1).foregroundStyle(Color.lineaSottile)
                }
        }
    }

    private var campoScadenza: some View {
        VStack(alignment: .leading, spacing: S.x2) {
            Toggle(isOn: $scadenzaAttiva) {
                Text("Entro una data")
                    .font(.equinozio(.corpoMedio))
            }
            .tint(.salvia)

            if scadenzaAttiva {
                DatePicker("", selection: $scadenza, in: Date.now..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "it_IT"))
            }
        }
    }

    private var radarLive: some View {
        VStack(alignment: .center, spacing: S.x2) {
            RadarDecisione(
                passione: passione,
                talento: talento,
                missione: missione,
                professione: professione
            )
            .frame(height: 220)
            .padding(.horizontal, S.x6)

            HStack {
                Text("PUNTEGGIO MEDIO")
                    .font(.equinozio(.etichetta))
                    .tracking(2.0)
                    .foregroundStyle(Color.attenuato)
                Text(punteggioFormattato)
                    .font(.system(size: 22, weight: .thin))
                    .monospacedDigit()
                    .foregroundStyle(Color.salvia)
                Text("/ 5")
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.attenuato)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, S.x3)
        .background(Color.superficie)
        .clipShape(RoundedRectangle(cornerRadius: R.r2))
        .overlay(
            RoundedRectangle(cornerRadius: R.r2)
                .stroke(Color.lineaSottile, lineWidth: 1)
        )
    }

    private var sliders: some View {
        VStack(spacing: S.x3) {
            sliderCerchio(.passione, $passione)
            sliderCerchio(.talento, $talento)
            sliderCerchio(.missione, $missione)
            sliderCerchio(.professione, $professione)
        }
    }

    private func sliderCerchio(_ tipo: TipoCerchio, _ valore: Binding<Int>) -> some View {
        VStack(spacing: S.x2) {
            HStack {
                HStack(spacing: S.x2) {
                    Circle().fill(tipo.colore).frame(width: 8, height: 8)
                    Text(tipo.titolo)
                        .font(.equinozio(.corpoMedio))
                }
                Spacer()
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { v in
                        Button {
                            valore.wrappedValue = v
                        } label: {
                            Text("\(v)")
                                .font(.system(size: 13, weight: .medium))
                                .monospacedDigit()
                                .frame(width: 32, height: 32)
                                .background(valore.wrappedValue == v ? tipo.colore : Color.superficie)
                                .foregroundStyle(valore.wrappedValue == v ? Color.white : Color.inchiostroTenue)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(
                                        valore.wrappedValue == v ? tipo.colore : Color.lineaSottile,
                                        lineWidth: 1
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var campoNote: some View {
        VStack(alignment: .leading, spacing: S.x1) {
            Text("Note (opzionale)")
                .font(.equinozio(.etichetta))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundStyle(Color.attenuato)

            TextEditor(text: $note)
                .font(.equinozio(.corpoMedio))
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .padding(S.x2)
                .background(Color.superficie)
                .clipShape(RoundedRectangle(cornerRadius: R.r2))
                .overlay(
                    RoundedRectangle(cornerRadius: R.r2)
                        .stroke(Color.lineaSottile, lineWidth: 1)
                )
                .accessibilityLabel("Note della decisione")
        }
    }

    private var punteggioFormattato: String {
        let media = Double(passione + talento + missione + professione) / 4.0
        return String(format: "%.2f", media).replacingOccurrences(of: ".", with: ",")
    }

    private func salva() {
        let testoPulito = titolo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !testoPulito.isEmpty else { return }

        let decisione = Decisione(
            titolo: testoPulito,
            scadenza: scadenzaAttiva ? scadenza : nil,
            punteggi: (p: passione, t: talento, m: missione, s: professione),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        contesto.insert(decisione)
        try? contesto.save()
        chiudi()
    }
}

// MARK: - Dettaglio decisione

private struct DettaglioDecisione: View {
    @Environment(\.modelContext) private var contesto
    @Environment(\.dismiss) private var chiudi
    @Bindable var decisione: Decisione

    @State private var sceltaInModifica: String = ""
    @State private var inModificaScelta: Bool = false

    private var isDecisa: Bool {
        !(decisione.decisione ?? "").isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: S.x4) {

                    if isDecisa {
                        bloccoArchiviata
                    }

                    Text(decisione.titolo)
                        .font(.equinozio(.titoloMedio))
                        .foregroundStyle(Color.inchiostro)

                    RadarDecisione(
                        passione: decisione.punteggioPassione,
                        talento: decisione.punteggioTalento,
                        missione: decisione.punteggioMissione,
                        professione: decisione.punteggioProfessione
                    )
                    .frame(height: 260)

                    HStack(alignment: .firstTextBaseline, spacing: S.x3) {
                        Text(decisione.punteggioFormattato)
                            .font(.equinozio(.cifraGrande))
                            .foregroundStyle(Color.salvia)
                            .monospacedDigit()
                            .tracking(-1.5)

                        Text("/ 5")
                            .font(.equinozio(.corpoGrande))
                            .foregroundStyle(Color.attenuato)
                    }

                    // Sezione decisione finale
                    bloccoDecisioneFinale

                    if !decisione.note.isEmpty {
                        VStack(alignment: .leading, spacing: S.x1) {
                            Text("NOTE")
                                .font(.equinozio(.etichetta))
                                .tracking(2.0)
                                .foregroundStyle(Color.attenuato)
                            Text(decisione.note)
                                .font(.equinozio(.corpo))
                                .foregroundStyle(Color.inchiostro)
                        }
                    }

                    if let scadenza = decisione.scadenza {
                        VStack(alignment: .leading, spacing: S.x1) {
                            Text("SCADENZA")
                                .font(.equinozio(.etichetta))
                                .tracking(2.0)
                                .foregroundStyle(Color.attenuato)
                            Text(scadenza, format: .dateTime.day().month(.wide).year().locale(Locale(identifier: "it_IT")))
                                .font(.equinozio(.corpo))
                                .foregroundStyle(Color.inchiostro)
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
                    Button("Chiudi") { chiudi() }
                        .tint(.attenuato)
                }
                ToolbarItem(placement: .principal) {
                    Text(isDecisa ? "DECISIONE ARCHIVIATA" : "DECISIONE APERTA")
                        .font(.equinozio(.etichetta))
                        .tracking(2.2)
                        .foregroundStyle(Color.salvia)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if isDecisa {
                            Button {
                                riapri()
                            } label: {
                                Label("Riapri decisione", systemImage: "arrow.uturn.backward")
                            }
                        }
                        Button(role: .destructive) {
                            cancella()
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
    }

    // MARK: - Blocchi

    private var bloccoArchiviata: some View {
        HStack(spacing: S.x3) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Color.salvia)
            Text("Hai preso questa decisione.")
                .font(.equinozio(.corpoMedio))
                .foregroundStyle(Color.inchiostro)
            Spacer()
        }
        .padding(S.x4)
        .background(Color.salviaTenue)
        .clipShape(RoundedRectangle(cornerRadius: R.r2))
    }

    @ViewBuilder
    private var bloccoDecisioneFinale: some View {
        VStack(alignment: .leading, spacing: S.x2) {
            Text("LA TUA DECISIONE")
                .font(.equinozio(.etichetta))
                .tracking(2.0)
                .foregroundStyle(Color.attenuato)

            if isDecisa && !inModificaScelta {
                // Mostra la decisione presa
                Text(decisione.decisione ?? "")
                    .font(.equinozio(.corpo))
                    .foregroundStyle(Color.inchiostro)
                    .padding(S.x4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.superficie)
                    .clipShape(RoundedRectangle(cornerRadius: R.r2))
                    .overlay(
                        RoundedRectangle(cornerRadius: R.r2)
                            .stroke(Color.lineaSottile, lineWidth: 1)
                    )

                Button {
                    sceltaInModifica = decisione.decisione ?? ""
                    inModificaScelta = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10, weight: .medium))
                        Text("MODIFICA")
                            .font(.equinozio(.etichetta))
                            .tracking(1.6)
                    }
                    .foregroundStyle(Color.salvia)
                }
                .buttonStyle(.plain)
            } else {
                TextEditor(text: $sceltaInModifica)
                    .font(.equinozio(.corpo))
                    .frame(minHeight: 96)
                    .scrollContentBackground(.hidden)
                    .padding(S.x3)
                    .background(Color.superficie)
                    .clipShape(RoundedRectangle(cornerRadius: R.r2))
                    .overlay(
                        RoundedRectangle(cornerRadius: R.r2)
                            .stroke(Color.lineaSottile, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if sceltaInModifica.isEmpty {
                            Text("Cosa hai deciso, e perché?")
                                .font(.equinozio(.corpo))
                                .foregroundStyle(Color.attenuato)
                                .padding(.top, S.x3 + 8)
                                .padding(.leading, S.x3 + 4)
                                .allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel("La tua decisione")

                HStack(spacing: S.x3) {
                    if inModificaScelta {
                        AzioneSecondaria("Annulla") {
                            inModificaScelta = false
                            sceltaInModifica = decisione.decisione ?? ""
                        }
                    }
                    AzionePrimaria(isDecisa ? "Salva modifica" : "Segna come decisa", azione: archivia)
                        .disabled(sceltaInModifica.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(sceltaInModifica.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1.0)
                }
                .padding(.top, S.x1)
            }
        }
    }

    // MARK: - Azioni

    private func archivia() {
        let pulito = sceltaInModifica.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pulito.isEmpty else { return }
        decisione.decisione = pulito
        try? contesto.save()
        inModificaScelta = false
    }

    private func riapri() {
        decisione.decisione = nil
        try? contesto.save()
    }

    private func cancella() {
        contesto.delete(decisione)
        try? contesto.save()
        chiudi()
    }
}

#Preview {
    DecisioneView()
        .modelContainer(for: [
            Profilo.self, Cerchio.self, Elemento.self,
            Pagina.self, Riflessione.self, Decisione.self, Insight.self,
        ], inMemory: true)
}
