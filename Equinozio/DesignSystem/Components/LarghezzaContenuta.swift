//
//  LarghezzaContenuta.swift
//  Equinozio · DesignSystem
//
//  Colonna di lettura per schermi larghi (iPad e Mac): il contenuto resta
//  entro una larghezza massima e si centra orizzontalmente. Su iPhone non
//  cambia nulla, perché lo schermo è più stretto del limite.
//

import SwiftUI

public extension View {
    /// Limita il contenuto a una colonna di lettura centrata (default 600 pt).
    func larghezzaContenuta(_ massima: CGFloat = 600) -> some View {
        frame(maxWidth: massima)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
