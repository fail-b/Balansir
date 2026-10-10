# Balansir — иконка (вариант 1b)

## Вариант 1: Asset Catalog (iOS 18+)
Замените папку `Assets.xcassets/AppIcon.appiconset` в Xcode-проекте на `AppIcon.appiconset` отсюда.
- AppIcon-1024.png — Light, фон #6449da, без прозрачности
- AppIcon-1024-dark.png — Dark, прозрачный фон (тёмную подложку даёт система)
- AppIcon-1024-tinted.png — Tinted, монохром на чёрном
Скругления не запечены — маску накладывает iOS.

## Вариант 2: Icon Composer (iOS 26, Liquid Glass)
1. Icon Composer → New, перетащите SVG из `Icon Composer layers`:
   - 1-top-half.svg — группа 1, белый, opacity 100%
   - 2-bottom-half.svg — группа 2, белый, opacity 50%
2. Background → Solid #6449da (Display P3: oklch(0.52 0.21 285)).
3. Dark: фон по умолчанию, цвет слоёв #A8A3FF.
4. Сохраните как AppIcon.icon, добавьте в проект и укажите имя в Build Settings → App Icon (ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon).
