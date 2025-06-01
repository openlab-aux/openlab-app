package de.openlab.openlabflutter

import android.content.Intent
import android.os.Bundle
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent.hasExtra("hce")) {
            onHCEResult(intent)
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
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.hasExtra("hce")) {
            onHCEResult(intent)
        }
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
