//
//  ChildrenSDK.swift
//  ChildrenSDK
//

import Foundation
import UISDK

#if canImport(UIKit)
import UIKit
#endif

public enum ChildrenSDK {
    #if canImport(UIKit)
    @MainActor
    public static func presentHelloWorld() {
        UISDK.presentWebView { action in
            switch action {
            case "launchCamera":
                ChildrenSDK.presentWebView()
            default:
                break
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
        guard let top = topViewController() else { return }

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let alert = UIAlertController(
                title: "カメラ起動",
                message: "この端末ではカメラを利用できません（シミュレータなど）。",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            top.present(alert, animated: true)
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        top.present(picker, animated: true)
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
