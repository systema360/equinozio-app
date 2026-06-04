//
//  EsportaDiario.swift
//  Equinozio · Domain
//
//  Formatta le pagine del diario in testo semplice condivisibile.
//

import Foundation

public enum EsportaDiario {
    public static func testo(da pagine: [Pagina]) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "EEEE d MMMM yyyy · HH:mm"

        return pagine.map { p -> String in
            var blocco = formatter.string(from: p.dataCreazione) + "\n" + p.testo
            let tag = p.etichette
                .sorted { $0.rawValue < $1.rawValue }
                .map(\.titolo)
                .joined(separator: ", ")
            if !tag.isEmpty {
                blocco += "\nCerchi: " + tag
            }
            return blocco
        }
        .joined(separator: "\n\n———\n\n")
    }
}
