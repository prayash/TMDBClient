import Foundation
import CoreData

// MARK: - Core Data Stack

class CoreDataStack {

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TMDBClient")

        container.loadPersistentStores { storeDesription, error in
            guard let error = error as NSError? else { return }
            fatalError("###\(#function): Failed to load persistent stores: \(error)")
        }

        // Merge the changes from other contexts automatically.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.shouldDeleteInaccessibleFaults = true

        // Pin the viewContext to the current generation token and set it to keep itself up to date with local changes.
        container.viewContext.automaticallyMergesChangesFromParent = true
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("###\(#function): Failed to pin viewContext to the current generation:\(error)")
        }

        return container
    }()

}
