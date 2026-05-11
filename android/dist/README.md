# ChildSDK 導入手順書（ParentSDK チーム向け）

本ドキュメントは、ChildSDK の AAR を **ParentSDK のビルドに取り込んで再配布** する開発者向けの手順書です。

ChildSDK は **AAR + POM**（mini Maven repo 形式）として配布されます。ParentSDK は ChildSDK + UISDK を推移依存として取り込み、最終的にホストアプリへは ParentSDK の AAR のみを配布する想定です。

---

## 1. 配布物

ChildSDK 開発チームから以下が提供されます:

```
ChildSDK-<version>.zip
└── repo/
    └── com/example/sdk/
        ├── childsdk/<version>/
        │   ├── childsdk-<version>.aar
        │   ├── childsdk-<version>.pom
        │   ├── childsdk-<version>.module       (Gradle Module Metadata)
        │   ├── childsdk-<version>-sources.jar
        │   └── *.{md5,sha1,sha256,sha512}
        └── uisdk/<version>/
            ├── uisdk-<version>.aar
            ├── uisdk-<version>.pom
            └── ...
```

特徴:
- **mini Maven repo 構造**（`groupId/artifactId/version/` のディレクトリ階層）
- ChildSDK の POM が UISDK を推移依存として宣言済み
- AndroidX 推移依存（webkit / appcompat / biometric / camera-* など）も POM に記載
- AndroidX 等のパブリック依存は Google Maven (`google()`) から自動解決される
- Kotlin 2.2.10 / AGP 9.1.1 でビルド済み
- minSdk 24 / compileSdk 36 をターゲット

`com.example.sdk:uisdk` は ChildSDK の推移依存として ParentSDK のクラスパスに現れますが、Gradle が自動で解決します。ParentSDK 自身のコードから UISDK の型を直接参照しなければ、ParentSDK の公開 API は ChildSDK のみで完結します。

---

## 2. ParentSDK への取り込み手順

### 2.1 配布物の配置

ParentSDK のリポジトリに zip を展開:

```
parentsdk/
├── libs/
│   └── sdk-repo/                       ← ここに repo/ を展開
│       └── com/example/sdk/
│           ├── childsdk/<version>/
│           └── uisdk/<version>/
├── src/                                 ← ParentSDK のソース
├── build.gradle.kts
└── settings.gradle.kts
```

### 2.2 Gradle リポジトリ設定

`parentsdk/settings.gradle.kts` に local Maven repo を追加:

```kotlin
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        // ChildSDK 配布物
        maven {
            name = "childsdk-local"
            url = uri("libs/sdk-repo")
        }
    }
}
```

### 2.3 ParentSDK ターゲットの依存宣言

`parentsdk/build.gradle.kts`:

```kotlin
dependencies {
    api("com.example.sdk:childsdk:<version>")
    // uisdk は childsdk の POM 経由で自動取得されるので明示宣言不要
}
```

| 宣言 | 用途 |
| --- | --- |
| `api(...)` | ParentSDK の公開 API から ChildSDK の型を返す/受け取る場合 |
| `implementation(...)` | ParentSDK 内部だけで使う場合（推奨。ChildSDK の型をホストアプリに露出させない） |

### 2.4 API ラッパで隠蔽する場合

ParentSDK の公開 API に ChildSDK の型を出さないなら、`implementation` を使い、薄いラッパを定義します:

```kotlin
// ParentSDK.kt
package com.example.parentsdk

import android.content.Context
import com.example.childsdk.ChildSDK

object ParentSDK {
    fun presentChild(context: Context) {
        ChildSDK.presentHelloWorld(context)
    }
}
```

ホストアプリは `import com.example.parentsdk.ParentSDK` のみで完結。ChildSDK の型を直接参照しません。

> ただし AAR 配布の場合、POM 経由で childsdk / uisdk のクラスは依然としてホストアプリのクラスパスに乗ります。ProGuard / R8 で minify すれば未使用クラスは最終 APK から除去されます。

### 2.5 リソースについて

ChildSDK / UISDK の HTML（`login.html` / `child.html` / `camera-overlay.html` / `index.html`）は AAR の `assets/childsdk/` / `assets/uisdk/` に同梱されています。Gradle の asset merge で自動的に最終 APK の `assets/` に配置されるので、ParentSDK 側で追加作業は不要です。

---

## 3. ビルド設定

ParentSDK モジュールの推奨設定:

| 設定 | 値 |
| --- | --- |
| `compileSdk` | 36 以上 |
| `minSdk` | 24 以上（ChildSDK と揃える） |
| `JavaVersion` | `VERSION_11` 以上 |
| Kotlin | 2.0 以上 |
| AGP | 8.6 以上（推奨 9.0+） |

`buildTypes.release` で R8 minify を有効化する場合、ChildSDK / UISDK の consumer ProGuard ルールが AAR に同梱されているため、ParentSDK 側で追加ルールは原則不要です。

