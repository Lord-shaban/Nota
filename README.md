# Nota App
AI-powered Notes & Diary Application

## Overview
**Nota** is an AI-powered notes and diary app built with Flutter and Firebase.  
Users can input notes via **text, voice, or image**, and the AI engine intelligently categorizes them into sections like *To-Do, Appointments, Expenses,* or *Personal Notes*.

## Features
- User authentication (register/login/forgot password)
- Dashboard with categorized notes
- Text, voice, and image input
- AI-based note categorization (Gemini API - mocked initially)
- CRUD operations for notes
- Search functionality

## Tech Stack
- **Frontend:** Flutter (Dart)
- **Backend:** Firebase Firestore, Firebase Auth, Firebase Storage
- **AI:** Gemini API (mocked initially)
- **Version Control:** Git & GitHub

## Installation & Setup

1. Clone the repository:
```
git clone https://github.com/Lord-shaban/Nota.git
```

2. Navigate to project directory and install dependencies:
```
cd nota_app
flutter pub get
```

3. Configure Firebase:
- Add your `google-services.json` for Android in `android/app/`
- Add your `GoogleService-Info.plist` for iOS in `ios/Runner/`

4. Run the app:
```
flutter run
```

## Contributing
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our contribution guidelines.  
Use GitHub Issues and Projects to track tasks and sprints.

## Project Board
Tasks and milestones are tracked in [GitHub Projects](https://github.com/Lord-shaban/Nota/projects).

## Security
Please read [SECURITY.md](SECURITY.md) for details on reporting vulnerabilities and security practices.

## Code of Conduct
Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) to understand expected behavior when contributing.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
