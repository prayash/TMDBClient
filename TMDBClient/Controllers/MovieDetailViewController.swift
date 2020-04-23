import UIKit
import CoreData

/**
 Facilitates communication with the parent controller to notify the data provider of changes.
 */
protocol MovieInteractionDelegate: class {
    func didFavoriteMovie(_ movie: Movie)
    func didUnfavoriteMovie(_ movie: Movie)
}

class MovieDetailViewController: UIViewController {

    // MARK: - Data Providers

    private lazy var favoritesProvider: FavoritesProvider = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let provider = FavoritesProvider(
            with: appDelegate!.coreDataStack.persistentContainer,
            fetchedResultsControllerDelegate: nil
        )
        return provider
    }()

    private lazy var movieProvider: MovieProvider = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        return MovieProvider(
            with: appDelegate!.coreDataStack.persistentContainer,
            fetchedResultsControllerDelegate: self,
            movie: self.movie
        )
    }()

    // MARK: - Properties

    /// This delegate is notified of actions taken upon a `Movie` record (favoriting etc.)
    weak var delegate: MovieInteractionDelegate?

    var movie: Movie

    // MARK: - View Components

    private let posterView = CachedImageView(cornerRadius: 6, emptyImage: nil)

    let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 3
        label.font = .boldSystemFont(ofSize: 24)
        label.text = "Movie Title"
        return label
    }()

    let ratingLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 14)
        label.text = "Rating: 7.0"
        label.textColor = .gray
        return label
    }()

    let synopsisLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 20)
        label.text = "Description"
        return label
    }()

    let overviewLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 17)
        label.text = "Overview"
        return label
    }()

    lazy var castView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        let view = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        view.register(CastCell.self, forCellWithReuseIdentifier: CastCell.cellId)
        view.showsHorizontalScrollIndicator = false
        view.delegate = self
        view.dataSource = self
        return view
    }()

    lazy var favoriteButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "heart_filled"), style: .plain, target: self, action: #selector(didFavorite))

        return button
    }()

    // MARK: - Lifecycle

    init(movie: Movie) {
        self.movie = movie
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) -has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        setupUI()
        movieProvider.fetchCast(for: movie)
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = favoriteButton

        let vStack = UIStackView(arrangedSubviews: [titleLabel, ratingLabel, UIView()])
        vStack.axis = .vertical
        vStack.spacing = 4

        posterView.constrainWidth(constant: 150)
        posterView.constrainHeight(constant: 200)

        let hStack = UIStackView(arrangedSubviews: [posterView, vStack])
        hStack.spacing = 12

        view.addSubview(hStack)
        hStack.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 12, left: 12, bottom: 12, right: 12))

        view.addSubview(synopsisLabel)
        synopsisLabel.anchor(top: hStack.bottomAnchor, leading: hStack.leadingAnchor, bottom: nil, trailing: hStack.trailingAnchor, padding: .init(top: 24, left: 12, bottom: 12, right: 12))

        view.addSubview(overviewLabel)
        overviewLabel.anchor(top: synopsisLabel.bottomAnchor, leading: hStack.leadingAnchor, bottom: nil, trailing: hStack.trailingAnchor, padding: .init(top: 12, left: 12, bottom: 12, right: 12))

        view.addSubview(castView)
        castView.anchor(top: overviewLabel.bottomAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
    }

    private func configure() {
        titleLabel.text = movie.originalTitle
        overviewLabel.text = movie.overview
        ratingLabel.text = "Rating: \(String(describing: movie.voteAverage))"

        // I'm such a noob this is probably a terrible way of detecting whether this movie is a favorite or not 🤦‍♀️
        let favoritedMovieIds = Set<String>(favoritesProvider.get().map { $0.movieId })
        if favoritedMovieIds.contains(movie.movieId) {
            favoriteButton.image = UIImage(named: "heart_filled")
            favoriteButton.action = #selector(didUnfavorite)
        } else {
            favoriteButton.image = UIImage(named: "heart")
            favoriteButton.action = #selector(didFavorite)
        }

        // We need to reach into the dynamically generated config to get the base path for images
        if let baseUrl = TMDBNetwork.shared.configuration?.images.secureBaseUrl {
            let posterUrl = "\(baseUrl)w500/\(movie.posterPath ?? "")"

            posterView.loadImage(urlString: posterUrl, completion: nil)
        }
    }

    // MARK: - Callbacks

    @objc func didFavorite() {
        toggleFavoriteButtonState(isFilled: false)
        delegate?.didFavoriteMovie(movie)
    }

    @objc func didUnfavorite() {
        toggleFavoriteButtonState(isFilled: true)
        delegate?.didUnfavoriteMovie(movie)
    }

    private func toggleFavoriteButtonState(isFilled: Bool) {
        let image = isFilled ? UIImage(named: "heart") : UIImage(named: "heart_filled")

        favoriteButton.image = image
    }

}

extension MovieDetailViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("CHANGE!")
        castView.reloadData()
    }
}

extension MovieDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movieProvider.fetchedCastResultsController.fetchedObjects?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CastCell.cellId, for: indexPath) as! CastCell
        guard let cast = movieProvider.fetchedCastResultsController.fetchedObjects?[indexPath.item] else { return cell }

        cell.cast = cast

        return cell
    }

}

extension MovieDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: 100, height: 200)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0, left: 24, bottom: 0, right: 0)
    }
}
