//
//  BasicTabelView.swift
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
    }

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        // Assign coordinator and add pan gesture for dragging
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
        let config = ARWorldTrackingConfiguration()
        sceneView.session.run(config)

        // Place a 0.3×0.3m plane with the dishShape image fixed in front of the camera
        let plane = SCNPlane(width: 0.3, height: 0.3)
        plane.firstMaterial?.diffuse.contents = UIImage(named: "dishShape")
        plane.firstMaterial?.isDoubleSided = true
        let node = SCNNode(geometry: plane)
        node.eulerAngles.x = -.pi / 2
        node.position = SCNVector3(0, -0.1, -0.5)
        sceneView.scene.rootNode.addChildNode(node)

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) { }
}
