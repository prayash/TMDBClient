import Foundation
import CoreData

// MARK: - Core Data

class Cast: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Cast> {
        return NSFetchRequest<Cast>(entityName: "Cast")
    }

    @NSManaged public var castId: Int32
    @NSManaged public var order: Int32
    @NSManaged public var character: String
    @NSManaged public var name: String
    @NSManaged public var profilePath: String?
    @NSManaged public var movie: Movie

    /**
     Updates a `Cast` instance with values from decoded JSON.
     */
    func update(with cast: CastFeed.CastItem) throws {
        castId = Int32(cast.castId)
        order = Int32(cast.order)
        character = cast.character
        name = cast.name
        profilePath = cast.profilePath
    }

}

struct CastFeed: Decodable {
    let id: Int
    let cast: [CastItem]

    struct CastItem: Decodable {
        let id: Int
        let castId: Int
        let character: String
        let creditId: String
        let name: String
        let order: Int
        let profilePath: String?
    }
}
