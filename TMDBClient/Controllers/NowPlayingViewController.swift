import UIKit
import CoreData

class NowPlayingViewController: UICollectionViewController {

    // MARK: - Data Providers

    private lazy var moviesProvider: MoviesProvider = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let provider = MoviesProvider(
            with: appDelegate!.coreDataStack.persistentContainer,
            fetchedResultsControllerDelegate: self
        )
        return provider
    }()

    private lazy var favoritesProvider: FavoritesProvider = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let provider = FavoritesProvider(
            with: appDelegate!.coreDataStack.persistentContainer,
            fetchedResultsControllerDelegate: self
        )
        
        return provider
    }()

    var isLoading: Bool = false
    var loadingView: LoadingViewCollectionReusableView?

    // MARK: - Lifecycle

    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        moviesProvider.fetchNowPlaying()
    }

    private func setupUI() {
        collectionView.backgroundColor = .systemBackground
        collectionView.register(MovieCell.self, forCellWithReuseIdentifier: MovieCell.cellId)

        let loadingViewNib = UINib(nibName: "LoadingViewCollectionReusableView", bundle: nil)
        collectionView.register(loadingViewNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "LoadingView")
        collectionView.contentInset = .init(top: 0, left: 16, bottom: 0, right: 16)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - UICollectionViewDataSource
d
extension NowPlayingViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return moviesProvider.fetchedResultsController.fetchedObjects?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCell.cellId, for: indexPath) as! MovieCell
        guard let movie = moviesProvider.fetchedResultsController.fetchedObjects?[indexPath.item] else { return cell }

        cell.movie = movie

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let totalRows = moviesProvider.fetchedResultsController.fetchedObjects?.count ?? 0
        if indexPath.item == totalRows - 1 && !self.isLoading {
            DispatchQueue.global().async {
                sleep(1)

                self.moviesProvider.fetchNowPlaying { _, _ in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "LoadingView", for: indexPath) as! LoadingViewCollectionReusableView
            loadingView = footerView
            loadingView?.backgroundColor = UIColor.clear
            return footerView
        }

        return UICollectionReusableView()
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter {
            loadingView?.activityIndicator.startAnimating()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter {
            loadingView?.activityIndicator.stopAnimating()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension NowPlayingViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 24
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: 104, height: 200)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 0, bottom: 24, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if isLoading {
            return .zero
        } else {
            return .init(width: view.frame.width, height: 55)
        }
    }
}

// MARK: - UICollectionViewDelegate

extension NowPlayingViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detailViewController = MovieDetailViewController(movie: moviesProvider.fetchedResultsController.object(at: indexPath))
        detailViewController.delegate = self

        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension NowPlayingViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.reloadData()
    }
}

// MARK: - MovieInteractionDelegate

extension NowPlayingViewController: MovieInteractionDelegate {
    func didUnfavoriteMovie(_ movie: Movie) {
        favoritesProvider.remove(movie.movieId, in: favoritesProvider.persistentContainer.viewContext)
    }

    func didFavoriteMovie(_ movie: Movie) {
        favoritesProvider.add(movie.movieId, in: favoritesProvider.persistentContainer.viewContext)
    }
}
