//
//  PreviewViewController.swift
//  GiftWrap
//
//  Created by Niranjan Ravichandran on 8/26/22.
//

import UIKit
import RoomPlan
import SceneKit
import SceneKit.ModelIO

private enum SelectionState {
    case `none`
    case surface(SCNNode)
}

class PreviewViewController: UIViewController {

    private lazy var sceneView = setupSceneView()
    private lazy var activity = setupActivity()
    private lazy var slidingGesture = setupSlidingGesture()

    private let modelLoader = ModelLoader()
    private var selectionState: SelectionState = .none

    private var isSceneSetup: Bool {
        view.subviews.contains(sceneView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        loadModel()
    }

    func loadModel() {
        Task {
            do {
                startActivity()
                let url = try await modelLoader.showPicker(from: self)
                setupSceneIfNeeded()
                addModel(path: url)
                stopActivity()
            } catch {
                stopActivity()
                let alert = UIAlertController(
                    title: "Error loading model",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
                present(alert, animated: true)
            }
        }
    }

    func addModel(path: URL) {
        startActivity()
        Task {
            let asset = MDLAsset(url: path)
            let scene = SCNScene(mdlAsset: asset)
            await MainActor.run { [weak self] in
                guard let self = self else { return }

                scene.rootNode.markAsSpaceNode()

                switch self.sceneView.scene {
                case let .some(existingScene):
                    existingScene.rootNode.addChildNode(scene.rootNode)
                case .none:
                    // We'll create an empty scene and append our model to it as a child node.
                    // This way we append each model as a separate child node, instead of adding new models as child nodes
                    // to the initial model.
                    // This way selection opacity / transforms are limited to each model separately, so it just makes
                    // operations much easier.
                    //
                    // We also prepare a camera node (which will be controlled by SCNCameraController / SCNView's defaultCameraController),
                    // if we do not set this up and let SceneKit add a default camera node, we can't move the camera via defaultCameraController

                    let rootScene = SCNScene()

                    let cameraNode = SCNNode()
                    cameraNode.camera = SCNCamera()
                    cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
                    rootScene.rootNode.addChildNode(cameraNode)
                    rootScene.rootNode.addChildNode(scene.rootNode)
                    self.sceneView.scene = rootScene

                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 1
                    let cameraController = self.sceneView.defaultCameraController
                    let rotation = (Float.pi / 4) * 50
                    cameraController.rotateBy(x: rotation, y: -rotation)
                    SCNTransaction.commit()
                }
                self.stopActivity()
            }
        }
    }

}

// MARK: - UI Helpers

private extension PreviewViewController {

    func setupView() {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.black.cgColor, UIColor.darkGray.cgColor]
        view.layer.insertSublayer(gradient, at: 0)

        let toggleFloor = UIBarButtonItem(title: "Add Floor", style: .plain, target: self, action: #selector(addFloor))
        let exportScene = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(exportScene))
        navigationItem.rightBarButtonItems = [toggleFloor, exportScene]
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
    }

    func startActivity() {
        guard !view.subviews.contains(where: { $0 == activity }) else { return }
        view.addSubview(activity)
        NSLayoutConstraint.activate([
            activity.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])
        activity.startAnimating()
    }

    func stopActivity() {
        activity.stopAnimating()
        activity.removeFromSuperview()
    }

    func setupSceneView() -> SCNView {
        let scnView = SCNView(frame: .zero)
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling2X
        scnView.preferredFramesPerSecond = 60
        scnView.rendersContinuously = true
        scnView.showsStatistics = true
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        return scnView
    }

    func setupActivity() -> UIActivityIndicatorView {
        let activity = UIActivityIndicatorView()
        activity.style = .medium
        activity.translatesAutoresizingMaskIntoConstraints = false
        return activity
    }

    func setupSlidingGesture() -> UIPanGestureRecognizer {
        let slidingGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSlideInScene(sender:)))
        slidingGesture.minimumNumberOfTouches = 2
        slidingGesture.maximumNumberOfTouches = 2
        slidingGesture.isEnabled = false
        return slidingGesture
    }

    func setupSceneIfNeeded() {
        if isSceneSetup { return }
        view.addSubview(sceneView)
        setupLayouts()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapInScene(sender:)))
        sceneView.addGestureRecognizer(tapGesture)
        sceneView.addGestureRecognizer(slidingGesture)
    }

    func setupLayouts() {
        sceneView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

}

