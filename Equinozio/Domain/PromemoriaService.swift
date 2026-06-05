//
//  PromemoriaService.swift
//  Equinozio · Domain
//
//  Gestione notifiche locali · promemoria settimanale per la Riflessione.
//  Programmata ogni domenica alle 19:00 (orario locale dell'utente).
//

import Foundation
import UserNotifications
import OSLog

@MainActor
public final class PromemoriaService {

    public static let shared = PromemoriaService()
    private let log = Logger(subsystem: "it.systema360.equinozio", category: "Promemoria")
    private let centro = UNUserNotificationCenter.current()

    public static let identificatoreRiflessione = "settimanale.riflessione"
    public static let categoriaRiflessione = "RIFLESSIONE_SETTIMANALE"
    public static let azioneRifletti = "RIFLETTI_ORA"

    /// Registra la categoria con l'azione "Rifletti ora". Chiamare una volta all'avvio.
    public func registraCategorie() {
        let azione = UNNotificationAction(
            identifier: Self.azioneRifletti,
            title: "Rifletti ora",
            options: [.foreground]
        )
        let categoria = UNNotificationCategory(
            identifier: Self.categoriaRiflessione,
            actions: [azione],
            intentIdentifiers: [],
            options: []
        )
        centro.setNotificationCategories([categoria])
    }

    private init() {}

    /// Stato corrente del permesso notifiche.
    public func statoAutorizzazione() async -> UNAuthorizationStatus {
        let settings = await centro.notificationSettings()
        return settings.authorizationStatus
    }

    /// Chiede il permesso notifiche. Ritorna true se concesso.
    /// NON schedula: il chiamante chiama `schedulaRiflessione(...)` con le preferenze.
    @discardableResult
    public func chiediEAttiva() async -> Bool {
        do {
            return try await centro.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            log.warning("Errore richiesta autorizzazione: \(error.localizedDescription)")
            return false
        }
    }

    /// Programma il promemoria settimanale ai parametri dati (default: domenica 19:00).
    public func schedulaRiflessione(
        giorno: Int = 1,
        ora: Int = 19,
        minuto: Int = 0,
        titolo: String = "Riflessione settimanale",
        corpo: String = "Cinque minuti per la tua riflessione settimanale."
    ) async {
        centro.removePendingNotificationRequests(withIdentifiers: [Self.identificatoreRiflessione])

        let contenuto = UNMutableNotificationContent()
        contenuto.title = titolo
        contenuto.body = corpo
        contenuto.sound = .default
        contenuto.threadIdentifier = "riflessione"
        contenuto.categoryIdentifier = Self.categoriaRiflessione

        var componenti = DateComponents()
        componenti.weekday = giorno
        componenti.hour = ora
        componenti.minute = minuto

        let trigger = UNCalendarNotificationTrigger(dateMatching: componenti, repeats: true)
        let richiesta = UNNotificationRequest(
            identifier: Self.identificatoreRiflessione,
            content: contenuto,
            trigger: trigger
        )

        do {
            try await centro.add(richiesta)
            log.info("Promemoria programmato · giorno \(giorno) \(ora):\(minuto)")
        } catch {
            log.warning("Impossibile programmare promemoria: \(error.localizedDescription)")
        }
    }

    /// Calcola la prossima occorrenza di (giorno della settimana, ora, minuto) dopo `da`.
    /// `giorno`: 1 = domenica … 7 = sabato (convenzione Calendar).
    nonisolated public static func prossimaData(
        giorno: Int, ora: Int, minuto: Int, da: Date = .now, calendario: Calendar = .current
    ) -> Date? {
        var componenti = DateComponents()
        componenti.weekday = giorno
        componenti.hour = ora
        componenti.minute = minuto
        return calendario.nextDate(after: da, matching: componenti, matchingPolicy: .nextTime)
    }

    /// Corpo della notifica: lo Spunto se presente, altrimenti il messaggio personalizzato.
    nonisolated public static func corpo(spunto: String?, personalizzato: String) -> String {
        let s = (spunto ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? personalizzato : s
    }

    /// Cancella il promemoria settimanale.
    public func cancella() {
        centro.removePendingNotificationRequests(withIdentifiers: [Self.identificatoreRiflessione])
        log.info("Promemoria cancellato")
    }
}
