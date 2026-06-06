//
//  SpuntoStore.swift
//  Equinozio · Domain
//
//  Genera lo Spunto della settimana UNA volta e lo mette in cache:
//  · @Model Insight (sincronizzato iCloud)
//  · snapshot App Group (per il widget)
//  e ricarica le timeline del widget.
//

import Foundation
import SwiftData
import UserNotifications
import WidgetKit

@MainActor
public enum SpuntoStore {

    nonisolated public static func esisteSpunto(per settimanaID: String, in insights: [Insight]) -> Bool {
        insights.contains { $0.settimanaID == settimanaID }
    }

    /// Forza la rigenerazione per la settimana corrente (usata al salvataggio di una Riflessione).
    public static func rigenera(contesto: ModelContext, adesso: Date = .now) async {
        let sid = Settimana.id(per: adesso)
        let esistenti = (try? contesto.fetch(FetchDescriptor<Insight>())) ?? []
        for vecchio in esistenti where vecchio.settimanaID == sid {
            contesto.delete(vecchio)
        }

        let riflessioni = (try? contesto.fetch(
            FetchDescriptor<Riflessione>(sortBy: [SortDescriptor(\.data, order: .reverse)])
        )) ?? []
        let decisioni = (try? contesto.fetch(FetchDescriptor<Decisione>())) ?? []

        // L'equilibrio del widget va tenuto allineato a prescindere dallo Spunto.
        let equilibrio = riflessioni.first?.equilibrio ?? 50

        guard let spunto = await MotoreSpunti.shared.spuntoPrincipale(
            riflessioni: riflessioni, decisioni: decisioni, adesso: adesso
        ) else {
            try? contesto.save()
            WidgetSnapshot.aggiornaEquilibrio(equilibrio)
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        let modello = Insight(tipo: spunto.tipo, testo: spunto.testo)
        modello.settimanaID = sid
        contesto.insert(modello)
        try? contesto.save()

        // Pota gli Insight vecchi: tieni i 8 più recenti.
        let tutti = (try? contesto.fetch(
            FetchDescriptor<Insight>(sortBy: [SortDescriptor(\.dataGenerazione, order: .reverse)])
        )) ?? []
        for vecchio in tutti.dropFirst(8) { contesto.delete(vecchio) }
        try? contesto.save()

        WidgetSnapshot.aggiorna(
            equilibrio: equilibrio,
            spuntoTesto: spunto.testo,
            spuntoTipo: spunto.tipo.rawValue,
            settimanaID: sid
        )
        WidgetCenter.shared.reloadAllTimelines()

        // Se il promemoria è attivo, aggiorna la notifica col nuovo Spunto.
        let difese = UserDefaults.standard
        if difese.bool(forKey: "promemoriaRiflessione") {
            let stato = await PromemoriaService.shared.statoAutorizzazione()
            if stato == .authorized || stato == .provisional {
                let giorno = difese.object(forKey: "promemoriaGiorno") as? Int ?? 1
                let ora = difese.object(forKey: "promemoriaOra") as? Int ?? 19
                let minuto = difese.object(forKey: "promemoriaMinuto") as? Int ?? 0
                let personalizzato = difese.string(forKey: "promemoriaTesto")
                    ?? "Cinque minuti per la tua riflessione settimanale."
                await PromemoriaService.shared.schedulaRiflessione(
                    giorno: giorno, ora: ora, minuto: minuto,
                    titolo: "Riflessione settimanale",
                    corpo: PromemoriaService.corpo(spunto: spunto.testo, personalizzato: personalizzato)
                )
            }
        }
    }

    /// Rigenera solo se non c'è già uno Spunto per la settimana corrente (usata all'apertura app).
    public static func aggiornaSeNecessario(contesto: ModelContext, adesso: Date = .now) async {
        let sid = Settimana.id(per: adesso)
        let esistenti = (try? contesto.fetch(FetchDescriptor<Insight>())) ?? []
        if esisteSpunto(per: sid, in: esistenti) {
            // Lo Spunto c'è già, ma l'equilibrio può essere cambiato (es. modifica
            // di una riflessione): rinfresca comunque il widget.
            let riflessioni = (try? contesto.fetch(
                FetchDescriptor<Riflessione>(sortBy: [SortDescriptor(\.data, order: .reverse)])
            )) ?? []
            WidgetSnapshot.aggiornaEquilibrio(riflessioni.first?.equilibrio ?? 50)
            WidgetCenter.shared.reloadAllTimelines()
            return
        }
        await rigenera(contesto: contesto, adesso: adesso)
    }
}
