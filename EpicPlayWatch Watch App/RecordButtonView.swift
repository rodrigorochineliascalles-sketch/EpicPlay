//
//  RecordButtonView.swift
//  EpicPlay
//
//  Created by user289202 on 1/13/26.
//
import SwiftUI

struct RecordButtonView: View {

    let enabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                } else {
                    Text("GRABAR")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .disabled(!enabled)
    }
}
