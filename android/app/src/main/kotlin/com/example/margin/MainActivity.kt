package com.example.margin

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var shareIntentChannel: MethodChannel? = null
    private var initialSharedText: String? = null

    companion object {
        private const val TAG = "Margin/MainActivity"
        private const val CHANNEL = "margin/share_intent"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        Log.d(TAG, "Setting up share intent channel")

        // Setup method channel for share intent
        shareIntentChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        shareIntentChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            Log.d(TAG, "Received method call: ${call.method}")
            if (call.method == "getInitialText") {
                // Return the initial shared text and clear it
                Log.d(TAG, "Returning initial shared text: $initialSharedText")
                result.success(initialSharedText)
                initialSharedText = null
            } else {
                Log.d(TAG, "Method not implemented: ${call.method}")
                result.notImplemented()
            }
        }

        Log.d(TAG, "Share intent channel setup complete")

        // If we already have shared text, notify Flutter now
        if (initialSharedText != null) {
            Log.d(TAG, "Notifying Flutter of pending share: $initialSharedText")
            shareIntentChannel?.invokeMethod("onShareReceived", initialSharedText)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate called")

        // Check if app was launched via share intent
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent called")

        // Handle new intent while app is already running
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            Log.d(TAG, "Intent is null, skipping")
            return
        }

        val action = intent.action
        val type = intent.type

        Log.d(TAG, "Handling intent - action: $action, type: $type")

        // Check if this is a SEND intent with text
        if (Intent.ACTION_SEND == action && type != null) {
            if (type.startsWith("text/")) {
                val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                Log.d(TAG, "Extracted shared text: $sharedText")

                if (sharedText != null) {
                    initialSharedText = sharedText

                    // Notify Flutter if the engine is already running
                    shareIntentChannel?.invokeMethod("onShareReceived", sharedText)

                    // Clear the intent to avoid re-processing
                    intent.action = null
                }
            }
        }
    }
}
