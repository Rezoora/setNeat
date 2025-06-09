//
//  CasualTableView.swift
//  Table Etiquette
//
//  Created by Bekhruzjon Hakmirzaev on 05/05/25.
//

import SwiftUI
import ARKit
import SceneKit

// MARK: - Casual Table Configuration
struct CasualTableConfiguration {
    static let casualTableSetting: [DishGuide] = [
        DishGuide(type: .plate, position: SCNVector3(0, 0, 0), size: DishType.plate.defaultSize),
        DishGuide(type: .fork, position: SCNVector3(-0.16, 0, 0), size: DishType.fork.defaultSize, rotation: 0),
        DishGuide(type: .knife, position: SCNVector3(0.16, 0, 0), size: DishType.knife.defaultSize, rotation: 0),
        DishGuide(type: .spoon, position: SCNVector3(0.23, 0, 0), size: DishType.spoon.defaultSize, rotation: 0),
        DishGuide(type: .cup, position: SCNVector3(0.18, 0, -0.18), size: DishType.cup.defaultSize)
        // Note: No bread plate in casual setting
    ]
}

struct CasualTableView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var feedbackManager = FeedbackManager()
    @StateObject private var guidanceManager = GuidanceManager()
    @State private var showingGuidance = false
    @State private var showingProgress = false
    @State private var completedItems: Set<DishType> = []
    
    // Casual setting excludes small plate
    private let casualDishTypes: [DishType] = [.plate, .fork, .knife, .spoon, .cup]
    
    var progressPercentage: Double {
        return Double(completedItems.count) / Double(casualDishTypes.count) * 100
    }
    
    var body: some View {
        ZStack {
            // AR View
            CasualARViewContainer(
                feedbackManager: feedbackManager,
                guidanceManager: guidanceManager,
                completedItems: $completedItems
            )
            .edgesIgnoringSafeArea(.all)
            
            // UI Overlay
            VStack {
                // Top Controls
                topControlsView
                
                // Feedback Display
                if feedbackManager.isShowingFeedback {
                    feedbackView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // Progress Indicator
                if showingProgress {
                    progressView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Bottom Instructions
                instructionsView
            }
            .animation(.easeInOut(duration: 0.3), value: feedbackManager.isShowingFeedback)
            .animation(.easeInOut(duration: 0.3), value: showingProgress)
        }
        .sheet(isPresented: $showingGuidance) {
            CasualGuidanceView()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(1.0)) {
                showingProgress = true
            }
        }
    }
    
    // MARK: - UI Components
    
    private var topControlsView: some View {
        HStack {
            // Back Button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            
            Spacer()
            
            // Title
            Text("Casual Table Setting")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
                .shadow(radius: 5)
            
            Spacer()
            
            HStack(spacing: 12) {
                // Guidance Button
                Button(action: { showingGuidance.toggle() }) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                
                // Reset Button
                Button(action: resetPlacement) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.orange.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
            }
        }
        .padding(.top, 50)
        .padding(.horizontal, 20)
    }
    
    private var feedbackView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: feedbackManager.currentFeedback.icon)
                    .font(.title3)
                    .foregroundColor(feedbackManager.currentFeedback.color)
                
                Text(feedbackManager.currentFeedback.message)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            if !feedbackManager.currentFeedback.subtitle.isEmpty {
                Text(feedbackManager.currentFeedback.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(radius: 10)
        )
        .padding(.horizontal)
    }
    
    private var progressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(completedItems.count)/\(casualDishTypes.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: progressPercentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            if progressPercentage == 100 {
                Text("🎉 Casual setting perfect!")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: 5)
        )
        .padding(.horizontal)
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Casual Dining Guide")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                instructionRow("1.", "Main plate in center")
                instructionRow("2.", "Fork on left")
                instructionRow("3.", "Knife & spoon on right")
                instructionRow("4.", "Glass above utensils")
                instructionRow("ℹ️", "No bread plate needed")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(radius: 10)
        )
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
    
    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack {
            Text(number)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            Text(text)
            Spacer()
        }
    }
    
    private func resetPlacement() {
        NotificationCenter.default.post(name: .resetCasualPlacement, object: nil)
        completedItems.removeAll()
        feedbackManager.showFeedback(.reset)
    }
}

