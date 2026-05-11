# ChildSDK 導入手順書（ParentSDK チーム向け）

本ドキュメントは、ChildSDK.xcframework を **ParentSDK のビルドに取り込んで再配布** する開発者向けの手順書です。

ChildSDK は **static XCFramework** として配布されます。ParentSDK は ChildSDK のシンボル + リソースを内部に静的に吸収し、最終的にホストアプリへは ParentSDK.xcframework のみを配布する想定です。

---

## 1. 配布物

ChildSDK 開発チームから以下が提供されます:

```
ChildSDK-<version>.zip
└── ChildSDK.xcframework/
```

`ChildSDK.xcframework` の特徴:
- **static framework**（バイナリは静的ライブラリ）
- UISDK のシンボル + リソースを内部で吸収済み（外部 UISDK 依存はない）
- iOS device (arm64) + iOS Simulator (arm64, x86_64) を同梱
- Swift モジュール安定性 (`BUILD_LIBRARY_FOR_DISTRIBUTION=YES`) 有効
- 公開 API は `import ChildSDK` のみで利用可能（UISDK は `@_implementationOnly` で隠蔽済み）

---

## 2. ParentSDK への取り込み手順

### 2.1 ChildSDK.xcframework を取り込み

ParentSDK の Xcode プロジェクトに `.xcframework` を配置:

```
ParentSDK/
├── Frameworks/
│   └── ChildSDK.xcframework        ← ここに配置
├── ParentSDK/                       ← ソース
└── ParentSDK.xcodeproj
```

または SPM `binaryTarget` で取り込み:

```swift
// ParentSDK/Package.swift
.binaryTarget(
    name: "ChildSDK",
    url: "https://example.com/sdk/<version>/ChildSDK-<version>.zip",
    checksum: "..."
)

// もしくはローカルパス指定
.binaryTarget(
    name: "ChildSDK",
    path: "Frameworks/ChildSDK.xcframework"
)
```

### 2.2 ParentSDK ターゲットの設定

ParentSDK は **dynamic framework** として最終ホストへ提供する想定なので、ChildSDK は以下のように扱います:

| 項目 | 値 |
| --- | --- |
| **Link Binary With Libraries** | `ChildSDK.xcframework` を追加 |
| **Embed** | **Do Not Embed**（static なので Embed しない） |
| **`import` 文** | `@_implementationOnly import ChildSDK`（公開 API に露出させないため） |

### 2.3 `@_implementationOnly` で隠蔽する理由

ParentSDK の公開 API は **ChildSDK の型を露出させない**設計が前提です。

```swift
// ParentSDK/ParentSDK.swift
import Foundation
@_implementationOnly import ChildSDK

public enum ParentSDK {
    @MainActor
    public static func presentChild() {
        ChildSDK.presentHelloWorld()
    }
}
```

これにより:
- ParentSDK の `swiftinterface` に ChildSDK が出現しない
- ホストアプリは `import ParentSDK` のみで完結（ChildSDK モジュールを認識する必要なし）
- ChildSDK バイナリのシンボルは ParentSDK.framework に静的にマージされる

ParentSDK の公開 API が ChildSDK の型を返したり受け取ったりすると `@_implementationOnly` は使えません。型を返す必要がある場合は、ParentSDK 側で同形のラッパ型を用意してください。

### 2.4 リソースのコピー

ChildSDK.xcframework 直下には以下の HTML が含まれます:
- `login.html` / `child.html` / `camera-overlay.html` (ChildSDK 由来)
- `index.html` (UISDK 由来)

ParentSDK が dynamic framework として最終ビルドされるとき、これらのリソースを **`ParentSDK.framework/` 直下にもコピー** する必要があります。`Bundle(for:)` がリソースを解決できるように、ファイルを framework 直下に置く構成です。

ParentSDK ビルド時に Run Script Phase を追加するか、ParentSDK のビルドスクリプトで以下を実行:

```bash
SLICE="Path/to/ChildSDK.xcframework/ios-arm64/ChildSDK.framework"
DEST="$BUILT_PRODUCTS_DIR/ParentSDK.framework"
cp "${SLICE}"/*.html "${DEST}/"
```

---

## 3. ビルド設定

ParentSDK ターゲットの設定:

| 設定 | 値 |
| --- | --- |
| `BUILD_LIBRARY_FOR_DISTRIBUTION` | `YES` |
| `MACH_O_TYPE` | `mh_dylib`（dynamic、デフォルト） |
| `IPHONEOS_DEPLOYMENT_TARGET` | `15.0` 以上 |
| `SWIFT_VERSION` | `5.9` 以上 |

`SKIP_INSTALL=NO` で archive 時にフレームワーク本体を含めるのを忘れずに。

---

## 4. 公開 API

ChildSDK が提供する `public` API:

| API | 説明 |
| --- | --- |
| `ChildSDK.presentHelloWorld()` | スプラッシュ → ログイン → メイン WebView の一連のフローを起動 |
| `ChildSDK.presentWebView()` | メイン WebView 単体を提示 |
| `ChildSDK.splashImageURLInfoKey` | Info.plist のスプラッシュ画像 URL キー名 (`"ChildSDKSplashImageURL"`) |

すべて `@MainActor`。メインスレッドから呼び出してください。

---

## 5. ホストアプリ側の Info.plist 要件

ChildSDK の機能を有効にするため、最終ホストアプリの Info.plist に以下が必要です。ParentSDK のドキュメントにも引き継いでください:

| キー | 必須 | 用途 |
| --- | --- | --- |
| `NSCameraUsageDescription` | **必須** | ChildSDK の WebView からカメラを起動するため |
| `ChildSDKSplashImageURL` | 任意 | スプラッシュ画像の URL |
| `NSFaceIDUsageDescription` | 任意 | Face ID ログインを使う場合 |

---

## 6. トラブルシュート

| 症状 | 原因 / 対処 |
| --- | --- |
| `Could not find module 'ChildSDK' for target 'arm64-apple-ios-simulator'` | XCFramework のシミュレータスライスが認識されていない。Xcode を再起動 → DerivedData 削除して再ビルド |
| ParentSDK の swiftinterface に `import ChildSDK` が現れる | `@_implementationOnly` を使っていない、または public API が ChildSDK 型を露出している。`@_implementationOnly` を付け、API シグネチャを見直す |
| ParentSDK ビルド時に `library not found for -lChildSDK` | Link Binary With Libraries に追加されていない。General → Frameworks で追加 |
| ParentSDK 実行時に `dyld: Library not loaded: @rpath/ChildSDK.framework` | ChildSDK を `Embed & Sign` にしている（static なので Embed 不要）。`Do Not Embed` に変更 |
| 実行時に `index.html` が見つからずスプラッシュが空白 | UISDK 由来の HTML が ParentSDK.framework にコピーされていない。§2.4 のリソースコピー手順を確認 |
| `using '@_implementationOnly' without enabling library evolution` 警告 | SPM ビルドでのみ出る警告。`xcodebuild archive` で `BUILD_LIBRARY_FOR_DISTRIBUTION=YES` を指定して XCFramework をビルドすれば消える |

---

## 7. アップグレード手順

新しい `ChildSDK.xcframework` を受領したとき:

1. 旧版を削除（`Frameworks/ChildSDK.xcframework` を Move to Trash）
2. 新版を同じ場所に配置
3. SPM `binaryTarget` で取り込んでいる場合は `url` / `checksum` を更新し、Xcode で `File → Packages → Reset Package Caches`
4. CHANGELOG を確認し、API 変更があれば呼び出し箇所を修正
5. 動作確認（demo アプリ等）

