import CoreData

class FavoritesProvider {

    private(set) var persistentContainer: NSPersistentContainer

    /**
     A fetched results controller delegate to give consumers a chance to update
     the user interface when content changes.
     */
    weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?

    /// A fetched results controller to fetch `Favorite` records sorted by popularity.
    lazy var fetchedResultsController: NSFetchedResultsController<Favorite> = {
        let fetchRequest = NSFetchRequest<Favorite>(entityName: "Favorite")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "timestamp", ascending: false)
        ]

        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        controller.delegate = fetchedResultsControllerDelegate

        // Perform the fetch!
        do {
            try controller.performFetch()
        } catch {
            fatalError("Unresolved error \(error)")
        }

        return controller
    }()

    // MARK: - Initialization

    init(
        with persistentContainer: NSPersistentContainer,
        fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?
    ) {
        self.persistentContainer = persistentContainer
        self.fetchedResultsControllerDelegate = fetchedResultsControllerDelegate
    }

    // MARK: - Operations

    func add(_ movieId: String, in context: NSManagedObjectContext) {
        print("Favoriting: \(movieId)")

        context.performAndWait {
            let favorite = Favorite(context: context)
            favorite.movieId = movieId
            favorite.timestamp = Date()

            context.save(with: .favoriteMovie)
        }
    }

    func remove(_ movieId: String, in context: NSManagedObjectContext) {
        print("Unfavoriting: \(movieId)")
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Favorite")
        guard let favorites = try? context.fetch(fetchRequest) as? [Favorite] else { return }

        if let favoriteToRemove = favorites.first(where: { $0.movieId == movieId }) {
            context.delete(favoriteToRemove)
        }

        context.save(with: .unfavoriteMovie)
    }

    func get() -> [Favorite] {
        let fetchRequest = NSFetchRequest<Favorite>(entityName: "Favorite")
        let favorites = try? persistentContainer.viewContext.fetch(fetchRequest)

        return favorites ?? []
    }
}
