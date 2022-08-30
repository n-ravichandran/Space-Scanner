//
//  RoomCaptureViewController.swift
//  SpaceScanner
//
//  Created by Niranjan Ravichandran on 8/25/22.
//

import UIKit
import RoomPlan

private enum ScanState {
    case ready
    case inProgress
    case done(CapturedRoom)

    var isInProgress: Bool {
        switch self {
            case .inProgress:
                return true
            default:
                return false
        }
    }
}

class RoomCaptureViewController: UIViewController {

    private let roomCaptureView: RoomCaptureView
    private var roomCaptureSessionConfig: RoomCaptureSession.Configuration = {
        var config = RoomCaptureSession.Configuration()
        config.isCoachingEnabled = true
        return config
    }()

    private var scanState: ScanState = .ready {
        didSet {
            updateNavbar()
        }
    }

    init() {
        roomCaptureView = RoomCaptureView(frame: UIScreen.main.bounds)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupRoomCaptureView()
        setupLayout()
        updateNavbar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        startScan()
    }

    func setupRoomCaptureView() {
        view.addSubview(roomCaptureView)
    }


    func updateNavbar() {
        let scanButton = UIBarButtonItem(title: "Scan", style: .plain, target: self, action: #selector(startScan))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(stopScan))
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(attemptExport))
        let cancelButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(cancelTapped))

        switch scanState {
            case .ready:
                navigationItem.rightBarButtonItem = scanButton
                navigationItem.leftBarButtonItem = cancelButton
            case .inProgress:
                navigationItem.rightBarButtonItem = doneButton
                navigationItem.leftBarButtonItem = nil
            case .done:
                navigationItem.rightBarButtonItem = saveButton
                navigationItem.leftBarButtonItem = cancelButton
        }
    }

    @objc func cancelTapped() {
        dismiss(animated: true)
    }

    func setupLayout() {
        roomCaptureView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            roomCaptureView.topAnchor.constraint(equalTo: view.topAnchor),
            roomCaptureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roomCaptureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            roomCaptureView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

}

// MARK: - Private Helpers

private extension RoomCaptureViewController {

    func export(_ room: CapturedRoom) {
        view.isUserInteractionEnabled = false
        let exportPath = FileManager.default.temporaryDirectory.appending(path: "Captured_Space_\(UUID().uuidString).usdz")
        do {
            try room.export(to: exportPath)
            showActivitySheet(activityItems: [exportPath])
        } catch {
            debugPrint("Error: \(error.localizedDescription)")
            showAlert(title: "Export failed", message: error.localizedDescription)
        }
    }

    func didFinishScanning(capturedRoom: CapturedRoom) {
        if capturedRoom.isValidScan { return }

        scanState = .ready
        showIncompleteScanAlert()
    }

    func showIncompleteScanAlert() {
        showAlert(title: "Incomplete Scan", message: "No objects found in the scan. Please try scanning again.")
    }

}

// MARK: - Event Handlers

private extension RoomCaptureViewController {

    @objc func startScan() {
        roomCaptureView.captureSession.run(configuration: roomCaptureSessionConfig)
        roomCaptureView.delegate = self
        scanState = .inProgress
    }

    @objc func stopScan() {
        roomCaptureView.captureSession.stop()
    }

    @objc func attemptExport() {
        guard case let ScanState.done(capturedRoom) = scanState else {
            print("Scan not done to export...")
            return
        }

        export(capturedRoom)
    }

}

// MARK: - RoomCaptureViewDelegate

extension RoomCaptureViewController: RoomCaptureViewDelegate {

    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        if let errorMessage = error?.localizedDescription {
            debugPrint("Captured room data with error: \(errorMessage)")
        }

        return true
    }


    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        scanState = .done(processedResult)
        didFinishScanning(capturedRoom: processedResult)
    }

}
