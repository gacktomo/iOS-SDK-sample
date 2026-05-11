//
//  HTMLCameraViewController.swift
//  ChildSDK
//

import Foundation

#if canImport(UIKit)
import UIKit
import WebKit

/// HTML/JS-only camera preview. Uses WKWebView + `getUserMedia` to render the
/// camera feed inside the WebView, with no native AVCaptureSession.
///
/// Permission notes:
/// - The iOS-level camera permission (NSCameraUsageDescription) is asked once
///   the first time the app accesses the camera. After that, the OS does not
///   re-prompt for the lifetime of the install (unless the user revokes it).
/// - WKWebView has its own per-origin media capture permission layer on top of
///   that OS permission. Without `WKUIDelegate
///   .webView(_:requestMediaCapturePermissionFor:initiatedByFrame:type:decisionHandler:)`,
///   WKWebView shows its own permission dialog on every `getUserMedia` call.
/// - Implementing the delegate and returning `.grant` suppresses the WKWebView
///   dialog. The OS dialog still appears the first time only.
final class HTMLCameraViewController: UIViewController, WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate {
    private static let bridgeName = "uiBridge"

    /// Shared across WebView instances so any cached media permission state
    /// (and cookies / network stack) is reused on subsequent opens instead of
    /// being torn down with the previous WebView.
    private static let sharedProcessPool = WKProcessPool()

    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let userContentController = WKUserContentController()
        userContentController.add(self, name: Self.bridgeName)

        let config = WKWebViewConfiguration()
        config.userContentController = userContentController
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.processPool = Self.sharedProcessPool
        config.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        let asyncSel = Selector(("webView:decideMediaCapturePermissionsForOrigin:initiatedBy:type:decisionHandler:"))
        let oldSel = Selector(("webView:requestMediaCapturePermissionForOrigin:initiatedByFrame:type:decisionHandler:"))
        NSLog("[ChildSDK] HTMLCameraViewController viewDidLoad uiDelegate=\(String(describing: webView.uiDelegate)) respondsAsync=\(webView.uiDelegate?.responds(to: asyncSel) ?? false) respondsOld=\(webView.uiDelegate?.responds(to: oldSel) ?? false)")
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        self.webView = webView

        if let url = Bundle.childSDK.url(forResource: "camera-html", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: Self.bridgeName)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("[ChildSDK] HTMLCameraViewController didFinish url=\(String(describing: webView.url?.absoluteString))")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("[ChildSDK] HTMLCameraViewController didFail error=\(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("[ChildSDK] HTMLCameraViewController didFailProvisionalNavigation error=\(error.localizedDescription)")
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == Self.bridgeName,
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        switch action {
        case "close":
            dismiss(animated: true)
        default:
            break
        }
    }

    // MARK: - WKUIDelegate

    // Suppress WKWebView's per-request media permission dialog. The OS-level
    // NSCameraUsageDescription prompt still appears on the first use.
    // The iOS 26 SDK renames the older `requestMediaCapturePermissionFor`
    // completion-handler form to this async `decideMediaCapturePermissionsFor`
    // signature; implementing the old one collides on the same ObjC selector
    // and gets rejected as an optional requirement mismatch.
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView,
                 decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
                 initiatedBy frame: WKFrameInfo,
                 type: WKMediaCaptureType) async -> WKPermissionDecision {
        NSLog("[ChildSDK] WKUIDelegate.decideMediaCapturePermissionsFor origin=\(origin.host):\(origin.port)/\(origin.protocol) type=\(type.rawValue) -> .grant")
        return .grant
    }
}
#endif
