//
//  ChildSDK.swift
//  ChildSDK
//

import Foundation
@_implementationOnly import UISDK

#if canImport(UIKit)
import UIKit
#endif

public enum ChildSDK {
    /// Info.plist key on the host app. Optional. When set, the SDK shows the
    /// downloaded image on the splash screen during initialization.
    public static let splashImageURLInfoKey = "ChildSDKSplashImageURL"

    #if canImport(UIKit)
    @MainActor
    public static func presentHelloWorld() {
        initialize {
            presentLogin {
                presentMainUI()
            }
        }
    }

    @MainActor
    private static func presentLogin(onLogin: @escaping @MainActor () -> Void) {
        guard let top = topViewController() else { return }
        let htmlURL = Bundle.childSDK.url(forResource: "login", withExtension: "html")
        let imageURL = splashImageURL()
        var loginRef: LoginViewController?
        let login = LoginViewController(htmlURL: htmlURL, imageURL: imageURL) {
            loginRef?.dismiss(animated: true) {
                onLogin()
            }
            loginRef = nil
        }
        loginRef = login
        login.modalPresentationStyle = .fullScreen
        top.present(login, animated: true)
    }

    @MainActor
    private static func presentMainUI() {
        UISDK.presentWebView { action in
            switch action {
            case "launchCamera":
                ChildSDK.presentWebView()
            default:
                break
            }
        }
    }

    private static func splashImageURL() -> URL? {
        (Bundle.main.object(forInfoDictionaryKey: splashImageURLInfoKey) as? String)
            .flatMap { $0.isEmpty ? nil : URL(string: $0) }
    }

    @MainActor
    private static func initialize(completion: @escaping @MainActor () -> Void) {
        guard let top = topViewController() else {
            completion()
            return
        }
        let imageURL = splashImageURL()
        var splashRef: SplashViewController?
        let splash = SplashViewController(imageURL: imageURL) {
            splashRef?.dismiss(animated: false) {
                completion()
            }
            splashRef = nil
        }
        splashRef = splash
        splash.modalPresentationStyle = .fullScreen
        top.present(splash, animated: false)
    }

    /// Present ChildSDK's own WebView (camera launch + close) on top of the
    /// current view stack via UISDK.
    @MainActor
    public static func presentWebView() {
        let htmlURL = Bundle.childSDK.url(forResource: "child", withExtension: "html")
        UISDK.presentWebView(htmlURL: htmlURL) { action in
            switch action {
            case "launchCamera":
                launchCamera()
            default:
                break
            }
        }
    }

    /// Present the HTML-based camera page (getUserMedia inside WKWebView).
    /// The iOS camera permission is handled by the WebView itself — the OS
    /// prompt appears on the first call only; WKWebView's per-request dialog
    /// is suppressed by `HTMLCameraViewController`'s WKUIDelegate.
    @MainActor
    private static func launchCamera() {
        guard let top = topViewController() else { return }
        let vc = HTMLCameraViewController()
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
    #endif
}
