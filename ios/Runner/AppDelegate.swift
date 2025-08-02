import UIKit
import Flutter
import shared_preferences_foundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let sharedPreferencesChannel = FlutterMethodChannel(name: "plugins.flutter.io/shared_preferences",
                                                      binaryMessenger: controller.binaryMessenger)
    sharedPreferencesChannel.setMethodCallHandler { (call, result) in
      if call.method == "getAll" {
        result([:])
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
