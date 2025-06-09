//
//  FormalTableView.swift
//  Table Etiquette
//
//  Created by Bekhruzjon Hakmirzaev on 05/05/25.
//

import SwiftUI
import ARKit
import SceneKit

// MARK: - Formal Dish Types
enum FormalDishType: String, CaseIterable {
    case dinnerPlate = "plate"
    case salladFork = "small_fork"
    case dinnerFork = "fork"
    case dinnerKnife = "knife"
    case spoon = "spoon"
    case breadPlate = "small_plate"
    case waterGlass = "cup"
    case wineGlass = "cup2"
    case champagneGlass = "cup3"
    
    var imageName: String {
        return self.rawValue
    }
    
    var displayName: String {
        switch self {
        case .dinnerPlate: return "Dinner Plate"
        case .salladFork: return "Salad Fork"
        case .dinnerFork: return "Dinner Fork"
        case .dinnerKnife: return "Dinner Knife"
        case .spoon: return "Spoon"
        case .breadPlate: return "Bread Plate"
        case .waterGlass: return "Water Glass"
        case .wineGlass: return "Wine Glass"
        case .champagneGlass: return "Champagne Glass"
        }
    }
    
    var defaultSize: CGSize {
        switch self {
        case .dinnerPlate: return CGSize(width: 0.28, height: 0.28)     // 28cm dinner plate
        case .salladFork: return CGSize(width: 0.035, height: 0.18)     // 3.5cm x 18cm salad fork
        case .dinnerFork: return CGSize(width: 0.04, height: 0.20)      // 4cm x 20cm dinner fork
        case .dinnerKnife: return CGSize(width: 0.04, height: 0.24)     // 4cm x 24cm dinner knife
        case .spoon: return CGSize(width: 0.04, height: 0.18)           // 4cm x 18cm spoon
        case .breadPlate: return CGSize(width: 0.16, height: 0.16)      // 16cm bread plate
        case .waterGlass: return CGSize(width: 0.08, height: 0.08)      // 8cm water glass
        case .wineGlass: return CGSize(width: 0.07, height: 0.07)       // 7cm wine glass
        case .champagneGlass: return CGSize(width: 0.06, height: 0.06)  // 6cm champagne glass
        }
    }
    
    var placementDescription: String {
        switch self {
        case .dinnerPlate: return "Center of the place setting"
        case .salladFork: return "Outer left, for the first course"
        case .dinnerFork: return "Inner left, next to the plate"
        case .dinnerKnife: return "Right of plate, blade facing inward"
        case .spoon: return "Right of knife"
        case .breadPlate: return "Upper left with butter knife"
        case .waterGlass: return "Above the knife and spoon"
        case .wineGlass: return "Right of water glass"
        case .champagneGlass: return "Upper right area"
        }
    }
}

// MARK: - Formal Dish Guide Model
struct FormalDishGuide: Identifiable {
    let id = UUID()
    let type: FormalDishType
    var position: SCNVector3
    var isCorrect: Bool = false
    let size: CGSize
    var rotation: Float = 0.0
    var opacity: Float = 0.7
}

// MARK: - Formal Table Configuration
struct FormalTableConfiguration {
    static let formalTableSetting: [FormalDishGuide] = [
        FormalDishGuide(type: .dinnerPlate, position: SCNVector3(0, 0, 0), size: FormalDishType.dinnerPlate.defaultSize),
        FormalDishGuide(type: .salladFork, position: SCNVector3(-0.22, 0, 0), size: FormalDishType.salladFork.defaultSize),
        FormalDishGuide(type: .dinnerFork, position: SCNVector3(-0.15, 0, 0), size: FormalDishType.dinnerFork.defaultSize),
        FormalDishGuide(type: .dinnerKnife, position: SCNVector3(0.15, 0, 0), size: FormalDishType.dinnerKnife.defaultSize),
        FormalDishGuide(type: .spoon, position: SCNVector3(0.22, 0, 0), size: FormalDishType.spoon.defaultSize),
        FormalDishGuide(type: .breadPlate, position: SCNVector3(-0.25, 0, -0.22), size: FormalDishType.breadPlate.defaultSize),
        FormalDishGuide(type: .waterGlass, position: SCNVector3(0.18, 0, -0.20), size: FormalDishType.waterGlass.defaultSize),
        FormalDishGuide(type: .wineGlass, position: SCNVector3(0.26, 0, -0.20), size: FormalDishType.wineGlass.defaultSize),
        FormalDishGuide(type: .champagneGlass, position: SCNVector3(0.30, 0, -0.14), size: FormalDishType.champagneGlass.defaultSize)
    ]
}

