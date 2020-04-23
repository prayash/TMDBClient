import CoreData

class MovieProvider {

    private(set) var persistentContainer: NSPersistentContainer

    /**
     A fetched results controller delegate to give consumers a chance to update
     the user interface when content changes.
     */
    weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?

    /// A fetched results controller to fetch `Cast` records sorted by order
    lazy var fetchedCastResultsController: NSFetchedResultsController<Cast> = {
        let fetchRequest: NSFetchRequest<Cast> = Cast.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "SELF in %@", movie.cast!)
        fetchRequest.sortDescriptors = [
             NSSortDescriptor(key: "order", ascending: true)
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

    let movie: Movie

    // MARK: - Initialization

    init(
        with persistentContainer: NSPersistentContainer,
        fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?,
        movie: Movie
    ) {
        self.persistentContainer = persistentContainer
        self.fetchedResultsControllerDelegate = fetchedResultsControllerDelegate
        self.movie = movie
    }

    // MARK: - Operations

    func fetchCast(for movie: Movie) {
        // TODO: UGHHHH YUCK y thooooooooo
        if movie.cast?.count == 0 {
            TMDBNetwork.shared.fetchCast(movieId: movie.movieId) { castFeed, error in
                castFeed.cast.forEach {
                    let cast = Cast(context: self.persistentContainer.viewContext)

                    do {
                        try cast.update(with: $0)

                        // Let's make sure not to add duplicate copies!
                        if !movie.cast!.contains(cast) {
                            movie.addToCast(cast)
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }

}
