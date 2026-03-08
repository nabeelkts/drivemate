package com.example.mds

import android.os.Build
import android.view.View
import android.view.WindowInsets
import androidx.annotation.OptIn
import io.flutter.embedding.android.FlutterFragmentActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat

class MainActivity : FlutterFragmentActivity() {
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            // Make status and navigation bars transparent with proper contrast
            val window = this.window
            WindowCompat.setDecorFitsSystemWindows(window, false)
            
            // Set light/dark icons based on theme
            WindowInsetsControllerCompat(window, window.decorView).apply {
                isAppearanceLightStatusBars = true
                isAppearanceLightNavigationBars = true
            }
        }
    }
}
