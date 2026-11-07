import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Shared with the PrayerWidget extension.
  private static let appGroupId = "group.com.alray.azkarna"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Prayer times for the lock-screen / home-screen widget.
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AwwabPrayerWidget")
    else { return }
    let channel = FlutterMethodChannel(
      name: "awwab/widget", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "update", let args = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      let defaults = UserDefaults(suiteName: AppDelegate.appGroupId)
      defaults?.set(args["prayers"] as? String, forKey: "prayers")
      defaults?.set(args["city"] as? String, forKey: "city")
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
      }
      result(true)
    }
  }
}
