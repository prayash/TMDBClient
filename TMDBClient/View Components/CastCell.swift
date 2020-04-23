import UIKit

class CastCell: UICollectionViewCell {

    // MARK: - Properties

    var cast: Cast? {
        didSet {
            titleLabel.text = cast?.name

            // We need to reach into the dynamically generated config to get the base path for images
            if let baseUrl = TMDBNetwork.shared.configuration?.images.secureBaseUrl {
                let imageUrl = "\(baseUrl)w500\(cast?.profilePath ?? "")"

                posterView.loadImage(urlString: imageUrl, alias: cast?.profilePath ?? "",completion: nil)
            }
        }
    }

    static let cellId = "castCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Movie Title"
        label.font = .boldSystemFont(ofSize: 13)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let posterView = CachedImageView(cornerRadius: 6, emptyImage: nil)

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .systemBackground

        let labelWrapper = UIView(frame: titleLabel.frame)
        labelWrapper.constrainHeight(constant: 36)
        labelWrapper.addSubview(titleLabel)

        // Constrain the height of the label to account for offset of long movie titles
        titleLabel.anchor(top: labelWrapper.topAnchor, leading: labelWrapper.leadingAnchor, bottom: nil, trailing: labelWrapper.trailingAnchor)

        let stackView = UIStackView(arrangedSubviews: [posterView, labelWrapper])
        stackView.spacing = 4
        stackView.axis = .vertical
        stackView.alignment = .top

        addSubview(stackView)
        stackView.fillSuperview()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


}
