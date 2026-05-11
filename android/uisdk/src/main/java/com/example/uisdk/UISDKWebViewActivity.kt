package com.example.uisdk

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONObject

class UISDKWebViewActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_HTML_ASSET = "uisdk.html_asset"
        private const val DEFAULT_ASSET = "uisdk/index.html"
        private const val BRIDGE_NAME = "uiBridge"

        /**
         * Caller-provided callback. Set by [UISDK.presentWebView] just before the
         * Activity launches. Treated as a session-scoped slot — the SDK is
         * single-flow at a time.
         */
        internal var onAction: ((Activity, String) -> Unit)? = null
    }

    private lateinit var webView: WebView

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        webView = WebView(this).also { setContentView(it) }
        webView.settings.javaScriptEnabled = true
        webView.settings.allowFileAccess = false
        webView.addJavascriptInterface(Bridge(), BRIDGE_NAME)

        val asset = intent.getStringExtra(EXTRA_HTML_ASSET) ?: DEFAULT_ASSET
        webView.loadUrl("file:///android_asset/$asset")
    }

    override fun onDestroy() {
        webView.removeJavascriptInterface(BRIDGE_NAME)
        webView.destroy()
        // Only clear the slot when this Activity owned it. If a chained flow
        // already installed a new callback, leave it intact.
        super.onDestroy()
    }

    private inner class Bridge {
        @JavascriptInterface
        fun postMessage(payload: String) {
            val action = runCatching { JSONObject(payload).optString("action") }
                .getOrNull()
                ?.takeIf { it.isNotEmpty() }
                ?: return
            runOnUiThread { handleAction(action) }
        }
    }

    private fun handleAction(action: String) {
        when (action) {
            "close" -> finish()
            else -> onAction?.invoke(this, action)
        }
    }
}
