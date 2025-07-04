# flutter_application_1

A new Flutter project.

## Firebase Setup Instructions

1. Create a Firebase project:
   - Go to https://console.firebase.google.com/
   - Click "Create a project"
   - Follow the setup wizard
   - Name your project (e.g., "ADAS App")

2. Add a web app to your project:
   - In Firebase Console, click the web icon (</>)
   - Register your app with any nickname
   - Copy the configuration object

3. Update firebase_options.dart:
   - Replace the placeholder values in lib/firebase_options.dart with your actual Firebase configuration values
   - The configuration values you need to replace are:
     - apiKey
     - authDomain
     - projectId
     - storageBucket
     - messagingSenderId
     - appId
     - measurementId (for web)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
