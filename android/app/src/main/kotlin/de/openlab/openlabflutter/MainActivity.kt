package de.openlab.openlabflutter

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    private lateinit var channel: MethodChannel
    private val TAG = "MainActivity"
    private var pendingBuzzType: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent.hasExtra("hce")) {
            onHCEResult(intent)
        }

        // Store the buzz_type for later processing
        pendingBuzzType = intent?.getStringExtra("buzz_type")
        if (pendingBuzzType != null) {
            Log.i(TAG, "Widget intent received in onCreate with buzz_type: $pendingBuzzType")
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hce")

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startHCE" -> {
                    result.success(true)
                }
                "accessToken" -> {
                    val token = call.argument<String>("accessToken")
                    val dateString = call.argument<String>("expirationDate")
                    if (token != null && dateString != null) {
                        try {
                            val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.getDefault())
                            val expiration = sdf.parse(dateString)

                            if (expiration != null) {
                                HCEService.tokenLiveData.value = token
                                HCEService.expirationDate.value = expiration
                                Log.i(TAG, "Access token and expiration date updated: $expiration")
                                result.success(true)
                            } else {
                                Log.e(TAG, "Parsed expiration date is null")
                                result.error("NULL_DATE", "Parsed expiration date was null", null)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Date parsing error", e)
                            result.error("PARSE_ERROR", "Invalid date format", e.localizedMessage)
                        }
                    } else {
                        Log.e(TAG, "Missing accessToken or expirationDate in arguments")
                        result.error("ARGUMENT_ERROR", "Missing required arguments", null)
                    }
                }
                "getBuzzType" -> {
                    val buzzType = intent?.getStringExtra("buzz_type") ?: pendingBuzzType
                    if (buzzType != null) {
                        result.success(buzzType)
                        // Clear the intent extra and pending buzz type to avoid repeated calls
                        intent?.removeExtra("buzz_type")
                        pendingBuzzType = null
                        Log.i(TAG, "Returned buzz_type: $buzzType")
                    } else {
                        result.success(null)
                    }
                }
                "isReady" -> {
                    // Flutter is ready, process any pending widget intents
                    processPendingWidgetIntent()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Give Flutter a moment to initialize, then process widget intent
        Handler(Looper.getMainLooper()).postDelayed({
            processPendingWidgetIntent()
        }, 500)
    }

    private fun processPendingWidgetIntent() {
        val buzzType = pendingBuzzType ?: intent?.getStringExtra("buzz_type")
        if (buzzType != null) {
            Log.i(TAG, "Processing widget intent with buzz_type: $buzzType")
            try {
                channel.invokeMethod("widgetBuzz", mapOf("type" to buzzType))
                Log.i(TAG, "Successfully invoked widgetBuzz method")
                // Clear after processing
                intent?.removeExtra("buzz_type")
                pendingBuzzType = null
            } catch (e: Exception) {
                Log.e(TAG, "Error invoking widgetBuzz method", e)
                // Don't clear pendingBuzzType if there was an error, so we can retry
            }
        } else {
            Log.d(TAG, "No pending widget intent to process")
        }
    }

    private fun handleWidgetIntent(intent: Intent?) {
        intent?.getStringExtra("buzz_type")?.let { buzzType ->
            Log.i(TAG, "Widget intent received with buzz_type: $buzzType")
            pendingBuzzType = buzzType

            // Try to process immediately if channel is available
            if (::channel.isInitialized) {
                try {
                    channel.invokeMethod("widgetBuzz", mapOf("type" to buzzType))
                    pendingBuzzType = null
                } catch (e: Exception) {
                    Log.e(TAG, "Error invoking widgetBuzz method", e)
                    // Keep pendingBuzzType for later processing
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // Important: Update the activity's intent
        if (intent.hasExtra("hce")) {
            onHCEResult(intent)
        }
        handleWidgetIntent(intent)
    }

    private fun onHCEResult(intent: Intent) {
        val command = intent.getIntExtra("hce", -1)
        if (command == 1) {
            Log.i(TAG, "Received HCE command 1")
            val expirationDate = HCEService.expirationDate.value
            if (expirationDate == null || expirationDate.after(Date())) {
                channel.invokeMethod("getAccessToken", null)
            } else {
                Log.i(TAG, "Token expired or null, not invoking getAccessToken")
            }
        }
    }
}
