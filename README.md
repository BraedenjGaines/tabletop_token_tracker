# TableTop Token Tracker
 
A fan-made companion app for **Flesh and Blood TCG** built with Flutter. Designed to replace pen-and-paper tracking during in-person games with a clean, fast, two-player interface.
 
## Features
 
### Life Tracking
- Large, readable life totals with tap-to-adjust controls
- Floating or static combat text showing accumulated damage/healing
- Customizable starting life values
### Token Management
- Built-in library of official Flesh and Blood tokens — buffs, debuffs, items, and allies
- Automatic token destruction based on game phase triggers
- Token stacking for non-ally tokens
- Create and save custom tokens with full category and trigger support
- Favorite tokens for quick access
### Turn & Phase Tracking
- Visual phase bar (Start → Action → End) between players
- Automatic turn advancement with active player indication
- Action Point and Pitch resource counters
### Armor Tracking
- Equipment slot icons for Head, Chest, Arms, and Legs
- Tap to add/remove defense counters
- Long-press to mark equipment as destroyed
### Match Timer
- Configurable countdown timer visible to both players
- Color-coded warnings at 10 and 5 minutes remaining
- Haptic alerts at time thresholds
- Visual flash effect when time expires
### Game Log
- Color-coded event log with rich text descriptions
- Player-colored names and category-colored token names
- Copy or share full game logs
- Undo support for recent actions
### First Turn Selection
- Choose who goes first or roll dice with an animated overlay
- Dice roll with winner selection before every game
### Customization
- Light, Dark, and System theme modes
- Frosted glass visual effect option
- Toggle visibility of clock, token button, armor, and resource trackers
- Floating or static combat text display modes
- Custom player names
## Screenshots
 
*Coming soon*
 
## Getting Started
 
### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- Android Studio or VS Code with Flutter extensions
### Installation
```bash
git clone https://github.com/BraedenjGaines/tabletop_token_tracker.git
cd tabletop_token_tracker
flutter pub get
flutter run
```
 
## Tech Stack
- **Framework:** Flutter / Dart
- **State Management:** Provider
- **Persistence:** SharedPreferences
- **Packages:** provider, shared_preferences, url_launcher, share_plus, wakelock_plus, package_info_plus
## Contributing
 
This is a personal project, but feedback and suggestions are welcome! Feel free to open an issue or reach out.
 
## Support
 
If you enjoy using the app, consider supporting development:
 
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-support-yellow?style=flat&logo=buy-me-a-coffee)](https://buymeacoffee.com/braedenjgaines)
 
## Disclaimer
 
This app is not affiliated with, endorsed by, or sponsored by Legend Story Studios or any other game company. Flesh and Blood is a trademark of Legend Story Studios. All game-related terms and token names are used for functional reference purposes only.
 
## License
 
See [LICENSE](LICENSE) for details.