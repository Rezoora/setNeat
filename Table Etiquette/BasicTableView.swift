//
//  BasicTableView.swift
//  Table Etiquette
//
//  Created by Bekhruzjon Hakmirzaev on 05/05/25.
//

import SwiftUI
import AVFoundation
import Vision
import RealityKit
import ARKit
import SceneKit

struct BasicTabelView: View {
    @StateObject private var tableAnalyzer = TableAnalyzer()

    var body: some View {
        ZStack {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

class TableAnalyzer: ObservableObject {
    @Published var dishPositions: [CGPoint] = []
    private let sequenceHandler = VNSequenceRequestHandler()

    func analyze(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            if let results = request.results as? [VNRectangleObservation], let table = results.first {
                // Compute dish positions based on table corners (stub implementation)
                let screenSize = UIScreen.main.bounds.size
                let topLeft = CGPoint(x: table.topLeft.x * screenSize.width,
                                      y: (1 - table.topLeft.y) * screenSize.height)
                // Add additional dish positions here as needed
                DispatchQueue.main.async {
                    self.dishPositions = [topLeft]
                }
            }
        }
        try? sequenceHandler.perform([request], on: pixelBuffer)
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        weak var sceneView: ARSCNView?
        var selectedNode: SCNNode?
        var initialScale: SCNVector3 = SCNVector3(1, 1, 1)
        var initialRotation: Float = 0.0

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let sceneView = sceneView else { return }
            let location = gesture.location(in: sceneView)

            switch gesture.state {
            case .began:
                let hits = sceneView.hitTest(location, options: nil)
                if let hitNode = hits.first?.node {
                    selectedNode = hitNode
                }
            case .changed:
                if let node = selectedNode {
                    // Project node to screen, keep its z-depth
                    let proj = sceneView.projectPoint(node.position)
                    let newScreen = SCNVector3(Float(location.x), Float(location.y), proj.z)
                    let newPos = sceneView.unprojectPoint(newScreen)
                    node.position = newPos
                }
            default:
                selectedNode = nil
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let sceneView = sceneView else { return }
            let location = gesture.location(in: sceneView)
            switch gesture.state {
            case .began:
                let hits = sceneView.hitTest(location, options: nil)
                if let hitNode = hits.first?.node {
                    selectedNode = hitNode
                    initialScale = hitNode.scale
                }
            case .changed:
                if let node = selectedNode {
                    let scale = Float(gesture.scale)
                    node.scale = SCNVector3(initialScale.x * scale,
                                             initialScale.y * scale,
                                             initialScale.z * scale)
                }
            case .ended, .cancelled:
                selectedNode = nil
            default:
                break
            }
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let sceneView = sceneView else { return }
            let location = gesture.location(in: sceneView)
            switch gesture.state {
            case .began:
                let hits = sceneView.hitTest(location, options: nil)
                if let hitNode = hits.first?.node {
                    selectedNode = hitNode
                    initialRotation = hitNode.eulerAngles.y
                }
            case .changed:
                if let node = selectedNode {
                    let rotation = Float(gesture.rotation)
                    node.eulerAngles.y = initialRotation - rotation
                }
            case .ended, .cancelled:
                selectedNode = nil
            default:
                break
            }
        }
        
        @objc func placeUtensils(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = sceneView,
                  let spoonNode = sceneView.scene.rootNode.childNode(withName: "spoonContainer", recursively: true),
                  let forkNode = sceneView.scene.rootNode.childNode(withName: "forkContainer", recursively: true) else { return }

            let tapLocation = gesture.location(in: sceneView)

            // Raycast onto existing horizontal plane geometry at the tap location
            guard let query = sceneView.raycastQuery(from: tapLocation,
                                                     allowing: .existingPlaneGeometry,
                                                     alignment: .horizontal) else { return }
            let results = sceneView.session.raycast(query)
            guard let first = results.first else { return }

            // Move both utensils so their bases sit flush with the surface
            let transform = first.worldTransform
            
            // Position spoon
            spoonNode.simdTransform = transform
            let (spoonMin, spoonMax) = spoonNode.boundingBox
            let spoonHeight = spoonMax.y - spoonMin.y
            spoonNode.position.y += Float(spoonHeight / 2)
            spoonNode.position.x += 0.2 // 20cm to the right
            spoonNode.isHidden = false
            
            // Position fork
            forkNode.simdTransform = transform
            let (forkMin, forkMax) = forkNode.boundingBox
            let forkHeight = forkMax.y - forkMin.y
            forkNode.position.y += Float(forkHeight / 2)
            forkNode.position.x -= 0.2 // 20cm to the left
            forkNode.isHidden = false
        }
    }

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        // Assign coordinator and add pan gesture for dragging
        sceneView.autoenablesDefaultLighting = true
        context.coordinator.sceneView = sceneView
        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.handlePinch(_:)))
        sceneView.addGestureRecognizer(pinch)

        let rotation = UIRotationGestureRecognizer(target: context.coordinator,
                                                   action: #selector(Coordinator.handleRotation(_:)))
        sceneView.addGestureRecognizer(rotation)

        // Start AR session without plane detection
        // Start AR session **with horizontal‑plane detection** so we can place the spoon on the table surface
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        sceneView.session.run(config)

        // Attempt to load the models via URL
        guard let spoonUrl = Bundle.main.url(forResource: "spoon", withExtension: "usdz"),
              let spoonScene = try? SCNScene(url: spoonUrl, options: nil),
              let forkUrl = Bundle.main.url(forResource: "fork", withExtension: "usdz"),
              let forkScene = try? SCNScene(url: forkUrl, options: nil) else {
            print("⚠️ Could not load models – make sure the files are in the target's Copy Bundle Resources")
            return sceneView
        }

        // Create container nodes for both utensils
        let spoonNode = SCNNode()
        spoonNode.name = "spoonContainer"
        for child in spoonScene.rootNode.childNodes {
            spoonNode.addChildNode(child)
        }

        let forkNode = SCNNode()
        forkNode.name = "forkContainer"
        for child in forkScene.rootNode.childNodes {
            forkNode.addChildNode(child)
        }

        // Set initial positions and scales
        spoonNode.scale = SCNVector3(0.1, 0.1, 0.1)
        forkNode.scale = SCNVector3(0.1, 0.1, 0.1)
        
        // Position fork on the left, spoon on the right
        forkNode.position = SCNVector3(-0.2, 0, -0.7) // 20cm to the left
        spoonNode.position = SCNVector3(0.2, 0, -0.7)  // 20cm to the right
        
        spoonNode.isHidden = true
        forkNode.isHidden = true
        
        sceneView.scene.rootNode.addChildNode(spoonNode)
        sceneView.scene.rootNode.addChildNode(forkNode)

        // Tap once to drop both utensils onto the nearest horizontal surface
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.placeUtensils(_:)))
        sceneView.addGestureRecognizer(tap)

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) { }
}
