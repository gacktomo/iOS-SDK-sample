package com.example.childsdk.internal

import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.URL

class SplashActivity : AppCompatActivity() {

    private companion object {
        const val DISPLAY_DURATION_MS = 2000L
        const val FADE_DURATION_MS = 300L
    }

    private lateinit var imageView: ImageView
    private var didStartCompletionTimer = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.rgb(255, 248, 225))
        }

        imageView = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(120), dp(120))
            scaleType = ImageView.ScaleType.FIT_CENTER
            alpha = 0f
        }
        val title = TextView(this).apply {
            text = "ChildSDK"
            textSize = 24f
            setTextColor(Color.rgb(255, 149, 0))
            gravity = Gravity.CENTER
        }
        val indicator = ProgressBar(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(16) }
        }
        val subtitle = TextView(this).apply {
            text = "起動中..."
            textSize = 14f
            setTextColor(Color.argb(153, 60, 60, 67))
            gravity = Gravity.CENTER
            (layoutParams as? LinearLayout.LayoutParams ?: LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            )).also { it.topMargin = dp(16); layoutParams = it }
        }

        val url = splashImageUrl()
        imageView.visibility = if (url == null) View.GONE else View.VISIBLE

        root.addView(imageView)
        root.addView(title, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT,
        ).apply { topMargin = dp(16) })
        root.addView(indicator)
        root.addView(subtitle)
        setContentView(root)

        if (url != null) {
            loadImageThen(url) { startCompletionTimer() }
        } else {
            startCompletionTimer()
        }
    }

    private fun loadImageThen(url: String, onDone: () -> Unit) {
        lifecycleScope.launch {
            val bitmap = withContext(Dispatchers.IO) {
                runCatching {
                    URL(url).openStream().use { BitmapFactory.decodeStream(it) }
                }.getOrNull()
            }
            if (bitmap != null) {
                imageView.setImageBitmap(bitmap)
                imageView.animate().alpha(1f).setDuration(FADE_DURATION_MS).start()
            }
            onDone()
        }
    }

    private fun startCompletionTimer() {
        if (didStartCompletionTimer) return
        didStartCompletionTimer = true
        Handler(Looper.getMainLooper()).postDelayed({
            startActivity(Intent(this, LoginActivity::class.java))
            finish()
            overridePendingTransition(0, 0)
        }, DISPLAY_DURATION_MS)
    }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()
}
