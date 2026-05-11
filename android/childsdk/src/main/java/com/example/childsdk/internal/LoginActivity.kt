package com.example.childsdk.internal

import android.annotation.SuppressLint
import android.app.AlertDialog
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebView
import androidx.appcompat.app.AppCompatActivity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import com.example.uisdk.UISDK
import org.json.JSONObject

class LoginActivity : AppCompatActivity() {

    private companion object {
        const val ASSET = "childsdk/login.html"
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

        val configJson = buildString {
            val url = splashImageUrl()
            val obj = JSONObject()
            if (url != null) obj.put("splashImageURL", url)
            append("window.SDK_CONFIG = ")
            append(obj.toString())
            append(";")
        }
        webView.evaluateJavascript(configJson, null)
        // The script above runs before page load only if injected via initial
        // JS; for an at-document-start equivalent we inject via WebViewClient.
        webView.webViewClient = object : android.webkit.WebViewClient() {
            override fun onPageStarted(view: WebView?, url: String?, favicon: android.graphics.Bitmap?) {
                view?.evaluateJavascript(configJson, null)
            }
        }
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
            "login" -> authenticateAndProceed()
        }
    }

    private fun authenticateAndProceed() {
        val manager = BiometricManager.from(this)
        val authenticators = BiometricManager.Authenticators.BIOMETRIC_WEAK
        if (manager.canAuthenticate(authenticators) != BiometricManager.BIOMETRIC_SUCCESS) {
            showBiometricsUnavailableAlert()
            return
        }

        val prompt = BiometricPrompt(
            this,
            ContextCompat.getMainExecutor(this),
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    proceedToMainUI()
                }
                // onAuthenticationFailed / onAuthenticationError: stay silently
                // on the login screen to mirror the iOS behavior.
            }
        )
        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle("ログイン")
            .setSubtitle("ログインのため本人確認を行います")
            .setNegativeButtonText("キャンセル")
            .setAllowedAuthenticators(authenticators)
            .build()
        prompt.authenticate(info)
    }

    private fun proceedToMainUI() {
        UISDK.presentWebView(this, htmlAssetPath = null) { host, action ->
            if (action == "launchCamera") {
                com.example.childsdk.ChildSDK.presentWebView(host)
            }
        }
        finish()
    }

    private fun showBiometricsUnavailableAlert() {
        AlertDialog.Builder(this)
            .setTitle("生体認証が利用できません")
            .setMessage("設定アプリから生体認証を有効化してください。")
            .setPositiveButton("OK", null)
            .show()
    }
}
