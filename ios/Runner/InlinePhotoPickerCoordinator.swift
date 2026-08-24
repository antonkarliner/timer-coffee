import PhotosUI
import UniformTypeIdentifiers
import UIKit

/// Presents Apple's privacy-preserving photo library as a compact sheet and
/// copies only the files explicitly selected by the user into the app's temp
/// directory. The copied paths are handed back to Flutter as XFiles.
final class InlinePhotoPickerCoordinator: NSObject {
  enum PickerError: LocalizedError {
    case noUsableImages

    var errorDescription: String? {
      switch self {
      case .noUsableImages:
        return "The selected photos could not be loaded."
      }
    }
  }

  private var completion: ((Result<[String], Error>) -> Void)?
  private var didComplete = false

  func present(
    from presentingViewController: UIViewController,
    selectionLimit: Int,
    completion: @escaping (Result<[String], Error>) -> Void
  ) {
    self.completion = completion

    var configuration = PHPickerConfiguration()
    configuration.filter = .images
    configuration.selectionLimit = max(1, selectionLimit)
    configuration.preferredAssetRepresentationMode = .compatible

    if #available(iOS 15.0, *) {
      configuration.selection = .ordered
    }
    if #available(iOS 17.0, *) {
      configuration.mode = .default
      configuration.edgesWithoutContentMargins = [.leading, .trailing, .bottom]
    }

    let picker = PHPickerViewController(configuration: configuration)
    picker.delegate = self
    picker.modalPresentationStyle = .pageSheet

    if let sheet = picker.sheetPresentationController {
      sheet.prefersGrabberVisible = false
      sheet.prefersScrollingExpandsWhenScrolledToEdge = false
      sheet.preferredCornerRadius = 36

      if #available(iOS 16.0, *) {
        let compactIdentifier = UISheetPresentationController.Detent.Identifier(
          "timerCoffeePhotoPicker"
        )
        let compactDetent = UISheetPresentationController.Detent.custom(
          identifier: compactIdentifier
        ) { context in
          min(context.maximumDetentValue * 0.68, 660)
        }
        sheet.detents = [compactDetent, .large()]
        sheet.selectedDetentIdentifier = compactIdentifier
      } else {
        sheet.detents = [.medium(), .large()]
        sheet.selectedDetentIdentifier = .medium
      }
    }

    picker.presentationController?.delegate = self
    presentingViewController.present(picker, animated: true)
  }

  private func loadSelectedFiles(from results: [PHPickerResult]) {
    let group = DispatchGroup()
    let lock = NSLock()
    var copiedPaths = Array<String?>(repeating: nil, count: results.count)

    for (index, pickerResult) in results.enumerated() {
      let provider = pickerResult.itemProvider
      guard let typeIdentifier = provider.registeredTypeIdentifiers.first(where: {
        UTType($0)?.conforms(to: .image) == true
      }) else {
        continue
      }

      group.enter()
      provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, _ in
        defer { group.leave() }
        guard let sourceURL = url else { return }

        let preferredExtension = UTType(typeIdentifier)?.preferredFilenameExtension
        let fileExtension = preferredExtension ?? sourceURL.pathExtension
        let filename = UUID().uuidString + (fileExtension.isEmpty ? "" : ".\(fileExtension)")
        let destinationURL = FileManager.default.temporaryDirectory
          .appendingPathComponent(filename)

        do {
          try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
          lock.lock()
          copiedPaths[index] = destinationURL.path
          lock.unlock()
        } catch {
          // A later selected image may still load successfully. The flow only
          // fails if none of the user's selections can be copied.
        }
      }
    }

    group.notify(queue: .main) { [weak self] in
      let paths = copiedPaths.compactMap { $0 }
      if paths.isEmpty {
        self?.finish(.failure(PickerError.noUsableImages))
      } else {
        self?.finish(.success(paths))
      }
    }
  }

  private func finish(_ result: Result<[String], Error>) {
    guard !didComplete else { return }
    didComplete = true
    completion?(result)
    completion = nil
  }
}

extension InlinePhotoPickerCoordinator: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)

    guard !results.isEmpty else {
      finish(.success([]))
      return
    }

    loadSelectedFiles(from: results)
  }
}

extension InlinePhotoPickerCoordinator: UIAdaptivePresentationControllerDelegate {
  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    finish(.success([]))
  }
}
