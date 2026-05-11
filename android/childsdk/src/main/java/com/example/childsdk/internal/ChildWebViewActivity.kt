package com.example.childsdk.internal

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONObject

class ChildWebViewActivity : AppCompatActivity() {

    private companion object {
        const val ASSET = "childsdk/child.html"
        const val BRIDGE_NAME = "uiBridge"
    }

    private lateinit var webView: WebView

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        webView = WebView(this).also { setContentView(it) }
        webView.settings.javaScriptEnabled = true
        webView.settings.allowFileAccess = false
        webView.addJavascriptInterface(Bridge(), BRIDGE_NAME)
        webView.loadUrl("file:///android_asset/$ASSET")
    }

    override fun onDestroy() {
        webView.removeJavascriptInterface(BRIDGE_NAME)
        webView.destroy()
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
            "launchCamera" -> startActivity(Intent(this, HTMLCameraActivity::class.java))
        }
    }
}
