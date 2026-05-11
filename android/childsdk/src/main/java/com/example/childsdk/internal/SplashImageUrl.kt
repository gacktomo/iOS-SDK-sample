package com.example.childsdk.internal

import android.content.Context
import android.content.pm.PackageManager
import com.example.childsdk.ChildSDK

internal fun Context.splashImageUrl(): String? {
    val info = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
    val raw = info.metaData?.get(ChildSDK.SPLASH_IMAGE_URL_META_KEY)?.toString()
    return raw?.takeIf { it.isNotBlank() }
}
