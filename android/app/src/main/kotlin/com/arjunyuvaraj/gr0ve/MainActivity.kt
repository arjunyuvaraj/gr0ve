package com.arjunyuvaraj.gr0ve

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Tell Android to do NOTHING when the keyboard appears.
        // Flutter handles all keyboard inset adjustments itself.
        // Without this, Android resizes/pans the window which conflicts
        // with Flutter's TextInputPlugin, causing the hide/show loop.
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_NOTHING)
    }
}