//
//  BundleToken.swift
//  UISDK
//

import Foundation

private final class _UISDKBundleToken {}

extension Bundle {
    static let uiSDK: Bundle = {
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle(for: _UISDKBundleToken.self)
        #endif
    }()
}
