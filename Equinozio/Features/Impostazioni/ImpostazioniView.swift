//
//  ImpostazioniView.swift
//  Equinozio · Features · Impostazioni
//
//  Sheet di configurazione · nome utente + aspetto.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ImpostazioniView: View {

    @Environment(\.modelContext) private var contesto
    @Environment(\.dismiss) private var chiudi
    @Query private var profili: [Profilo]

    @State private var nomeEditabile: String = ""
    @State private var manifestoAperto = false
    @State private var esplorazioneAperta = false
    @State private var promemoriaAttivo: Bool = false
    @State private var statoPromemoria: UNAuthorizationStatus = .notDetermined
    @State private var iCloudService = iCloudStatoService.shared
    @AppStorage("schemaPreferito") private var schemaPreferito: SchemaPreferito = .sistema
    @AppStorage("promemoriaRiflessione") private var promemoriaPersistito: Bool = false
    @AppStorage("promemoriaGiorno") private var promemoriaGiorno: Int = 1
    @AppStorage("promemoriaOra") private var promemoriaOra: Int = 19
    @AppStorage("promemoriaMinuto") private var promemoriaMinuto: Int = 0
    @AppStorage("promemoriaTesto") private var promemoriaTesto: String = "Cinque minuti per la tua riflessione settimanale."
    @AppStorage("esplorazioneCompletata") private var esplorazioneCompletata: Bool = false
    @AppStorage("protezioneBiometrica") private var protezioneBiometrica: Bool = false

    private var profilo: Profilo? { profili.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: S.x5) {

                    sezione(occhiello: "Identità", titolo: "Come ti chiami?") {
                        TextField("Il tuo nome", text: $nomeEditabile)
                            .font(.equinozio(.corpoGrande))
                            .padding(.vertical, S.x2)
                            .textFieldStyle(.plain)
                            .overlay(alignment: .bottom) {
                                Rectangle().frame(height: 1).foregroundStyle(Color.lineaSottile)
                            }
                            .onSubmit(salva)

                        Text("Lo vedi nel saluto in alto sulla Mappa. Resta solo sul tuo dispositivo e sul tuo iCloud privato.")
                            .font(.equinozio(.corpoMedio))
                            .foregroundStyle(Color.attenuato)
                            .padding(.top, S.x2)
                    }

                    sezione(occhiello: "Aspetto", titolo: "Tema dell'applicazione") {
                        VStack(spacing: S.x2) {
                            ForEach(SchemaPreferito.allCases) { tema in
                                temaCella(tema)
                            }
                        }
                    }

                    sezione(occhiello: "Cerchi", titolo: "Ridefinisci i tuoi cerchi") {
                        Button {
                            esplorazioneAperta = true
                        } label: {
                            HStack {
                                Image(systemName: "circle.grid.2x2")
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundStyle(Color.salvia)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Rifai l'Esplorazione")
                                        .font(.equinozio(.corpo))
                                        .foregroundStyle(Color.inchiostro)
                                    Text("Aggiorna passione, talento, missione, professione")
                                        .font(.equinozio(.corpoMedio))
                                        .foregroundStyle(Color.attenuato)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.attenuato)
                            }
                            .padding(S.x4)
                            .background(Color.superficie)
                            .clipShape(RoundedRectangle(cornerRadius: R.r1))
                            .overlay(
                                RoundedRectangle(cornerRadius: R.r1)
                                    .stroke(Color.lineaSottile, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    sezione(occhiello: "Privacy", titolo: "Protezione con \(BlocoAppService.shared.tipoBiometria.nome)") {
                        sezioneBiometrica
                    }

                    sezione(occhiello: "Sincronizzazione", titolo: "Stato iCloud") {
                        sezioneICloud
                    }

                    sezione(occhiello: "Promemoria", titolo: "Riflessione settimanale") {
                        VStack(alignment: .leading, spacing: S.x3) {
                            Toggle(isOn: bindingPromemoria) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Promemoria settimanale")
                                        .font(.equinozio(.corpo))
                                    Text(testoStatoPromemoria)
                                        .font(.equinozio(.corpoMedio))
                                        .foregroundStyle(Color.attenuato)
                                }
                            }
                            .tint(.salvia)

                            if promemoriaAttivo {
                                Picker("Giorno", selection: bindingGiorno) {
                                    ForEach(1...7, id: \.self) { g in
                                        Text(nomeGiorno(g)).tag(g)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.salvia)

                                DatePicker(
                                    "Orario",
                                    selection: bindingOrario,
                                    displayedComponents: .hourAndMinute
                                )
                                .environment(\.locale, Locale(identifier: "it_IT"))

                                VStack(alignment: .leading, spacing: S.x1) {
                                    Text("MESSAGGIO")
                                        .font(.equinozio(.etichetta))
                                        .tracking(1.8)
                                        .foregroundStyle(Color.attenuato)
                                    TextField("Messaggio del promemoria", text: bindingTesto, axis: .vertical)
                                        .font(.equinozio(.corpoMedio))
                                        .lineLimit(1...3)
                                        .textFieldStyle(.plain)
                                        .padding(.vertical, S.x2)
                                        .overlay(alignment: .bottom) {
                                            Rectangle().frame(height: 1).foregroundStyle(Color.lineaSottile)
                                        }
                                }
                            }
                        }
                        .padding(S.x4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.superficie)
                        .clipShape(RoundedRectangle(cornerRadius: R.r1))
                        .overlay(
                            RoundedRectangle(cornerRadius: R.r1)
                                .stroke(Color.lineaSottile, lineWidth: 1)
                        )
                    }

                    sezione(occhiello: "Equinozio", titolo: "Da Systema360, con cura") {
                        Button {
                            manifestoAperto = true
                        } label: {
                            HStack {
                                Image(systemName: "book")
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundStyle(Color.salvia)
                                    .frame(width: 28)
                                Text("Leggi il manifesto")
                                    .font(.equinozio(.corpo))
                                    .foregroundStyle(Color.inchiostro)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.attenuato)
                            }
                            .padding(S.x4)
                            .background(Color.superficie)
                            .clipShape(RoundedRectangle(cornerRadius: R.r1))
                            .overlay(
                                RoundedRectangle(cornerRadius: R.r1)
                                    .stroke(Color.lineaSottile, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        Text("Versione 1.0 (1)")
                            .font(.equinozio(.corpoMedio))
                            .foregroundStyle(Color.inchiostroTenue)
                            .padding(.top, S.x3)

                        Link(destination: URL(string: "https://systema360.it")!) {
                            HStack(spacing: S.x2) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .medium))
                                Text("systema360.it")
                                    .font(.equinozio(.corpoMedio))
                            }
                            .foregroundStyle(Color.salvia)
                        }
                        .padding(.top, S.x1)
                    }
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
                    Text("IMPOSTAZIONI")
                        .font(.equinozio(.etichetta))
                        .tracking(2.2)
                        .foregroundStyle(Color.salvia)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salva") { salva(); chiudi() }
                        .tint(.salvia)
                        .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            nomeEditabile = profilo?.nome ?? ""
            promemoriaAttivo = promemoriaPersistito
            Task {
                await caricaStatoPromemoria()
                await iCloudService.verifica()
            }
        }
        .sheet(isPresented: $manifestoAperto) {
            ManifestoView()
                .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $esplorazioneAperta) {
            EsplorazioneView(modale: true, onCompletato: {
                esplorazioneCompletata = true
                esplorazioneAperta = false
            })
        }
    }

    // MARK: - Promemoria

    private var bindingPromemoria: Binding<Bool> {
        Binding(
            get: { promemoriaAttivo },
            set: { nuovoValore in
                promemoriaAttivo = nuovoValore
                Task { await aggiornaPromemoria(nuovoValore) }
            }
        )
    }

    private var bindingGiorno: Binding<Int> {
        Binding(get: { promemoriaGiorno }, set: { promemoriaGiorno = $0; Task { await riprogramma() } })
    }

    private var bindingOrario: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents(); c.hour = promemoriaOra; c.minute = promemoriaMinuto
                return Calendar.current.date(from: c) ?? .now
            },
            set: { nuova in
                let c = Calendar.current.dateComponents([.hour, .minute], from: nuova)
                promemoriaOra = c.hour ?? 19
                promemoriaMinuto = c.minute ?? 0
                Task { await riprogramma() }
            }
        )
    }

    private var bindingTesto: Binding<String> {
        Binding(get: { promemoriaTesto }, set: { promemoriaTesto = $0; Task { await riprogramma() } })
    }

    private func nomeGiorno(_ g: Int) -> String {
        let it = DateFormatter(); it.locale = Locale(identifier: "it_IT")
        let nomi = it.weekdaySymbols ?? Calendar(identifier: .gregorian).weekdaySymbols
        let idx = max(0, min(6, g - 1))
        return nomi[idx].capitalized
    }

    /// Riprogramma con le preferenze correnti, solo se attivo e autorizzato.
    private func riprogramma() async {
        guard promemoriaAttivo else { return }
        let stato = await PromemoriaService.shared.statoAutorizzazione()
        guard stato == .authorized || stato == .provisional else { return }
        await PromemoriaService.shared.schedulaRiflessione(
            giorno: promemoriaGiorno, ora: promemoriaOra, minuto: promemoriaMinuto,
            titolo: "Riflessione settimanale", corpo: promemoriaTesto
        )
    }

    private var testoStatoPromemoria: String {
        switch statoPromemoria {
        case .denied:
            return "Permesso notifiche negato · attivalo da Impostazioni di sistema"
        case .authorized, .provisional, .ephemeral:
            if promemoriaAttivo,
               let prossima = PromemoriaService.prossimaData(giorno: promemoriaGiorno, ora: promemoriaOra, minuto: promemoriaMinuto) {
                let f = DateFormatter(); f.locale = Locale(identifier: "it_IT"); f.dateFormat = "EEEE 'alle' HH:mm"
                return "Prossimo · " + f.string(from: prossima)
            }
            return promemoriaAttivo ? "Attivo" : "Tocca per attivare il promemoria"
        case .notDetermined:
            return "Tocca per attivare e dare il permesso notifiche"
        @unknown default:
            return ""
        }
    }

    private func caricaStatoPromemoria() async {
        statoPromemoria = await PromemoriaService.shared.statoAutorizzazione()
    }

    private func aggiornaPromemoria(_ attivo: Bool) async {
        if attivo {
            var stato = await PromemoriaService.shared.statoAutorizzazione()
            if stato == .notDetermined {
                let concesso = await PromemoriaService.shared.chiediEAttiva()
                if !concesso { promemoriaAttivo = false }
                stato = await PromemoriaService.shared.statoAutorizzazione()
            }
            if stato == .authorized || stato == .provisional {
                await riprogramma()
            } else {
                promemoriaAttivo = false
            }
        } else {
            PromemoriaService.shared.cancella()
        }
        promemoriaPersistito = promemoriaAttivo
        await caricaStatoPromemoria()
    }

    // MARK: - Sezione biometrica

    @ViewBuilder
    private var sezioneBiometrica: some View {
        let tipo = BlocoAppService.shared.tipoBiometria

        if tipo == .nessuna {
            VStack(alignment: .leading, spacing: S.x2) {
                Text("Nessun metodo biometrico disponibile su questo dispositivo.")
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.attenuato)
            }
            .padding(S.x4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.superficie)
            .clipShape(RoundedRectangle(cornerRadius: R.r1))
            .overlay(
                RoundedRectangle(cornerRadius: R.r1)
                    .stroke(Color.lineaSottile, lineWidth: 1)
            )
        } else {
            VStack(alignment: .leading, spacing: S.x2) {
                Toggle(isOn: $protezioneBiometrica) {
                    HStack(spacing: S.x3) {
                        Image(systemName: tipo.simbolo)
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(Color.salvia)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Richiedi \(tipo.nome) per aprire l'app")
                                .font(.equinozio(.corpo))
                            Text(protezioneBiometrica
                                 ? "L'app si sblocca con \(tipo.nome) all'apertura e quando torna dal background."
                                 : "Chiunque possa sbloccare il dispositivo può vedere il tuo diario.")
                                .font(.equinozio(.corpoMedio))
                                .foregroundStyle(Color.attenuato)
                        }
                    }
                }
                .tint(.salvia)
            }
            .padding(S.x4)
            .background(Color.superficie)
            .clipShape(RoundedRectangle(cornerRadius: R.r1))
            .overlay(
                RoundedRectangle(cornerRadius: R.r1)
                    .stroke(Color.lineaSottile, lineWidth: 1)
            )
        }
    }

    // MARK: - Sezione iCloud

    private var sezioneICloud: some View {
        VStack(alignment: .leading, spacing: S.x3) {
            HStack(spacing: S.x3) {
                Image(systemName: iCloudService.stato.simbolo)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(iCloudService.stato.disponibile ? Color.salvia : Color.attenuato)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(iCloudService.stato.titolo)
                        .font(.equinozio(.corpo))
                        .foregroundStyle(Color.inchiostro)
                    Text(iCloudService.stato.descrizione)
                        .font(.equinozio(.corpoMedio))
                        .foregroundStyle(Color.attenuato)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: S.x3) {
                Button {
                    Task { await iCloudService.verifica() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .medium))
                        Text("VERIFICA")
                            .font(.equinozio(.etichetta))
                            .tracking(1.6)
                    }
                    .foregroundStyle(Color.salvia)
                }
                .buttonStyle(.plain)

                if !iCloudService.stato.disponibile {
                    if let url = URL(string: "App-prefs:CASTLE") {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: "gear")
                                    .font(.system(size: 11, weight: .medium))
                                Text("APRI IMPOSTAZIONI iOS")
                                    .font(.equinozio(.etichetta))
                                    .tracking(1.6)
                            }
                            .foregroundStyle(Color.salvia)
                        }
                    }
                }
            }

            Text("Container · iCloud.it.systema360.equinozio")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Color.attenuato)
                .padding(.top, S.x1)
        }
        .padding(S.x4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.superficie)
        .clipShape(RoundedRectangle(cornerRadius: R.r1))
        .overlay(
            RoundedRectangle(cornerRadius: R.r1)
                .stroke(Color.lineaSottile, lineWidth: 1)
        )
    }

    // MARK: - Helper

    @ViewBuilder
    private func sezione<C: View>(occhiello: String, titolo: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: S.x2) {
            Text(occhiello.uppercased())
                .font(.equinozio(.etichetta))
                .tracking(2.2)
                .foregroundStyle(Color.salvia)
            Text(titolo)
                .font(.equinozio(.titoloPiccolo))
                .foregroundStyle(Color.inchiostro)
                .padding(.bottom, S.x2)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func temaCella(_ tema: SchemaPreferito) -> some View {
        let attivo = schemaPreferito == tema
        return Button {
            schemaPreferito = tema
        } label: {
            HStack {
                Image(systemName: tema.iconaSimbolo)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(attivo ? Color.salvia : Color.inchiostroTenue)
                    .frame(width: 28)
                Text(tema.titolo)
                    .font(.equinozio(.corpo))
                    .foregroundStyle(Color.inchiostro)
                Spacer()
                if attivo {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.salvia)
                }
            }
            .padding(S.x4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(attivo ? Color.salviaTenue : Color.superficie)
            .clipShape(RoundedRectangle(cornerRadius: R.r1))
            .overlay(
                RoundedRectangle(cornerRadius: R.r1)
                    .stroke(attivo ? Color.salvia : Color.lineaSottile, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func salva() {
        let pulito = nomeEditabile.trimmingCharacters(in: .whitespacesAndNewlines)
        if let p = profilo {
            p.nome = pulito
        } else {
            contesto.insert(Profilo(nome: pulito))
        }
        try? contesto.save()
    }
}

// MARK: - Schema tema

enum SchemaPreferito: String, CaseIterable, Identifiable {
    case sistema, chiaro, scuro

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .sistema: return "Segui il sistema"
        case .chiaro:  return "Sempre chiaro"
        case .scuro:   return "Sempre scuro"
        }
    }

    var iconaSimbolo: String {
        switch self {
        case .sistema: return "circle.lefthalf.filled"
        case .chiaro:  return "sun.max"
        case .scuro:   return "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .sistema: return nil
        case .chiaro:  return .light
        case .scuro:   return .dark
        }
    }
}

#Preview {
    ImpostazioniView()
        .modelContainer(for: [
            Profilo.self, Cerchio.self, Elemento.self,
            Pagina.self, Riflessione.self, Decisione.self, Insight.self,
        ], inMemory: true)
}
