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
        // ── Widget bridge channel ─────────────────────────────────────────────
        // home_widget package handles its own channel — we just need to tell
        // WidgetKit to reload all three timelines whenever the app launches
        // so widgets are fresh immediately on open.

        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "Gr0veBusWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "Gr0veTeacherWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "Gr0veScheduleWidget")
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}