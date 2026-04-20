# TableTop Token Tracker
 
A fan-made companion app for **Flesh and Blood TCG** built with Flutter. Designed to help keep track of game states during in-person matches with a clean, fast, two-player interface.
 
## Features
 
### Life Tracking
- Large, readable life totals with tap-to-adjust controls
- Customizable starting life values
### Token Management
- Built-in library of official Flesh and Blood tokens — buffs, debuffs, items, and allies
- Automatic token destruction based on game phase triggers
- Create and save custom tokens with trigger support
- Favorite tokens for quick access
### Turn & Phase Tracking
- Visual phase bar (Start → Action → End) between players
- Action Point and Pitch resource counters
### Armor Tracking
- Equipment slot icons for Head, Chest, Arms, and Legs
- Tap to add/remove defense counters
- Long-press to mark equipment as destroyed
### Match Timer
- Configurable countdown timer visible to both players
### Game Log
- Color-coded event log with rich text descriptions
- Copy or share full game logs
- Undo support for recent actions
### First Turn Selection
- Choose who goes first or roll dice
### Customization
- Toggle visibility of clock, token button, armor, and resource trackers
- Floating or static combat text display modes
- Custom player names
## Screenshots
 
<img width="376" height="804" alt="Screenshot 2026-04-20 004502" src="https://github.com/user-attachments/assets/a563c49c-99ff-4f89-ae99-6448e49083f0" />
<br><br>
<img width="377" height="819" alt="Screenshot 2026-04-20 004508" src="https://github.com/user-attachments/assets/c14e04ac-7ddf-442f-a851-9670954877d9" />
<br><br>
<img width="374" height="811" alt="Screenshot 2026-04-20 004522" src="https://github.com/user-attachments/assets/8a483f79-2580-44ab-9c89-788de1f57606" />
<br><br>
<img width="383" height="829" alt="Screenshot 2026-04-20 004530" src="https://github.com/user-attachments/assets/295f4e22-c7f0-48cf-a6d5-79d800b71cb4" />
<br><br>
<img width="378" height="816" alt="Screenshot 2026-04-20 004609" src="https://github.com/user-attachments/assets/e10ffd0c-e90e-4b56-b5e5-397b27185946" />
<br><br>
<img width="380" height="821" alt="Screenshot 2026-04-20 004617" src="https://github.com/user-attachments/assets/a6ec35ca-fce0-4679-a181-35ad8b833fc3" />
<br><br>
<img width="377" height="819" alt="Screenshot 2026-04-20 004628" src="https://github.com/user-attachments/assets/a261e3b1-5682-44e9-ae7a-2d90e27925dc" />
 
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
