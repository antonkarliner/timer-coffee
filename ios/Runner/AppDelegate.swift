import UIKit
import Flutter
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let pendingExternalUrlKey = "pending_external_url"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Push notification tap handling (FCM/APNs)

  // Called when user taps a notification (or taps an action button).
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo

    // Debug (optional)
    print("🔔 AppDelegate: Notification tap received. userInfo keys: \(Array(userInfo.keys))")

    if let urlString = extractExternalUrl(from: userInfo) {
      print("🌐 AppDelegate: Storing pending external URL: \(urlString)")
      storePendingExternalUrl(urlString)
    } else {
      print("ℹ️ AppDelegate: No external URL found in notification payload")
    }

    // Important: forward to Flutter/Firebase handlers
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  private func storePendingExternalUrl(_ urlString: String) {
    UserDefaults.standard.set(urlString, forKey: pendingExternalUrlKey)
    // synchronize() is generally unnecessary nowadays, but harmless if you want immediate flush:
    // UserDefaults.standard.synchronize()
  }

  private func extractExternalUrl(from userInfo: [AnyHashable: Any]) -> String? {
    // Your backend sends these:
    // - external_url
    // - validated_url
    // - open_in_browser ("true"/true)
    // - link_type ("external_url")
    let linkType = (userInfo["link_type"] as? String)?.lowercased()
    let openInBrowser = boolFromAny(userInfo["open_in_browser"]) ?? false

    // Only treat as "open in browser" if your flags indicate it,
    // OR if it's clearly an external domain.
    let candidates: [String?] = [
      userInfo["validated_url"] as? String,
      userInfo["external_url"] as? String,
      userInfo["url"] as? String,
      userInfo["link"] as? String
    ]

    for candidate in candidates {
      guard let s = candidate?.trimmingCharacters(in: .whitespacesAndNewlines),
            !s.isEmpty,
            let url = URL(string: s) else { continue }

      if openInBrowser || linkType == "external_url" || shouldOpenExternally(url) {
        return url.absoluteString
      }
    }

    return nil
  }

  private func boolFromAny(_ value: Any?) -> Bool? {
    if let b = value as? Bool { return b }
    if let n = value as? NSNumber { return n.boolValue }
    if let s = value as? String {
      let v = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      if ["true", "1", "yes", "y"].contains(v) { return true }
      if ["false", "0", "no", "n"].contains(v) { return false }
    }
    return nil
  }

  // MARK: - Universal Links handling (your existing logic)

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {

    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let incomingURL = userActivity.webpageURL else {
      return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    print("🔍 AppDelegate: Received Universal Link - \(incomingURL.absoluteString)")

    if shouldOpenExternally(incomingURL) {
      print("🌐 AppDelegate: Redirecting external URL to Safari - \(incomingURL.absoluteString)")

      UIApplication.shared.open(incomingURL, options: [:]) { success in
        if success {
          print("✅ AppDelegate: Successfully opened URL in Safari")
        } else {
          print("❌ AppDelegate: Failed to open URL in Safari")
        }
      }
      return true
    }

    print("📱 AppDelegate: Passing internal URL to Flutter - \(incomingURL.absoluteString)")
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  // Determine if a URL should be opened externally (in Safari) rather than in the app
  private func shouldOpenExternally(_ url: URL) -> Bool {
    let urlString = url.absoluteString.lowercased()

    // If the URL contains external_url parameter or open_in_browser flag, open externally
    if urlString.contains("external_url=") || urlString.contains("open_in_browser=true") {
      return true
    }

    // Common external domains that should always open in browser
    let externalDomains = [
      "www.timer.coffee",
      "instagram.com",
      "facebook.com",
      "twitter.com",
      "x.com",
      "youtube.com"
    ]

    for domain in externalDomains {
      if urlString.contains(domain) {
        print("🌐 AppDelegate: External domain detected - \(domain)")
        return true
      }
    }

    return false
  }
}
