# Aurora Glass — Liquid Glass UI Kit

A complete glassmorphism design system: **173 live components** on the web
showcase plus a **Flutter widget port** — all built on the same six optical
layers that make glass look like glass instead of plastic. Now including a
**Shapes** section — squircles, morphing blobs, tickets, scallops, speech
bubbles, gooey metaballs and more.

## The recipe (researched against Apple Liquid Glass / glassmorphism v2)

Glass is a stack of optical layers, never a single `backdrop-filter`:

| Layer | What it does | Web mechanism | Flutter mechanism |
|---|---|---|---|
| Backdrop | Blurs + saturates what's behind | `backdrop-filter: blur() saturate()` | `BackdropFilter` + `ImageFilter.blur` |
| Body tint | Translucent gradient fill, top-lit | `linear-gradient` over the blur | `LinearGradient` decoration |
| Rim | Hairline edge, brightest top-left | gradient `border` + `::after` mask | `_RimPainter` + border sides |
| Specular | Sharp sheen on the upper face | `::before` gradient, masked to 42% | inner `LinearGradient` in a `Stack` |
| Inner depth | Material thickness | `inset` shadows | gradient stops at edges |
| Elevation | Separates pane from world | `box-shadow` scale | `BoxShadow` |
| Grain | Breaks digital smoothness | SVG `feTurbulence` overlay | `_GrainPainter` |
| Refraction* | Bends the backdrop at edges | SVG `feDisplacementMap` (Chromium only) | — |

\* Progressive enhancement — falls back to blur everywhere else.

## Files

```
css/glass.css            the entire design system — tokens, 3 glass levels,
                         6 tints, all component styles, light theme, fallbacks
index.html               the showcase — 173 numbered live components
js/glass.js              interactions: ripple, spotlight, ⌘K palette, toasts,
                         modals/drawers/sheets, scrollspy, tilt, counters
flutter/glass_kit.dart   Flutter port — GlassSurface + 20 ready widgets
```

## Use it on the web

Drop `css/glass.css` into any app (plain web, Wails, Electron, React):

```html
<link rel="stylesheet" href="glass.css" />
<div class="glass-2 rim spec" style="border-radius:22px;padding:24px">
  Hello, glass.
</div>
```

Glass needs something colorful to bend — put orbs/gradients behind your panes
(see `.stage` / `.orb` in `index.html`) or the blur reads as flat gray.

### The vocabulary

- **Levels** — `.glass-1` controls (14px), `.glass-2` surfaces (22px),
  `.glass-3` floating/nav/modals (36px)
- **Tints** — `.glass-indigo|cyan|pink|amber|green|red` for emphasis
- **Layers** — `.rim` gradient hairline, `.spec` sheen, `.spot` cursor spotlight
- **Components** — `btn`, `chip`, `switch`, `gcheck`, `gradio`, `grange`,
  `input`, `otp`, `card`, `stat`, `price`, `profile`, `player`, `tabs`,
  `pager`, `wizard`, `dock`, `bottombar`, `menu`, `palette`, `modal`,
  `drawer`, `sheet`, `toast`, `tip`, `alert`, `table`, `timeline`, `avatar`,
  `badge`, `prog`, `ring`, `donut`, `skel`, `acc`, `cal`, `spark`, `kpi`,
  `banner`, `status`, `spinner`, `marquee`, `dropzone`, `gauge`, `device` …

### Shapes — glass is not a rectangle

| Silhouette | Mechanism | Notes |
|---|---|---|
| `.shape-squircle` | `clip-path: url(#clip-squircle)` | `corner-shape: squircle` upgrade via `@supports` (Chrome 139+) |
| `.shape-blob` | animated 8-value `border-radius` | borders, rim & shadows follow for free |
| `.shape-bevel` | polygon clip / `corner-shape: bevel` | chamfered corners |
| `.shape-scoop` | 4× `radial-gradient` corner masks | concave cutouts |
| `.shape-ticket` | side-notch masks | punched circle holes |
| `.shape-scallop` | `repeating-x` radial mask | receipt edge |
| `.shape-hex` `.shape-shield` `.shape-sparkle` | polygon clips | tech / verified / star |
| `.shape-pin` `.shape-crescent` `.shape-wave` `.shape-folder` `.shape-tag` | `clip-path: url(#…)` objectBoundingBox | scale to any size |
| `.shape-leaf` `.shape-petal` | opposite-corner radii | organic |
| `.bubble-chat` `.sticker` `.ribbon` `.gooey` `.arc-text` | pseudo-element / SVG filter / textPath | composition shapes |

Clipped shapes lose `box-shadow`/`border` — wrap them in `.shape-frame`
(gradient padding ring + `drop-shadow` filter) to get rim + elevation back.

## Use it in Flutter

Copy `flutter/glass_kit.dart` into your project. Zero dependencies.

```dart
import 'glass_kit.dart';

AuroraStage(                       // ambient backdrop — REQUIRED under glass
  child: GlassSurface(
    level: GlassLevel.floating,
    radius: 22,
    child: Text('Hello, glass.'),
  ),
)
```

Ready widgets: `GlassButton` (plain/primary/destructive/ghost + loading),
`GlassFAB`, `GlassIconButton`, `GlassInput`, `GlassSwitch`, `GlassSlider`,
`GlassChip`, `GlassCard`, `GlassStatCard`, `GlassProfileCard`, `GlassNavBar`,
`GlassSegmented`, `GlassBottomBar`, `GlassBreadcrumb`, `GlassDialog`,
`GlassSheet`, `GlassToast`, `GlassTooltip`, `GlassAvatar`, `GlassAvatarStack`,
`GlassBadge`, `GlassProgress`, `GlassProgressRing`, `GlassTimeline`,
`GlassAlert`, `GlassStatus`, `GlassSpinner`, `GlassSpotlight`, `GlassEmpty`,
`GlassDivider` — plus shapes: `GlassSquircle` (ContinuousRectangleBorder),
`GlassBlob` (animated border-radius morph), `GlassTicket` + `TicketClipper`
(side notches), `GlassBubble` + `BubbleClipper` (chat tail), `GlassGooLoader`
(metaball loader).

## Guardrails baked in

- `-webkit-backdrop-filter` paired everywhere (values hardcoded — custom
  properties don't resolve inside the prefixed declaration)
- `@supports` fallback goes nearly opaque — text stays readable everywhere
- `prefers-reduced-motion` respected
- Performance: glass is a highlight material. `backdrop-filter` recomposites
  the layers beneath it — don't frost every element on a mobile page.
