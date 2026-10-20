import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    WidgetBridge.register(with: engineBridge.applicationRegistrar.messenger())
  }
}

/// Hands the data the home-screen / lock-screen widgets show to the widget
/// extension through the shared App Group, then asks WidgetKit to refresh.
enum WidgetBridge {
  static let appGroup = "group.com.alray.azkarna"
  static let payloadKey = "awwab_widget_payload"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "awwab/widgets", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "save":
        guard let json = call.arguments as? String else {
          result(FlutterError(code: "bad_args", message: "Expected a JSON string", details: nil))
          return
        }
        guard let defaults = UserDefaults(suiteName: appGroup) else {
          result(false)
          return
        }
        defaults.set(json, forKey: payloadKey)
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
