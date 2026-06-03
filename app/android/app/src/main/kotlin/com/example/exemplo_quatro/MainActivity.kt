package com.example.exemplo_quatro

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val foregroundChannelName = "br.sp.gov.cps.dsm.chat/connection_foreground_service"
    private val wifiDirectChannelName = "br.sp.gov.cps.dsm.chat/wifi_direct"
    private var wifiDirectTransport: WifiDirectTransport? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, foregroundChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        startConnectionService()
                        result.success(null)
                    }
                    "stop" -> {
                        stopService(Intent(this, ConnectionForegroundService::class.java))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        val wifiDirectChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            wifiDirectChannelName,
        )
        wifiDirectTransport = WifiDirectTransport(this, wifiDirectChannel)
        wifiDirectChannel.setMethodCallHandler(wifiDirectTransport)
    }

    override fun onDestroy() {
        wifiDirectTransport?.dispose()
        wifiDirectTransport = null
        super.onDestroy()
    }

    private fun startConnectionService() {
        val intent = Intent(this, ConnectionForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
