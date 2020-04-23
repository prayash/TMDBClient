import Foundation

class TMDBNetwork {

    // A private constructor forces this to be a singleton.
    private init() {}

    // MARK: - Properties

    /// Globally shared network instance
    static let shared = TMDBNetwork()

    /// A configuration object which holds metadata for fetching other assets
    var configuration: TMDBConfiguration?

    /// Tracks the total number of pages coming in from the network
    var totalPages: Int = Int.max

    let decoder: JSONDecoder = {
        let jd = JSONDecoder()
        jd.keyDecodingStrategy = .convertFromSnakeCase
        return jd
    }()

    // MARK: - TMDB Data

    let CONFIGURATION_URL = "https://api.themoviedb.org/3/configuration"
    let NOW_PLAYING_URL = "https://api.themoviedb.org/3/movie/now_playing"

    // TODO: !! Store this in secrets !!
    let API_KEY = ""

    func fetchConfiguration(completionHandler: @escaping () -> Void) {
        guard let url = URL(string: "\(CONFIGURATION_URL)?api_key=\(API_KEY)") else {
            completionHandler()
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data else {
                completionHandler()
                return
            }

            do {
                // Set the configuration coming back from the API and we're done
                let config = try self.decoder.decode(TMDBConfiguration.self, from: data)
                self.configuration = config
                completionHandler()

                return
            } catch {
                completionHandler()
                return
            }
        }.resume()
    }

    typealias FetchHandler = ((MovieFeed?, Error?) -> Void)

    func fetchMovies(page: Int, completionHandler: @escaping FetchHandler) {
        var feed: MovieFeed?
        var feedError: Error?
        let endpoint = "\(NOW_PLAYING_URL)?api_key=\(API_KEY)&page=\(page)&region=us"
        let networkDispatchGroup = DispatchGroup()

        // As noted on https://developers.themoviedb.org/3/configuration/get-api-configuration
        // This should ideally be cached and only invalidated every few days, but we'll
        // reload the API configuration every request just to keep things simple
        if configuration == nil {
            networkDispatchGroup.enter()
            fetchConfiguration {
                networkDispatchGroup.leave()
            }
        }

        networkDispatchGroup.enter()
        guard let url = URL(string: endpoint) else {
            feedError = MovieError.urlError
            networkDispatchGroup.leave()
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, err in
            guard let data = data else {
                feedError = MovieError.invalidData
                networkDispatchGroup.leave()
                return
            }

            do {
                feed = try self.decoder.decode(MovieFeed.self, from: data)
                networkDispatchGroup.leave()
            } catch {
                feedError = MovieError.decodingError
                networkDispatchGroup.leave()
                return
            }
        }.resume()

        networkDispatchGroup.notify(queue: .main) {
            completionHandler(feed, feedError)
        }
    }

    func fetchCast(movieId: String, completionHandler: @escaping ((CastFeed, Error?) -> Void)) {
        let endpoint = "https://api.themoviedb.org/3/movie/\(movieId)/credits?api_key=\(API_KEY)"
        guard let url = URL(string: endpoint) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data else { return }

            do {
                let castFeed = try self.decoder.decode(CastFeed.self, from: data)
                completionHandler(castFeed, nil)
            } catch {
                print("Failed to decode cast data.")
                return
            }
        }.resume()
    }
}
