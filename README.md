# Expense Splitter App

## Project Description

The Expense Splitter App is a simple yet powerful Flutter-based mobile application designed to help
users manage and split expenses among a group of people without needing an internet connection or
multiple devices. Unlike other existing expense splitter apps that require every user to log in and
be connected to the internet, our app works offline and stores all data locally.

This app solves the problem of needing network connectivity or logging into separate devices when
managing group expenses during trips, events, or shared living. Whether you're in a remote place
with no network or just prefer simplicity, the Expense Splitter App lets one user manage all
expenses on a single device.

### Key Features

* **No login required**: No need for users to log in or share personal information
* **Offline functionality**: Fully functional without the need for a network connection
* **Local storage**: All data (members, expenses, debts) is stored on the device and will persist
  until the app's data is cleared
* **Simple, intuitive UI**: Add members, log expenses, calculate who owes whom, and settle debts
  with a clean and easy-to-use interface
* **Future support**: In the future, history tracking and syncing across devices can be added, but
  for now, the app is focused on simplicity and offline use

This app is perfect for group travelers, roommates, friends, or anyone needing a straightforward way
to manage shared expenses during their time together, all on one device.

## Features

### Core Functionality

* **Add Members**: Easily add new members to the group by entering their name
* **Log Expenses**: Add expenses with a title, amount, the person who paid, and those who were
  involved in the expense
* **Debt Calculation**: Automatically calculates how much each person owes after an expense is
  logged
* **Debt Settlement**: Allows users to settle debts by paying part or all of what they owe, updating
  the records accordingly

### Technical Features

* **No Internet Required**: Works entirely offline without the need for an active network connection
* **Local Storage**: Data is stored locally on the device, and can be cleared anytime after a trip
  or event
* **Simple Setup**: Add users, log expenses, and track who owes whom—just like in larger, more
  complex apps but in a simple, offline manner

## Installation Instructions

### Prerequisites

Before you begin, ensure that you have the following installed on your system:

* **Flutter SDK**: You need to have Flutter installed on your machine. You can install it by
  following the official Flutter installation
  guide: [Install Flutter](https://flutter.dev/docs/get-started/install)
* **Android Studio / VS Code**: A suitable IDE for Flutter development (both Android Studio and VS
  Code are recommended)
* **Xcode** (for iOS development): If you're developing on macOS, ensure Xcode is installed for
  building iOS apps

### Steps to Install

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/expense-splitter.git
   ```

2. Navigate into the project directory:
   ```bash
   cd expense-splitter
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Dependencies

* `flutter`: The core framework for building cross-platform apps
* `shared_preferences`: To persist user data locally between app sessions

## Usage

Here's how you can use the Expense Splitter App:

1. **Add Members**
    * Tap the "Add Member" button in the top-right corner of the screen
    * Enter the name of the person and tap "Add"

2. **Add an Expense**
    * Tap the "Add Expense" floating action button (the "+" button)
    * Enter the title of the expense, the total amount
    * Select who paid the expense
    * Select the people involved
    * Tap "Add Expense" to log the expense

3. **View Debts**
    * Each person's list shows the amount they've paid and the people they owe money to (or who owe
      them money)
    * Tap the "Check" button next to a person's name to open a dialog and settle debts

4. **Settle Debts**
    * In the "Settle Debt" dialog, enter the amount to pay
    * The app will update the debts accordingly
    * The debt will be reduced or cleared based on the amount entered

5. **Persistent Storage**
    * The app automatically saves all members, expenses, and debts locally on your device using
      SharedPreferences
    * Data will persist even if the app is closed or restarted

6. **Clear Data**
    * After each trip or event, you can clear the stored data to reset everything

## Configuration

The app is designed to work out of the box with minimal configuration. However, there are a few
configuration aspects you might want to be aware of:

* **Local Storage**: Data (members, expenses, and debts) is stored in SharedPreferences. You do not
  need to configure this; the app handles it automatically
* **Dependencies**: If you need to update or add new dependencies, modify the `pubspec.yaml` file
* **Environment Configuration**: No environment variables are required for this project, as it uses
  local storage and standard Flutter widgets
* **Localization and Language Support**: Currently, the app is in English. To add more languages,
  you can implement Flutter's localization features

## Contact Information

If you have any questions, suggestions, or issues with the app, feel free to reach out:

* **Author**: Vishnu Deepan P
* **Email**: vishnudeepanp@gmail.com
