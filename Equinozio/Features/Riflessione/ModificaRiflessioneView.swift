//
//  ModificaRiflessioneView.swift
//  Equinozio · Features · Riflessione
//
//  Sheet per correggere una riflessione passata: quote (somma 100%) + pensiero.
//

import SwiftUI
import SwiftData

struct ModificaRiflessioneView: View {

    @Environment(\.modelContext) private var contesto
    @Environment(\.dismiss) private var chiudi
    @Bindable var riflessione: Riflessione

    @State private var passione: Int = 25
    @State private var talento: Int = 25
    @State private var missione: Int = 25
    @State private var professione: Int = 25
    @State private var pensiero: String = ""
    @State private var caricato = false

    private var totale: Int { passione + talento + missione + professione }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: S.x4) {
                    Text(dataFormattata(riflessione.data).uppercased())
                        .font(.equinozio(.etichetta))
                        .tracking(2.0)
                        .foregroundStyle(Color.attenuato)

                    VStack(spacing: S.x3) {
                        sliderRiga(.passione, valore: $passione)
                        sliderRiga(.talento, valore: $talento)
                        sliderRiga(.missione, valore: $missione)
                        sliderRiga(.professione, valore: $professione)
                    }

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
                    .padding(.vertical, S.x2)

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
                        .accessibilityLabel("Pensiero della settimana")

                    AzionePrimaria("Salva le modifiche", azione: salva)
                        .disabled(totale != 100)
                        .opacity(totale == 100 ? 1 : 0.4)
                }
                .padding(.horizontal, S.x5)
                .padding(.top, S.x4)
                .padding(.bottom, S.x6)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.sfondo)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { chiudi() }
                        .tint(.attenuato)
                }
                ToolbarItem(placement: .principal) {
                    Text("MODIFICA RIFLESSIONE")
                        .font(.equinozio(.etichetta))
                        .tracking(2.2)
                        .foregroundStyle(Color.salvia)
                }
            }
            .toolbarTastieraFine()
            .onAppear(perform: carica)
        }
    }

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
                }
            ), in: 0...100, step: 1)
            .tint(tipo.colore)
            .accessibilityLabel(tipo.titoloRiflessione)
            .accessibilityValue("\(valore.wrappedValue) percento")
        }
    }

    private func carica() {
        guard !caricato else { return }
        caricato = true
        passione = riflessione.quotaPassione
        talento = riflessione.quotaTalento
        missione = riflessione.quotaMissione
        professione = riflessione.quotaProfessione
        pensiero = riflessione.pensiero
    }

    private func salva() {
        guard totale == 100 else { return }
        riflessione.quotaPassione = passione
        riflessione.quotaTalento = talento
        riflessione.quotaMissione = missione
        riflessione.quotaProfessione = professione
        riflessione.pensiero = pensiero.trimmingCharacters(in: .whitespacesAndNewlines)
        try? contesto.save()
        // Le quote sono cambiate: riallinea Spunto e widget all'equilibrio aggiornato.
        Task { await SpuntoStore.rigenera(contesto: contesto) }
        chiudi()
    }

    private func dataFormattata(_ data: Date) -> String {
        Formattazione.giornoMese.string(from: data)
    }
}
