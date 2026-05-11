//
//  BundleToken.swift
//  ChildSDK
//

import Foundation

private final class _ChildSDKBundleToken {}

extension Bundle {
    static let childSDK: Bundle = {
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle(for: _ChildSDKBundleToken.self)
        #endif
    }()
}
