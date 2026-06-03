# Coral AI Landing Page - Design System Themes

This document extracts the specific light and dark theme design tokens from the Coral AI Landing Page (React build). These tokens establish the visual foundation for the application and are intended for use with AI generation tools (like Google Stitch / Project IDX) when generating new components or layouts.

## 1. Typography (Shared)
The font stack applies across both themes.

*   **Display:** `'Rethink Sans', 'Inter', system-ui, sans-serif`
*   **Body:** `'Inter', 'Rethink Sans', system-ui, sans-serif`
*   **Mono:** `'JetBrains Mono', ui-monospace, monospace`

---

## 2. Light Theme (Default `:root`)

### Backgrounds
*   `--bg-page`: `#f7f5f1`
*   `--bg-card`: `#ffffff`
*   `--bg-alt`: `#f9fafb`
*   `--bg-chip`: `#f3f4f6`

### Borders
*   `--border-subtle`: `#d1d5db`
*   `--border-base`: `#e8e6e2`
*   `--border-faint`: `#f3f4f6`

### Text Colors
*   `--text-primary`: `#1e1c1a`
*   `--text-secondary`: `#5a5650`
*   `--text-faint`: `#827d76`
*   `--text-muted`: `#a8a39c`

### Brand Accents
*   `--brand-primary`: `#0057e6`
*   `--brand-hover`: `#3379eb`
*   `--brand-pressed`: `#0048bd`
*   `--brand-technical`: `#224eee`
*   `--brand-cyan`: `#38bdf8`
*   `--brand-light`: `rgba(0, 87, 230, 0.08)`
*   `--brand-glow`: `rgba(0, 87, 230, 0.28)`
*   `--navy-deep`: `#0d1738`
*   `--text-brand`: `var(--brand-primary)`

### Accent Tints (Backgrounds)
*   `--tint-blue`: `#e5eefc`
*   `--tint-sky`: `#f0f9ff`
*   `--tint-green`: `#f0faf3`
*   `--tint-orange`: `#fef3e8`
*   `--tint-red`: `#fdf0f0`
*   `--tint-teal`: `#f0fdfa`

### Navigation Backdrop
*   `--header-bg-rest`: `rgba(255, 255, 255, 0.05)`
*   `--header-bg-scrolled`: `rgba(255, 255, 255, 0.15)`
*   `--header-border-rest`: `rgba(255, 255, 255, 0.2)`
*   `--header-border-scrolled`: `rgba(255, 255, 255, 0.4)`
*   `--header-shadow-scrolled`: `rgba(13, 23, 56, 0.08)`
*   `--header-text`: `#0f172a`
*   `--header-nav-text`: `#0f172a`
*   `--header-hover`: `rgba(15, 23, 42, 0.06)`

---

## 3. Dark Theme (`.dark`)

### Backgrounds
*   `--bg-page`: `#080a0f`
*   `--bg-card`: `#121620`
*   `--bg-alt`: `#0d1017`
*   `--bg-chip`: `#1c212d`

### Borders
*   `--border-subtle`: `#262d3d`
*   `--border-base`: `#1c212d`
*   `--border-faint`: `#121620`

### Text Colors
*   `--text-primary`: `#e2f1fa`
*   `--text-secondary`: `#8ba3b8`
*   `--text-faint`: `#607386`
*   `--text-muted`: `#8ba3b8`

### Brand Accents (Brightened for Contrast)
*   `--brand-primary`: `#3b82f6`
*   `--brand-hover`: `#60a5fa`
*   `--brand-pressed`: `#2563eb`
*   `--brand-light`: `rgba(59, 130, 246, 0.12)`
*   `--brand-glow`: `rgba(59, 130, 246, 0.28)`
*   `--text-brand`: `var(--brand-cyan)`

### Accent Tints (Backgrounds)
*   `--tint-blue`: `rgba(59, 130, 246, 0.16)`
*   `--tint-sky`: `rgba(14, 165, 233, 0.16)`
*   `--tint-green`: `rgba(60, 171, 87, 0.2)`
*   `--tint-orange`: `rgba(224, 123, 42, 0.2)`
*   `--tint-red`: `rgba(184, 65, 65, 0.2)`
*   `--tint-teal`: `rgba(45, 212, 191, 0.16)`

### Navigation Backdrop
*   `--header-bg-rest`: `rgba(8, 10, 15, 0.15)`
*   `--header-bg-scrolled`: `rgba(8, 10, 15, 0.65)`
*   `--header-border-rest`: `rgba(255, 255, 255, 0.05)`
*   `--header-border-scrolled`: `rgba(255, 255, 255, 0.1)`
*   `--header-shadow-scrolled`: `rgba(0, 0, 0, 0.3)`
*   `--header-text`: `#ffffff`
*   `--header-nav-text`: `#ffffff`
*   `--header-hover`: `rgba(255, 255, 255, 0.08)`

---

## 4. Special Components

### Hero Section (Dark Oceanic Concept - Shared across both themes)
*   `--hero-bg-base`: `#04091a` *(Light)* / `#080a0f` *(Dark)*
*   `--hero-text-title`: `#ffffff`
*   `--hero-text-copy`: `rgba(255, 255, 255, 0.78)`
*   `--hero-stamp-text`: `#38bdf8`
*   `--hero-stamp-border`: `rgba(56, 189, 248, 0.35)` *(Light)* / `rgba(56, 189, 248, 0.45)` *(Dark)*
*   `--hero-stamp-bg`: `rgba(56, 189, 248, 0.08)` *(Light)* / `transparent` *(Dark)*
*   `--hero-metric-bg`: `rgba(255, 255, 255, 0.07)`
*   `--hero-metric-border`: `rgba(255, 255, 255, 0.12)`
*   `--hero-metric-label`: `rgba(255, 255, 255, 0.55)`
*   `--hero-btn-sec-bg`: `rgba(255, 255, 255, 0.07)`
*   `--hero-btn-sec-border`: `rgba(255, 255, 255, 0.18)`
*   `--hero-btn-sec-text`: `rgba(255, 255, 255, 0.88)`

### CSS Utilities (Tailwind Mapping)
The following text utilities are mapped closely to the specific semantic text tokens across light and dark mode:
*   `.text-gray-900` / `.text-gray-800` -> `var(--text-primary)`
*   `.text-gray-700` / `.text-gray-600` / `.text-gray-500` -> `var(--text-secondary)`
*   `.text-gray-400` -> `var(--text-faint)`
*   `.text-gray-300` -> `var(--text-muted)`
