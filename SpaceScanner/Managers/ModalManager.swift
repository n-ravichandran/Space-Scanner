//
//  ModalManager.swift
//  SpaceScanner
//
//  Created by Niranjan Ravichandran on 8/27/22.
//

import UIKit

enum LoaderError: LocalizedError {
    case noURL
    case exportError(Error)
    case cancelled

    var errorDescription: String? {
        switch self {
            case .noURL: return "No URL found"
            case .exportError(let underlyingError): return underlyingError.localizedDescription
            case .cancelled: return "No file selected. Please select a file to view a previous scan."
        }
    }
}

class ModelLoader: NSObject {

    var pickerCompletion: ((Result<URL, LoaderError>) -> Void)?

    func showPicker(from viewController: UIViewController) async throws -> URL {
        return try await withCheckedThrowingContinuation { checkedContinuation in
            self.pickerCompletion = { checkedContinuation.resume(with: $0) }
            DispatchQueue.main.async {
                let documentPicker = UIDocumentPickerViewController(
                    forOpeningContentTypes: [.usdz, .usd],
                    asCopy: true
                )
                documentPicker.delegate = self
                viewController.present(documentPicker, animated: true)
            }
        }
    }

}

// MARK: - UIDocumentPickerDelegate

extension ModelLoader: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            pickerCompletion?(.failure(.noURL))
            return
        }

        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }

        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { url in
            do {
                let exportPath = FileManager.default.temporaryDirectory.appending(path: "Captured_Space_\(UUID().uuidString).usdz")
                try FileManager.default.copyItem(at: url, to: exportPath)
                self.pickerCompletion?(.success(exportPath))
            } catch {
                self.pickerCompletion?(.failure(.exportError(error)))
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        pickerCompletion?(.failure(.cancelled))
    }

}
