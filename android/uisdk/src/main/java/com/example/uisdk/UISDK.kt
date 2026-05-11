package com.example.uisdk

import android.app.Activity
import android.content.Context
import android.content.Intent
import androidx.annotation.MainThread

object UISDK {
    /**
     * Present a WebView screen.
     *
     * @param context Caller context. If not an Activity, the activity is launched in a new task.
     * @param htmlAssetPath Optional asset path of an HTML file to load
     *   (e.g. "childsdk/child.html"). Pass `null` to use UISDK's bundled default.
     * @param htmlUrl Optional full URL (e.g. "http://10.0.2.2:5173/") to load.
     *   Wins over [htmlAssetPath] when set; intended for non-asset sources such
     *   as a local dev server or a CDN.
     * @param onAction Called when the WebView posts a non-built-in action via the
     *   `uiBridge` interface. The hosting [Activity] is passed so the callback can
     *   chain follow-up screens in the same task. The `close` action is handled
     *   internally (finishes the activity) and is not forwarded.
     */
    @MainThread
    fun presentWebView(
        context: Context,
        htmlAssetPath: String? = null,
        htmlUrl: String? = null,
        onAction: ((host: Activity, action: String) -> Unit)? = null,
    ) {
        UISDKWebViewActivity.onAction = onAction
        val intent = Intent(context, UISDKWebViewActivity::class.java).apply {
            putExtra(UISDKWebViewActivity.EXTRA_HTML_ASSET, htmlAssetPath)
            putExtra(UISDKWebViewActivity.EXTRA_HTML_URL, htmlUrl)
            if (context !is Activity) {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        context.startActivity(intent)
    }
}
