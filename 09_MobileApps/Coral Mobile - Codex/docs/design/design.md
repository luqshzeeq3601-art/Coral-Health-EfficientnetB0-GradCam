# Coral AI Mobile Application - Stitch Design System Tokens

This document acts as the structural style guide for the Google Stitch AI compilation engine. It adapts the core typography, padding configurations, and semantic color rules from the main project landing page into an optimized Cross-Platform Bento Grid architecture.

## 1. Core Color Variables (Light Theme Baseline)
*   **Application Canvas Background (`--bg-page`):** `#f7f5f1` (Soft warm off-white sand tone)
*   **Primary Bento Card Containers (`--bg-card`):** `#ffffff` (Stark white solid background)
*   **Primary Interactive Action Accent (`--brand-primary`):** `#0057e6` (Deep vibrant cobalt blue)
*   **Hover & Active States (`--brand-hover`):** `#3379eb` (Bright mid-tone blue)
*   **Disabled Neutral States (`--border-subtle`):** `#d1d5db` (Light gray border tint)

## 2. Prediction & Categorization Semantic Tokens
*   **Healthy Coral Classification:** `--tint-teal` (`#f0fdfa`) fill background with `#00685f` crisp dark-teal labels.
*   **Bleached Coral Classification:** `--tint-orange` (`#fef3e8`) fill background with `#d97706` high-contrast amber labels.
*   **Dead Coral Classification:** `--tint-red` (`#fdf0f0`) fill background with `#dc2626` bright crimson-red labels.

## 3. Layout, Density & Shape Mechanics
*   **Bento Framework Radius:** All container cards must use a strict `24px` border-radius layout template (`rounded-3xl` in Tailwind utility mapping).
*   **Interactive Radius:** Action buttons, utility chips, and selection switches must use a full pill-shaped configuration (`rounded-full`).
*   **Grid Padding System:** Maintain a uniform 20px padding margin wrapper around inside card edges to enforce an airy visual density.
*   **Shadow Signatures:** Apply soft, highly diffused ambient drop shadows with low opacity values (`rgba(0, 0, 0, 0.05)`) instead of using rigid borders or dark lines.

## 4. Typography Hierarchy
*   **Display / Metric Headers:** 'Rethink Sans', Bold weight, tight letter-spacing. Max size 24px on mobile screens.
*   **Body Description Labels:** 'Inter', Regular weight, cool gray tint, loose line-height.
*   **Mathematical / Code Readouts:** 'JetBrains Mono', Medium weight, monospace data alignment.