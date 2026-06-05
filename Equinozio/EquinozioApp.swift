//
//  EquinozioApp.swift
//  Equinozio
//
//  Entry point dell'applicazione.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct EquinozioApp: App {

    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("schemaPreferito") private var schemaPreferito: SchemaPreferito = .sistema
    @AppStorage("protezioneBiometrica") private var protezioneAttiva: Bool = false
    @AppStorage("primoAvvioFatto") private var primoAvvioFatto: Bool = false

    @State private var router = AppRouter()
    @State private var splashAttiva: Bool
    @State private var richiedeSblocco: Bool = false

    init() {
        // Splash animato solo al primo avvio dopo installazione (HIG: niente splash ricorrenti).
        let primo = UserDefaults.standard.bool(forKey: "primoAvvioFatto")
        _splashAttiva = State(initialValue: !primo)
    }

    var modelContainer: ModelContainer = {
        let schema = Schema([
            Profilo.self,
            Cerchio.self,
            Elemento.self,
            Pagina.self,
            Riflessione.self,
            Decisione.self,
            Insight.self,
        ])

        // Sotto il test runner usiamo uno store in-memory: evita l'inizializzazione
        // di CloudKit (che, senza account iCloud, fa crashare l'host dei test sul
        // simulatore) e isola ogni esecuzione dei test.
        let inTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

        let config: ModelConfiguration = inTest
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.it.systema360.equinozio")
            )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Impossibile creare il ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContenitoreView()
                    .environment(router)
                    .tint(.salvia)

                if richiedeSblocco {
                    BloccoView(
                        tipoBiometria: BlocoAppService.shared.tipoBiometria,
                        onSbloccato: {
                            withAnimation(.easeOut(duration: 0.35)) {
                                richiedeSblocco = false
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(1)
                }

                if splashAttiva {
                    SplashScreenView(onTerminato: {
                        splashAttiva = false
                        primoAvvioFatto = true
                        if protezioneAttiva {
                            richiedeSblocco = true
                        }
                    })
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .preferredColorScheme(schemaPreferito.colorScheme)
            .onAppear {
                // Se lo splash è saltato (avvii successivi al primo) richiedo subito lo sblocco.
                if !splashAttiva && protezioneAttiva {
                    richiedeSblocco = true
                }
                NotificationeDelegate.shared.onApri = { scheda in router.scheda = scheda }
                UNUserNotificationCenter.current().delegate = NotificationeDelegate.shared
                PromemoriaService.shared.registraCategorie()
            }
            .onChange(of: scenePhase) { _, nuovo in
                gestisciCambioStato(nuovo)
            }
            .onOpenURL { url in
                if let scheda = Scheda.fromDeepLink(url) {
                    router.scheda = scheda
                }
            }
        }
        .modelContainer(modelContainer)
    }

    /// Quando l'app va in background (o si chiude) la riblocco subito.
    /// Al ritorno in foreground richiedo lo sblocco.
    private func gestisciCambioStato(_ fase: ScenePhase) {
        guard protezioneAttiva else { return }
        switch fase {
        case .background, .inactive:
            richiedeSblocco = true
            BlocoAppService.shared.blocca()
        default:
            break
        }
    }
}
