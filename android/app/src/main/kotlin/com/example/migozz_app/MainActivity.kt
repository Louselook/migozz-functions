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
            if (data.scheme == "migozz" && data.host == "spotify" && data.path == "/success") {
                val queryParams = data.query ?: ""

                // Notificar a Flutter mediante platform channel
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger: BinaryMessenger ->
                    val channel = MethodChannel(messenger, "socialAuth")
                    channel.invokeMethod("spotifySuccess", queryParams)
                }
            }
        }
    }
}
