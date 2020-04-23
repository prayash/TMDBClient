import CoreData

class MoviesProvider {

    private(set) var persistentContainer: NSPersistentContainer

    /**
     A fetched results controller delegate to give consumers a chance to update
     the user interface when content changes.
     */
    weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?

    /// A fetched results controller to fetch `Movie` records sorted by popularity.
    lazy var fetchedResultsController: NSFetchedResultsController<Movie> = {
        let fetchRequest = NSFetchRequest<Movie>(entityName: "Movie")
        fetchRequest.sortDescriptors = [
             NSSortDescriptor(key: "popularity", ascending: false)
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

    /// Tracks the current position in pagination of network data
    var page: Int = 1

    // MARK: - Initialization

    init(
        with persistentContainer: NSPersistentContainer,
        fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?
    ) {
        self.persistentContainer = persistentContainer
        self.fetchedResultsControllerDelegate = fetchedResultsControllerDelegate
    }

    // MARK: - Operations

    func fetchNowPlaying(completionHandler: ((MovieFeed?, Error?) -> Void)? = nil) {
        // We'll cap it at 5 pages
        guard page < 5 else { completionHandler?(nil, nil); return }

        TMDBNetwork.shared.fetchMovies(page: page) { feed, error in
            completionHandler?(feed, error)

            guard let feed = feed else { return }

            do {
                // Import decoded JSON into CoreData
                try self.importMovies(from: feed)

                // Advance to the next page once data sync finishes.
                self.page += 1
            } catch let importError {
                completionHandler?(nil, importError)
                return
            }
        }
    }

    // MARK: - Importing

    private func importMovies(from feed: MovieFeed) throws {
        guard !feed.results.isEmpty else { return }

        // Private queue context
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        let batchSize = 3
        let count = feed.results.count

        var numBatches = count / batchSize
        numBatches += count % batchSize > 0 ? 1 : 0

        for batchNumber in 0..<numBatches {
            // Determine the range for this batch.
            let batchStart = batchNumber * batchSize
            let batchEnd = batchStart + min(batchSize, count - batchNumber * batchSize)
            let range = batchStart..<batchEnd

            // Create a batch for this range from the decoded JSON.
            let moviesBatch = Array(feed.results[range])

            // Stop the entire import if any batch is unsuccessful.
            if !importBatch(moviesBatch, taskContext: taskContext) {
                return
            }
        }
    }

    /**
     Imports a single batch of `Movie` records, creating managed objects from the data,
     and saving them to the persistent store on a private queue. After saving,
     resets the context to clean up the cache and lower the memory footprint.

     NSManagedObjectContext.performAndWait doesn't rethrow so this function
     catches throws within the closure and uses a return value to indicate
     whether the import is successful.
    */
    private func importBatch(_ moviesBatch: [MovieFeed.MovieProperties], taskContext: NSManagedObjectContext) -> Bool {
        var success = false

        // taskContext.performAndWait runs on the URLSession's delegate queue
        // so it won’t block the main thread.
        taskContext.performAndWait {
            // Create a new record for each movie in the batch.
            for movieData in moviesBatch {

                // Create a Movie managed object on the private queue context.
                guard let movie = NSEntityDescription.insertNewObject(forEntityName: "Movie", into: taskContext) as? Movie else {
                    print("Failed to create a new Movie object.")
                    return
                }
                // Populate the Movie's properties using the raw data.
                do {
                    try movie.update(with: movieData)
                } catch MovieError.missingData {
                    // Delete invalid Movie from the private queue context.
                    print("Found and will discard a Movie missing data.")
                    taskContext.delete(movie)
                } catch {
                    print(error.localizedDescription)
                }
            }

            // Save all insertions and deletions from the context to the store.
            if taskContext.hasChanges {
                do {
                    try taskContext.save()
                } catch {
                    print("Error: \(error)\nCould not save Core Data context.")
                    return
                }

                // Reset the taskContext to free the cache and lower the memory footprint.
                taskContext.reset()
            }

            success = true
        }

        return success
    }
}
