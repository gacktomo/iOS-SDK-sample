# ChildSDK XCFramework ビルド & 配布手順書（内部向け）

本ドキュメントは SDK 開発者向け。リポジトリから `ChildSDK.xcframework` をビルドし、配布するまでの手順を記載します。

> ChildSDK 利用者（ParentSDK チーム）向け: [../dist/README.md](../dist/README.md)（配布 zip に同梱）

---

## 1. 配布物と責務

| Framework | 種別 | 配布責務 | 備考 |
| --- | --- | --- | --- |
| **ChildSDK.xcframework** | static | **本チームの納品物** | UISDK のシンボル + リソースを焼き込み済み |
| UISDK.xcframework | static | 外部ベンダ提供 | 現状はリポジトリ内の仮実装 |
| ParentSDK.xcframework | dynamic | 別チームの責務 | demo 動作確認用に本リポジトリでも生成 |

ホストアプリは ParentSDK.xcframework のみを Embed する想定。ParentSDK が ChildSDK（さらに UISDK）を内部で吸収して再配布します。

```
[外部ベンダ]   UISDK.xcframework        (static)
                      ↓ static link + resource copy
[本チーム]     ChildSDK.xcframework     (static)        ← 納品物
                      ↓ static link + resource copy
[別チーム]     ParentSDK.xcframework    (dynamic)
                      ↓ Embed & Sign
[ホストアプリ] App
```

---

## 2. 環境

| 項目 | 推奨 |
| --- | --- |
| macOS | 14 以上 |
| Xcode | 15 以上 |
| Swift | プロジェクト設定で `SWIFT_VERSION = 5.9` |
| iOS デプロイメントターゲット | 15.0 |

---

## 3. リポジトリ構成

```
.
├── UISDK/                    # 仮実装 (Package.swift のみ、type: .static)
├── ChildSDK/                 # 本チームのモジュール (Package.swift + .xcodeproj)
├── ParentSDK/                # demo 動作確認用 (Package.swift + .xcodeproj)
├── demo/                     # 動作確認アプリ
├── scripts/
│   └── build-xcframeworks.sh # XCFramework ビルドスクリプト
└── docs/
```

各 .xcodeproj は Local Swift Package Reference 経由で隣接モジュールを参照しています:
- `ChildSDK.xcodeproj` → `../UISDK`
- `ParentSDK.xcodeproj` → `../ChildSDK`

---

## 4. ビルド方法

### 4.1 ワンコマンドビルド

```bash
./scripts/build-xcframeworks.sh
```

成果物:
```
build/ChildSDK.xcframework      ← 納品物
build/ParentSDK.xcframework     ← demo 動作確認用
```

ビルドログは `build/work/archive-*.log` に保存されます。

### 4.2 スクリプトの中身（要点）

各モジュールについて以下を実行:

1. **iOS device + iOS Simulator の 2 プラットフォームで `xcodebuild archive`**
   - `BUILD_LIBRARY_FOR_DISTRIBUTION=YES` でモジュール安定性を有効化
   - `SKIP_INSTALL=NO` で archive にフレームワーク本体を含める
2. **依存モジュールのリソースをコピー**
   - SPM の resource bundle (`UISDK_UISDK.bundle` 等) から HTML を `<Module>.framework/` 直下にフラット配置
3. **`_CodeSignature` を削除**
   - リソース変更後の再署名トラブルを避けるため、archive 時の ad-hoc 署名を破棄
4. **`xcodebuild -create-xcframework`** で device/simulator スライスを結合

### 4.3 出力構造（検証済み）

```
ChildSDK.xcframework/
├── Info.plist
├── ios-arm64/
│   └── ChildSDK.framework/
│       ├── ChildSDK              ← UISDK のシンボル焼き込み済み (T _$s5UISDKAAO...)
│       ├── Info.plist
│       ├── Modules/
│       │   └── ChildSDK.swiftmodule/
│       │       ├── arm64-apple-ios.swiftinterface  ← UISDK の import なし
│       │       └── ...
│       ├── login.html            ← ChildSDK のリソース
│       ├── child.html
│       ├── camera-overlay.html
│       └── index.html            ← UISDK のリソース (スクリプトで埋め込み)
└── ios-arm64_x86_64-simulator/
    └── ChildSDK.framework/
        └── (同上)
```

---

## 5. 静的吸収を成立させている技術ポイント

### 5.1 UISDK 側
- `UISDK/Package.swift`: `.library(name: "UISDK", type: .static, ...)` で static library 出力
- `UISDK/UISDK/BundleToken.swift`: `Bundle.module` (SPM 専用) と `Bundle(for: Token.self)` (xcodeproj 経由) を切り替えるヘルパ
- `UISDK.swift`: `Bundle.uiSDK` 経由で `index.html` を解決

### 5.2 ChildSDK 側
- `ChildSDK/Package.swift`: `.library(name: "ChildSDK", type: .static, ...)`
- `ChildSDK/ChildSDK/BundleToken.swift`: 同上
- `ChildSDK.swift` / `CameraOverlayViewController.swift`: `Bundle.childSDK` 経由でリソース解決
- **`@_implementationOnly import UISDK`** ← UISDK を swiftinterface から隠蔽。これにより ChildSDK の利用者側で UISDK モジュールを認識する必要がなくなる
- `ChildSDK.xcodeproj` に UISDK の `XCLocalSwiftPackageReference` を追加 → `xcodebuild archive` 時に UISDK の static library が ChildSDK バイナリに焼き込まれる

