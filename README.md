# Dominican Casino

A beautiful, cross-platform card game app featuring traditional Dominican card games. Experience the thrill of Casino, Tres y Dos, and Robaito with friends and family in real-time multiplayer matches.

## 🎮 Games

### Casino
The classic Dominican card game where players capture cards from the table by matching values. Features include:
- Strategic card capturing
- Stack building and management
- Point scoring system
- Multiple rounds per game

### Tres y Dos
A fast-paced Dominican game combining elements of rummy and traditional card games.

### Robaito
Another popular Dominican variant with unique scoring mechanics.

## ✨ Features

- **Real-time Multiplayer**: Play with friends using Firebase Firestore for live synchronization
- **Push Notifications**: Get notified when it's your turn
- **Deep Linking**: Share game invites via links that open directly in the app
- **Cross-Platform**: Available on iOS, Android, Web, and Desktop
- **Beautiful UI**: Customizable themes with a casino felt aesthetic
- **Player Profiles**: Track your game history and statistics
- **Game Invites**: Create private games or join by game ID
- **Offline Support**: Local gameplay capabilities

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Firestore (real-time database)
  - Cloud Messaging (push notifications)
  - Cloud Functions (game logic)
- **State Management**: Provider
- **Routing**: Go Router
- **UI Framework**: Cupertino (iOS-style widgets)
- **Platform Support**: iOS, Android, Web, macOS, Windows, Linux

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.11.0)
- Firebase project with Firestore enabled
- For mobile development: Xcode (iOS) or Android Studio (Android)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/dominican-casino.git
   cd dominican-casino
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Firestore Database
   - Enable Firebase Cloud Messaging
   - Add your Firebase configuration to `lib/services/firebase_options.dart`
   - Deploy the Cloud Functions:
     ```bash
     cd functions
     npm install
     npm run deploy
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

**Android APK:**
```bash
flutter build apk --release
```

**iOS App Store:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

## 📱 Usage

1. **Launch the app** and enter your player name
2. **Choose a game mode** from the carousel (Casino, Tres y Dos, Robaito)
3. **Create a new game** or join an existing one by ID
4. **Invite friends** by sharing the game link
5. **Play your cards** strategically to capture and score points
6. **Win rounds** and accumulate points to become the champion!

## 🎯 Game Rules

### Basic Gameplay
- Players take turns playing cards from their hand
- Match card values to capture cards from the table
- Build and capture stacks for bonus points
- Game continues for multiple rounds until a player reaches the target score

### Scoring
- Points awarded for captured cards
- Bonus points for special combinations
- Different games have unique scoring mechanics

## 🏗️ Architecture

The app follows a clean architecture pattern:

```
lib/
├── app.dart              # Main app widget and routing
├── main.dart             # App initialization and providers
├── data/                 # Data layer (DTOs, serialization)
├── models/               # Domain models (GameState, Player, etc.)
├── repositories/         # Data access layer (Firestore integration)
├── services/             # External services (Firebase, etc.)
├── game_control/         # Game logic and engines
├── ui/                   # UI layer (screens, widgets)
├── style/                # Theming and styling
└── view_models/          # Presentation logic (Provider models)
```

### Key Components

- **Game Engines**: Handle game-specific logic for each variant
- **Real-time Sync**: Firestore listeners for live game updates
- **Push Notifications**: Firebase Cloud Messaging integration
- **Deep Linking**: App Links for game invites
- **State Management**: Provider pattern for reactive UI updates

## 🔧 Configuration

### Firebase Configuration
Update `lib/services/firebase_options.dart` with your Firebase project credentials.

### Themes
The app supports multiple visual themes. Currently includes:
- Felt Walnut (default casino theme)

### Game Settings
- Player name customization
- Game mode selection
- Private/public game options

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Traditional Dominican card games community
- Flutter and Firebase teams for excellent frameworks
- Dominican culture for inspiring these classic games

## 📞 Support

For questions, issues, or contributions:
- Open an issue on GitHub
- Contact the maintainers

---

*Experience the rich tradition of Dominican card games in the digital age!* 
