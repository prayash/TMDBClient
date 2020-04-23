import UIKit
import Foundation
import RealityKit
import simd

protocol ARControllerObserver: class {
    /// Called when the AR controller's mainAnchor content finishes loading.
    func arControllerContentDidLoad(_ arController: Experience.ARController)

    /// Called when the AR controller is ready for the user to locate a suitable surface on which to display.
    func arControllerReadyForContentPlacement(_ arController: Experience.ARController)

    func readyForUserToExplore(_ arController: Experience.ARController)
}

extension Experience {

    public struct AnchorPlacement {
        /// The identifier of the anchor the game is placed on. Used to re-localized the game between levels.
        var arAnchorIdentifier: UUID?

        /// The transform of the anchor the game is placed on . Used to re-localize the game between levels.
        var placementTransform: Transform?
    }

    /**
     The primary controller of the AR interaction, with a state machine to transition
     through various states.
     */
    class ARController {
        indirect enum State: Equatable {
            /// The initial state, which immediately transitions to appStart.
            case begin

            /// The app has started but has not yet displayed the game menu.
            case appStart

            /// The player is attempting to locate a playable real-world surface.
            case placingContent

            /// Game content is loading and the app is waiting for the load to complete before transitioning to the next state.
            case waitingForContent(nextState: State)

            /// The game is ready for the player to attempt a bowling frame.
            case readyToExplore
        }

        /// The app's Reality File anchored scene (from Reality Composer).
        var scene: Experience.Scene!

        var anchorPlacement: Experience.AnchorPlacement?

        /// The current state of the experience.
        private var currentState: State

        /// The current game number (monotonically increases with each frame).
        private var gameNumber = 0

        /// The object that observes our events.
        private weak var observer: ARControllerObserver?

        init(observer: ARControllerObserver) {
            currentState = .begin
            self.observer = observer
        }

        /// Begins the game from application launch.
        func begin() {
            transition(to: .appStart)
        }

        /// Informs the game controller that the player is ready to play the game.
        func playerReadyToBeginPlay() {
            transition(to: .placingContent)
        }

        /// Informs the AR controller that the user is ready to explore.
        func userReadyToExploreFrame() {
            transition(to: .readyToExplore)
        }

        /// Shows the cards.
        func setupDisplay() {
            scene.actions.displayCards.onAction = { entity in
                if let reveal = self.scene.notifications.allNotifications.first {
                    reveal.post()
                }
            }
        }

        // MARK: - State Transitions

        private func transition(to state: State) {
            guard state != currentState else { return }

            func transitionToAppStart() {
                Experience.loadSceneAsync { [unowned self] result in
                    switch result {
                    case .success(let game):
                        if self.scene == nil {
                            self.scene = game
                            self.observer?.arControllerContentDidLoad(self)
                        }

                        if case let .waitingForContent(nextState) = self.currentState {
                            self.transition(to: nextState)
                        }
                    case .failure(let error):
                        print("Unable to load the experience with error: \(error.localizedDescription)")
                    }
                }

                transition(to: .placingContent)
            }

            func transitionToPlacingContent() {
                observer?.arControllerReadyForContentPlacement(self)
            }

            func transitionToWaitingForContent(for nextState: State) {
                if scene != nil {
                    transition(to: nextState)
                }
            }

            func transitionToReadyToExplore() {
                // It's possible to lose anchor in the process, so do one more check.
                if scene == nil {
                    transition(to: .waitingForContent(nextState: .readyToExplore))
                } else {
                    observer?.readyForUserToExplore(self)
                }
            }

            currentState = state
            switch state {
            case .begin: break
            case .appStart:
                transitionToAppStart()
            case .placingContent:
                transitionToPlacingContent()
            case .waitingForContent(let nextState):
                transitionToWaitingForContent(for: nextState)
            case .readyToExplore:
                transitionToReadyToExplore()
            }
        }
    }

}

extension Experience.Scene {

    /// An array of the movie cards.
    var movieCards: [Entity?] {
        return [movieCardUno, movieCardDos, movieCardTres]
    }

}
