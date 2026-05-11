//
//  ParentSDK.swift
//  ParentSDK
//

import Foundation
import ChildSDK

public enum ParentSDK {
    #if canImport(UIKit)
    @MainActor
    public static func presentChild() {
        ChildSDK.presentHelloWorld()
    }
    #endif
}
