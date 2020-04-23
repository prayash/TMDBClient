# TMDBClient (iOS)

Works best on iPhone X or 11 (regular size). For the sake of time I did not ensure the layout works well for other sizes.

## Tools used:

- UIKit & Foundation
- CoreData

## Application Architecture:

- A variant of MVC design, with data fetching abstracted to `DataProvider`.
- All models/entities are stored inside of CoreData's persistence layer.
- Movies are downloaded and stored on device. Favorites are persisted between sessions as well.
- UI is done programmatically, with the help of Auto Layout extensions. Check `Extensions/UIView+Layout` for more details on that.
- Networking is done through `TDBMNetwork` shared instance.

![TMDBClient iOS Architecture Diagram](./TMDBClient-Arch.png 'Architecture Diagram')

## Screenshots:

![TMDBClient iOS](./TMDBClient-NowPlaying.png 'TMDBClient iOS')
![TMDBClient iOS](./TMDBClient-Detail.png 'TMDBClient iOS')
