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

// MARK: - Dish Guide Model
struct DishGuide: Identifiable {
    let id = UUID()
    let type: DishType
    var position: SCNVector3
    var isCorrect: Bool = false
    let size: CGSize
    var rotation: Float = 0.0
    var opacity: Float = 0.7
}

// MARK: - Dish Types Enum
enum DishType: String, CaseIterable {
    case plate = "plate"
    case fork = "fork"
    case knife = "knife"
    case spoon = "spoon"
    case cup = "cup"
    case smallPlate = "small_plate"
    
    var imageName: String {
        return self.rawValue
    }
    
    var displayName: String {
        switch self {
        case .plate: return "Dinner Plate"
        case .fork: return "Fork"
        case .knife: return "Knife"
        case .spoon: return "Spoon"
        case .cup: return "Glass/Cup"
        case .smallPlate: return "Bread Plate"
        }
    }
    
    var defaultSize: CGSize {
        switch self {
        case .plate: return CGSize(width: 0.27, height: 0.27)      // 27cm dinner plate
        case .fork: return CGSize(width: 0.04, height: 0.20)       // 4cm x 20cm fork
        case .knife: return CGSize(width: 0.04, height: 0.23)      // 4cm x 23cm knife
        case .spoon: return CGSize(width: 0.04, height: 0.18)      // 4cm x 18cm spoon
        case .cup: return CGSize(width: 0.08, height: 0.08)        // 8cm glass
        case .smallPlate: return CGSize(width: 0.15, height: 0.15) // 15cm bread plate
        }
    }
    
    var placementDescription: String {
        switch self {
        case .plate: return "Center of the place setting"
        case .fork: return "Left side of the plate"
        case .knife: return "Right side of the plate, blade facing inward"
        case .cup: return "Upper right area"
        case .spoon: return "Right side of the plate"
        case .smallPlate: return "Upper left area"
        }
    }
}

// MARK: - Table Configuration
struct TableConfiguration {
    static let basicTableSetting: [DishGuide] = [
        DishGuide(type: .plate, position: SCNVector3(0, 0, 0), size: DishType.plate.defaultSize),
        DishGuide(type: .fork, position: SCNVector3(-0.18, 0, 0), size: DishType.fork.defaultSize, rotation: 0),
        DishGuide(type: .knife, position: SCNVector3(0.18, 0, 0), size: DishType.knife.defaultSize, rotation: 0),
        DishGuide(type: .cup, position: SCNVector3(0.25, 0, -0.15), size: DishType.cup.defaultSize)
    ]
}

// MARK: - BasicTableView
struct BasicTableView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var feedbackManager = FeedbackManager()
    @StateObject private var guidanceManager = GuidanceManager()
    @State private var showingGuidance = false
    @State private var showingProgress = false
    @State private var completedItems: Set<DishType> = []
    
    var progressPercentage: Double {
        return Double(completedItems.count) / Double(DishType.allCases.count) * 100
    }
    
    var body: some View {
        ZStack {
            // AR View
            ARViewContainer(
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
            GuidanceView()
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
            Text("Basic Table Setting")
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
                Text("\(completedItems.count)/\(DishType.allCases.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: progressPercentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            if progressPercentage == 100 {
                Text("🎉 Perfect! Well done!")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
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
            Text("Quick Guide")
                        .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                instructionRow("1.", "Place dinner plate in center")
                instructionRow("2.", "Fork on the left side")
                instructionRow("3.", "Knife on the right side")
                instructionRow("4.", "Glass in upper right area")
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
                .foregroundColor(.accentColor)
            Text(text)
            Spacer()
        }
    }
    
    private func resetPlacement() {
        NotificationCenter.default.post(name: .resetPlacement, object: nil)
        completedItems.removeAll()
        feedbackManager.showFeedback(.reset)
    }
}

// MARK: - Feedback Manager
class FeedbackManager: ObservableObject {
    @Published var isShowingFeedback = false
    @Published var currentFeedback = FeedbackType.neutral
    
    private var feedbackTimer: Timer?
    
    func showFeedback(_ type: FeedbackType, duration: TimeInterval = 3.0) {
        feedbackTimer?.invalidate()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFeedback = type
            isShowingFeedback = true
        }
        
        // Haptic feedback
        triggerHapticFeedback(for: type)
        
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                self.isShowingFeedback = false
            }
        }
    }
    
    private func triggerHapticFeedback(for type: FeedbackType) {
        switch type {
        case .correct:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .incorrect:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .reset:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .completed:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            // Add celebration haptics
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                generator.notificationOccurred(.success)
            }
        case .neutral:
            break
        }
    }
}

