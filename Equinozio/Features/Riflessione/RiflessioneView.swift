//
//  RiflessioneView.swift
//  Equinozio · Features · Riflessione
//
//  Check-in settimanale: quattro slider che sommano a 100% + pensiero guidato.
//

import SwiftUI
import SwiftData

struct RiflessioneView: View {

    @Environment(\.modelContext) private var contesto
    @Query(sort: \Riflessione.data, order: .reverse) private var riflessioniPassate: [Riflessione]

    @State private var quotePassione: Int = 25
    @State private var quoteTalento: Int = 25
    @State private var quoteMissione: Int = 25
    @State private var quoteProfessione: Int = 25
    @State private var storicoAperto = false
    @State private var salvataggioFatto: Bool = false
    @State private var caricato: Bool = false
    @State private var pensiero: String = ""

    @AppStorage("riflessioneIntroLetta") private var introLetta: Bool = false

    private var riflessioneSettimanaCorrente: Riflessione? {
        let inizio = inizioSettimana(per: .now)
        return riflessioniPassate.first { Calendar.current.isDate($0.data, inSameDayAs: inizio) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                intestazione

                Text(periodoCorrente + " · cinque minuti")
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.attenuato)
                    .padding(.bottom, S.x3)

                (Text("Dove hai speso il tuo ") +
                 Text("tempo").foregroundColor(.salvia) +
                 Text(" questa settimana?"))
                    .font(.equinozio(.titoloPiccolo))
                    .foregroundStyle(Color.inchiostro)
                    .padding(.bottom, S.x4)

                if !introLetta {
                    bannerIntro
                        .padding(.bottom, S.x4)
                }

                if salvataggioFatto {
                    bannerSalvato
                        .padding(.bottom, S.x4)
                }

                VStack(spacing: S.x3) {
                    sliderRiga(.passione, valore: $quotePassione)
                    sliderRiga(.talento, valore: $quoteTalento)
                    sliderRiga(.missione, valore: $quoteMissione)
                    sliderRiga(.professione, valore: $quoteProfessione)
                }
                .padding(.bottom, S.x5)

                HStack {
                    Text("TOTALE")
                        .font(.equinozio(.etichetta))
                        .tracking(1.8)
                        .foregroundStyle(Color.attenuato)
                    Spacer()
                    Text("\(totale)%")
                        .font(.system(size: 22, weight: .thin))
                        .monospacedDigit()
                        .foregroundStyle(totale == 100 ? Color.salvia : Color.passione)
                }
                .padding(.vertical, S.x3)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.lineaSottile), alignment: .top)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.lineaSottile), alignment: .bottom)
                .padding(.bottom, S.x4)

                pensieroGuidato
                    .padding(.bottom, S.x4)

                AzionePrimaria(testoBottone, azione: salva)
                    .disabled(totale != 100)
                    .opacity(totale == 100 ? 1 : 0.4)
            }
            .padding(.horizontal, S.x5)
            .padding(.top, S.x7)
            .padding(.bottom, S.x6)
        }
        .background(Color.sfondo)
        .sheet(isPresented: $storicoAperto) {
            StoricoRiflessioniView()
                .presentationDetents([.large])
        }
        .onAppear {
            caricaSettimanaCorrente()
        }
    }

    // MARK: - Intestazione

    private var intestazione: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Riflessione settimanale")
                .font(.equinozio(.occhiello))
                .tracking(2.4)
                .foregroundStyle(Color.salvia)
            Spacer()
            if introLetta {
                Button {
                    withAnimation { introLetta = false }
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Color.attenuato)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mostra spiegazione della riflessione")
                .padding(.trailing, S.x2)
            }
            if !riflessioniPassate.isEmpty {
                Button {
                    storicoAperto = true
                } label: {
                    HStack(spacing: 4) {
                        Text("STORICO")
                            .font(.equinozio(.etichetta))
                            .tracking(1.8)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(Color.salvia)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, S.x2)
    }

    private var testoBottone: String {
        if riflessioneSettimanaCorrente != nil {
            return "Aggiorna la settimana"
        }
        return "Salva la settimana"
    }

    // MARK: - Banner

    private var bannerSalvato: some View {
        HStack(spacing: S.x3) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Color.salvia)
            VStack(alignment: .leading, spacing: 2) {
                Text("Riflessione salvata")
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.inchiostro)
                Text("Equilibrio di questa settimana · \(equilibrioCorrente)%")
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.attenuato)
            }
            Spacer()
        }
        .padding(S.x4)
        .background(Color.salviaTenue)
        .clipShape(RoundedRectangle(cornerRadius: R.r2))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var bannerIntro: some View {
        VStack(alignment: .leading, spacing: S.x2) {
            HStack(spacing: S.x2) {
                Image(systemName: "moon.stars")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color.salvia)
                Text("COSA È LA RIFLESSIONE")
                    .font(.equinozio(.etichetta))
                    .tracking(2.0)
                    .foregroundStyle(Color.salvia)
            }

            Text("Sposta i quattro cursori per dirti, in percentuale, **dove è andato davvero il tuo tempo questa settimana**.")
                .font(.equinozio(.corpoMedio))
                .foregroundStyle(Color.inchiostro)

            Text("La somma è sempre 100%. Equinozio misura l'**equilibrio**: più ti avvicini a 25/25/25/25 più sei bilanciato. Nel tempo vedrai il pattern reale della tua vita.")
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

    // MARK: - Slider

    private func sliderRiga(_ tipo: TipoCerchio, valore: Binding<Int>) -> some View {
        VStack(spacing: S.x2) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: S.x2) {
                    Circle().fill(tipo.colore).frame(width: 8, height: 8)
                    Text(tipo.titoloRiflessione)
                        .font(.equinozio(.corpoMedio))
                }
                Spacer()
                Text("\(valore.wrappedValue)%")
                    .font(.system(size: 17, weight: .thin))
                    .monospacedDigit()
            }
            Slider(value: Binding(
                get: { Double(valore.wrappedValue) },
                set: { nuovo in
                    let altri = totale - valore.wrappedValue
                    let limite = 100 - altri
                    valore.wrappedValue = min(Int(nuovo), limite)
                    // Quando cambi qualcosa dopo aver salvato, togli il banner di conferma
                    if salvataggioFatto {
                        withAnimation { salvataggioFatto = false }
                    }
                }
            ), in: 0...100, step: 1)
            .tint(tipo.colore)
            .accessibilityLabel(tipo.titoloRiflessione)
            .accessibilityValue("\(valore.wrappedValue) percento")
        }
    }

    private var pensieroGuidato: some View {
        VStack(alignment: .leading, spacing: S.x2) {
            Text("PENSIERO GUIDATO")
                .font(.equinozio(.etichetta))
                .tracking(1.8)
                .foregroundStyle(Color.salvia)

            Text("Mentre rifletti su questa settimana, dove hai sentito più presenza?")
                .font(.equinozio(.corpo))
                .foregroundStyle(Color.inchiostroTenue)

            TextEditor(text: $pensiero)
                .font(.equinozio(.corpo))
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .padding(S.x2)
                .background(Color.superficie)
                .clipShape(RoundedRectangle(cornerRadius: R.r2))
                .overlay(
                    RoundedRectangle(cornerRadius: R.r2)
                        .stroke(Color.lineaSottile, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if pensiero.isEmpty {
                        Text("Una riga, se ti va.")
                            .font(.equinozio(.corpo))
                            .foregroundStyle(Color.attenuato)
                            .padding(.top, S.x2 + 8)
                            .padding(.leading, S.x2 + 5)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel("Pensiero della settimana")
        }
        .padding(.leading, S.x4)
        .overlay(Rectangle().frame(width: 2).foregroundStyle(Color.salvia), alignment: .leading)
    }

    // MARK: - Stato derivato

    private var totale: Int {
        quotePassione + quoteTalento + quoteMissione + quoteProfessione
    }

    private var equilibrioCorrente: Int {
        Riflessione.equilibrio(
            passione: quotePassione,
            talento: quoteTalento,
            missione: quoteMissione,
            professione: quoteProfessione
        )
    }

    private var periodoCorrente: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "EEEE d MMMM"
        return f.string(from: .now)
    }

    // MARK: - Persistenza

    private func inizioSettimana(per data: Date) -> Date {
        let calendar = Calendar.current
        let componenti = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: data)
        return calendar.date(from: componenti) ?? data
    }

    private func caricaSettimanaCorrente() {
        guard !caricato else { return }
        caricato = true
        if let esistente = riflessioneSettimanaCorrente {
            quotePassione = esistente.quotaPassione
            quoteTalento = esistente.quotaTalento
            quoteMissione = esistente.quotaMissione
            quoteProfessione = esistente.quotaProfessione
            pensiero = esistente.pensiero
        }
    }

    private func salva() {
        guard totale == 100 else { return }

        let inizio = inizioSettimana(per: .now)

        if let esistente = riflessioneSettimanaCorrente {
            // Aggiorna · evita duplicati per la stessa settimana
            esistente.quotaPassione = quotePassione
            esistente.quotaTalento = quoteTalento
            esistente.quotaMissione = quoteMissione
            esistente.quotaProfessione = quoteProfessione
            esistente.data = inizio
            esistente.pensiero = pensiero.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let nuova = Riflessione(
                data: inizio,
                quotaPassione: quotePassione,
                quotaTalento: quoteTalento,
                quotaMissione: quoteMissione,
                quotaProfessione: quoteProfessione,
                pensiero: pensiero.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            contesto.insert(nuova)
        }

        do {
            try contesto.save()
            WidgetSnapshot.aggiorna(equilibrio: equilibrioCorrente)
            withAnimation(.easeInOut(duration: 0.3)) {
                salvataggioFatto = true
            }
            // Apri lo storico dopo un attimo, così l'utente vede la sua riflessione
            // entrata nel pattern complessivo
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                storicoAperto = true
            }
        } catch {
            print("Errore salvataggio riflessione: \(error)")
        }
    }
}

#Preview {
    RiflessioneView()
        .modelContainer(for: [
            Profilo.self, Cerchio.self, Elemento.self,
            Pagina.self, Riflessione.self, Decisione.self, Insight.self,
        ], inMemory: true)
}
