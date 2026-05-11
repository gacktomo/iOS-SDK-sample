package com.example.parentsdk

import android.content.Context
import androidx.annotation.MainThread
import com.example.childsdk.ChildSDK

object ParentSDK {
    @MainThread
    fun presentChild(context: Context) {
        ChildSDK.presentHelloWorld(context)
    }
}
