import UIKit
import Flutter
import Photos
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  // MARK: - Background task for keeping Flutter alive during brewing
  private var brewingBackgroundTaskId: UIBackgroundTaskIdentifier = .invalid
  private var analyticsFlushTaskId: UIBackgroundTaskIdentifier = .invalid
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let backgroundTaskRegistrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "TimerCoffeeBackgroundTask"
    ) {
      let bgTaskChannel = FlutterMethodChannel(
        name: "com.coffee.timer/background_task",
        binaryMessenger: backgroundTaskRegistrar.messenger()
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
        case "beginAnalyticsFlushTask":
          result(self.beginAnalyticsFlushTask())
        case "endAnalyticsFlushTask":
          self.endAnalyticsFlushTask()
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    } else {
      print("❌ AppDelegate: Background task registrar unavailable")
    }

    if let photoPickerRegistrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "TimerCoffeeInlinePhotoPicker"
    ) {
      let photoPickerChannel = FlutterMethodChannel(
        name: "com.coffee.timer/inline_photo_picker",
        binaryMessenger: photoPickerRegistrar.messenger()
      )

      photoPickerChannel.setMethodCallHandler { [weak self] call, result in
        guard let self = self, let controller = photoPickerRegistrar.viewController else {
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
    } else {
      print("❌ AppDelegate: Inline photo picker registrar unavailable")
    }

    if let photoLibraryRegistrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "TimerCoffeePhotoLibrary"
    ) {
      let photoLibraryChannel = FlutterMethodChannel(
        name: "com.coffee.timer/photo_library",
        binaryMessenger: photoLibraryRegistrar.messenger()
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
    } else {
      print("❌ AppDelegate: Photo library registrar unavailable")
    }
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

  private func beginAnalyticsFlushTask() -> Bool {
    endAnalyticsFlushTask()
    analyticsFlushTaskId = UIApplication.shared.beginBackgroundTask(
      withName: "AnalyticsFlush"
    ) { [weak self] in
      self?.endAnalyticsFlushTask()
    }
    return analyticsFlushTaskId != .invalid
  }

  private func endAnalyticsFlushTask() {
    guard analyticsFlushTaskId != .invalid else { return }
    UIApplication.shared.endBackgroundTask(analyticsFlushTaskId)
    analyticsFlushTaskId = .invalid
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

  // FlutterAppDelegate forwards notification taps to the registered plugins.
}
