import UIKit
import ARKit
import RealityKit
import simd

// MARK: - ARCoachingOverlayViewDelegate

/// Used to display the coaching overlay view and kick-off the search for a horizontal plane anchor.
extension ARViewController: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        // Ask the user to gather more data before placing the game into the scene
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Set the view controller as the delegate of the session to get updates per-frame
            #if !targetEnvironment(simulator)
            self.arView.session.delegate = self
            #endif
        }
    }
}

// MARK: - ARSessionDelegate

extension ARViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        #if !targetEnvironment(simulator)
        let screenCenter = CGPoint(x: arView.frame.midX, y: arView.frame.midY)
        let results = arView.hitTest(screenCenter, types: [.existingPlaneUsingExtent])

        guard let result = results.first(where: { result -> Bool in

            // Ignore results that are too close or too far away to the camera when initially placing
            guard result.distance > 0.5 && result.distance < 2.0 || self.onboardingOverlay.isActive else {
                return false
            }

            // Make sure the anchor is a horizontal plane with a reasonable extent
            guard let planeAnchor = result.anchor as? ARPlaneAnchor,
                planeAnchor.alignment == .horizontal else {
                    return false
            }

            let extent = simd_length(planeAnchor.extent)
            guard extent > 1 && extent < 2 else {
                return false
            }

            return true
        }), let planeAnchor = result.anchor as? ARPlaneAnchor else {
            return
        }

        // Create an anchor and add it to the session to place the game at this location
        let mainAnchor = ARAnchor(name: "mainAnchor", transform: normalize(planeAnchor.transform))
        arView.session.add(anchor: mainAnchor)

        arController.anchorPlacement = Experience.AnchorPlacement(
            arAnchorIdentifier: mainAnchor.identifier,
            placementTransform: Transform(matrix: planeAnchor.transform)
        )

        // Remove the coaching overlay view
        self.onboardingOverlay.delegate = nil
        self.onboardingOverlay.setActive(false, animated: false)
        self.onboardingOverlay.removeFromSuperview()

        // Now that an anchor has been found, remove the view controller as a delegate to stop receiving updates per-frame
        arView.session.delegate = nil

        // Reset the session to stop searching for horizontal planes after we found the anchor for the game
        arView.session.run(ARWorldTrackingConfiguration())

        print("Ready to start!")
        arController.userReadyToExploreFrame()
        #endif
    }

    func normalize(_ matrix: float4x4) -> float4x4 {
        var normalized = matrix
        normalized.columns.0 = simd.normalize(normalized.columns.0)
        normalized.columns.1 = simd.normalize(normalized.columns.1)
        normalized.columns.2 = simd.normalize(normalized.columns.2)
        return normalized
    }
}
