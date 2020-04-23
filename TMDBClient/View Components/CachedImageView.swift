import UIKit

/**
 A convenient UIImageView to load and cache images.
 */
open class CachedImageView: UIImageView {

    public static let cache = NSCache<NSString, DiscardableImageCacheItem>()

    open var shouldUseEmptyImage = true

    private var urlStringForChecking: String?
    private var emptyImage: UIImage?

    public init(cornerRadius: CGFloat = 0, emptyImage: UIImage? = nil) {
        super.init(frame: .zero)
        contentMode = .scaleAspectFit
        clipsToBounds = true
        layer.cornerRadius = cornerRadius

        self.emptyImage = emptyImage
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Easily load an image from a URL string and cache it to reduce network overhead later.
     - parameter urlString: The url location of your image, usually on a remote server somewhere.
     - parameter completion: Optionally execute some task after the image download completes
     */
    open func loadImage(urlString: String, alias: String = "", completion: (() -> ())? = nil) {
        image = nil

        self.urlStringForChecking = urlString
        let urlKey = urlString as NSString

        if let cachedItem = CachedImageView.cache.object(forKey: urlKey) {
            image = cachedItem.image
            completion?()
            return
        }

        guard let url = URL(string: urlString) else {
            if shouldUseEmptyImage {
                image = emptyImage
            }

            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, res, error in
            if let err = error {
                print("Error loading image: ", err)
                return
            }

            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    let cacheItem = DiscardableImageCacheItem(image: image)
                    CachedImageView.cache.setObject(cacheItem, forKey: urlKey)

                    if urlString == self?.urlStringForChecking {
                        self?.image = image
                        self?.alpha = 0.0

                        UIView.animate(withDuration: 0.2) {
                            self?.alpha = 1.0
                        }

                        completion?()

                        // Let's store the cached image inside of our app's /Documents directory to use as a texture in AR
                        if let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let imgPath = path.appendingPathComponent(alias)

                            do {
                                try image.jpegData(compressionQuality: 1)?.write(to: imgPath, options: .atomic)
                            } catch {
                                // print("Failed to write image to Documents directory.", error.localizedDescription)
                            }
                        }
                    }
                }
            }

        }.resume()
    }
}

extension FileManager {
    func urls(for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true ) -> [URL]? {
        let documentsURL = urls(for: directory, in: .userDomainMask)[0]
        let fileURLs = try? contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        return fileURLs
    }
}

open class DiscardableImageCacheItem: NSObject, NSDiscardableContent {

    private(set) public var image: UIImage?
    var accessCount: UInt = 0

    public init(image: UIImage) {
        self.image = image
    }

    public func beginContentAccess() -> Bool {
        if image == nil {
            return false
        }

        accessCount += 1
        return true
    }

    public func endContentAccess() {
        if accessCount > 0 {
            accessCount -= 1
        }
    }

    public func discardContentIfPossible() {
        if accessCount == 0 {
            image = nil
        }
    }

    public func isContentDiscarded() -> Bool {
        return image == nil
    }

}