// MARK: - Event Handlers

private extension PreviewViewController {

    @objc func closeTapped() {
        dismiss(animated: true)
    }

    @objc func exportScene() {
        guard let scene = sceneView.scene else { return }
        let exportPath = FileManager.default.temporaryDirectory.appending(path: "Scene_\(UUID().uuidString).usdz")
        let exportSuccess = scene.write(
            to: exportPath,
            options: nil,
            delegate: nil,
            progressHandler: { progress, error, _ in
                debugPrint("[] Progress exporting: \(progress), error: \(String(describing: error))")
            })

        guard exportSuccess else {
            let alert = UIAlertController(
                title: nil,
                message: "Could not export model",
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let activity = UIActivityViewController(activityItems: [exportPath], applicationActivities: nil)
        activity.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.dismiss(animated: true)
        }
        present(activity, animated: true)
    }

    @objc func addFloor() {
        let roomNode = sceneView.scene!.rootNode.childNodes[1].childNodes[0] // Fix this later
        let boundingBox = roomNode.boundingBox
        let floorHeight: CGFloat = 0.11
        let boxOffset = Float(0.005) // 0.05m per side hangs off the wall
        let boxWidth = (boundingBox.max.x - boundingBox.min.x) + (boxOffset * 2)
        let boxLenght = (boundingBox.max.z - boundingBox.min.z) + (boxOffset * 2)
        let box = SCNBox(
            width: CGFloat(boxWidth),
            height: floorHeight,
            length: CGFloat(boxLenght),
            chamferRadius: 0
        )

        print("Bounding box: \(boundingBox)")
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "Floor"
        let x = boundingBox.min.x + (boxWidth / 2.0) - boxOffset
        let z = boundingBox.min.z + (boxLenght / 2.0) - boxOffset
        boxNode.localTranslate(by: .init(x: x, y: boundingBox.min.y - Float(box.height), z: z))
        roomNode.addChildNode(boxNode)
    }

    @objc func handleSlideInScene(sender: UIPanGestureRecognizer) {
        guard case let SelectionState.surface(selectedNode) = selectionState else { return }

        let translation = sender.translation(in: sender.view)

        let x = Float(translation.x)
        let y = Float(-translation.y)
        let anglePan = (sqrt(pow(x,2)+pow(y,2)))*(Float)(Double.pi)/180.0

        var rotationVector = SCNVector4()
        rotationVector.x = 0.0
        rotationVector.y = x
        rotationVector.z = 0.0
        rotationVector.w = anglePan


        selectedNode.rotation = rotationVector

        if(sender.state == .ended) {
            let currentPivot = selectedNode.pivot
            let changePivot = SCNMatrix4Invert(selectedNode.transform)

            selectedNode.pivot = SCNMatrix4Mult(changePivot, currentPivot)
            selectedNode.transform = SCNMatrix4Identity
        }
    }

    @objc func handleTapInScene(sender: UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        let node = sceneView.hitTest(
            location,
            options: [.boundingBoxOnly: false, .searchMode: SCNHitTestSearchMode.all.rawValue]
        ).map(\.node)
            .first(where: { $0.type != nil })

        guard let selectedNode = node, selectedNode.type != .furniture else {
            return
        }

        let previousSelectionState = selectionState
        switch previousSelectionState {
            case .none:
                selectedNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGreen.withAlphaComponent(0.6)
                selectionState = .surface(selectedNode)
                slidingGesture.isEnabled = selectedNode.type == .floor
                sceneView.allowsCameraControl = false
            case .surface(let node):
                selectionState = .none
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
                slidingGesture.isEnabled = false
                sceneView.allowsCameraControl = true
        }
    }

}
