# 💸 Spendly — Personal Expense Tracker

> A clean and modern Flutter expense tracker designed to make personal
> finance management simple, visual, and effortless.

<p align="center">
  <b>Track • Manage • Understand • Improve</b>
</p>

---

## 📱 About Spendly

**Spendly** is a personal expense tracking application built with
**Flutter, Dart, Firebase Authentication, and Cloud Firestore**.

The main goal of Spendly is to provide a simple and user-friendly way to
record daily expenses, organize spending by category, and understand
monthly spending habits through a clean dashboard and insights.

The application was developed as part of the **CyphLab Flutter Developer
Internship Practical Task**.

---

## ✨ Features

### 💰 Expense Management

- ➕ Add new expenses
- ✏️ Edit existing expenses
- 🗑️ Delete expenses with confirmation
- 📝 Add optional notes to expenses
- 💵 Record expense amount
- 📅 Select expense date
- 🏷️ Categorize expenses

### 📊 Dashboard & Insights

- 📈 Monthly spending overview
- 📅 Advanced date-range filtering
- 📊 Category-based expense visualization
- 💳 Total spending summary
- 📅 Monthly expense tracking
- 🌙 Dark mode improvements
- 🔎 Search and filter expenses
- 💡 Spending insights

### 🔐 Authentication

- 🔑 User registration
- 🔓 User login
- 🚪 Logout
- 🔄 Password reset
- 👤 Profile management

### 🎨 User Experience

- Clean and modern interface
- Responsive Flutter UI
- Consistent typography and spacing
- Loading states
- Empty states
- Error handling
- Confirmation dialogs for destructive actions
- Smooth navigation
- offline Service

---

## 🛠️ Technologies & Packages

| Technology | Purpose |
|---|---|
| **Flutter** | Cross-platform UI development |
| **Dart** | Application programming language |
| **Firebase Authentication** | User authentication |
| **Cloud Firestore** | Cloud database |
| **Provider** | State management |
| **fl_chart** | Charts and data visualization |
| **intl** | Date and number formatting |

---

## 🏗️ Project Structure

The project follows a modular structure to keep the application
maintainable and easy to extend.

```text
lib/
│
├── models/
│   └── Expense model
│
├── providers/
│   └── Application state management
│
├── services/
│   └── Firebase / Firestore services
│
├── screens/
│   ├── auth/
│   ├── home/
│   ├── expenses/
│   ├── budget/
│   ├── insights/
│   └── profile/
│
├── widgets/
│   └── Reusable UI components
│
├── utils/
│   └── Helpers and constants
│
└── main.dart
```

---

## 🔥 Firebase

Spendly uses Firebase for authentication and cloud data storage.

### Firebase Authentication

Used for:

- User registration
- User login
- Password reset
- Logout
- User account management

### Cloud Firestore

Used to securely store:

- User expense records
- Expense categories
- Amounts
- Dates
- Notes
- Other expense-related information

---

## 📦 Expense Data

Each expense contains information such as:

```text
Title
Amount
Category
Date
Note (Optional)
```

This structure makes it possible to organize and analyze spending over
different time periods and categories.

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone YOUR_GITHUB_REPOSITORY_URL
```

### 2. Open the project

```bash
cd spendly
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Configure Firebase

Create a Firebase project and connect it with the Flutter application.

Add the required Firebase configuration files for your platform.

### 5. Run the application

```bash
flutter run
```

---

## 🧪 Testing

The application was tested during development with focus on:

- Expense creation
- Expense editing
- Expense deletion
- Form validation
- Firebase authentication
- Firestore data operations
- Search and filtering
- Loading states
- Empty states
- Error handling
- Different screen sizes

> Additional device testing is recommended before production release.

---

## 🤖 AI Tools Used

AI-assisted development tools were used during the development process to
improve productivity, code quality, debugging, and documentation.

### ChatGPT

**Used for:**

- Flutter/Dart development guidance
- Debugging and identifying potential issues
- UI/UX improvement ideas
- Code structure suggestions
- Firebase implementation guidance
- README documentation
- Reviewing the application against the internship requirements

ChatGPT was used as a development assistant, while the final
implementation and decisions were reviewed and integrated into the
project manually.

### GitHub Copilot

**Used for:**

- Code completion
- Boilerplate generation
- Development productivity

---

## 🎯 Design Goals

Spendly was designed around a few simple principles:

### Simple

Users should be able to add and manage an expense quickly.

### Clear

Important financial information should be easy to understand at a
glance.

### Modern

The interface uses a clean visual hierarchy, cards, spacing, and
consistent components.

### Practical

The application focuses on useful expense-tracking functionality
without unnecessary complexity.

---

## 📱 Main Screens

The application includes:

- 🏠 **Home** — Monthly spending overview
- 💳 **Expenses** — Expense history and filtering
- 💰 **Budget** — Budget tracking
- 📊 **Insights** — Spending analysis and charts
- 👤 **Profile** — User account management

---

## 🔮 Future Improvements

Possible future improvements include:

- 📤 Export expenses as CSV/PDF
- 🔔 Budget notifications
- ☁️ Improved offline support
- 🔐 Additional authentication providers
- 📈 More detailed financial analytics


---

## 👨‍💻 Developer

**AMC Sandaruwan**

Flutter Developer | Mobile Application Development
https://amcnw2002.github.io/portfolio/

---

## 📄 License

This project was created for educational and internship evaluation
purposes.

---

