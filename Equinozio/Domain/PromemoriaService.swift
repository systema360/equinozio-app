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

    private init() {}

    /// Stato corrente del permesso notifiche.
    public func statoAutorizzazione() async -> UNAuthorizationStatus {
        let settings = await centro.notificationSettings()
        return settings.authorizationStatus
    }

    /// Chiede il permesso · se viene concesso, schedula automaticamente il promemoria.
    @discardableResult
    public func chiediEAttiva() async -> Bool {
        do {
            let concesso = try await centro.requestAuthorization(options: [.alert, .sound, .badge])
            if concesso {
                await schedulaRiflessione()
            }
            return concesso
        } catch {
            log.warning("Errore richiesta autorizzazione: \(error.localizedDescription)")
            return false
        }
    }

    /// Programma il promemoria settimanale (domenica 19:00).
    /// Rimuove eventuali notifiche precedenti per evitare duplicati.
    public func schedulaRiflessione() async {
        centro.removePendingNotificationRequests(withIdentifiers: [Self.identificatoreRiflessione])

        let contenuto = UNMutableNotificationContent()
        contenuto.title = "È domenica."
        contenuto.body = "Cinque minuti per la tua riflessione settimanale."
        contenuto.sound = .default
        contenuto.threadIdentifier = "riflessione"

        var componenti = DateComponents()
        componenti.weekday = 1   // Domenica (Calendar.current con weekday 1 = Sunday)
        componenti.hour = 19
        componenti.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: componenti, repeats: true)
        let richiesta = UNNotificationRequest(
            identifier: Self.identificatoreRiflessione,
            content: contenuto,
            trigger: trigger
        )

        do {
            try await centro.add(richiesta)
            log.info("Promemoria settimanale programmato · domenica 19:00")
        } catch {
            log.warning("Impossibile programmare promemoria: \(error.localizedDescription)")
        }
    }

    /// Cancella il promemoria settimanale.
    public func cancella() {
        centro.removePendingNotificationRequests(withIdentifiers: [Self.identificatoreRiflessione])
        log.info("Promemoria cancellato")
    }
}
