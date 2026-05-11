# web

UISDK の WebView 内 UI を React で再実装したもの。将来的に S3 + CloudFront から配信する想定で、現状はSDKにバンドルされている `index.html` を置き換える独立プロジェクトとして開発できる。

## Stack

- Vite + React 18 + TypeScript
- ネイティブ通信は `src/bridge.ts`（iOS `webkit.messageHandlers.uiBridge` / Android `window.uiBridge` を吸収）
- ビルド成果物はハッシュ付きアセット + `index.html`。CSPメタタグは本番ビルド時のみ注入

## 開発フロー

### 1. ローカルでブラウザ表示

```bash
npm install
npm run dev
```

`http://localhost:5173/` で表示できる。ブラウザではネイティブブリッジは無いので、タイル押下時は `console.warn('native bridge unavailable', ...)` が出るだけ。

### 2. iOS Simulator / 実機の WebView で表示する

Xcode 上部の**スキーム選択ドロップダウン**で `demo (Local Web)` を選んで実行するだけ。`CHILDSDK_WEBVIEW_URL_OVERRIDE=http://localhost:5173` がスキームから自動でセットされ、ChildSDK がそれを読んで UISDK に `htmlURL` として渡す。`NSAllowsLocalNetworking` は Info.plist で有効済み。

バンドル版に戻すときはスキームを `demo` に戻すだけ。

実機で試す場合は、スキームの環境変数を `http://<Mac の LAN IP>:5173` に変えるか、開発機と USB 接続して `iproxy` 等でポート転送する。

### 3. Android Emulator の WebView で表示する

Android Studio の左ペイン下にある **Build Variants** パネルで `app` のバリアントを `localWebDebug` に切り替えて実行するだけ。`AndroidManifest.xml` の `ChildSDKWebViewURLOverride` メタデータが `http://10.0.2.2:5173/` に置換され、ChildSDK の `LoginActivity` がそれを読んで UISDK に `htmlUrl` として渡す。cleartext は `localWeb` フレーバーの source set で localhost/10.0.2.2 にだけ許可済み。

バンドル版に戻すときは `bundledDebug` に切り替える。

実機をUSB接続する場合は `adb reverse tcp:5173 tcp:5173` でホストの 5173 をデバイスに転送するか、フレーバーの URL を Mac の LAN IP に変更する。

### 4. 本番ビルド

```bash
npm run build
```

`dist/index.html` + `dist/assets/*.[hash].{js,css}` が出力される。`.env.production` の `ASSET_BASE_URL` で `<script src>` / `<link href>` の絶対パスを CloudFront のオリジン+バージョンディレクトリに解決する。

## ネイティブとの規約

WebView からネイティブへ送る payload は `{ action: string, ... }` 形式。ネイティブ側で予約されているアクション:

- `close` — WebView を閉じる（UISDK が処理、コールバックには渡らない）
- それ以外 — ChildSDK 等の `onAction` に伝搬する

JS側のヘルパは `postToNative({ action: 'launchCamera' })` のように呼ぶ。新しいアクションを増やすときは `src/bridge.ts` の `BridgeAction` ユニオンに追加する。

## ファイル構成

```
src/
├── main.tsx              # エントリ
├── App.tsx               # ルート画面
├── bridge.ts             # ネイティブブリッジ（iOS/Android両対応）
├── icons.tsx             # SVGアイコン
├── components/
│   ├── TileGrid.tsx
│   └── SkeletonSection.tsx
├── data/tiles.ts         # タイル定義
└── index.css             # スタイル（CSS変数でlight/dark両対応）
```
