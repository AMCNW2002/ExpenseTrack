# Spendly

Spendly is a Flutter personal spending assistant. It uses Firebase Authentication for accounts and Cloud Firestore for expenses, monthly budgets, and savings goals.

## Requirements

- Flutter stable with Dart 3.5 or later
- Android Studio/Android SDK for Android builds
- Node.js 20 or 22 and npm for Firestore rules tests
- Java 21 or later for the current Firebase CLI Firestore emulator
- A Firebase project with Email/Password Authentication and Cloud Firestore enabled

## Firebase Setup

The checked-in Android Firebase settings point to project `spendly2-1adc5`. Authentication and Firestore are separate Firebase products: successful sign-in does not mean Firestore indexes or security rules are ready. This is a student project and does not integrate payments, subscriptions, Stripe, or in-app purchases. You can use the Firebase Spark (free) plan for this app; do not enable billing or upgrade plans unless you intentionally choose to.

For a simple setup without CLI:

1. In Firebase Console, open project `spendly2-1adc5` and enable **Authentication > Sign-in method > Email/Password**.
2. Open **Firestore Database**. If a database already exists in test mode, keep using it; there is no need to create it again.
3. In **Firestore Database > Rules**, replace the rules with the basic signed-in owner rules in [firestore.rules](firestore.rules), then click **Publish**. A signed-in user can work with their own profile and financial documents; they cannot read or change another user's documents. This is intentionally simpler than production schema validation, but safer than open test-mode rules.
4. In **Firestore Database > Indexes > Composite**, create the Expenses list index:
   - Collection ID: `expenses`
   - `userId`: Ascending
   - `date`: Descending
   - Query scope: Collection

   Wait until the index status is **Enabled**, then retry in the app. Other queries may request additional indexes; use the Firebase error's **Create index** link, or refer to [firestore.indexes.json](firestore.indexes.json). Rules do not create indexes.

Firestore's automatic **test mode** rules are open to anyone and expire after a temporary period. Avoid leaving those rules published. The owner rules in this project are still basic, but require sign-in and isolate each user's data.

The CLI is not required. If you later choose to publish from a terminal, install Firebase CLI and sign in, then run `firebase deploy --only firestore:rules,firestore:indexes --project spendly2-1adc5`.

## Install and Run

From the repository root:

```sh
flutter pub get
flutter run -d <device-id>
```

List attached targets with `flutter devices`. Android's current application ID is `com.example.expencetracker`; change it only together with the Firebase Android registration and native configuration if adopting a production identifier.

On Android, Firestore disk persistence is enabled. Previously loaded records remain available from the local cache while offline, and Firestore queues writes locally to sync when connectivity returns. The app's Firestore snapshot listeners update the screens as soon as cached or server data changes; it intentionally does not poll Firebase every two seconds, which would create unnecessary reads and battery use. Data that has never been cached cannot be fetched during a first-ever offline launch.

## Validation

Run Dart analysis and the Flutter unit tests:

```sh
flutter analyze
flutter test
```

Install the Node test dependencies and run the Firestore rules against the local emulator:

```sh
npm ci
npm run test:rules
```

The rules tests cover anonymous access, owner and cross-owner reads, profile identity changes, expense ownership, budget merge writes, and goal progress updates. They do not require a Firebase login or touch production data.

Build Android locally:

```sh
flutter build apk --debug
```

For a release, configure production Android signing separately and verify the app on a physical Android device with a test Firebase account. Confirm account creation/login, expense CRUD, budgets across months, insights, and savings-goal CRUD/progress. Do not use production financial data during smoke testing.

## Data Collections

- `users/{uid}`: account profile, readable and editable only by that account
- `expenses/{expenseId}`: expense records with an immutable `userId`
- `budgets/{budgetId}`: monthly budget records owned by `userId`
- `goals/{goalId}`: savings goals with an immutable `userId`
