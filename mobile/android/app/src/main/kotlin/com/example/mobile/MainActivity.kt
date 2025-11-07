package com.example.mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // AudioService plugin automatically registers itself when FlutterEngine is configured
        // No manual registration needed - the plugin finds the FlutterEngine automatically
    }
}
