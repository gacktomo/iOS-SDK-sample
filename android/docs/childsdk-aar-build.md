# ChildSDK AAR ビルド & 配布手順書（内部向け）

本ドキュメントは SDK 開発者向け。リポジトリから `ChildSDK` の AAR + POM を生成し、配布するまでの手順を記載します。

> ChildSDK 利用者（ParentSDK チーム）向け: [../dist/README.md](../dist/README.md)（配布 zip に同梱）

---

## 1. 配布物と責務

| Artifact | 種別 | 配布責務 | 備考 |
| --- | --- | --- | --- |
| **childsdk-\<version\>.aar** | AAR (Android Archive) | **本チームの納品物** | 単体では UISDK 依存を POM で宣言 |
| **childsdk-\<version\>.pom** | Maven POM | **本チームの納品物** | UISDK / AndroidX 推移依存を記載 |
| **uisdk-\<version\>.aar / .pom** | AAR + POM | 外部ベンダ提供（現状は仮実装） | ChildSDK の zip に同梱して再配布 |
| **parentsdk-\<version\>.aar / .pom** | AAR + POM | 別チームの責務 | demo 動作確認用に本リポジトリでも生成 |

ホストアプリは ParentSDK の AAR のみを依存宣言する想定。ParentSDK が ChildSDK（さらに UISDK）を推移依存として吸収します。

```
[外部ベンダ]   uisdk.aar + uisdk.pom        (Android Library)
                      ↓ POM transitive
[本チーム]     childsdk.aar + childsdk.pom  (Android Library)        ← 納品物
                      ↓ POM transitive
[別チーム]     parentsdk.aar + parentsdk.pom(Android Library)
                      ↓ implementation
[ホストアプリ] App
```

ChildSDK の AAR には UISDK のクラスは含まれません。ChildSDK の POM が UISDK 依存を宣言し、Gradle が解決します。「単一 AAR 内包」を必要とする場合は §10 を参照。

---

## 2. 環境

| 項目 | 推奨 |
| --- | --- |
| macOS / Linux / Windows | 任意 |
| JDK | 17 以上（Gradle 9 要件） |
| Android Gradle Plugin | 9.1.1（本リポジトリ） |
| Gradle | 9.3.1（wrapper で固定） |
| Kotlin | 2.2.10 |
| compileSdk | 36 |
| minSdk | 24 |

`local.properties` の `sdk.dir` で Android SDK 位置を指定（または `ANDROID_HOME` 環境変数）。

---

## 3. リポジトリ構成

```
android/
├── settings.gradle.kts                ← Roll-up build (includeBuild × 3)
├── build.gradle.kts
├── gradle/, gradlew, ...              ← Roll-up 用ラッパ
├── dist/repo/                         ← Publish 出力先（mini Maven repo）
├── uisdk/                             ← 独立 Gradle ビルド (仮実装)
│   ├── settings.gradle.kts
│   ├── build.gradle.kts
│   ├── gradle/, gradlew, ...
│   └── src/...
├── childsdk/                          ← 独立 Gradle ビルド (本チーム)
│   ├── settings.gradle.kts            ← includeBuild("../uisdk")
│   ├── build.gradle.kts
│   └── src/...
├── parentsdk/                         ← 独立 Gradle ビルド (demo 検証用)
│   ├── settings.gradle.kts            ← includeBuild("../uisdk") + includeBuild("../childsdk")
│   ├── build.gradle.kts
│   └── src/...
└── demo/                              ← 独立 Gradle ビルド (動作確認アプリ)
    ├── settings.gradle.kts            ← includeBuild("..")  / -PuseLocalSdk で AAR 経由に切替
    └── app/
```

各 SDK は Gradle composite build (`includeBuild`) で依存 SDK のソースを取り込みます。`-PuseLocalSdk` フラグを指定すると `dist/repo/` の AAR/POM 経由に切り替わります。

---

## 4. ビルド方法

### 4.1 単体 publish

```bash
cd android/childsdk
./gradlew publish
```

成果物:
```
android/dist/repo/com/example/sdk/childsdk/1.0.0/
├── childsdk-1.0.0.aar
├── childsdk-1.0.0.pom
├── childsdk-1.0.0.module             ← Gradle Module Metadata (richer than POM)
├── childsdk-1.0.0-sources.jar
└── (各 .md5 / .sha1 / .sha256 / .sha512)
```

UISDK / ParentSDK も同様（各ディレクトリで `./gradlew publish`）。

### 4.2 一括 publish（Roll-up）

```bash
cd android
./gradlew :uisdk:publish :childsdk:publish :parentsdk:publish
```

`android/settings.gradle.kts` が 3 つの SDK を `includeBuild` しているので、roll-up から各 SDK のタスクを呼べます。

### 4.3 ビルドスクリプトの中身（要点）

各 SDK の `build.gradle.kts`:

