package com.migozz.migozzApp

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.BinaryMessenger

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val data: Uri? = intent.data

        if (Intent.ACTION_VIEW == action && data != null) {
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                val channel = MethodChannel(messenger, "socialAuth")

                when {
                    data.scheme == "migozz" && data.host == "spotify" && data.path == "/success" -> {
                        val queryParams = data.query ?: ""
                        channel.invokeMethod("spotifySuccess", queryParams)
                    }
                    data.scheme == "migozz" && data.host == "twitter" && data.path == "/success" -> {
                        val queryParams = data.query ?: ""
                        channel.invokeMethod("twitterSuccess", queryParams)
                    }
                }
            }
        }
    }
}
