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

        // Le misure del widget vanno tenute allineate a prescindere dallo Spunto.
        let misureCorrenti = misure(da: riflessioni)

        guard let spunto = await MotoreSpunti.shared.spuntoPrincipale(
            riflessioni: riflessioni, decisioni: decisioni, adesso: adesso
        ) else {
            try? contesto.save()
            WidgetSnapshot.aggiornaMisure(misureCorrenti)
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
            misure: misureCorrenti,
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

    /// Costruisce le misure del widget dalle riflessioni (ordinate dalla più recente).
    nonisolated static func misure(da riflessioni: [Riflessione]) -> MisureWidget {
        let equilibri = riflessioni.map(\.equilibrio)
        let quote = riflessioni.first.map {
            (passione: $0.quotaPassione, talento: $0.quotaTalento,
             missione: $0.quotaMissione, professione: $0.quotaProfessione)
        }
        return MisureWidget.deriva(equilibri: equilibri, quotePrimo: quote)
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
            WidgetSnapshot.aggiornaMisure(misure(da: riflessioni))
            WidgetCenter.shared.reloadAllTimelines()
            return
        }
        await rigenera(contesto: contesto, adesso: adesso)
    }
}
