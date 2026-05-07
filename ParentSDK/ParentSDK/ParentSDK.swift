//
//  ParentSDK.swift
//  ParentSDK
//

import SwiftUI
import ChildrenSDK

public struct ParentButton: View {
    private let title: String

    public init(title: String = "Open BaaS") {
        self.title = title
    }

    public var body: some View {
        Button(title) {
            #if canImport(UIKit)
            ChildrenSDK.presentHelloWorld()
            #endif
        }
        .buttonStyle(.borderedProminent)
    }
}
