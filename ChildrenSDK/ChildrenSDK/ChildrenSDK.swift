//
//  ChildrenSDK.swift
//  ChildrenSDK
//

import Foundation

#if canImport(UIKit)
import UIKit
import SwiftUI

public enum ChildrenSDK {
    @MainActor
    public static func presentHelloWorld() {
        guard let top = topViewController() else { return }
        let host = UIHostingController(rootView: HelloWorldView())
        top.present(host, animated: true)
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

private struct HelloWorldView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Hello, World!")
                .font(.largeTitle).bold()
            Text("from ChildrenSDK")
                .foregroundStyle(.secondary)
            Button("Close") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
#endif
