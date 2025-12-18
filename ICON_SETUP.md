# App Icon Setup Instructions

## Overview
VaultLock needs app icons for iOS and Android. You'll need to create or design an icon that represents security and passwords.

## Icon Design Recommendations
- **Theme**: Lock, shield, vault, or key imagery
- **Colors**: Use the app's primary color (#0EA5E9 - cyan blue) as the main color
- **Style**: Modern, clean, minimalist
- **Avoid**: Text in the icon (looks bad at small sizes)

## Required Files

### 1. Main Icon (1024x1024)
**Path:** `assets/icon/app_icon.png`
- Size: 1024x1024 pixels
- Format: PNG with transparency
- This will be used for both iOS and Android

### 2. Android Adaptive Icon Foreground (Optional)
**Path:** `assets/icon/app_icon_foreground.png`
- Size: 1024x1024 pixels
- The actual icon should be centered in a 432x432px safe zone
- Background will be solid color (#0EA5E9)

## Quick Start Options

### Option A: Use a Design Tool
1. Use Figma, Canva, or Adobe Illustrator
2. Create a 1024x1024 canvas
3. Design your icon (shield/lock theme)
4. Export as PNG

### Option B: Use an AI Image Generator
```
Prompt: "A modern, minimalist app icon for a password manager.  
Features a stylized shield or lock symbol in cyan blue (#0EA5E9)  
on a white or gradient background. Clean, professional, flat design  
style. 1024x1024 pixels. No text."
```

### Option C: Use Free Icon Resources
- **Flaticon**: https://www.flaticon.com/ (search "password vault")
- **Icons8**: https://icons8.com/ (search "security shield")
- Remember to check licensing for commercial use!

## Generation Steps

1. **Create the icon file**
   - Save your 1024x1024 icon as `assets/icon/app_icon.png`

2. **Run the generator**
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

3. **Verify**
   - Check `android/app/src/main/res/` for multiple mipmap folders
   - Check `ios/Runner/Assets.xcassets/AppIcon.appiconset/` for icons

## Current Configuration

The app is configured in `pubspec.yaml` with:
- **Android**: Adaptive icon with #0EA5E9 background
- **iOS**: Standard icon
- **Image path**: `assets/icon/app_icon.png`

## Placeholder Until You Have an Icon

For now, you can:
1. Create a simple placeholder using any image editor
2. Just put any 1024x1024 PNG at `assets/icon/app_icon.png`
3. Run the generator to test it works

## Icon Checklist

- [ ] Create 1024x1024 PNG icon
- [ ] Place at `assets/icon/app_icon.png`
- [ ] (Optional) Create adaptive foreground
- [ ] Run `flutter pub run flutter_launcher_icons`
- [ ] Test on device/simulator
- [ ] Verify looks good at all sizes

---

**Note:** This is the only remaining manual step for App Store readiness. Everything else is code-complete!
