//
//  SplashViewController.swift
//  ChildrenSDK
//

import Foundation

#if canImport(UIKit)
import UIKit

final class SplashViewController: UIViewController {
    private let imageURL: URL?
    private let imageView = UIImageView()
    private let titleLabel = UILabel()

    init(imageURL: URL?) {
        self.imageURL = imageURL
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
        imageView.isHidden = (imageURL == nil)

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
        }
    }

    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.imageView.image = image
                self?.titleLabel.isHidden = true
            }
        }.resume()
    }
}
#endif