1. **`maven-publish` プラグイン適用**
   ```kotlin
   plugins {
       alias(libs.plugins.android.library)
       `maven-publish`
   }
   ```
2. **`group` / `version` 設定**（POM の Maven 座標）
   ```kotlin
   group = "com.example.sdk"
   version = "1.0.0"
   ```
3. **公開する variant を宣言**
   ```kotlin
   android.publishing {
       singleVariant("release") { withSourcesJar() }
   }
   ```
4. **Publication と Repository を定義**
   ```kotlin
   afterEvaluate {
       publishing {
           publications {
               register<MavenPublication>("release") {
                   from(components["release"])
               }
           }
           repositories {
               maven {
                   name = "local"
                   url = uri("${rootDir}/../dist/repo")
               }
           }
       }
   }
   ```

`afterEvaluate { ... }` は android plugin の components 登録後に実行する必要があるため。

---

## 5. 依存解決の仕組み

### 5.1 ChildSDK 側

- `childsdk/build.gradle.kts` に `api("com.example.sdk:uisdk:1.0.0")` と宣言
- `childsdk/settings.gradle.kts` で `includeBuild("../uisdk")`
- 開発時: Gradle が `com.example.sdk:uisdk:1.0.0` を **隣接ソースの uisdk プロジェクトに自動 substitute**（composite build の標準動作）
- Publish 時: `from(components["release"])` が POM を生成し、`api` で宣言した依存を `<dependency>scope=compile` として書き出す

### 5.2 リソースの扱い

- UISDK の HTML (`index.html`) は `uisdk.aar` の `assets/uisdk/` に格納
- ChildSDK の HTML (`login.html` / `child.html` / `camera-overlay.html`) は `childsdk.aar` の `assets/childsdk/` に格納
- それぞれの AAR が assets を持つので、Gradle のリソース統合で最終 APK の `assets/` に両方が配置される

AAR + assets ディレクトリ構造で APK に統合されます。

### 5.3 API 隠蔽について

ChildSDK の Kotlin API から UISDK の型を露出させないため、UISDK 由来の型はすべて ChildSDK の `internal` 関数内で使い、`public` 関数は ChildSDK 自身の型のみを返す設計です（[childsdk/src/main/java/com/example/childsdk/ChildSDK.kt](../childsdk/src/main/java/com/example/childsdk/ChildSDK.kt)）。

ただし POM に UISDK が依存として記載されるので、利用者のクラスパス上には UISDK のクラスが乗ります（Gradle が自動で解決）。完全に隠したい場合は §10 の Fat AAR を検討。

---

## 6. 検証手順

### 6.1 POM に推移依存が記載されていること

```bash
cat android/dist/repo/com/example/sdk/childsdk/1.0.0/childsdk-1.0.0.pom | grep -A2 'uisdk'
# → <artifactId>uisdk</artifactId> 等が出ること
```

### 6.2 AAR の中身

```bash
unzip -l android/dist/repo/com/example/sdk/childsdk/1.0.0/childsdk-1.0.0.aar
# → classes.jar / AndroidManifest.xml / assets/childsdk/*.html / R.txt が出ること
```

### 6.3 demo アプリでの動作確認（配布物経由）

`demo` 側で `-PuseLocalSdk` を付けると composite build を経由せず `dist/repo/` から解決される:

```bash
cd android/demo
./gradlew clean :app:installDebug -PuseLocalSdk
```

エミュレータ起動後、`ParentSDKを起動` ボタンで Splash → Login → メイン WebView → カメラまで通れば OK。

### 6.4 公開シンボルが利用者から見えること

```bash
unzip -p android/dist/repo/com/example/sdk/childsdk/1.0.0/childsdk-1.0.0.aar classes.jar > /tmp/childsdk.jar
javap -classpath /tmp/childsdk.jar com.example.childsdk.ChildSDK
# → presentHelloWorld / presentWebView が public で出ること
```

---

## 7. 配布

### 7.1 配布物

mini Maven repo のディレクトリツリーを丸ごと zip:

```bash
cd android
./gradlew clean :uisdk:publish :childsdk:publish

cd dist
zip -ry ChildSDK-1.0.0.zip repo
```

`ChildSDK-1.0.0.zip` の内容:
```
repo/
└── com/example/sdk/
    ├── childsdk/1.0.0/   ← childsdk-1.0.0.{aar,pom,module,...}
    └── uisdk/1.0.0/      ← uisdk-1.0.0.{aar,pom,module,...}
```

> ChildSDK の AAR には UISDK のクラスが含まれていないため、**UISDK も同梱する必要があります**。Fat AAR で内包する場合は §10 参照。

### 7.2 配布チャネル候補

- 社内 GitHub Releases にタグ付きアセットとして添付
- 社内 Artifactory / Nexus に publish（`maven { url = "..." }` の URL を社内向けに公開）
- GitHub Packages にユーザ認証で publish
- 直接 zip を渡す（社内のみ）