---

## 4. 公開 API

ChildSDK が提供する `public` API:

| API | 説明 |
| --- | --- |
| `ChildSDK.presentHelloWorld(context: Context)` | スプラッシュ → 生体認証ログイン → メイン WebView の一連のフローを起動 |
| `ChildSDK.presentWebView(context: Context)` | メイン WebView 単体を提示 |
| `ChildSDK.SPLASH_IMAGE_URL_META_KEY` | AndroidManifest の `<meta-data>` キー名 (`"ChildSDKSplashImageURL"`) |

すべてメインスレッドから呼び出してください（`@MainThread`）。

---

## 5. ホストアプリ側の AndroidManifest 要件

ChildSDK の機能を有効にするため、最終ホストアプリの `AndroidManifest.xml` に以下が必要です。ParentSDK のドキュメントにも引き継いでください。

### 5.1 自動マージされるもの（追記不要）

ChildSDK の AAR には以下が宣言済みで、ホストアプリのマニフェストに自動マージされます:

| 要素 | 値 |
| --- | --- |
| `<uses-permission>` | `android.permission.CAMERA` / `USE_BIOMETRIC` / `INTERNET` |
| `<uses-feature>` | `android.hardware.camera`（`required="false"`） |
| `<activity>` | SplashActivity / LoginActivity / ChildWebViewActivity / CameraOverlayActivity / UISDKWebViewActivity |

### 5.2 ホストアプリ側で必要な宣言

| キー | 必須 | 用途 |
| --- | --- | --- |
| `<application>` の `theme` | Material/AppCompat 系 | SDK の Activity は `Theme.AppCompat.NoActionBar` を内部利用するので、ホストアプリは AppCompat 互換テーマを使う |
| `<meta-data android:name="ChildSDKSplashImageURL">` | 任意 | スプラッシュ画像の URL（指定するとスプラッシュ画面にダウンロード画像を表示） |

例:

```xml
<application
    android:label="@string/app_name"
    android:theme="@style/Theme.AppCompat">
    <meta-data
        android:name="ChildSDKSplashImageURL"
        android:value="https://example.com/splash.png" />
    ...
</application>
```

### 5.3 Permission の Runtime 要求

- **CAMERA**: ChildSDK が内部で Runtime permission を要求します（`ActivityResultContracts.RequestPermission`）。ホストアプリ側での追加実装不要
- **USE_BIOMETRIC**: 通常権限（Runtime 要求不要）。生体認証が未登録のデバイスでは ChildSDK がアラートで案内

---

## 6. トラブルシュート

| 症状 | 原因 / 対処 |
| --- | --- |
| `Could not find com.example.sdk:childsdk:<version>` | settings.gradle.kts の `maven { url = ... }` のパスが間違っている。`libs/sdk-repo/com/example/sdk/childsdk/<version>/childsdk-<version>.pom` が存在することを確認 |
| `Could not find com.example.sdk:uisdk:<version>` | UISDK の AAR/POM が配布 zip に含まれていない。配布チームに連絡 |
| `java.lang.NoClassDefFoundError: androidx.webkit.*` | UISDK の推移依存解決が効いていない。`google()` リポジトリが `dependencyResolutionManagement.repositories` に登録されているか確認 |
| `Activity not found: com.example.childsdk.internal.LoginActivity` | ChildSDK の AAR が最終 APK に取り込まれていない。`./gradlew :app:dependencies` で `com.example.sdk:childsdk` が出るか確認 |
| ログイン画面で「生体認証が利用できません」が出る | デバイス／エミュレータに指紋などが登録されていない。Settings → Security から登録、もしくは Emulator の Extended controls → Fingerprint → Touch Sensor を使う |
| カメラ画面が真っ黒 | Emulator のカメラ設定（Extended controls → Camera → Back camera を `Emulated` 等に設定）または実機の確認 |
| 実機で ProGuard 後にクラッシュ | ChildSDK の consumer-rules.pro は同梱されているが、必要に応じてホスト側 `proguard-rules.pro` にも `-keep` ルールを追加（基本不要） |
| ホストアプリのテーマで AppCompat 例外 | ホストアプリの `<application>` テーマが AppCompat 系でない。`Theme.AppCompat.*` か `Theme.Material3.*` ベースに変更 |

---

## 7. アップグレード手順

新しい `ChildSDK-<version>.zip` を受領したとき:

1. 旧 `libs/sdk-repo/com/example/sdk/childsdk/<old-version>/` を削除（複数バージョン共存させたい場合は残しても OK）
2. 新 `repo/` を `libs/sdk-repo/` に展開（同じ階層に上書き）
3. `parentsdk/build.gradle.kts` の `implementation("com.example.sdk:childsdk:<new-version>")` を更新
4. `./gradlew --refresh-dependencies build` で再解決
5. CHANGELOG を確認し、API 変更があれば呼び出し箇所を修正
6. 動作確認（demo アプリ等）
