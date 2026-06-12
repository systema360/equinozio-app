//
//  SchemaCloudKitDebug.swift
//  Equinozio
//
//  Inizializzazione completa dello schema CloudKit nell'ambiente Development.
//  Solo build DEBUG: crea tutti i record type e tutti i campi (anche quelli
//  opzionali mai valorizzati) così da poter fare "Deploy Schema Changes" in
//  Production dalla CloudKit Console senza buchi di schema.
//
//  Uso: aggiungi l'argomento di lancio "-inizializza-schema-cloudkit" allo
//  scheme (Edit Scheme → Run → Arguments), avvia su simulatore o device con
//  un account iCloud attivo, verifica l'esito nei log, poi rimuovi
//  l'argomento. Da ripetere a ogni modifica dei modelli, prima del deploy.
//

#if DEBUG
import CoreData
import OSLog
import SwiftData

enum SchemaCloudKitDebug {

    private static let logger = Logger(subsystem: "it.systema360.equinozio", category: "SchemaCloudKit")

    /// Esegue l'inizializzazione dello schema solo se richiesto dall'argomento di lancio.
    static func inizializzaSeRichiesto() {
        guard ProcessInfo.processInfo.arguments.contains("-inizializza-schema-cloudkit") else { return }

        do {
            try inizializzaSchema()
            logger.info("✅ Schema CloudKit inizializzato nell'ambiente Development.")
        } catch {
            logger.error("❌ Inizializzazione schema CloudKit fallita: \(error.localizedDescription)")
        }
    }

    /// Costruisce un NSPersistentCloudKitContainer equivalente al ModelContainer
    /// dell'app (stessi modelli, stesso container iCloud) su uno store temporaneo
    /// e invoca initializeCloudKitSchema(), che SwiftData non espone direttamente.
    private static func inizializzaSchema() throws {
        guard let modello = NSManagedObjectModel.makeManagedObjectModel(for: [
            Profilo.self,
            Cerchio.self,
            Elemento.self,
            Pagina.self,
            Riflessione.self,
            Decisione.self,
            Insight.self,
        ]) else {
            throw NSError(domain: "SchemaCloudKitDebug", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Impossibile generare il managed object model dai tipi SwiftData.",
            ])
        }

        let urlTemporaneo = URL.temporaryDirectory.appending(path: "schema-cloudkit.sqlite")
        let descrizione = NSPersistentStoreDescription(url: urlTemporaneo)
        descrizione.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.it.systema360.equinozio"
        )

        let container = NSPersistentCloudKitContainer(name: "Equinozio", managedObjectModel: modello)
        container.persistentStoreDescriptions = [descrizione]

        var erroreCaricamento: Error?
        container.loadPersistentStores { _, errore in erroreCaricamento = errore }
        if let erroreCaricamento {
            throw erroreCaricamento
        }

        try container.initializeCloudKitSchema()
    }
}
#endif
