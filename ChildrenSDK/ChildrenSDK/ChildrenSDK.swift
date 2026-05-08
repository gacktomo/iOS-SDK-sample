//
//  ChildrenSDK.swift
//  ChildrenSDK
//

import Foundation
import UISDK

#if canImport(UIKit)
import UIKit
import AVFoundation
#endif

public enum ChildrenSDK {
    /// Info.plist key on the host app. Optional. When set, the SDK shows the
    /// downloaded image on the splash screen during initialization.
    public static let splashImageURLInfoKey = "ChildrenSDKSplashImageURL"

    #if canImport(UIKit)
    @MainActor
    public static func presentHelloWorld() {
        initialize {
            UISDK.presentWebView { action in
                switch action {
                case "launchCamera":
                    ChildrenSDK.presentWebView()
                default:
                    break
                }
            }
        }
    }

    /// Show a splash screen while the SDK "initializes". Currently the
    /// initialization just waits 2 seconds before invoking `completion`.
    @MainActor
    private static func initialize(completion: @escaping @MainActor () -> Void) {
        guard let top = topViewController() else {
            completion()
            return
        }
        let imageURL = (Bundle.main.object(forInfoDictionaryKey: splashImageURLInfoKey) as? String)
            .flatMap { $0.isEmpty ? nil : URL(string: $0) }
        let splash = SplashViewController(imageURL: imageURL)
        splash.modalPresentationStyle = .fullScreen
        top.present(splash, animated: false) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                splash.dismiss(animated: false) {
                    completion()
                }
            }
        }
    }

    /// Present ChildrenSDK's own WebView (camera launch + close) on top of the
    /// current view stack via UISDK.
    @MainActor
    public static func presentWebView() {
        let htmlURL = Bundle.module.url(forResource: "children", withExtension: "html")
        UISDK.presentWebView(htmlURL: htmlURL) { action in
            switch action {
            case "launchCamera":
                launchCamera()
            default:
                break
            }
        }
    }

    @MainActor
    private static func launchCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentCameraOverlay()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        presentCameraOverlay()
                    } else {
                        showCameraDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showCameraDeniedAlert()
        @unknown default:
            showCameraDeniedAlert()
        }
    }

    @MainActor
    private static func presentCameraOverlay() {
        guard let top = topViewController() else { return }
        let vc = CameraOverlayViewController()
        vc.modalPresentationStyle = .fullScreen
        top.present(vc, animated: true)
    }

    @MainActor
    private static func showCameraDeniedAlert() {
        guard let top = topViewController() else { return }
        let alert = UIAlertController(
            title: "カメラを利用できません",
            message: "設定アプリからカメラの利用を許可してください。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        top.present(alert, animated: true)
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
