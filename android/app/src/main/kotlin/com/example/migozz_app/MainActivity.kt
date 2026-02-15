package com.migozz.migozzApp

import android.content.Intent
import android.net.Uri
import android.os.Bundle
// 1. CAMBIO: Importamos FlutterFragmentActivity en lugar de FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

// 2. CAMBIO: La clase ahora hereda de FlutterFragmentActivity
class MainActivity: FlutterFragmentActivity() {

    private val CHANNEL = "socialAuth"
    private val DEEPLINK_CHANNEL = "profileDeeplink"

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
                
                // Manejar App Links de perfiles (https://migozz.app/u/username)
                if (data.scheme == "https" && 
                    (data.host == "migozz-e2a21.web.app" || 
                    data.host == "migozz-e2a21.firebaseapp.com" ||
                    data.host == "www.migozz-e2a21.web.app") &&
                    data.pathSegments.size >= 2 && 
                    data.pathSegments[0] == "u") {
                    
                    val username = data.pathSegments[1]
                    val profileChannel = MethodChannel(messenger, DEEPLINK_CHANNEL)
                    profileChannel.invokeMethod("openProfile", username)
                    return
                }

                // Manejar deep links de redes sociales (migozz://...)
                val socialChannel = MethodChannel(messenger, CHANNEL)
                when {
                    data.scheme == "migozz" && data.host == "spotify" && data.path == "/success" -> {
                        val queryParams = data.query ?: ""
                        socialChannel.invokeMethod("spotifySuccess", queryParams)
                    }
                    data.scheme == "migozz" && data.host == "twitter" && data.path == "/success" -> {
                        val queryParams = data.query ?: ""
                        socialChannel.invokeMethod("twitterSuccess", queryParams)
                    }
                    data.scheme == "migozz" && data.host == "facebook" && data.path == "/success" -> {
                        val queryParams = data.query ?: ""
                        socialChannel.invokeMethod("facebookSuccess", queryParams)
                    }
                    data.scheme == "migozz" && data.host == "tiktok" && data.path == "/success" -> {
                        val queryParams = data.query ?: ""
                        socialChannel.invokeMethod("tiktokSuccess", queryParams)
                    }
                    data.scheme == "migozz" && data.host == "instagram" && data.path == "/success" -> {
                        val queryParams = data.query ?: ""
                        socialChannel.invokeMethod("instagramSuccess", queryParams)
                    }
                }
            }
        }
    }
}