// MARK: - Feedback Types
enum FeedbackType {
    case correct
    case incorrect
    case completed
    case reset
    case neutral
    
    var message: String {
        switch self {
        case .correct: return "Perfect Placement! ✨"
        case .incorrect: return "Not quite right"
        case .completed: return "🎉 Table Setting Complete!"
        case .reset: return "Table Reset"
        case .neutral: return ""
        }
    }
    
    var subtitle: String {
        switch self {
        case .correct: return "Keep going!"
        case .incorrect: return "Try adjusting the position"
        case .completed: return "Excellent work on your table etiquette!"
        case .reset: return "Start fresh with your placement"
        case .neutral: return ""
        }
    }
    
    var icon: String {
        switch self {
        case .correct: return "checkmark.circle.fill"
        case .incorrect: return "exclamationmark.triangle.fill"
        case .completed: return "star.fill"
        case .reset: return "arrow.counterclockwise.circle.fill"
        case .neutral: return ""
        }
    }
    
    var color: Color {
        switch self {
        case .correct: return .green
        case .incorrect: return .orange
        case .completed: return .yellow
        case .reset: return .blue
        case .neutral: return .primary
        }
    }
}

// MARK: - Guidance Manager
class GuidanceManager: ObservableObject {
    @Published var currentStep = 0
    @Published var isActive = false
    
    let steps = [
        "Scan the table surface by moving your device slowly",
        "Wait for the placement guides to appear",
        "Place real utensils inside the outlined shapes",
        "Watch for green feedback when positioned correctly",
        "Complete all items for a perfect table setting"
    ]
}

// MARK: - Extensions
extension Notification.Name {
    static let resetPlacement = Notification.Name("resetPlacement")
    static let dishPlacedCorrectly = Notification.Name("dishPlacedCorrectly")
}

// MARK: - ARViewContainer
struct ARViewContainer: UIViewRepresentable {
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
        sceneView.session.delegate = context.coordinator
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        // Show AR debugging information
        sceneView.showsStatistics = false
        sceneView.debugOptions = []
        
        context.coordinator.sceneView = sceneView
        
        // Configure AR session with better error handling
        context.coordinator.setupARSession()
        
        // Add gesture recognizers
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        sceneView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        sceneView.addGestureRecognizer(tapGesture)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    // MARK: - AR Coordinator
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        weak var sceneView: ARSCNView?
        let feedbackManager: FeedbackManager
        let guidanceManager: GuidanceManager
        @Binding var completedItems: Set<DishType>
        
        private var dishGuides: [DishGuide] = []
        private var guideNodes: [SCNNode] = []
        private var selectedNode: SCNNode?
        private var hasPlacedGuides = false
        private var detectionCooldown = false
        
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
                                                 name: .resetPlacement,
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
        
