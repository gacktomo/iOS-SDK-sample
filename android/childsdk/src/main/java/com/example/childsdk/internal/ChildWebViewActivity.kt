package com.example.childsdk.internal

import android.Manifest
import android.annotation.SuppressLint
import android.app.AlertDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebView
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import org.json.JSONObject

class ChildWebViewActivity : AppCompatActivity() {

    private companion object {
        const val ASSET = "childsdk/child.html"
        const val BRIDGE_NAME = "uiBridge"
    }

    private lateinit var webView: WebView

    private val cameraPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) presentCameraOverlay() else showCameraDeniedAlert()
    }

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
            "launchCamera" -> launchCamera()
        }
    }

    private fun launchCamera() {
        val granted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
        if (granted) {
            presentCameraOverlay()
        } else {
            cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    private fun presentCameraOverlay() {
        startActivity(Intent(this, CameraOverlayActivity::class.java))
    }

    private fun showCameraDeniedAlert() {
        AlertDialog.Builder(this)
            .setTitle("カメラを利用できません")
            .setMessage("設定アプリからカメラの利用を許可してください。")
            .setPositiveButton("OK", null)
            .show()
    }
}
