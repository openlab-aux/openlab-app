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

class MainActivity : FlutterActivity() {
    private val channel: MethodChannel by lazy { MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "hce") }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent.hasExtra("hce")) {
            onHCEResult(intent)
        }
    }

    override fun configureFlutterEngine(
        @NonNull flutterEngine: FlutterEngine,
    ) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hce").setMethodCallHandler {
                // This method is invoked on the main thread.
                call,
                result,
            ->
            if (call.method == "startHCE") {
                result.success(true)
            } else if (call.method == "accessToken") {
                print("It called after get")
                HCEService.tokenLiveData.setValue(call.argument<String>("accessToken"))
                val sdf: SimpleDateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS")
                Log.i("HCE", "MethodCall: " + sdf.parse(call.argument<String>("expirationDate")).toString())
                HCEService.expirationDate.setValue(sdf.parse(call.argument<String>("expirationDate")))
                result.success(true)
            } else {
                result.success(false)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent?.hasExtra("hce") == true) {
            onHCEResult(intent)
        }
    }

    private fun onHCEResult(intent: Intent) =
        intent.getIntExtra("hce", -1).let { success ->
            val command = intent.getIntExtra("hce", -1)
            if (command == 1) {
                Log.i("HCE", "command 1")
                val expirationDate: Date? = HCEService.expirationDate.value
                if (expirationDate == null || expirationDate.compareTo(Date()) > 0) {
                    channel.invokeMethod("getAccessToken", null)
                }
            }
        }
}