        // MARK: - AR Session Setup
        func setupARSession() {
            guard let sceneView = sceneView else { return }
            
            // Check if ARWorldTrackingConfiguration is supported
            guard ARWorldTrackingConfiguration.isSupported else {
                print("AR World Tracking is not supported on this device")
                return
            }
            
            // Configure AR session
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            configuration.environmentTexturing = .automatic
            
            // Run the session
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        
        // MARK: - ARSessionDelegate
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("AR Session failed with error: \(error.localizedDescription)")
            
            // Handle specific error cases
            if let arError = error as? ARError {
                switch arError.errorCode {
                case ARError.Code.cameraUnauthorized.rawValue:
                    print("Camera access denied. Please enable camera access in Settings.")
                case ARError.Code.unsupportedConfiguration.rawValue:
                    print("AR configuration not supported on this device.")
                case ARError.Code.sensorUnavailable.rawValue:
                    print("AR sensor unavailable. Please try again.")
                default:
                    print("AR Error: \(arError.localizedDescription)")
                }
            }
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("AR Session was interrupted")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("AR Session interruption ended")
            // Restart the session
            setupARSession()
        }
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            switch camera.trackingState {
            case .normal:
                print("AR tracking normal")
            case .notAvailable:
                print("AR tracking not available")
            case .limited(let reason):
                switch reason {
                case .excessiveMotion:
                    print("AR tracking limited: Excessive motion")
                case .insufficientFeatures:
                    print("AR tracking limited: Insufficient features")
                case .initializing:
                    print("AR tracking limited: Initializing")
                case .relocalizing:
                    print("AR tracking limited: Relocalizing")
                @unknown default:
                    print("AR tracking limited: Unknown reason")
                }
            }
        }
        
        // MARK: - ARSCNViewDelegate
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor,
                  !hasPlacedGuides else { return }
            
            hasPlacedGuides = true
            createTableGuides(on: node, planeAnchor: planeAnchor)
        }
        
        private func createTableGuides(on node: SCNNode, planeAnchor: ARPlaneAnchor) {
            let centerPosition = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            
            // Create guides based on table configuration
            for template in TableConfiguration.basicTableSetting {
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
            
            // Add subtle glow effect
            material.emission.contents = UIColor.white.withAlphaComponent(0.1)
            
            plane.materials = [material]
            
            let node = SCNNode(geometry: plane)
            node.position = guide.position
            node.eulerAngles.x = -.pi / 2
            node.name = "\(guide.type.rawValue)_guide"
            
            // Add subtle animation
            let breathingAction = SCNAction.sequence([
                SCNAction.fadeOpacity(to: 0.5, duration: 1.5),
                SCNAction.fadeOpacity(to: 0.8, duration: 1.5)
            ])
            node.runAction(SCNAction.repeatForever(breathingAction))
            
            return node
        }
        
        // MARK: - Gesture Handlers
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            // Implementation for tap interactions
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let sceneView = sceneView else { return }
            let location = gesture.location(in: sceneView)

            switch gesture.state {
            case .began:
                // Find tapped node
                let hitResults = sceneView.hitTest(location, options: nil)
                selectedNode = hitResults.first?.node
                
            case .changed:
                guard let node = selectedNode else { return }
                
                // Update node position based on gesture
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
            let threshold: Float = 0.08 // 8cm tolerance
            
            if distance < threshold {
                // Correct placement - visual feedback
                node.opacity = 1.0
                highlightGuide(for: dishType, correct: true)
            } else {
                // Incorrect placement
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
                // Correct placement
                node.position = closestGuide.position
                completedItems.insert(dishType)
                
                feedbackManager.showFeedback(.correct)
                
                // Check if all items are completed
                if completedItems.count == DishType.allCases.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.feedbackManager.showFeedback(.completed)
                    }
                }
                
                // Mark guide as completed
                updateGuideCompletion(for: dishType, completed: true)
                
            } else {
                // Incorrect placement
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
                material.emission.contents = UIColor.green.withAlphaComponent(0.3)
            } else {
                material.emission.contents = UIColor.orange.withAlphaComponent(0.2)
            }
            
            // Reset after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                material.emission.contents = UIColor.white.withAlphaComponent(0.1)
            }
        }
        
        private func updateGuideCompletion(for type: DishType, completed: Bool) {
            guard let guideNode = guideNodes.first(where: { $0.name?.contains(type.rawValue) == true }),
                  let material = guideNode.geometry?.materials.first else { return }
            
            if completed {
                material.diffuse.contents = UIColor.green.withAlphaComponent(0.6)
                material.emission.contents = UIColor.green.withAlphaComponent(0.3)
                
                // Celebration animation
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

// MARK: - Guidance View
struct GuidanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    let steps = [
        GuidanceStep(
            title: "Getting Started",
            description: "Move your device slowly to scan the table surface. Look for a flat, well-lit area.",
            icon: "camera.viewfinder",
            color: .blue
        ),
        GuidanceStep(
            title: "Placement Guides",
            description: "Once detected, translucent guides will appear showing where each item should be placed.",
            icon: "square.3.layers.3d",
            color: .green
        ),
        GuidanceStep(
            title: "Object Placement",
            description: "Place real utensils and dishes inside the corresponding guide shapes on the table.",
            icon: "hand.point.up.left.fill",
            color: .orange
        ),
        GuidanceStep(
            title: "Visual Feedback",
            description: "Correctly placed items will turn green and provide haptic feedback. Keep adjusting until perfect!",
            icon: "checkmark.circle.fill",
            color: .purple
        ),
        GuidanceStep(
            title: "Table Etiquette",
            description: "Learn proper placement distances and cultural customs for different dining scenarios.",
            icon: "graduationcap.fill",
            color: .red
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("How to Use AR Table Setting")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Follow these steps to master table etiquette")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Steps
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        VStack(spacing: 32) {
                            // Icon
                            Image(systemName: steps[index].icon)
                                .font(.system(size: 80))
                                .foregroundColor(steps[index].color)
                            
                            // Content
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
                
                // Navigation
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
                        Button("Get Started") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
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

struct GuidanceStep {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

#Preview {
    BasicTableView()
}
