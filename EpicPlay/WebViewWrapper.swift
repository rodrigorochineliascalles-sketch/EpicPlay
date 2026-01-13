import SwiftUI

struct WebViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> WebViewController {
        return WebViewController()
    }

    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        // No necesitas actualizar nada por ahora
    }
}
//
//  WebViewWrapper.swift
//  EpicPlay
//
//  Created by Rodrigo Rochin on 16/07/25.
//

