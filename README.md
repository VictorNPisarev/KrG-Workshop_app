# workshop_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## RUN
**Chrome:** flutter run -d chrome --web-browser-flag "--disable-web-security"

## BUILD release
**Web:** flutter build web --release --no-tree-shake-icons
**Apk (push main с новой версией + публикация на Github):** .\scripts\release_w_push.ps1

## ЗАПУСК СЕРВЕРА
cd build/web
**node.js**  npx http-server -p 3030 --host 0.0.0.0
