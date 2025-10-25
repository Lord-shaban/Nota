# 🧾 Sprint 1 Tasks – Nota App

## 🎯 Sprint Goal
Build an MVP version of **Nota App** (AI-powered Notes & Diary App) where:
- Users can register/login.
- Users can input text (or other modes, mock for now).
- Notes are stored in Firebase.
- Notes are displayed in the dashboard.

---

## 🧱 Core Setup (Shared) – [Team Lead & All]

| # | Task | Description |
|---|------|--------------|
| 1 | Create Flutter project & link to GitHub | Initialize repository `nota_app` |
| 2 | Setup folder structure | Follow Feature-First Architecture |
| 3 | Integrate Firebase | Connect Firebase & add google-services.json |
| 4 | Implement `firebase_service.dart` | Setup Firestore access |
| 5 | Create `note.dart` model | id, title, content, category, date |
| 6 | Implement `notes_repository.dart` | CRUD operations for notes |
| 7 | Add `app_theme.dart` | Define app colors & styles |
| 8 | Add `constants.dart` & `helpers.dart` | Global constants & helper functions |
| 9 | Write `README.md` | Include idea, members, and technologies |

---

## 🔐 Authentication Module – [Student 1]

| # | Task | Description |
|---|------|--------------|
| 10 | Create Splash Screen | Animated splash intro |
| 11 | Build Login Screen | UI + fields for email/password |
| 12 | Build Register Screen | User registration form |
| 13 | Implement `auth_service.dart` | Firebase Auth functions |
| 14 | Add Forgot Password Dialog | Password reset popup |
| 15 | Test Firebase Auth | Ensure login/register works |

---

## 🏠 Dashboard Module – [Student 2]

| # | Task | Description |
|---|------|--------------|
| 16 | Create `main_screen.dart` | Base Scaffold with navigation |
| 17 | Build `app_drawer.dart` | Sidebar with options |
| 18 | Create `tab_bar.dart` | Tab navigation between sections |
| 19 | Build `home_view.dart` | Display user notes in cards |
| 20 | Add `welcome_card.dart` | Welcome message and summary |
| 21 | Create category views | Tasks, Expenses, Appointments, etc. |
| 22 | Implement `search_functionality.dart` | Local search among notes |

---

## ✍️ Input System Module – [Student 3]

| # | Task | Description |
|---|------|--------------|
| 23 | Build `text_input_dialog.dart` | Text input popup |
| 24 | Add `text_processor.dart` | Process input text (mock for now) |
| 25 | Create `voice_recorder_dialog.dart` | Voice input UI |
| 26 | Implement `speech_to_text_service.dart` | Convert speech to text |
| 27 | Add `camera_capture_screen.dart` | Capture image UI |
| 28 | Add `image_picker_handler.dart` | Select image from gallery |
| 29 | Implement `input_options_sheet.dart` | Choose input mode (Text/Voice/Image) |

---

## 🧠 AI Brain Module – [Student 4]

| # | Task | Description |
|---|------|--------------|
| 30 | Implement `gemini_service.dart` | Connect to Gemini API (mock for now) |
| 31 | Create `gemini_prompts.dart` | Define prompts used by AI |
| 32 | Add `smart_categorizer.dart` | Basic text classification |
| 33 | Build `ai_results_dialog.dart` | Show AI analysis results |
| 34 | Add `ai_models.dart` | Models for AI response objects |

---

## 🤝 Integration & Delivery – [Team Lead + All]

| # | Task | Description |
|---|------|--------------|
| 35 | Integrate Auth with Dashboard | Move user to dashboard after login |
| 36 | Connect text input with AI Mock | Show mock AI categorization |
| 37 | Link Firebase with Dashboard | Save and load notes dynamically |
| 38 | Perform system testing | Ensure all features work together |
| 39 | Submit Pull Requests | Each feature merged into `dev` |
| 40 | Document Project Board | Ensure all tasks tracked on GitHub |

---

## 📘 GitHub Project Board Columns

| Column | Purpose |
|---------|----------|
| 📝 To Do | Not started |
| 🔧 In Progress | Being developed |
| 🧩 In Review | Awaiting review/PR |
| ✅ Done | Merged into `dev` branch |

---

## ⚙️ Notes
- Each student must create a **branch** for their module.
- Each task = 1 GitHub Issue linked to its branch.
- After finishing, open a **Pull Request** to `dev`.
- The leader merges `dev` → `main` once all modules are stable.
