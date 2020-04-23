import CoreData
import UIKit

// MARK: - Saving Contexts

/**
 Contextual information for handling Core Data context save errors.
 */
enum ContextSaveContextualInfo: String {
    case updateMovie = "Updating Movie"
    case favoriteMovie = "Favoriting Movie"
    case unfavoriteMovie = "Unfavoriting Movie"
}

extension NSManagedObjectContext {

    /**
     Handles save error by presenting an alert.
     */
    private func handleSavingError(_ error: Error, contextualInfo: ContextSaveContextualInfo) {
        print("Context saving error: \(error)")

        DispatchQueue.main.async {
            guard let window = UIApplication.shared.delegate?.window,
                let viewController = window?.rootViewController else { return }

            let message = "Failed to save the context when \(contextualInfo.rawValue)."

            // Append message to existing alert if present
            if let currentAlert = viewController.presentedViewController as? UIAlertController {
                currentAlert.message = (currentAlert.message ?? "") + "\n\n\(message)"
                return
            }

            // Otherwise present a new alert
            let alert = UIAlertController(title: "Core Data Saving Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(alert, animated: true)
        }
    }

    /**
     Save a context, or handle the save error (for example, when there data inconsistency or low memory).
     */
    func save(with contextualInfo: ContextSaveContextualInfo) {
        guard hasChanges else { return }

        do {
            try save()
        } catch {
            handleSavingError(error, contextualInfo: contextualInfo)
        }
    }
}

