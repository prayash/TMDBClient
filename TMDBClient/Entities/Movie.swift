import Foundation
import CoreData

// MARK: - Core Data

class Movie: NSManagedObject {

    /// A unique identifier used as a unique constraint for removing duplicates.
    @NSManaged public var movieId: String

    @NSManaged public var originalTitle: String?
    @NSManaged public var overview: String?
    @NSManaged public var popularity: Float
    @NSManaged public var posterPath: String?
    @NSManaged public var releaseDate: Date?
    @NSManaged public var voteAverage: Float
    @NSManaged public var cast: NSSet?

    /**
     Updates a `Movie` instance with values from decoded JSON.
     */
    func update(with movie: MovieFeed.MovieProperties) throws {
        movieId = String(movie.id)
        originalTitle = movie.title
        overview = movie.overview
        popularity = movie.popularity
        posterPath = movie.posterPath
        voteAverage = movie.voteAverage
        
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Movie> {
        return NSFetchRequest<Movie>(entityName: "Movie")
    }

}

// MARK: Generated accessors for cast
extension Movie {

    @objc(addCastObject:)
    @NSManaged public func addToCast(_ value: Cast)

    @objc(removeCastObject:)
    @NSManaged public func removeFromCast(_ value: Cast)

    @objc(addCast:)
    @NSManaged public func addToCast(_ values: NSSet)

    @objc(removeCast:)
    @NSManaged public func removeFromCast(_ values: NSSet)

}


// MARK: - Codable

/// A set of error states related to downloading and parsing `Movie` records
enum MovieError: Error {
    case urlError
    case networkUnavailable
    case invalidData
    case missingData
    case decodingError
}

/**
 A struct for decoding JSON with the following structure:

     [{
        "results": [
          {
            "popularity": 243.267,
            "vote_count": 330,
            "video": false,
            "poster_path": "/aQvJ5WPzZgYVDrxLX4R6cLJCEaQ.jpg",
            "id": 454626,
            "adult": false,
            "backdrop_path": "/qonBhlm0UjuKX2sH7e73pnG0454.jpg",
            "original_language": "en",
            "original_title": "Sonic the Hedgehog",
            "genre_ids": [28, 35, 878, 10751],
            "title": "Sonic the Hedgehog",
            "vote_average": 7.1,
            "overview": "Based on the global blockbuster videogame franchise from Sega...",
            "release_date": "2020-02-12"
          }]
     }]

 Stores an array of decoded `MovieProperties` for later use in
 creating or updating `Movie` instances.
 */
struct MovieFeed: Decodable {
    let results: [MovieProperties]

    struct MovieProperties: Decodable {
        let id: Int
        let title: String
        let overview: String
        let popularity: Float
        let releaseDate: String
        let posterPath: String?
        let voteAverage: Float
    }

}
