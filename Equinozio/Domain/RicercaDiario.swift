//
//  RicercaDiario.swift
//  Equinozio · Domain
//
//  Filtro puro delle pagine del diario: per cerchio e/o parola chiave.
//

import Foundation

public nonisolated enum RicercaDiario {
    public static func filtra(_ pagine: [Pagina], cerchio: TipoCerchio?, ricerca: String) -> [Pagina] {
        let q = ricerca.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return pagine.filter { p in
            let okCerchio = cerchio == nil || p.etichette.contains(cerchio!)
            let okRicerca = q.isEmpty || p.testo.lowercased().contains(q)
            return okCerchio && okRicerca
        }
    }
}
