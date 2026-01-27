import Flutter
import UIKit
import MovementSdk

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Movement SDK
    MovementSdkManager.shared.configure(
      withConsumerKey: "YOUR_CONSUMER_KEY",
      secret: "YOUR_CONSUMER_SECRET",
      oauthToken: nil,
      delegate: nil,
      completion: nil
    )

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