// MARK: - Casual AR View Container
struct CasualARViewContainer: UIViewRepresentable {
    let feedbackManager: FeedbackManager
    let guidanceManager: GuidanceManager
    @Binding var completedItems: Set<DishType>
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            feedbackManager: feedbackManager,
            guidanceManager: guidanceManager,
            completedItems: $completedItems
        )
    }
    
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.delegate = context.coordinator
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        context.coordinator.sceneView = sceneView
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        sceneView.session.run(configuration)
        
        // Add gesture recognizers
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        sceneView.addGestureRecognizer(panGesture)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    // MARK: - Casual AR Coordinator
    class Coordinator: NSObject, ARSCNViewDelegate {
        weak var sceneView: ARSCNView?
        let feedbackManager: FeedbackManager
        let guidanceManager: GuidanceManager
        @Binding var completedItems: Set<DishType>
        
        private var dishGuides: [DishGuide] = []
        private var guideNodes: [SCNNode] = []
        private var selectedNode: SCNNode?
        private var hasPlacedGuides = false
        private let casualDishTypes: [DishType] = [.plate, .fork, .knife, .spoon, .cup]
        
        init(feedbackManager: FeedbackManager, guidanceManager: GuidanceManager, completedItems: Binding<Set<DishType>>) {
            self.feedbackManager = feedbackManager
            self.guidanceManager = guidanceManager
            self._completedItems = completedItems
            super.init()
            
            setupNotifications()
        }
        
        private func setupNotifications() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(resetPlacement),
                name: .resetCasualPlacement,
                object: nil
            )
        }
        
        @objc private func resetPlacement() {
            hasPlacedGuides = false
            guideNodes.forEach { $0.removeFromParentNode() }
            guideNodes.removeAll()
            dishGuides.removeAll()
            completedItems.removeAll()
        }
        
        // MARK: - ARSCNViewDelegate
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor,
                  !hasPlacedGuides else { return }
            
            hasPlacedGuides = true
            createCasualTableGuides(on: node, planeAnchor: planeAnchor)
        }
        
        private func createCasualTableGuides(on node: SCNNode, planeAnchor: ARPlaneAnchor) {
            let centerPosition = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            
            // Create guides based on casual table configuration
            for template in CasualTableConfiguration.casualTableSetting {
                let guide = DishGuide(
                    type: template.type,
                    position: SCNVector3(
                        centerPosition.x + template.position.x,
                        centerPosition.y,
                        centerPosition.z + template.position.z
                    ),
                    size: template.size,
                    rotation: template.rotation
                )
                
                dishGuides.append(guide)
                
                let guideNode = createGuideNode(for: guide)
                node.addChildNode(guideNode)
                guideNodes.append(guideNode)
            }
        }
        
        private func createGuideNode(for guide: DishGuide) -> SCNNode {
            let plane = SCNPlane(width: guide.size.width, height: guide.size.height)
            
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: guide.type.imageName)
            material.isDoubleSided = true
            material.transparency = 0.7
            
            // Blue tint for casual setting
            material.emission.contents = UIColor.blue.withAlphaComponent(0.1)
            
            plane.materials = [material]
            
            let node = SCNNode(geometry: plane)
            node.position = guide.position
            node.eulerAngles.x = -.pi / 2
            node.name = "\(guide.type.rawValue)_casual_guide"
            
            // Add subtle animation
            let breathingAction = SCNAction.sequence([
                SCNAction.fadeOpacity(to: 0.5, duration: 1.5),
                SCNAction.fadeOpacity(to: 0.8, duration: 1.5)
            ])
            node.runAction(SCNAction.repeatForever(breathingAction))
            
            return node
        }
        
        // MARK: - Gesture Handlers
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let sceneView = sceneView else { return }
            let location = gesture.location(in: sceneView)
            
            switch gesture.state {
            case .began:
                let hitResults = sceneView.hitTest(location, options: nil)
                selectedNode = hitResults.first?.node
                
            case .changed:
                guard let node = selectedNode else { return }
                
                let proj = sceneView.projectPoint(node.position)
                let newScreenPos = CGPoint(x: location.x, y: location.y)
                let newPos = sceneView.unprojectPoint(SCNVector3(
                    Float(newScreenPos.x),
                    Float(newScreenPos.y),
                    proj.z
                ))
                
                node.position = newPos
                checkPlacement(for: node)
                
            case .ended:
                guard let node = selectedNode else { return }
                finalizeePlacement(for: node)
                selectedNode = nil
                
            default:
                selectedNode = nil
            }
        }
        
        private func checkPlacement(for node: SCNNode) {
            guard let dishType = extractDishType(from: node.name),
                  let closestGuide = findClosestGuide(to: node.position, for: dishType) else { return }
            
            let distance = distance(from: node.position, to: closestGuide.position)
            let threshold: Float = 0.08
            
            if distance < threshold {
                node.opacity = 1.0
                highlightGuide(for: dishType, correct: true)
            } else {
                node.opacity = 0.7
                highlightGuide(for: dishType, correct: false)
            }
        }
        
        private func finalizeePlacement(for node: SCNNode) {
            guard let dishType = extractDishType(from: node.name),
                  let closestGuide = findClosestGuide(to: node.position, for: dishType) else { return }
            
            let distance = distance(from: node.position, to: closestGuide.position)
            let threshold: Float = 0.08
            
            if distance < threshold {
                node.position = closestGuide.position
                completedItems.insert(dishType)
                
                feedbackManager.showFeedback(.correct)
                
                // Check if all casual items are completed
                if completedItems.count == casualDishTypes.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.feedbackManager.showFeedback(.completed)
                    }
                }
                
                updateGuideCompletion(for: dishType, completed: true)
                
            } else {
                feedbackManager.showFeedback(.incorrect)
            }
        }
        
        // MARK: - Helper Methods
        private func extractDishType(from nodeName: String?) -> DishType? {
            guard let name = nodeName else { return nil }
            return DishType.allCases.first { name.contains($0.rawValue) }
        }
        
        private func findClosestGuide(to position: SCNVector3, for type: DishType) -> DishGuide? {
            return dishGuides.first { $0.type == type }
        }
        
        private func distance(from: SCNVector3, to: SCNVector3) -> Float {
            let dx = from.x - to.x
            let dy = from.y - to.y
            let dz = from.z - to.z
            return sqrt(dx*dx + dy*dy + dz*dz)
        }
        
        private func highlightGuide(for type: DishType, correct: Bool) {
            guard let guideNode = guideNodes.first(where: { $0.name?.contains(type.rawValue) == true }),
                  let material = guideNode.geometry?.materials.first else { return }
            
            if correct {
                material.emission.contents = UIColor.blue.withAlphaComponent(0.3)
            } else {
                material.emission.contents = UIColor.orange.withAlphaComponent(0.2)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                material.emission.contents = UIColor.blue.withAlphaComponent(0.1)
            }
        }
        
        private func updateGuideCompletion(for type: DishType, completed: Bool) {
            guard let guideNode = guideNodes.first(where: { $0.name?.contains(type.rawValue) == true }),
                  let material = guideNode.geometry?.materials.first else { return }
            
            if completed {
                material.diffuse.contents = UIColor.blue.withAlphaComponent(0.6)
                material.emission.contents = UIColor.blue.withAlphaComponent(0.3)
                
                let scaleUp = SCNAction.scale(to: 1.1, duration: 0.2)
                let scaleDown = SCNAction.scale(to: 1.0, duration: 0.2)
                let celebrate = SCNAction.sequence([scaleUp, scaleDown])
                guideNode.runAction(celebrate)
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// MARK: - Casual Guidance View
struct CasualGuidanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    let steps = [
        GuidanceStep(
            title: "Casual Dining",
            description: "Casual table settings are simpler and more relaxed than formal arrangements.",
            icon: "house.fill",
            color: .blue
        ),
        GuidanceStep(
            title: "Essential Items",
            description: "Focus on the basics: main plate, fork, knife, spoon, and one glass.",
            icon: "square.grid.2x2.fill",
            color: .green
        ),
        GuidanceStep(
            title: "Simple Layout",
            description: "Keep it simple - no bread plates or multiple utensils needed.",
            icon: "rectangle.3.group.fill",
            color: .orange
        ),
        GuidanceStep(
            title: "Relaxed Placement",
            description: "Spacing can be more relaxed, but maintain basic etiquette principles.",
            icon: "hand.wave.fill",
            color: .purple
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Text("Casual Table Setting Guide")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Perfect for everyday meals and informal gatherings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        VStack(spacing: 32) {
                            Image(systemName: steps[index].icon)
                                .font(.system(size: 80))
                                .foregroundColor(steps[index].color)
                            
                            VStack(spacing: 16) {
                                Text(steps[index].title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text(steps[index].description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                        }
                        .padding(.horizontal, 40)
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                
                HStack {
                    Button("Previous") {
                        if currentStep > 0 {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    }
                    .disabled(currentStep == 0)
                    
                    Spacer()
                    
                    if currentStep == steps.count - 1 {
                        Button("Start Setting") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    } else {
                        Button("Next") {
                            if currentStep < steps.count - 1 {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions
extension Notification.Name {
    static let resetCasualPlacement = Notification.Name("resetCasualPlacement")
}

#Preview {
    CasualTableView()
} 