//
//  PreviewViewController.swift
//  GiftWrap
//
//  Created by Niranjan Ravichandran on 8/26/22.
//

import UIKit
import SceneKit
import SceneKit.ModelIO

class PreviewViewController: UIViewController {

    private lazy var sceneView = setupSceneView()
    private lazy var activity: UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView()
        activity.style = .medium
        activity.translatesAutoresizingMaskIntoConstraints = false
        return activity
    }()

    private var isSceneSetup: Bool {
        view.subviews.contains(sceneView)
    }

    let modelLoader = ModelLoader()

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

        let toggleFloor = UIBarButtonItem(title: "Toggle Floor", style: .plain, target: self, action: #selector(toggleFloor))
        navigationItem.rightBarButtonItem = toggleFloor
    }

    @objc func toggleFloor() {
//        let spaceNode = sceneView.scene?.rootNode.childNodes
        print("Total nodes: \(sceneView.scene?.rootNode.childNodes.count ?? 0)")
        for node in sceneView.scene?.rootNode.childNodes ?? [] {
            debugPrint(node.name)
        }

        let roomNode = sceneView.scene!.rootNode.childNodes[1].childNodes[0]
        let boundingBox = roomNode.boundingBox
        let floorHeight: CGFloat = 0.1
        let boxOffset = Float(0.05) // 0.05m per side hangs off the wall
        let boxWidth = (boundingBox.max.x - boundingBox.min.x) + (boxOffset * 2)
        let boxLenght = (boundingBox.max.z - boundingBox.min.z) + (boxOffset * 2)
        let box = SCNBox(
            width: CGFloat(boxWidth),
            height: floorHeight,
            length: CGFloat(boxLenght),
            chamferRadius: 2.0
        )

        print("Bounding box: \(boundingBox)")
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "Floor"
        let x = boundingBox.min.x + (boxWidth / 2.0) - boxOffset
        let z = boundingBox.min.z + (boxLenght / 2.0) - boxOffset
        boxNode.localTranslate(by: .init(x: x, y: boundingBox.min.y - Float(box.height), z: z))
//        boxNode.
        roomNode.addChildNode(boxNode)
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

    func setupSceneIfNeeded() {
        if isSceneSetup { return }
        view.addSubview(sceneView)
        setupLayouts()
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
