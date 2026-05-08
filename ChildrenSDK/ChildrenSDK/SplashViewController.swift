//
//  SplashViewController.swift
//  ChildrenSDK
//

import Foundation

#if canImport(UIKit)
import UIKit

final class SplashViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 1.0, green: 0.973, blue: 0.882, alpha: 1.0)

        let title = UILabel()
        title.text = "ChildrenSDK"
        title.font = .systemFont(ofSize: 24, weight: .bold)
        title.textColor = UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0)
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel()
        subtitle.text = "起動中..."
        subtitle.font = .systemFont(ofSize: 14, weight: .regular)
        subtitle.textColor = .secondaryLabel
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        indicator.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [title, indicator, subtitle])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        if traitCollection.userInterfaceStyle == .dark {
            view.backgroundColor = UIColor(red: 0.165, green: 0.141, blue: 0.063, alpha: 1.0)
        }
    }
}
#endif
