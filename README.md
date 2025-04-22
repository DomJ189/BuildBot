# BuildBot

![BuildBot Logo](https://raw.githubusercontent.com/DomJ189/BuildBot/master/assets/images/buildbot_logo.png)

## Overview
BuildBot is a mobile application that provides AI-assisted PC building and maintenance guidance. It leverages artificial intelligence to offer personalized recommendations, troubleshooting, and step-by-step guidance for computer enthusiasts of all skill levels.

## Key Features
- **AI-Powered Assistance**: Get intelligent recommendations for PC components based on your needs and budget
- **Interactive Chat Interface**: Communicate with the AI assistant using natural language
- **PC Building Guides**: Step-by-step instructions for assembling a custom PC
- **Troubleshooting Support**: Diagnose and fix common PC issues
- **YouTube Integration**: Relevant tutorial videos recommended by the AI
- **Component Compatibility**: Check if components will work together before purchasing
- **User Authentication**: Secure login and account management
- **Dark/Light Theme**: Customizable UI to suit your preferences
- **Chat History**: Review previous conversations and advice

## Screenshots
<table>
  <tr>
    <td><img src="assets/screenshots/chat_screen.png" width="200"/></td>
    <td><img src="assets/screenshots/theme_screen.png" width="200"/></td>
    <td><img src="assets/screenshots/profile_screen.png" width="200"/></td>
  </tr>
</table>

## Technologies & Software Used
- **Flutter (v3.19)**: Cross-platform UI toolkit for building natively compiled applications
- **Dart (v3.0+)**: Programming language optimized for building UIs
- **Firebase Suite**:
  - Firebase Authentication: For secure user management
  - Cloud Firestore: NoSQL database for chat history and user data
  - Firebase Storage: For asset storage
- **APIs & Services**:
  - YouTube Data API: For video recommendations
  - Perplexity Sonar Model Integration: Powering the AI assistant's intelligence
- **State Management**:
  - Provider: For app-wide state management
  - MVVM Architecture: For separation of UI and business logic
- **Development Tools**:
  - Visual Studio Code: Primary IDE
  - Android Studio: For Android-specific development and emulation
  - Flutter DevTools: For debugging and performance analysis
- **UI Components**:
  - Material Design: For consistent and modern UI elements
  - Custom animations: For enhanced user experience
  - Responsive layouts: For compatibility across different device sizes

## Development Setup

### Prerequisites
1. Install Flutter SDK: https://docs.flutter.dev/get-started/install
2. Install Android Studio or VS Code with Flutter plugins
3. Set up an Android emulator or connect a physical device

### Getting Started
1. Clone this repository
   ```
   git clone https://github.com/DomJ189/BuildBot.git
   ```
2. Navigate to the project directory
   ```
   cd BuildBot
   ```
3. Install dependencies
   ```
   flutter pub get
   ```
4. Run the application
   ```
   flutter run
   ```

### Troubleshooting
- If you encounter dependency errors, try:
  ```
  flutter clean
  flutter pub get
  ```
- Make sure you have an emulator running or device connected
- Verify your Flutter installation with `flutter doctor`

## About the Project
BuildBot was created to democratize PC building knowledge, making it accessible to everyone from beginners to experienced builders. By combining AI technology with a user-friendly interface, BuildBot aims to reduce the learning curve associated with PC building and maintenance.

## Contact
- GitHub: [@DomJ189](https://github.com/DomJ189)
