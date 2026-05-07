//
//  ParentSDK.swift
//  ParentSDK
//

import Foundation
import ChildrenSDK

public enum ParentSDK {
    #if canImport(UIKit)
    @MainActor
    public static func presentChildren() {
        ChildrenSDK.presentHelloWorld()
    }
    #endif
}
