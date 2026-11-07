# BizPilot – Business Manager (Android App)

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage%20%7C%20FCM-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--First%20Clean%20Riverpod-4F46E5)](#)
[![Design](https://img.shields.io/badge/Design-Material%203-2563EB)](https://m3.material.io)

**BizPilot – Business Manager** is a complete, modern, professional mobile application engineered specifically for small business owners, freelancers, sales executives, and service providers. It empowers entrepreneurs to manage sales leads, track customer work and payments, manage expenses, maintain cash flow visibility, and organize daily tasks with automated reminders and scheduling.

---

## 📱 Core Modules & Feature Highlights

### 1. Lead Management
- **Intelligent Visibility & Follow-up Scheduler**:
  - **Upcoming Follow-ups**: Leads with future follow-up dates and times remain organized under Upcoming until the scheduled moment.
  - **Follow-ups Due**: Automatically highlighted and surfaced when the scheduled follow-up time arrives or has passed.
  - **Active Leads**: Unconverted leads without a scheduled follow-up stay visible for prompt action.
  - Leads are **never lost or deleted** due to scheduling.
- **Response Status Tracking**: `Follow Up`, `Interested` (highlighted in teal), `DNP - Did Not Pick` (visual warning badge).
- **Direct Dial & One-Tap Conversion**: Direct phone dialer integration and **Convert to Customer** action that pre-fills customer information into contract records.
- **Search & Filters**: Instant search by shop name, customer name, contact phone, and response status.

### 2. Customer Management
- **Comprehensive Business Dossier**:
  - Shop Name, Customer/Owner Name, Contact Number, Address, Work Details, Work Status, Remarks.
  - Work Statuses: `Not Started`, `In Progress`, `In Review`, `On Hold`, `Completed`, `Cancelled`.
- **Automated Financial Accounting (Integer Paise)**:
  - All currency calculations use integer paise (`1 INR = 100 paise`) to prevent IEEE 754 floating-point precision issues.
  - `Balance Amount = Total Work Amount - Total Amount Received`.
  - Atomic Firestore transactions and batch writes maintain real-time integrity between payments and customer balances.
  - **Advance Payment Guard**: Prevents recording payments higher than outstanding balance unless user explicitly confirms an advance.
- **Customer Detail Screen**: Complete work log, phone dialer, prominent outstanding card, and full payment audit history.

### 3. Payment & Expense Management
- **A. Monthly Collection Targets**:
  - Set, edit, track, and review target history.
  - Real-time progress bar, percentage achieved indicator, and remaining target calculations.
- **B. Collection History**:
  - Comprehensive history of all payments across all customers with date, payment method (`Cash`, `UPI`, `Bank Transfer`, `Other`), and remarks.
  - Filter by month, customer, method, and date range.
  - Export collection reports directly as **PDF** or **CSV/Excel**.
- **C. Outstanding Payments**:
  - **Completed Work Outstanding**: Dues from finished deliverables.
  - **Incomplete Work Outstanding**: Pending dues from work in progress.
  - Direct 1-tap navigation to open customer profiles from outstanding lists.
  - PDF & CSV export for recovery audits.
- **D. Expense Management**:
  - Categories: `Salary`, `Personal Expense`, `Other Expense`.
  - Monthly expense total and category breakdown visualization bars.
- **E. Scheduled Future Expenses**:
  - Schedule upcoming rent, tax, or vendor expenses with due date and time.
  - **Overdue Logic**: If not marked as paid by scheduled date/time, highlighted in red as **OVERDUE** from the next day until marked paid.
  - 1-Tap "Mark as Paid" automatically logs the payment into actual monthly expenses.
- **F. Financial Summary & Cash Flow**:
  - `Net Cash Flow = Total Collected - Total Expenses`.
  - Visual charts comparing collections vs. expenses.
  - *Strict Rule*: Outstanding balances are kept in receivables and never counted as realized cash.

### 4. Day Planner
- **Daily Agenda & Scheduling**:
  - Tasks with title, details, date, 12-hour time, priority (`Low`, `Medium`, `High`), and status (`Pending`, `Completed`).
  - **Overdue Task Logic**: If a task is not marked completed by the end of its scheduled date, it is prominently displayed in red from the next day and kept in a dedicated **Overdue Tasks** section until completed.
  - Daily completion progress indicator (e.g. `4/5 Tasks (80%)`).
  - View toggle: **List View** and interactive **Calendar View** (via `table_calendar`).
  - Add execution remarks to any task.

---

## 🎨 Design System & UX

- **Material Design 3 (M3)** with custom palette:
  - **Royal Blue & Indigo Primary**: `#2563EB`, `#1E40AF`, `#4F46E5`
  - **Success Green**: `#10B981` (Completed tasks, successful payments)
  - **Warning Amber/Orange**: `#F59E0B` (Pending follow-ups, DNP status)
  - **Urgent Red**: `#EF4444` (Overdue tasks, overdue expenses, outstanding dues)
  - **Teal & Purple Secondary Accents**: `#14B8A6`, `#7C3AED`
- **Theme Modes**: Seamless **Light Mode** and **Dark Mode** toggle stored in local preferences.
- **Navigation**: Clean Bottom Navigation Bar (`Dashboard`, `Leads`, `Customers`, `More`) + Quick Action Sheet.
- **Formatting Standards**:
  - Dates: `DD-MM-YYYY` (e.g. `04-11-2026`)
  - Times: 12-Hour format (`02:30 PM`)
  - Currency: Indian Rupee (`₹1,25,000.00`)

---

## 📁 Project Architecture

```
lib/
├── app.dart                                # MaterialApp, Theme, and Route setup
├── main.dart                               # App entry point & failsafe initialization
├── firebase_options.dart                   # Multiplatform Firebase options
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                 # Color palette & semantic status colors
│   │   ├── app_constants.dart              # Enums, statuses, collections & keys
│   │   └── app_typography.dart             # Modern typography styles
│   ├── theme/
│   │   ├── app_theme.dart                  # Material 3 light & dark theme definitions
│   │   └── theme_provider.dart             # Persistent theme switcher
│   ├── utils/
│   │   ├── currency_formatter.dart         # Integer paise <-> INR formatting
│   │   ├── date_formatter.dart             # DD-MM-YYYY and 12-hr time helpers
│   │   └── notification_service.dart       # Local notifications & alert channels
│   ├── widgets/
│   │   ├── custom_card.dart                # Rounded elevated cards
│   │   ├── empty_state_view.dart           # Illustrated empty states with actions
│   │   ├── stat_badge.dart                 # Color-coded status badges
│   │   └── confirm_dialog.dart             # Confirmation dialogs
│   └── services/
│       ├── firebase_service.dart           # Cloud Firestore service & atomic batches
│       └── pdf_export_service.dart         # PDF printing & CSV export generator
├── features/
│   ├── auth/                               # Auth models, Riverpod state, Splash, Login,
│   │                                       # Register, Forgot Password, Profile & Settings
│   ├── dashboard/                          # Metric cards, quick actions, activity log
│   ├── leads/                              # Lead models, CRUD, filters & follow-up scheduler
│   ├── customers/                          # Customer & Payment models, batch writes,
│   │                                       # outstanding splits, details & call actions
│   ├── payments/                           # Monthly targets, collection history,
│   │                                       # expenses, future expenses, financial summary
│   ├── day_planner/                        # Task model, overdue detector, calendar/list view
│   ├── reports/                            # Multi-tab analytics, PDF & CSV export
│   └── navigation/                         # Main bottom navigation & quick action modal
```

---

## 🗄️ Firestore Security Rules & Indexes

The app follows strict user-scoped tenancy (`users/{userId}/...`):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() { return request.auth != null; }
    function isOwner(userId) { return isAuthenticated() && request.auth.uid == userId; }

    match /users/{userId} {
      allow read, write: if isOwner(userId);
      match /leads/{leadId} { allow read, write: if isOwner(userId); }
      match /customers/{customerId} {
        allow read, write: if isOwner(userId);
        match /payments/{paymentId} { allow read, write: if isOwner(userId); }
      }
      match /monthlyTargets/{targetId} { allow read, write: if isOwner(userId); }
      match /expenses/{expenseId} { allow read, write: if isOwner(userId); }
      match /futureExpenses/{expenseId} { allow read, write: if isOwner(userId); }
      match /tasks/{taskId} { allow read, write: if isOwner(userId); }
    }
  }
}
```

Deploy security rules:
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

---

## ☁️ Firebase Cloud Functions (Daily Alerts Cron)

Located in `functions/index.js`, a scheduled cron runs every morning at **08:00 AM IST** to scan:
1. Pending tasks scheduled before today and trigger an FCM `🚨 Overdue Tasks Alert`.
2. Pending future expenses past due and trigger an FCM `⚠️ Overdue Scheduled Expenses`.
3. Leads scheduled for follow-up today and trigger a reminder push.

Deploy Cloud Functions:
```bash
cd functions
npm install
firebase deploy --only functions
```

---

## 🧪 Testing

Run all unit tests and widget smoke tests:
```bash
flutter test
```

Test coverage includes:
- Integer paise accuracy (no floating-point rounding errors)
- Date formatting (`DD-MM-YYYY`) and 12-hour time format
- Automatic customer balance calculation (`Total - Received`)
- Lead follow-up status partition (Upcoming, Due, Active)
- Overdue task calculation (overdue from next day if pending)
- Overdue future expense identification
- Full widget smoke test

---

## 📦 Building the Android APK

To build a release Android APK:

1. Connect your Android device or start an emulator.
2. Run:
```bash
flutter build apk --release
```
The output APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

To build an Android App Bundle (for Google Play Store upload):
```bash
flutter build appbundle
```
The AAB file will be located at:
`build/app/outputs/bundle/release/app-release.aab`
