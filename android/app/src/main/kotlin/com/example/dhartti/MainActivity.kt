package com.example.dhartti

import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            // Clean up any legacy background service handles from old apps sharing the test package name
            val prefsNames = listOf("FlutterSharedPreferences", "com.baseflow.geolocator.GeolocatorLocationService", "geolocator_service")
            for (name in prefsNames) {
                val sp = getSharedPreferences(name, Context.MODE_PRIVATE)
                val editor = sp.edit()
                for (key in sp.all.keys) {
                    if (key.contains("deliveazone", ignoreCase = true) || 
                        key.contains("callback", ignoreCase = true) || 
                        key.contains("geolocator", ignoreCase = true) || 
                        key.contains("location", ignoreCase = true)) {
                        editor.remove(key)
                    }
                }
                editor.apply()
            }
        } catch (_: Exception) {}
    }
}
