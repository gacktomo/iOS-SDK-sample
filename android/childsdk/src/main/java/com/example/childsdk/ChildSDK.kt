package com.example.childsdk

import android.content.Context
import android.content.Intent
import androidx.annotation.MainThread
import com.example.childsdk.internal.ChildWebViewActivity
import com.example.childsdk.internal.SplashActivity

object ChildSDK {
    /**
     * AndroidManifest `<meta-data>` key on the host app. Optional. When set, the
     * SDK shows the downloaded image on the splash screen during initialization.
     *
     * Example:
     * ```
     * <meta-data
     *     android:name="ChildSDKSplashImageURL"
     *     android:value="https://example.com/splash.png" />
     * ```
     */
    const val SPLASH_IMAGE_URL_META_KEY = "ChildSDKSplashImageURL"

    /**
     * Run the full flow: splash → biometric login → UISDK main UI.
     */
    @MainThread
    fun presentHelloWorld(context: Context) {
        val intent = Intent(context, SplashActivity::class.java).apply {
            if (context !is android.app.Activity) {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        context.startActivity(intent)
    }

    /**
     * Present ChildSDK's own WebView (camera-launch screen) on top of the
     * current activity stack.
     */
    @MainThread
    fun presentWebView(context: Context) {
        val intent = Intent(context, ChildWebViewActivity::class.java).apply {
            if (context !is android.app.Activity) {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        context.startActivity(intent)
    }
}
