# Supabase Notes App

A Flutter notes application demonstrating CRUD operations with Supabase, plus file and storage integration.

## Features
- Create, edit, and delete notes
- Supabase database integration
- Supabase Storage / file-picker integration
- Flutter Material UI

## Tech Stack
- Flutter & Dart
- Supabase
- `supabase_flutter`
- `file_picker`

## Getting Started
```bash
flutter pub get
flutter run
```

Configure your Supabase project before running the app. Do not commit private service-role credentials.

## Project Structure
```text
lib/
├── main.dart
├── auth1.dart
└── storage.dart
```

## Security
The client uses Supabase's publishable/anon key model. Production deployments should enforce Row Level Security (RLS) and appropriate database policies. Never expose a Supabase service-role key in a Flutter client.

## Purpose
An intentionally small project for demonstrating Flutter + Supabase integration and cloud-backed CRUD workflows.