### 7.3 バージョニング

`MAJOR.MINOR.PATCH` の SemVer。各 SDK の `build.gradle.kts` の `version = "..."` で管理。CHANGELOG を `docs/CHANGELOG.md`（必要に応じて作成）で管理。

---

## 8. 仮 UISDK と本物の UISDK 受領後の差分

### 現状（仮 UISDK）
- `uisdk/` ディレクトリのソースから AAR を都度ビルド
- `childsdk/settings.gradle.kts` は `includeBuild("../uisdk")` で隣接ソース参照

### 本物の UISDK が届いた後
ベンダ提供形態によって対応が分岐。**受領前にベンダと擦り合わせ必須**:

| 受領形態 | 対応 |
| --- | --- |
| **AAR + POM がmini Maven repo構造の zip** | `uisdk/` ディレクトリを削除。`childsdk/settings.gradle.kts` の `includeBuild("../uisdk")` を削除し、`dependencyResolutionManagement.repositories { maven { url = "/path/to/vendor-repo" } }` に置換 |
| **AAR のみ（POM なし）** | 同様に `uisdk/` 削除＋ `flatDir` か手書き POM で対応。UISDK の推移依存（AndroidX webkit 等）を ChildSDK 側で手動宣言 |
| **リソース同梱の有無** | AAR の中の `assets/` を確認。同梱されていれば追加作業不要 |

### ベンダ確認事項チェックリスト
- [ ] AAR と POM の両方を提供してくれるか（POM なしだと推移依存を手書きする必要が出る）
- [ ] AAR の `minSdk` が ChildSDK の `minSdk` (24) 以下か
- [ ] AAR に必要なリソース（HTML 等）が `assets/` に含まれているか
- [ ] AAR に `consumer-rules.pro`（ProGuard 設定）が含まれているか
- [ ] sources.jar の提供有無（IDE のデバッグ用、必須ではない）
- [ ] dependencies の `scope`（`compile` か `runtime` か）が POM で正しく分かれているか
- [ ] バージョニング規約

---

## 9. リリースチェックリスト

- [ ] `cd android/uisdk && ./gradlew assemble` が通る
- [ ] `cd android/childsdk && ./gradlew assemble` が通る
- [ ] `cd android/parentsdk && ./gradlew assemble` が通る
- [ ] `cd android && ./gradlew :uisdk:publish :childsdk:publish :parentsdk:publish` がエラーなく完走する
- [ ] §6 の検証コマンドがすべて期待通り
- [ ] `cd android/demo && ./gradlew :app:installDebug -PuseLocalSdk` で配布物経由のビルドが通り、emulator/実機で全フローが動作する
- [ ] CHANGELOG が更新されている
- [ ] バージョンタグが Git に切られている
- [ ] zip / checksum が配布チャネルにアップロードされている

---

## 10. 単一 AAR 配布（Fat AAR）について

「ChildSDK の AAR 1 個だけを利用者に渡す（UISDK のクラスとリソースを内包する）」運用を実現したい場合の選択肢:

| 方式 | 内容 | 検討事項 |
| --- | --- | --- |
| **ソースセット統合** | 配布用モジュール `childsdk-dist/` を新設し、UISDK と ChildSDK のソースを source set で取り込んでひとつの AAR にビルド | クリーンだが、配布用と開発用でモジュール構成が分岐 |
| **Fat AAR プラグイン** | `com.kezong.fat-aar` 等のコミュニティプラグインで依存 AAR を classes.jar + res に展開して再パッケージ | AGP 9 系での動作は要検証。メンテリスクあり |
| **手動マージ** | `unzip → classes.jar 結合 → res / assets コピー → zip` をシェルで実装 | 制御は完全だが脆い |

現状は §1 のとおり **複数 AAR + POM 推移依存** で配布する方針。Fat AAR が必要になったら本セクションを別ドキュメントに展開して実装。

---

## 11. 既知の事項

- AGP 9.0 から `android.publishing { singleVariant("release") }` で variant を宣言してから `from(components["release"])` を参照する形式が必須。AGP 8 系以前の `from(components["all"])` は使えない
- `kotlin-android` プラグインを明示適用すると `"Cannot add extension with name 'kotlin', as there is an extension already registered"` エラーになる（AGP 9 が暗黙適用するため）。SDK の `build.gradle.kts` には `android.library` プラグインだけ書く
- `local.properties` は各 Gradle ルート（4 か所: uisdk/childsdk/parentsdk/demo）に必要。CI では `ANDROID_HOME` 環境変数を使うので不要
- Composite build を使う場合、依存される側の SDK でも `group` / `version` を宣言しないと dependency substitution が効かない
- demo の `-PuseLocalSdk` は配布物検証用。日常の開発では composite build (`includeBuild`) を使う方がホットリロードが効く
