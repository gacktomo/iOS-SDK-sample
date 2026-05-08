//
//  LoginViewController.swift
//  ChildrenSDK
//

import Foundation

#if canImport(UIKit)
import UIKit
import WebKit
import LocalAuthentication

final class LoginViewController: UIViewController, WKScriptMessageHandler {
    private static let bridgeName = "uiBridge"

    private let htmlURL: URL?
    private let imageURL: URL?
    private let onLogin: () -> Void
    private var webView: WKWebView!

    init(htmlURL: URL?, imageURL: URL?, onLogin: @escaping () -> Void) {
        self.htmlURL = htmlURL
        self.imageURL = imageURL
        self.onLogin = onLogin
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let userContentController = WKUserContentController()
        userContentController.add(self, name: Self.bridgeName)

        var config: [String: Any] = [:]
        if let imageURL { config["splashImageURL"] = imageURL.absoluteString }
        if !config.isEmpty,
           let data = try? JSONSerialization.data(withJSONObject: config),
           let json = String(data: data, encoding: .utf8) {
            let script = WKUserScript(
                source: "window.SDK_CONFIG = \(json);",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            userContentController.addUserScript(script)
        }

        let webConfig = WKWebViewConfiguration()
        webConfig.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: webConfig)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        self.webView = webView

        if let url = htmlURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: Self.bridgeName)
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == Self.bridgeName else { return }
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        switch action {
        case "close":
            dismiss(animated: true)
        case "login":
            authenticateAndProceed()
        default:
            break
        }
    }

    private func authenticateAndProceed() {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        var error: NSError?
        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
        guard context.canEvaluatePolicy(policy, error: &error) else {
            showBiometricsUnavailableAlert()
            return
        }
        context.evaluatePolicy(policy, localizedReason: "ログインのため本人確認を行います") { [weak self] success, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    self.onLogin()
                }
                // On failure/cancel: stay on the login screen silently.
            }
        }
    }

    private func showBiometricsUnavailableAlert() {
        let alert = UIAlertController(
            title: "生体認証が利用できません",
            message: "設定アプリから Face ID / Touch ID を有効化してください。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
#endif
