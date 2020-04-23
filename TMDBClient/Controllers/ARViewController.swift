import UIKit
import ARKit
import RealityKit

class ARViewController: UIViewController {

    // MARK: - Properties

    /// The AR window into the world.
    lazy var arView = ARView(frame: view.frame)

    /// A view that instructs the user's movement during session initialization.
    lazy var onboardingOverlay = ARCoachingOverlayView(frame: view.frame)

    /// The main controller, which manages state for the AR experience.
    var arController: Experience.ARController!

    /// An entity gesture recognizer that translates swipe movements to ball velocity.
    #if !targetEnvironment(simulator)
    var gestureRecognizer: EntityTranslationGestureRecognizer?
    #endif

    /// The world location at which the current translate gesture began.
    var gestureStartLocation: SIMD3<Float>?

    var movies: [Movie] = [] {
        didSet {
            resetCurrentState()
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the AR session for horizontal plane tracking.
        let arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = .horizontal

        // If the following line fails to compile "Value of type `ARView` has no member `session`"
        // You need to select a Real Device or Generic iOS Device and not a simulator
        #if !targetEnvironment(simulator)
        arView.session.run(arConfig)
        arView.automaticallyConfigureSession = true
        #endif

        // Initialize the AR controller, which begins the experience
        arController = Experience.ARController(observer: self)
        arController.begin()

        // Ensure our AR views are added to the view hierarchy
        view.addSubview(arView)
        view.addSubview(onboardingOverlay)

        presentCoachingOverlay()
    }

    /// Begins the coaching process that instructs the user's movement during
    /// ARKit's session initialization.
    func presentCoachingOverlay() {
        #if !targetEnvironment(simulator)
        onboardingOverlay.session = arView.session
        #endif

        onboardingOverlay.delegate = self
        onboardingOverlay.goal = .horizontalPlane
        onboardingOverlay.activatesAutomatically = false
        self.onboardingOverlay.setActive(true, animated: true)
    }
}

// MARK: - ARControllerObserver
extension ARViewController: ARControllerObserver {
    func arControllerContentDidLoad(_ arController: Experience.ARController) {
        // Clean up dem anchors
        arView.scene.anchors.removeAll()

        guard let scene = arController.scene else { return }

        // Disabling the synchronization of entities to reduce the memory
        // consumption (since this is a single-player experience).
        scene.visit {
            $0.synchronization = nil
        }
    }

    func arControllerReadyForContentPlacement(_ arController: Experience.ARController) {
        // Prevent power idle during coaching (coaching phase may take a while and typically expects no touch events)
        UIApplication.shared.isIdleTimerDisabled = true

        presentCoachingOverlay()
    }

    func readyForUserToExplore(_ arController: Experience.ARController) {
        guard let scene = arController.scene else { return }

        // Prevent power idle during active gameplay
        UIApplication.shared.isIdleTimerDisabled = true

        arView.scene.addAnchor(scene)

        resetCurrentState()
    }

    func resetCurrentState() {
        guard let scene = arController.scene else { return }

        restart(scene)
    }

    func restart(_ scene: Experience.Scene) {
        #if !targetEnvironment(simulator)
        gestureRecognizer?.isEnabled = true
        #endif
        scene.movieCards.forEach { $0?.isEnabled = false }

        // Texture loading locally via https://stackoverflow.com/a/59115208/2272112
        if let cards = FileManager.default.urls(for: .documentDirectory)?[0...2] {
            for (index, movieCard) in scene.movieCards.enumerated() {
                let entity = movieCard!.children[0]
                var component: ModelComponent = entity.components[ModelComponent].self!

                // TODO: Texture is not resized properly, and RealityKit doesn't expose any APIs to do so :(
                var material = SimpleMaterial()
                let texResource = try! TextureResource.load(contentsOf: cards[index])
                let texture = MaterialColorParameter.texture(texResource)

                material.baseColor = texture
                material.tintColor = .white
                material.roughness = MaterialScalarParameter(floatLiteral: 0.3)
                material.metallic = MaterialScalarParameter(floatLiteral: 0.0)
                component.materials = [material]

                movieCard!.components.set(component)
            }
        }

        arController.setupDisplay()
    }
}

extension Entity {
    func visit(using block: (Entity) -> Void) {
        block(self)

        for child in children {
            child.visit(using: block)
        }
    }
}
