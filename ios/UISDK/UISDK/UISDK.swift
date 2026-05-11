//
//  UISDK.swift
//  UISDK
//

import Foundation

#if canImport(UIKit)
import UIKit
import WebKit

public enum UISDK {
    /// Present a WebView modally.
    ///
    /// - Parameters:
    ///   - htmlURL: HTML file URL to load. Pass `nil` to use UISDK's bundled default.
    ///   - onAction: Called when the WebView posts a non-built-in action via the
    ///     `uiBridge` message handler. The `close` action is handled internally
    ///     (dismisses the WebView) and is not forwarded.
    @MainActor
    public static func presentWebView(
        htmlURL: URL? = nil,
        onAction: (@MainActor (String) -> Void)? = nil
    ) {
        guard let top = topViewController() else { return }
        let url = htmlURL ?? Bundle.uiSDK.url(forResource: "index", withExtension: "html")
        let vc = WebViewController(htmlURL: url, onAction: onAction)
        vc.modalPresentationStyle = .fullScreen
        top.present(vc, animated: true)
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first
        let root = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? scene?.windows.first?.rootViewController
        var top = root
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

private final class WebViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    private static let bridgeName = "uiBridge"

    private let htmlURL: URL?
    private let onAction: (@MainActor (String) -> Void)?
    private var webView: WKWebView!

    init(htmlURL: URL?, onAction: (@MainActor (String) -> Void)?) {
        self.htmlURL = htmlURL
        self.onAction = onAction
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

        let config = WKWebViewConfiguration()
        config.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
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

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == Self.bridgeName else { return }
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        switch action {
        case "close":
            dismiss(animated: true)
        default:
            onAction?(action)
        }
    }
}
#endif
