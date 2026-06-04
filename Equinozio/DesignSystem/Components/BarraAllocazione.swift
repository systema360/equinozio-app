//
//  BarraAllocazione.swift
//  Equinozio · DesignSystem · Components
//
//  Riga del check-in settimanale: pallino colorato + nome + percentuale + barra sottile.
//

import SwiftUI

public struct BarraAllocazione: View {

    public let cerchio: TipoCerchio
    @Binding public var percentuale: Int  // 0-100

    public init(cerchio: TipoCerchio, percentuale: Binding<Int>) {
        self.cerchio = cerchio
        self._percentuale = percentuale
    }

    public var body: some View {
        VStack(spacing: S.x2) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: S.x2) {
                    Circle()
                        .fill(cerchio.colore)
                        .frame(width: 8, height: 8)
                    Text(cerchio.titoloRiflessione)
                        .font(.equinozio(.corpoMedio))
                        .foregroundStyle(Color.inchiostro)
                }

                Spacer()

                Text("\(percentuale)%")
                    .font(.system(size: 17, weight: .thin))
                    .monospacedDigit()
                    .foregroundStyle(Color.inchiostro)
                    .tracking(-0.2)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.lineaSottile)
                        .frame(height: 4)
                    Capsule()
                        .fill(cerchio.colore)
                        .frame(width: proxy.size.width * CGFloat(percentuale) / 100, height: 4)
                }
            }
            .frame(height: 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cerchio.titoloRiflessione)
        .accessibilityValue("\(percentuale) percento")
    }
}

#Preview {
    struct Prova: View {
        @State var v1 = 8
        @State var v2 = 62
        var body: some View {
            VStack(spacing: 16) {
                BarraAllocazione(cerchio: .passione, percentuale: $v1)
                BarraAllocazione(cerchio: .talento, percentuale: $v2)
            }
            .padding()
        }
    }
    return Prova()
}
