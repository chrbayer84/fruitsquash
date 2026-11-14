# LL Fruit Squash

LL Fruit Squash is an physics-based 2D fruit merging puzzle game for iPhone and iPad. Drop fruits into the box and merge matching pairs to evolve them — starting with tiny red currants and working your way up to giant watermelons. Don't let the pile reach the danger line!

## Installation

LL Fruit Squash is not available on the Apple App Store. You can install it using [AltStore](https://altstore.io/).

1. Install AltStore on your iPhone or iPad.
2. Open AltStore and tap **Sources** at the bottom.
3. Tap the **+** button in the top left corner.
4. Paste the following source URL and add it:

   ```
   https://raw.githubusercontent.com/chrbayer84/fruitsquash/master/altstore-source.json
   ```

5. Open the **LL Fruit Squash** source and tap **Free** next to the app to install it.

Alternatively, you can compile the app from source using Xcode (see [Building](#building)).

## Features

- **Physics-based fruit merging** — 11 fruit tiers from Red Currant to Watermelon
- **Bomb power-up** — spend points to clear a targeted area of the board
- **Single-fruit evolution** — spend points to upgrade an individual fruit
- **Board shake** — shake the box to settle the pile (also available via device motion)
- **Customizable themes** — Dark, Light, and Green Hills
- **iPhone and iPad support** — adaptive portrait and landscape layouts
- **Haptics and sound effects** — with mute toggle
- **High score tracking** — your best score is saved between sessions

## Screenshots

Coming soon.

## Requirements

- iOS 16.0 or later
- Xcode 15.0 or later (for building from source)
- Swift 5.0

## Building

### Building an IPA for AltStore/Development

#### Method 1: Using Xcode GUI

1. Open the project in Xcode:
   ```bash
   open FruitSquash.xcodeproj
   ```
2. Select your signing team and a device (not a simulator).
3. Go to **Product → Archive**.
4. In the Organizer, click **Distribute App → Development → Export**.
5. The IPA file will be created in the selected destination folder.

#### Method 2: Using the command line

Run the IPA export script with a version number:
```bash
./build-ipa.sh 1.0
```

The script builds the archive, exports the IPA, and updates the version in `altstore-source.json`. Upload the resulting IPA to a GitHub release so the AltStore source can download it.

## License

GPL v3
