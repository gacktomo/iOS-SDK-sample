package com.example.childsdk.internal

import android.annotation.SuppressLint
import android.graphics.Color
import android.os.Bundle
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.widget.FrameLayout
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import org.json.JSONObject

/**
 * Native camera preview with a transparent WebView overlay rendering HTML UI on top.
 */
class CameraOverlayActivity : AppCompatActivity() {

    private companion object {
        const val ASSET = "childsdk/camera-overlay.html"
        const val BRIDGE_NAME = "uiBridge"
    }

    private lateinit var previewView: PreviewView
    private lateinit var webView: WebView

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.BLACK)
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
        }
        previewView = PreviewView(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
        }
        webView = WebView(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            setBackgroundColor(Color.TRANSPARENT)
        }
        root.addView(previewView)
        root.addView(webView)
        setContentView(root)

        webView.settings.javaScriptEnabled = true
        webView.settings.allowFileAccess = false
        webView.addJavascriptInterface(Bridge(), BRIDGE_NAME)
        webView.loadUrl("file:///android_asset/$ASSET")

        startCamera()
    }

    override fun onDestroy() {
        webView.removeJavascriptInterface(BRIDGE_NAME)
        webView.destroy()
        super.onDestroy()
    }

    private fun startCamera() {
        val providerFuture = ProcessCameraProvider.getInstance(this)
        providerFuture.addListener({
            val provider = runCatching { providerFuture.get() }.getOrNull() ?: return@addListener
            val preview = Preview.Builder().build().also {
                it.setSurfaceProvider(previewView.surfaceProvider)
            }
            val selector = CameraSelector.DEFAULT_BACK_CAMERA
            runCatching {
                provider.unbindAll()
                provider.bindToLifecycle(this, selector, preview)
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private inner class Bridge {
        @JavascriptInterface
        fun postMessage(payload: String) {
            val action = runCatching { JSONObject(payload).optString("action") }
                .getOrNull()
                ?.takeIf { it.isNotEmpty() }
                ?: return
            runOnUiThread {
                if (action == "close") finish()
            }
        }
    }
}
