import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var shareIntentChannel: FlutterMethodChannel?
  private var initialSharedText: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Check for incoming URL
    if let url = launchOptions?[.url] as? URL {
      handleIncomingURL(url)
    }

    // Setup method channel for share intent
    setupShareIntentChannel()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    handleIncomingURL(url)
    return true
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]) -> Void
  ) -> Bool {
    handleUserActivity(userActivity)
    return true
  }

  private func setupShareIntentChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      debugPrint("❌ Could not retrieve FlutterViewController")
      return
    }

    shareIntentChannel = FlutterMethodChannel(
      name: "margin/share_intent",
      binaryMessenger: controller.binaryMessenger
    )

    shareIntentChannel?.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate unavailable", details: nil))
        return
      }

      if call.method == "getInitialText" {
        result(self.initialSharedText)
        // Clear after consuming
        self.initialSharedText = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    debugPrint("✅ Share intent channel setup complete")
  }

  private func handleIncomingURL(_ url: URL) {
    // For iOS, URLs might come from share extensions
    // Extract text if URL contains data
    if url.scheme == "margin" {
      // Handle custom URL scheme if needed
      initialSharedText = url.absoluteString
    }
  }

  private func handleUserActivity(_ userActivity: NSUserActivity) {
    // Check for various activity types
    if userActivity.activityType == "com.apple.sharelink" ||
       userActivity.activityType == "INShareIntent" ||
       userActivity.activityType == "NSUserActivityTypeBrowsingWeb" {
      // Extract shared content from the activity
      if let webpageURL = userActivity.webpageURL {
        initialSharedText = webpageURL.absoluteString
        debugPrint("📥 Received share via user activity: \(initialSharedText ?? "nil")")
      }
    }
  }
}
