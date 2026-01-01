# App Icon Generation with flutter_launcher_icons

This project uses the flutter_launcher_icons package to generate app icons for Android and iOS from a single source image.

## How to Use

1. Place your logo image at `docs/logo.jpeg`.
2. Add the following configuration to your `pubspec.yaml`:

```yaml
flutter_icons:
  android: true
  ios: true
  image_path: "docs/logo.jpeg"
  remove_alpha_ios: true
```

3. Add flutter_launcher_icons as a dev dependency:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

4. Run the following command to generate the icons:

```
flutter pub get
flutter pub run flutter_launcher_icons:main
```

This will automatically generate and replace the launcher icons in all required mipmap folders for Android and the Assets.xcassets for iOS.

---

**Note:**
- Make sure your logo is square and at least 512x512 pixels for best results.
- You can adjust the `image_path` if you move the logo to a different location.
- For more options, see the [flutter_launcher_icons documentation](https://pub.dev/packages/flutter_launcher_icons).
