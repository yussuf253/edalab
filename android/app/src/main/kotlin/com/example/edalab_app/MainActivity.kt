package com.edalab.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

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
