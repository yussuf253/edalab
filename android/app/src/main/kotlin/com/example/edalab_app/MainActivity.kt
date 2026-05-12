package com.edalab.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.webviewflutter.WebViewFlutterPlugin

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    // Register WebView plugin
    flutterEngine.plugins.add(WebViewFlutterPlugin())

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "com.edalab.app/maps_config",
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "getGoogleMapsApiKey" -> {
          val appInfo = packageManager.getApplicationInfo(
            packageName,
            android.content.pm.PackageManager.GET_META_DATA,
          )
          result.success(appInfo.metaData?.getString("com.google.android.geo.API_KEY"))
        }
        else -> result.notImplemented()
      }
    }
  }
}

