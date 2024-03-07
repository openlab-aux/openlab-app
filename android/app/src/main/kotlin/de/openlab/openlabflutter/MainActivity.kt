package de.openlab.openlabflutter
import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

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
                intent.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    putExtra("accessToken", call.argument<String>("accessToken"))
                }
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
            if (command == 0) {
                channel.invokeMethod("commandApdu", null)
            } else if (command == 1) {
                channel.invokeMethod("getAccessToken", null)
            }
        }
}
