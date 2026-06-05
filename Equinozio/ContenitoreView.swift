//
//  ContenitoreView.swift
//  Equinozio
//
//  Root view dell'applicazione.
//  TabView a 4 voci · Esplorazione come fullScreenCover.
//

import SwiftUI
import SwiftData

enum Scheda: Hashable {
    case mappa, diario, riflessione, decisione
}

struct ContenitoreView: View {

    @Environment(\.modelContext) private var contesto
    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    @Query private var profili: [Profilo]
    @Query private var cerchi: [Cerchio]
    @Query private var elementi: [Elemento]

    @State private var schedaAttiva: Scheda = .mappa
    @State private var esplorazioneAperta = false
    @AppStorage("esplorazioneCompletata") private var esplorazioneCompletata: Bool = false

    var body: some View {
        Group {
            #if os(macOS)
            sidebarView
            #else
            if sizeClass == .regular {
                // iPad in landscape o portrait grande → sidebar nativa (HIG).
                sidebarView
            } else {
                // iPhone o iPad split compatto → tab bar.
                tabView
            }
            #endif
        }
        .task {
            await setupPrimoAvvio()
        }
        .fullScreenCover(isPresented: $esplorazioneAperta) {
            EsplorazioneView(
                modale: true,
                onCompletato: {
                    esplorazioneCompletata = true
                    esplorazioneAperta = false
                }
            )
            .interactiveDismissDisabled(elementi.isEmpty) // primo avvio · obbligatorio
        }
    }

    // MARK: - Tab bar (iPhone, iPad compact)

    #if !os(macOS)
    private var tabView: some View {
        TabView(selection: $schedaAttiva) {
            MappaView()
                .tabItem { Label("Mappa", systemImage: "circle.grid.2x2.fill") }
                .tag(Scheda.mappa)

            DiarioView()
                .tabItem { Label("Diario", systemImage: "book.closed") }
                .tag(Scheda.diario)

            RiflessioneView()
                .tabItem { Label("Riflessione", systemImage: "moon.stars") }
                .tag(Scheda.riflessione)

            DecisioneView()
                .tabItem { Label("Decisione", systemImage: "scale.3d") }
                .tag(Scheda.decisione)
        }
    }
    #endif

    // MARK: - Sidebar (Mac, iPad regular)

    private var sidebarView: some View {
        NavigationSplitView {
            List(selection: Binding(
                get: { schedaAttiva as Scheda? },
                set: { if let s = $0 { schedaAttiva = s } }
            )) {
                Label("Mappa", systemImage: "circle.grid.2x2.fill").tag(Scheda.mappa)
                Label("Diario", systemImage: "book.closed").tag(Scheda.diario)
                Label("Riflessione", systemImage: "moon.stars").tag(Scheda.riflessione)
                Label("Decisione", systemImage: "scale.3d").tag(Scheda.decisione)
            }
            .navigationTitle("Equinozio")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            switch schedaAttiva {
            case .mappa:        MappaView()
            case .diario:       DiarioView()
            case .riflessione:  RiflessioneView()
            case .decisione:    DecisioneView()
            }
        }
    }

    // MARK: - Setup primo avvio

    private func setupPrimoAvvio() async {
        if profili.isEmpty {
            contesto.insert(Profilo(nome: "", lingua: "it"))
        }
        let tipiPresenti = Set(cerchi.map(\.tipo))
        for tipo in TipoCerchio.allCases where !tipiPresenti.contains(tipo) {
            contesto.insert(Cerchio(tipo: tipo))
        }
        try? contesto.save()

        // Se non hai mai completato l'esplorazione · apri il wizard
        if !esplorazioneCompletata {
            // Aspetta un istante che la UI si stabilizzi
            try? await Task.sleep(nanoseconds: 200_000_000)
            esplorazioneAperta = true
        }
    }
}

#Preview {
    ContenitoreView()
        .modelContainer(for: [
            Profilo.self, Cerchio.self, Elemento.self,
            Pagina.self, Riflessione.self, Decisione.self, Insight.self,
        ], inMemory: true)
}
