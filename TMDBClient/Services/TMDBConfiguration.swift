struct TMDBConfiguration: Decodable {
    let images: ImageConfig

    struct ImageConfig: Decodable {
        let baseUrl: String
        let secureBaseUrl: String
        let posterSizes: [String]
    }
}
