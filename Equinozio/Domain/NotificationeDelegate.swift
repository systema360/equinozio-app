//
//  NotificationeDelegate.swift
//  Equinozio · Domain
//
//  Instrada il tap sulla notifica (o l'azione "Rifletti ora") verso la Riflessione.
//

import Foundation
import UserNotifications

final class NotificationeDelegate: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationeDelegate()

    /// Collegata dall'app al router (es. { scheda in router.scheda = scheda }).
    var onApri: ((Scheda) -> Void)?

    private override init() { super.init() }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.actionIdentifier
        if id == PromemoriaService.azioneRifletti || id == UNNotificationDefaultActionIdentifier {
            DispatchQueue.main.async { [weak self] in
                self?.onApri?(.riflessione)
            }
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
