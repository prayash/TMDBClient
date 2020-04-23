import CoreData

// MARK: - Core Data

class Favorite: NSManagedObject {

    /// A unique identifier used as a unique constraint for removing duplicates.
    @NSManaged var movieId: String
    @NSManaged var timestamp: Date

}
