# Haven App Icon Setup

## Files

| File | Variant | Description |
|------|---------|-------------|
| `AppIcon-Light.svg` | Any Appearance | Light cream background, warm brown layered rectangles |
| `AppIcon-Dark.svg` | Dark | Dark gray background, lighter brown rectangles |
| `AppIcon-Tinted.svg` | Tinted | White shapes on transparent — iOS applies user's tint |

## Adding to Xcode (Xcode 14+)

1. Open `Assets.xcassets` in the project navigator
2. Select the **AppIcon** asset (or create one: Editor > Add New Asset > iOS App Icon)
3. In the Attributes Inspector (right panel), ensure **iOS** is checked
4. Drag each SVG to the correct slot:
   - **Any Appearance** (top row) -> `AppIcon-Light.svg`
   - **Dark** (middle row) -> `AppIcon-Dark.svg`
   - **Tinted** (bottom row) -> `AppIcon-Tinted.svg`
5. Xcode accepts SVG directly and generates all required sizes automatically

## Verifying

- Build and run on a device or simulator with iOS 18+
- Long-press the home screen, tap an icon, and switch between Light/Dark/Tinted to confirm all three variants render correctly
- Check the App Store Connect preview at 1024x1024

## Design Notes

- Concept: "Layered Thought" — three overlapping rounded rectangles suggesting stacked notes
- Subtle horizontal lines on the front rectangle suggest text content
- No text in the icon (unreadable at small sizes)
- Primary brand color: #8B6F47 (warm brown)