struct FormalTableView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var feedbackManager = FeedbackManager()
    @StateObject private var guidanceManager = GuidanceManager()
    @State private var showingGuidance = false
    @State private var showingProgress = false
    @State private var completedItems: Set<FormalDishType> = []
    
    var progressPercentage: Double {
        return Double(completedItems.count) / Double(FormalDishType.allCases.count) * 100
    }
    
    var body: some View {
        ZStack {
            // AR View
            FormalARViewContainer(
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
            FormalGuidanceView()
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
            Text("Formal Table Setting")
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
                        .background(Color.purple.opacity(0.8))
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
                Text("Formal Setting Progress")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(completedItems.count)/\(FormalDishType.allCases.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: progressPercentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            if progressPercentage == 100 {
                Text("🎩 Exquisite formal setting!")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
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
            Text("Formal Dining Protocol")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                instructionRow("1.", "Dinner plate center")
                instructionRow("2.", "Forks left (outside-in)")
                instructionRow("3.", "Knife & spoon right")
                instructionRow("4.", "Bread plate upper left")
                instructionRow("5.", "Glasses upper right")
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
                .foregroundColor(.purple)
            Text(text)
            Spacer()
        }
    }
    
    private func resetPlacement() {
        NotificationCenter.default.post(name: .resetFormalPlacement, object: nil)
        completedItems.removeAll()
        feedbackManager.showFeedback(.reset)
    }
}

// MARK: - Formal AR View Container
struct FormalARViewContainer: UIViewRepresentable {
    let feedbackManager: FeedbackManager
    let guidanceManager: GuidanceManager
    @Binding var completedItems: Set<FormalDishType>
    
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
        
        // Configure AR session with enhanced settings for formal dining
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
    
    // MARK: - Formal AR Coordinator
    class Coordinator: NSObject, ARSCNViewDelegate {
        weak var sceneView: ARSCNView?
        let feedbackManager: FeedbackManager
        let guidanceManager: GuidanceManager
        @Binding var completedItems: Set<FormalDishType>
        
        private var dishGuides: [FormalDishGuide] = []
        private var guideNodes: [SCNNode] = []
        private var selectedNode: SCNNode?
        private var hasPlacedGuides = false
        
        init(feedbackManager: FeedbackManager, guidanceManager: GuidanceManager, completedItems: Binding<Set<FormalDishType>>) {
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
                name: .resetFormalPlacement,
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
            createFormalTableGuides(on: node, planeAnchor: planeAnchor)
        }
        
        private func createFormalTableGuides(on node: SCNNode, planeAnchor: ARPlaneAnchor) {
            let centerPosition = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            
            // Create guides based on formal table configuration
            for template in FormalTableConfiguration.formalTableSetting {
                let guide = FormalDishGuide(
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
        
        private func createGuideNode(for guide: FormalDishGuide) -> SCNNode {
            let plane = SCNPlane(width: guide.size.width, height: guide.size.height)
            
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: guide.type.imageName)
            material.isDoubleSided = true
            material.transparency = 0.7
            
            // Purple/gold tint for formal setting
            material.emission.contents = UIColor.purple.withAlphaComponent(0.1)
            
            // Add subtle metallic effect for formal setting
            material.metalness.contents = NSNumber(value: 0.2)
            material.roughness.contents = NSNumber(value: 0.8)
            
            plane.materials = [material]
            
            let node = SCNNode(geometry: plane)
            node.position = guide.position
            node.eulerAngles.x = -.pi / 2
            node.name = "\(guide.type.rawValue)_formal_guide"
            
            // Add elegant animation for formal setting
            let breathingAction = SCNAction.sequence([
                SCNAction.fadeOpacity(to: 0.5, duration: 2.0),
                SCNAction.fadeOpacity(to: 0.8, duration: 2.0)
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
            let threshold: Float = 0.06 // Stricter tolerance for formal setting (6cm)
            
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
            let threshold: Float = 0.06 // Stricter for formal
            
            if distance < threshold {
                node.position = closestGuide.position
                completedItems.insert(dishType)
                
                feedbackManager.showFeedback(.correct)
                
                // Check if all formal items are completed
                if completedItems.count == FormalDishType.allCases.count {
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
        private func extractDishType(from nodeName: String?) -> FormalDishType? {
            guard let name = nodeName else { return nil }
            return FormalDishType.allCases.first { name.contains($0.rawValue) }
        }
        
        private func findClosestGuide(to position: SCNVector3, for type: FormalDishType) -> FormalDishGuide? {
            return dishGuides.first { $0.type == type }
        }
        
        private func distance(from: SCNVector3, to: SCNVector3) -> Float {
            let dx = from.x - to.x
            let dy = from.y - to.y
            let dz = from.z - to.z
            return sqrt(dx*dx + dy*dy + dz*dz)
        }
        
        private func highlightGuide(for type: FormalDishType, correct: Bool) {
            guard let guideNode = guideNodes.first(where: { $0.name?.contains(type.rawValue) == true }),
                  let material = guideNode.geometry?.materials.first else { return }
            
            if correct {
                material.emission.contents = UIColor.purple.withAlphaComponent(0.3)
            } else {
                material.emission.contents = UIColor.orange.withAlphaComponent(0.2)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                material.emission.contents = UIColor.purple.withAlphaComponent(0.1)
            }
        }
        
        private func updateGuideCompletion(for type: FormalDishType, completed: Bool) {
            guard let guideNode = guideNodes.first(where: { $0.name?.contains(type.rawValue) == true }),
                  let material = guideNode.geometry?.materials.first else { return }
            
            if completed {
                material.diffuse.contents = UIColor.purple.withAlphaComponent(0.6)
                material.emission.contents = UIColor.systemYellow.withAlphaComponent(0.3)
                
                // Elegant celebration animation
                let scaleUp = SCNAction.scale(to: 1.15, duration: 0.3)
                let scaleDown = SCNAction.scale(to: 1.0, duration: 0.3)
                let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 0.6)
                let celebrate = SCNAction.group([
                    SCNAction.sequence([scaleUp, scaleDown]),
                    rotateAction
                ])
                guideNode.runAction(celebrate)
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// MARK: - Formal Guidance View
struct FormalGuidanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    let steps = [
        GuidanceStep(
            title: "Formal Dining Excellence",
            description: "Master the art of formal table setting with precision and elegance.",
            icon: "crown.fill",
            color: .purple
        ),
        GuidanceStep(
            title: "Multiple Utensils",
            description: "Formal settings include multiple forks, glasses, and specialized pieces.",
            icon: "fork.knife",
            color: .yellow
        ),
        GuidanceStep(
            title: "Precise Placement",
            description: "Every item has an exact position. Attention to detail is crucial.",
            icon: "ruler.fill",
            color: .indigo
        ),
        GuidanceStep(
            title: "Outside-In Rule",
            description: "Utensils are arranged in order of use, working from outside to inside.",
            icon: "arrow.right.circle.fill",
            color: .brown
        ),
        GuidanceStep(
            title: "Glass Arrangement",
            description: "Multiple glasses arranged by size and use, starting with water glass.",
            icon: "wineglass.fill",
            color: .cyan
        ),
        GuidanceStep(
            title: "Bread & Butter",
            description: "Bread plate positioned upper left with its own butter knife.",
            icon: "circle.grid.cross.fill",
            color: .orange
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Text("Formal Dining Mastery")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("The pinnacle of table etiquette and sophisticated dining")
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
                        Button("Begin Formal Setting") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.purple)
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
    static let resetFormalPlacement = Notification.Name("resetFormalPlacement")
}

// Helper extension for gold color
extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

#Preview {
    FormalTableView()
} 