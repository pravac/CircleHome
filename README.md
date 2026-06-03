# CircleHome

A household management app built with Flutter and Firebase. CircleHome helps households coordinate tasks, track contributions, share care notes, and stay on top of who is doing what.

## Features

**Task Management**
Create tasks with a title, category, due date/time, and difficulty level (1 to 5). Assign tasks to a specific member, to everyone at once, or use auto-assign which picks the member with the lowest current workload. Tasks can be marked complete, edited, deleted, or swapped between members. Recurring tasks are supported with frequencies from daily to yearly.

**Household Management**
Create a household and share an invite code for others to join. Members can belong to multiple households and switch between them. The household owner can kick members and members can leave voluntarily.

**Leaderboard**
Tracks points earned by completing tasks, weighted by difficulty. You can drill into any member's contribution history.

**Care Notes**
A shared log for health and care related notes like medications, appointments, and observations. Any member can add a note. Notes are immutable once created.

**Task Swap Requests**
Request to swap an assigned task with another member. The recipient accepts or rejects, and the task reassigns automatically on accept.

**Push Notifications**
FCM notifications when a task is assigned to you. Works on Android (foreground and background) and web (foreground).

**Profile**
Set a display name and profile photo, and configure your weekly workload level which is used by auto-assign. Name changes propagate to all existing task assignments.

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart), runs on Android, iOS, and Web |
| Database | Firebase Firestore |
| Authentication | Firebase Auth (email and password) |
| Push Notifications | Firebase Cloud Messaging |
| Cloud Functions | Node.js (Firebase Functions v2) |
| Storage | Firebase Storage (profile and household photos) |
| Security | Firestore Security Rules |

## Getting Started

**Prerequisites**
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- [Firebase CLI](https://firebase.google.com/docs/cli) — `npm install -g firebase-tools`
- A Firebase project (already configured, `firebase_options.dart` is included)

**Running the app**
```bash
cd CircleHome/frontend
flutter pub get

flutter run -d chrome   # web
flutter run             # connected Android or iOS device
```

**Running tests**
```bash
cd CircleHome/frontend
flutter test
```

65 unit tests covering service logic, utility functions, app state, and widget rendering.

## Project Structure

```
CircleHome/
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── theme.dart           # Shared colors and text styles
│   │   ├── screens/             # All UI screens and dialogs
│   │   ├── services/            # FirestoreService, AuthService, NotificationService
│   │   ├── providers/           # AppState
│   │   └── utils/               # task_utils.dart, time_utils.dart
│   └── test/                    # Unit tests
├── functions/
│   └── index.js                 # notifyTaskAssigned cloud function
├── firestore.rules
└── firebase.json
```

## User Guide

**1. Create an account**
Open the app and tap **Sign Up**. Enter your email and password. After signing up you will be taken to the home screen.

**2. Create or join a household**
- To create: go to **Settings → Create Household**, enter a name, and an invite code will be generated.
- To join: go to **Settings → Join Household** and enter the invite code someone shared with you.
- To switch between households: tap the household name at the top of the home screen.

**3. Set up your profile**
Go to **Profile** (bottom nav). Set your display name, profile photo, and weekly workload level (1–5). The workload level is used by auto-assign when distributing tasks.

**4. Create a task**
Tap the **+** button on the Tasks screen. Fill in:
- Title and category
- Due date and optional time
- Assignee — pick a specific member, assign to Everyone, or use Auto-Assign
- Difficulty (1–5) — this determines how many points the assignee earns on completion
- Toggle Recurring on if the task should repeat, then choose a frequency

**5. Manage tasks**
- **My Tasks / All Tasks** — toggle at the top of the task feed to switch views
- **Filter by status** — filter tasks by incomplete, complete, or overdue
- **Complete a task** — tap the checkmark; an Undo option appears briefly in the snackbar
- **Edit a task** — tap the task to open it, then tap Edit
- **Swap a task** — tap Swap on any task assigned to you to request a reassignment to another member

**6. Leaderboard**
Tap **Leaderboard** in the bottom nav to see household members ranked by points. Points are weighted by task difficulty. Tap any member to see their individual contribution history.

**7. Care Diary**
Tap **Care** in the bottom nav to view and add care notes. Tap **Add Note**, choose a category (General, Medication, Appointment, Emergency), fill in the details, and optionally note who the entry is about. Emergency notes are highlighted in red.

**8. Notifications**
Allow notifications when prompted on first launch. You will receive a push notification when a task is assigned to you.

## Security

Firestore rules enforce that users can only read and write their own profile, household data is scoped to members, tasks and care notes are scoped to the household, swap requests are only visible to the two people involved, and the activity feed is append only.
