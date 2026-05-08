//
//  SplashViewController.swift
//  ChildrenSDK
//

import Foundation

#if canImport(UIKit)
import UIKit

final class SplashViewController: UIViewController {
    private static let displayDuration: TimeInterval = 2.0
    private static let fadeDuration: TimeInterval = 0.3

    private let imageURL: URL?
    private let onReady: () -> Void
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private var didStartCompletionTimer = false

    init(imageURL: URL?, onReady: @escaping () -> Void) {
        self.imageURL = imageURL
        self.onReady = onReady
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 1.0, green: 0.973, blue: 0.882, alpha: 1.0)
        if traitCollection.userInterfaceStyle == .dark {
            view.backgroundColor = UIColor(red: 0.165, green: 0.141, blue: 0.063, alpha: 1.0)
        }

        titleLabel.text = "ChildrenSDK"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel()
        subtitle.text = "起動中..."
        subtitle.font = .systemFont(ofSize: 14, weight: .regular)
        subtitle.textColor = .secondaryLabel
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        indicator.translatesAutoresizingMaskIntoConstraints = false

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // Reserve the image slot in the stack from the start so layout doesn't
        // shift when the downloaded image fades in.
        imageView.isHidden = (imageURL == nil)
        imageView.alpha = 0

        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, indicator, subtitle])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 120),
            imageView.heightAnchor.constraint(equalToConstant: 120),
        ])

        if let url = imageURL {
            loadImage(from: url)
        } else {
            startCompletionTimer()
        }
    }

    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if let data, let image = UIImage(data: data) {
                    self.imageView.image = image
                    UIView.animate(withDuration: Self.fadeDuration) {
                        self.imageView.alpha = 1.0
                    }
                }
                // Whether the image loaded or not, begin the visible-duration
                // timer now so the splash holds for a fixed time post-load.
                self.startCompletionTimer()
            }
        }.resume()
    }

    private func startCompletionTimer() {
        guard !didStartCompletionTimer else { return }
        didStartCompletionTimer = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.displayDuration) { [weak self] in
            self?.onReady()
        }
    }
}
#endif
