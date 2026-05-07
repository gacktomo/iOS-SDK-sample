//
//  ChildrenSDK.swift
//  ChildrenSDK
//

import Foundation
import UISDK

public enum ChildrenSDK {
    #if canImport(UIKit)
    @MainActor
    public static func presentHelloWorld() {
        UISDK.presentWebView()
    }
    #endif
}
