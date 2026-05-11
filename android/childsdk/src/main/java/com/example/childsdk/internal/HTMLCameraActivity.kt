package com.example.childsdk.internal

import android.Manifest
import android.annotation.SuppressLint
import android.app.AlertDialog
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.PermissionRequest
import android.webkit.WebChromeClient
import android.webkit.WebView
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import org.json.JSONObject

/**
 * HTML/JS-only camera preview. Loads `camera-html.html` in a WebView and lets
 * `navigator.mediaDevices.getUserMedia` drive the preview — no CameraX session.
 *
 * Permission notes:
 * - The Android runtime `CAMERA` permission is asked once per grant lifetime
 *   (until the user revokes it or the app is reinstalled). This mirrors iOS's
 *   `NSCameraUsageDescription` prompt.
 * - The WebView has its own per-origin media capture permission on top of the
 *   app permission. Without `WebChromeClient.onPermissionRequest`, the request
 *   is denied by default (the page never gets the camera). Implementing the
 *   callback and calling `request.grant(...)` suppresses any extra prompt; the
 *   WebView grants immediately and `getUserMedia` resolves.
 */
class HTMLCameraActivity : AppCompatActivity() {

    private companion object {
        const val TAG = "HTMLCameraActivity"
        const val ASSET = "childsdk/camera-html.html"
        const val BRIDGE_NAME = "uiBridge"
    }

    private lateinit var webView: WebView

    private val cameraPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        Log.d(TAG, "CAMERA runtime permission result granted=$granted")
        if (granted) loadCameraPage() else showCameraDeniedAlert()
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        webView = WebView(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            setBackgroundColor(Color.BLACK)
        }
        setContentView(webView)

        webView.settings.javaScriptEnabled = true
        webView.settings.mediaPlaybackRequiresUserGesture = false
        webView.settings.allowFileAccess = false
        webView.addJavascriptInterface(Bridge(), BRIDGE_NAME)
        webView.webChromeClient = object : WebChromeClient() {
            override fun onPermissionRequest(request: PermissionRequest) {
                Log.d(
                    TAG,
                    "onPermissionRequest origin=${request.origin} resources=${request.resources.joinToString()}"
                )
                val wanted = request.resources.filter { it == PermissionRequest.RESOURCE_VIDEO_CAPTURE }
                if (wanted.isNotEmpty()) {
                    request.grant(wanted.toTypedArray())
                } else {
                    request.deny()
                }
            }
        }

        val granted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
        if (granted) {
            loadCameraPage()
        } else {
            cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    override fun onDestroy() {
        webView.removeJavascriptInterface(BRIDGE_NAME)
        webView.destroy()
        super.onDestroy()
    }

    private fun loadCameraPage() {
        webView.loadUrl("file:///android_asset/$ASSET")
    }

    private fun showCameraDeniedAlert() {
        AlertDialog.Builder(this)
            .setTitle("カメラを利用できません")
            .setMessage("設定アプリからカメラの利用を許可してください。")
            .setPositiveButton("OK") { _, _ -> finish() }
            .setOnCancelListener { finish() }
            .show()
    }

    private inner class Bridge {
        @JavascriptInterface
        fun postMessage(payload: String) {
            val action = runCatching { JSONObject(payload).optString("action") }
                .getOrNull()
                ?.takeIf { it.isNotEmpty() }
                ?: return
            runOnUiThread { if (action == "close") finish() }
        }
    }
}
