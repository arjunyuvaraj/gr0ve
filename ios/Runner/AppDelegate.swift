// widget_appdelegate_patch.swift
//
// Merge this into your existing AppDelegate.swift.
// It adds the MethodChannel that WidgetBridge.dart calls,
// writes the JSON to the shared App Group, then tells
// WidgetKit to reload its timeline immediately.

import UIKit
import Flutter
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        // ── Widget bridge channel ────────────────────────────
        guard let controller = window?.rootViewController as? FlutterViewController
        else { return super.application(application, didFinishLaunchingWithOptions: launchOptions) }

        FlutterMethodChannel(
            name: "com.gr0ve.app/widget",
            binaryMessenger: controller.binaryMessenger
        ).setMethodCallHandler { call, result in
            guard call.method == "updateWidget",
                  let args = call.arguments as? [String: Any],
                  let json = try? JSONSerialization.data(withJSONObject: args),
                  let jsonStr = String(data: json, encoding: .utf8)
            else {
                result(FlutterError(code: "BAD_ARGS", message: nil, details: nil))
                return
            }

            // Write to App Group shared defaults
            let defaults = UserDefaults(suiteName: "group.com.arjunyuvaraj.gr0ve")
            defaults?.set(jsonStr, forKey: "gr0ve_widget_data")
            defaults?.synchronize()

            // Tell WidgetKit to reload immediately
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadTimelines(ofKind: "Gr0veWidget")
            }

            result(nil)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}