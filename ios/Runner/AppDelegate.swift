import UIKit
import Flutter
import Photos
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let pendingExternalUrlKey = "pending_external_url"

  // MARK: - Background task for keeping Flutter alive during brewing
  private var brewingBackgroundTaskId: UIBackgroundTaskIdentifier = .invalid
  private var inlinePhotoPickerCoordinator: InlinePhotoPickerCoordinator?

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

    // Set up MethodChannel for background task management
    let controller = window?.rootViewController as! FlutterViewController
    let bgTaskChannel = FlutterMethodChannel(
      name: "com.coffee.timer/background_task",
      binaryMessenger: controller.binaryMessenger
    )

    bgTaskChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate deallocated", details: nil))
        return
      }
      switch call.method {
      case "startBrewingBackgroundTask":
        self.startBrewingBackgroundTask()
        result(true)
      case "stopBrewingBackgroundTask":
        self.stopBrewingBackgroundTask()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let photoPickerChannel = FlutterMethodChannel(
      name: "com.coffee.timer/inline_photo_picker",
      binaryMessenger: controller.binaryMessenger
    )

    photoPickerChannel.setMethodCallHandler { [weak self, weak controller] call, result in
      guard let self = self, let controller = controller else {
        result(FlutterError(code: "UNAVAILABLE", message: "Photo picker unavailable", details: nil))
        return
      }
      guard call.method == "pickImages" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard self.inlinePhotoPickerCoordinator == nil else {
        result(FlutterError(code: "ALREADY_ACTIVE", message: "Photo picker is already open", details: nil))
        return
      }

      let arguments = call.arguments as? [String: Any]
      let selectionLimit = arguments?["selectionLimit"] as? Int ?? 2
      let coordinator = InlinePhotoPickerCoordinator()
      self.inlinePhotoPickerCoordinator = coordinator

      coordinator.present(from: controller, selectionLimit: selectionLimit) { [weak self] pickerResult in
        self?.inlinePhotoPickerCoordinator = nil
        switch pickerResult {
        case .success(let paths):
          result(paths)
        case .failure(let error):
          result(FlutterError(code: "PHOTO_LOAD_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }

    let photoLibraryChannel = FlutterMethodChannel(
      name: "com.coffee.timer/photo_library",
      binaryMessenger: controller.binaryMessenger
    )

    photoLibraryChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "saveImages" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "Photo library unavailable", details: nil))
        return
      }
      let arguments = call.arguments as? [String: Any]
      guard let paths = arguments?["paths"] as? [String], !paths.isEmpty else {
        result(["status": "failed", "savedCount": 0, "failedCount": 0])
        return
      }

      self.saveImagesToPhotoLibrary(paths: paths, result: result)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func startBrewingBackgroundTask() {
    // End any existing task first
    if brewingBackgroundTaskId != .invalid {
      UIApplication.shared.endBackgroundTask(brewingBackgroundTaskId)
      brewingBackgroundTaskId = .invalid
    }

    brewingBackgroundTaskId = UIApplication.shared.beginBackgroundTask(
      withName: "BrewingTimer"
    ) { [weak self] in
      // Expiration handler: iOS is about to suspend us
      print("[BackgroundTask] Brewing background task expired by iOS")
      self?.stopBrewingBackgroundTask()
    }

    if brewingBackgroundTaskId == .invalid {
      print("[BackgroundTask] Failed to start brewing background task")
    } else {
      let remaining = UIApplication.shared.backgroundTimeRemaining
      print("[BackgroundTask] Started brewing background task (id=\(brewingBackgroundTaskId.rawValue), remaining=\(String(format: "%.0f", remaining))s)")
    }
  }

  private func stopBrewingBackgroundTask() {
    guard brewingBackgroundTaskId != .invalid else { return }
    print("[BackgroundTask] Ending brewing background task (id=\(brewingBackgroundTaskId.rawValue))")
    UIApplication.shared.endBackgroundTask(brewingBackgroundTaskId)
    brewingBackgroundTaskId = .invalid
  }

  // MARK: - Add-only photo library writes

  private func saveImagesToPhotoLibrary(paths: [String], result: @escaping FlutterResult) {
    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      switch status {
      case .authorized, .limited:
        self.savePhotoLibraryImages(paths, index: 0, savedCount: 0, result: result)
      case .denied, .restricted, .notDetermined:
        self.finishPhotoLibrarySave(
          status: "denied",
          savedCount: 0,
          failedCount: paths.count,
          result: result
        )
      @unknown default:
        self.finishPhotoLibrarySave(
          status: "unsupported",
          savedCount: 0,
          failedCount: paths.count,
          result: result
        )
      }
    }
  }

  private func savePhotoLibraryImages(
    _ paths: [String],
    index: Int,
    savedCount: Int,
    result: @escaping FlutterResult
  ) {
    guard index < paths.count else {
      let failedCount = paths.count - savedCount
      let status: String
      if failedCount == 0 {
        status = "saved"
      } else if savedCount == 0 {
        status = "failed"
      } else {
        status = "partial"
      }
      finishPhotoLibrarySave(
        status: status,
        savedCount: savedCount,
        failedCount: failedCount,
        result: result
      )
      return
    }

    let fileURL = URL(fileURLWithPath: paths[index])
    guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
      savePhotoLibraryImages(paths, index: index + 1, savedCount: savedCount, result: result)
      return
    }

    PHPhotoLibrary.shared().performChanges({
      let request = PHAssetCreationRequest.forAsset()
      let options = PHAssetResourceCreationOptions()
      options.originalFilename = fileURL.lastPathComponent
      options.shouldMoveFile = false
      request.addResource(with: .photo, fileURL: fileURL, options: options)
    }) { success, _ in
      self.savePhotoLibraryImages(
        paths,
        index: index + 1,
        savedCount: savedCount + (success ? 1 : 0),
        result: result
      )
    }
  }

  private func finishPhotoLibrarySave(
    status: String,
    savedCount: Int,
    failedCount: Int,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.main.async {
      result([
        "status": status,
        "savedCount": savedCount,
        "failedCount": failedCount
      ])
    }
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
