//
//  CancellazioneDati.swift
//  Equinozio · Domain
//
//  Cancellazione totale dei dati dell'utente: SwiftData e, via sync,
//  il database iCloud privato. CloudKit propaga le cancellazioni a
//  tutti i dispositivi collegati allo stesso Apple ID.
//

import Foundation
import SwiftData

public nonisolated enum CancellazioneDati {

    /// Elimina tutti gli oggetti di tutti i modelli e salva il contesto.
    /// Ordine figli-prima, per non dipendere dalle regole di cascata.
    public static func cancellaTutto(in contesto: ModelContext) throws {
        try contesto.delete(model: Elemento.self)
        try contesto.delete(model: Cerchio.self)
        try contesto.delete(model: Pagina.self)
        try contesto.delete(model: Riflessione.self)
        try contesto.delete(model: Decisione.self)
        try contesto.delete(model: Insight.self)
        try contesto.delete(model: Profilo.self)
        try contesto.save()
    }
}
