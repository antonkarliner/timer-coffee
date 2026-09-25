import Flutter
import UIKit

enum ExternalLinkRouting {
  // Determine if a URL should be opened externally (in Safari) rather than in the app
  static func shouldOpenExternally(_ url: URL) -> Bool {
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

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let incomingURL = userActivity.webpageURL else {
      super.scene(scene, continue: userActivity)
      return
    }

    print("🔍 AppDelegate: Received Universal Link - \(incomingURL.absoluteString)")

    if ExternalLinkRouting.shouldOpenExternally(incomingURL) {
      print("🌐 AppDelegate: Redirecting external URL to Safari - \(incomingURL.absoluteString)")

      UIApplication.shared.open(incomingURL, options: [:]) { success in
        if success {
          print("✅ AppDelegate: Successfully opened URL in Safari")
        } else {
          print("❌ AppDelegate: Failed to open URL in Safari")
        }
      }
      return
    }

    print("📱 AppDelegate: Passing internal URL to Flutter - \(incomingURL.absoluteString)")
    super.scene(scene, continue: userActivity)
  }

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    for userActivity in connectionOptions.userActivities {
      guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL else { continue }

      print("🔍 AppDelegate: Received Universal Link - \(incomingURL.absoluteString)")

      if ExternalLinkRouting.shouldOpenExternally(incomingURL) {
        print("🌐 AppDelegate: Redirecting external URL to Safari - \(incomingURL.absoluteString)")

        UIApplication.shared.open(incomingURL, options: [:]) { success in
          if success {
            print("✅ AppDelegate: Successfully opened URL in Safari")
          } else {
            print("❌ AppDelegate: Failed to open URL in Safari")
          }
        }
      }
    }

    // Cold-start connection options cannot be filtered, so super also delivers the activity to Flutter.
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
