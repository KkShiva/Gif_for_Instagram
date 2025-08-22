package com.Shiva.insta_gif // your package

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.arthenica.ffmpegkit.FFmpegKit

class MainActivity : FlutterActivity() {
    private val CHANNEL = "ffmpeg"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "execute") {
                val command = call.argument<String>("command")
                if (command != null) {
                    Thread {
                        FFmpegKit.execute(command)
                        result.success(null)
                    }.start()
                } else {
                    result.error("INVALID", "Command is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
