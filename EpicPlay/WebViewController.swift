import UIKit
import WebKit
import Photos

final class WebViewController: UIViewController, WKScriptMessageHandler {
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) Configurar content controller + handlers
        let contentController = WKUserContentController()
        contentController.add(self, name: "compartirDesdeNativo")
        contentController.add(self, name: "descargarDesdeNativo")

        // 2) Inyectar puente JS para que la web llame a los handlers nativos
        let bridgeJS = """
        (function() {
          window.epicPlayNative = window.epicPlayNative || {};

          window.epicPlayNative.descargarVideo = function(url) {
            try {
              if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.descargarDesdeNativo) {
                window.webkit.messageHandlers.descargarDesdeNativo.postMessage(url);
              } else {
                console.log('iOS bridge not available: descargarDesdeNativo');
              }
            } catch (e) {
              console.error('descargarVideo bridge error:', e);
            }
          };

          window.epicPlayNative.compartirVideo = function(url) {
            try {
              if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.compartirDesdeNativo) {
                window.webkit.messageHandlers.compartirDesdeNativo.postMessage(url);
              } else {
                console.log('iOS bridge not available: compartirDesdeNativo');
              }
            } catch (e) {
              console.error('compartirVideo bridge error:', e);
            }
          };
        })();
        """
        let userScript = WKUserScript(source: bridgeJS, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(userScript)

        // 3) Crear WKWebView con la config
        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)

        // 4) Cargar tu app web
        if let url = URL(string: "https://studio--epic-play.us-central1.hosted.app/") {
            webView.load(URLRequest(url: url))
        } else {
            mostrarAlerta("❌ Error", "URL de la web inválida.")
        }
    }

    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "compartirDesdeNativo":
            guard let videoUrl = message.body as? String else { return }
            compartir(urlString: videoUrl)

        case "descargarDesdeNativo":
            guard let videoUrl = message.body as? String else { return }
            descargarYGuardarEnGaleria(urlString: videoUrl)

        default:
            break
        }
    }

    // MARK: - Compartir
    private func compartir(urlString: String) {
        guard let url = URL(string: urlString) else {
            mostrarAlerta("❌ Error", "La URL del video es inválida.")
            return
        }
        // Mensaje + link (no descarga)
        let texto = "¡Qué jugada! Mírala aquí: \(url.absoluteString)"
        let activityVC = UIActivityViewController(activityItems: [texto], applicationActivities: nil)

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        present(activityVC, animated: true)
    }

    // MARK: - Descargar + Guardar en Fotos
    private func descargarYGuardarEnGaleria(urlString: String) {
        guard let url = URL(string: urlString) else {
            mostrarAlerta("❌ Error", "La URL del video es inválida.")
            return
        }

        // Pedir permiso a Fotos (iOS 14+: authorized/limited)
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self.mostrarAlerta("Permiso denegado", "No se puede guardar el video porque no se otorgó acceso a la galería.")
                }
                return
            }

            // Descargar con URLSession (token de Firebase incluido en la URL)
            let task = URLSession.shared.downloadTask(with: url) { tempLocalURL, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.mostrarAlerta("❌ Error", "No se pudo descargar el video: \(error.localizedDescription)")
                    }
                    return
                }
                guard let tempLocalURL = tempLocalURL else {
                    DispatchQueue.main.async {
                        self.mostrarAlerta("❌ Error", "No se recibió archivo temporal.")
                    }
                    return
                }

                // Copiar a ruta temporal estable con extensión .mp4 (algunos handlers lo requieren)
                let fm = FileManager.default
                let fileName = UUID().uuidString + ".mp4"
                let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

                do {
                    if fm.fileExists(atPath: localURL.path) {
                        try fm.removeItem(at: localURL)
                    }
                    try fm.copyItem(at: tempLocalURL, to: localURL)
                } catch {
                    DispatchQueue.main.async {
                        self.mostrarAlerta("❌ Error", "No se pudo copiar el video: \(error.localizedDescription)")
                    }
                    return
                }

                // Guardar en Fotos
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localURL)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.mostrarAlerta("✅ Video guardado", "El video se ha guardado en tu galería.")
                        } else {
                            self.mostrarAlerta("❌ Error", "No se pudo guardar el video: \(error?.localizedDescription ?? "desconocido").")
                        }
                    }
                }
            }
            task.resume()
        }
    }

    // MARK: - Util
    private func mostrarAlerta(_ titulo: String, _ mensaje: String) {
        let alert = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async { self.present(alert, animated: true) }
    }
}