### 5.3 リソース解決の仕組み
- 静的リンク後、UISDK のクラス（`_UISDKBundleToken` 等）は ChildSDK.framework のバイナリ内に存在
- `Bundle(for: _UISDKBundleToken.self)` は **ChildSDK.framework** を返す
- ChildSDK.framework 直下に `index.html` が配置されているので解決成功

ParentSDK が ChildSDK を吸収する際も同じパターン。すべてのリソースが ParentSDK.framework 直下に集まり、`Bundle(for:)` も ParentSDK.framework を返すので動作する。

---

## 6. 検証手順

### 6.1 swiftinterface に UISDK が露出していないこと

```bash
cat build/ChildSDK.xcframework/ios-arm64/ChildSDK.framework/Modules/ChildSDK.swiftmodule/arm64-apple-ios.swiftinterface | grep -i UISDK
# → 何も出力されないこと
```

### 6.2 UISDK のシンボルが焼き込まれていること

```bash
nm -gU build/ChildSDK.xcframework/ios-arm64/ChildSDK.framework/ChildSDK | grep UISDK
# → _$s5UISDKAAO14presentWebView... 等が出ること
```

### 6.3 リソースが揃っていること

```bash
ls build/ChildSDK.xcframework/ios-arm64/ChildSDK.framework/*.html
# → camera-overlay.html / child.html / index.html / login.html の 4 つ
```

### 6.4 アーキテクチャの確認

```bash
lipo -info build/ChildSDK.xcframework/ios-arm64/ChildSDK.framework/ChildSDK
# → arm64
lipo -info build/ChildSDK.xcframework/ios-arm64_x86_64-simulator/ChildSDK.framework/ChildSDK
# → x86_64 arm64
```

---

## 7. 配布

### 7.1 配布物

```
ChildSDK-<version>.zip
└── ChildSDK.xcframework/
```

```bash
cd build
zip -ry ChildSDK-1.0.0.zip ChildSDK.xcframework
```

### 7.2 SPM `binaryTarget` 用の checksum

```bash
swift package compute-checksum build/ChildSDK-1.0.0.zip
```

ParentSDK チーム側の `Package.swift` 例:
```swift
.binaryTarget(
    name: "ChildSDK",
    url: "https://example.com/sdk/1.0.0/ChildSDK-1.0.0.zip",
    checksum: "..."
)
```

### 7.3 配布チャネル候補

- 社内 GitHub Releases にタグ付きアセットとして添付
- 社内 Artifactory / S3 に置いて URL 配布
- 直接 zip を渡す（社内のみ）

### 7.4 バージョニング

`MAJOR.MINOR.PATCH` の SemVer。CHANGELOG を `docs/CHANGELOG.md`（必要に応じて作成）で管理。

---

## 8. 仮 UISDK と本物の UISDK 受領後の差分

### 現状（仮 UISDK）
- `UISDK/` ディレクトリの Package.swift から static library を都度ビルド
- ChildSDK.xcodeproj は `XCLocalSwiftPackageReference "../UISDK"`

### 本物の UISDK.xcframework が届いた後
ベンダ提供形態によって対応が分岐。**受領前にベンダと擦り合わせ必須**:

| 受領形態 | 対応 |
| --- | --- |
| **static XCFramework** | `UISDK/` ディレクトリを削除し、ChildSDK.xcodeproj の SPM ref を ベンダ XCFramework のリンク参照に置き換え |
| **dynamic XCFramework** | シンボル焼き込み不可。ベンダに static 版を依頼するか、配布形態を変更（ChildSDK.xcframework の中に nested で UISDK.xcframework を含める等） |
| **リソース内包/非内包** | スクリプトの `copy_dependency_resources` で扱う bundle 名を調整 |

### ベンダ確認事項チェックリスト
- [ ] XCFramework は static か dynamic か
- [ ] iOS device (arm64) + iOS Simulator (arm64, x86_64) の両スライスを含むか
- [ ] リソース（HTML 等）が framework 直下に同梱されているか
- [ ] `BUILD_LIBRARY_FOR_DISTRIBUTION = YES` でビルドされているか（swiftinterface が含まれるか）
- [ ] dSYM が同梱されるか（クラッシュレポート用）
- [ ] 公開 API がモジュール境界をまたぐ Swift 型を使っていないか（`@_implementationOnly` で隠蔽できるか）

---

## 9. リリースチェックリスト

- [ ] `swift build` が UISDK / ChildSDK / ParentSDK のすべてで通る
- [ ] `./scripts/build-xcframeworks.sh` がエラーなく完走する
- [ ] §6 の検証コマンドがすべて期待通り
- [ ] demo アプリで全フローが動作する
- [ ] CHANGELOG が更新されている
- [ ] バージョンタグが Git に切られている
- [ ] zip / checksum が配布チャネルにアップロードされている

---

## 10. 既知の事項

- ビルド時に `using '@_implementationOnly' without enabling library evolution` の警告が SPM ビルドで出るが、`xcodebuild archive` 時には `BUILD_LIBRARY_FOR_DISTRIBUTION=YES` が指定されるため XCFramework 配布物では出ない。SPM ビルドは開発時の確認用。
- `_CodeSignature` を archive 後に削除している。Apple Distribution 証明書で再署名する場合はビルドスクリプトに `codesign` ステップを追加する必要がある。
- ParentSDK.xcframework の生成ロジックは demo 検証用。本来 ParentSDK は別チームが自前でビルドする想定なので、本リポジトリの ParentSDK 構成は参考情報。
