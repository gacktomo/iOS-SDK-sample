//
//  ContentView.swift
//  demo
//

import SwiftUI
import ParentSDK

struct ContentView: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    fileprivate struct Tile: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
        let action: (() -> Void)?
    }

    private var tiles: [Tile] {
        [
            Tile(title: "Open SDK", systemImage: "sparkles") {
                ParentSDK.presentChild()
            },
            Tile(title: "Feature 2", systemImage: "square.grid.2x2", action: nil),
            Tile(title: "Feature 3", systemImage: "bolt", action: nil),
            Tile(title: "Feature 4", systemImage: "bell", action: nil),
            Tile(title: "Feature 5", systemImage: "gear", action: nil),
            Tile(title: "Feature 6", systemImage: "star", action: nil),
            Tile(title: "Feature 7", systemImage: "heart", action: nil),
            Tile(title: "Feature 8", systemImage: "bookmark", action: nil),
            Tile(title: "Feature 9", systemImage: "tray", action: nil),
        ]
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Super App")
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(tiles) { tile in
                    TileButton(tile: tile)
                }
            }

            SkeletonSection(title: "Recommended")
            SkeletonSection(title: "Recent Activity")

            Spacer()
        }
        .padding()
    }
}

private struct SkeletonSection: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { _ in
                    SkeletonRow()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum SkeletonStyle {
    static let cardFill = Color.gray.opacity(0.08)
    static let blockStrong = Color.gray.opacity(0.2)
    static let blockWeak = Color.gray.opacity(0.15)
}

private struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(SkeletonStyle.blockStrong)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(SkeletonStyle.blockStrong)
                    .frame(height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(SkeletonStyle.blockWeak)
                    .frame(height: 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 60)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(SkeletonStyle.cardFill)
        )
    }
}

private struct TileButton: View {
    let tile: ContentView.Tile

    private var isDisabled: Bool { tile.action == nil }

    var body: some View {
        Button(action: { tile.action?() }) {
            VStack(spacing: 8) {
                Image(systemName: tile.systemImage)
                    .font(.title2)
                Text(tile.title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDisabled ? SkeletonStyle.cardFill : Color.accentColor.opacity(0.15))
            )
            .foregroundStyle(isDisabled ? SkeletonStyle.blockStrong : Color.accentColor)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!isDisabled)
    }
}

#Preview {
    ContentView()
}
