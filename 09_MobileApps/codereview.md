# Coral Mobile App Analysis & Improvement Plan (Revised — Execution-Ready)

Based on a deep analysis of the Flutter application (`09_MobileApps/Coral Mobile - Codex`), verified directly against the source. This revision corrects one misdiagnosis in the original draft, confirms the accurate findings with evidence, and adds the items required before execution.

> **Status of claims:** Every finding below was checked against the actual code. Line numbers and file sizes are real. Items marked **[CORRECTED]** or **[NEW]** changed from the first draft.

---

## 0. Pre-Execution Checklist (do these FIRST)

Do not start editing code until these are in place — they are the safety net and the source of truth for whether the work actually helped.

- [ ] **Initialize version control.** This folder is **not a git repo**. Run `git init`, add a `.gitignore` (Flutter default), and commit a baseline. Refactoring ~4,600 lines of UI with no rollback is the single biggest risk here.
- [ ] **Capture a performance baseline on a real low-end device** (not just an emulator) using Flutter DevTools:
  - Timeline/Frame chart → where do frames actually drop? (cold start, scroll, analyze, result)
  - Memory view → peak RAM during/after an offline ensemble run.
  - Record the numbers. Every fix below must be re-measured against this baseline.
- [ ] **Confirm the real bottleneck before refactoring UI.** See Bug B — the original "preprocessing freezes the UI" theory is wrong, so measure before spending days decoupling widgets.
- [ ] **Keep existing tests green.** Baseline-run `flutter test` (`test/prediction_integration_test.dart`, `test/widget_test.dart`) so you can detect regressions.

---

## 1. Deep Analysis of App Bugs & "Laggy" Aspects

### A. Memory & Device Compatibility (the "God Object" AI) — CONFIRMED
**Issue:** `offline_prediction_service.dart` loads **6 separate TFLite models** (5 ensemble seeds 42–46 + 1 base) and creates a matching `IsolateInterpreter` for each. Each `.tflite` is **~8.9 MB** (verified in `assets/models/`), ≈**53 MB on disk**; resident RAM is materially higher once interpreter arenas and **6 persistent background isolates** are allocated.
**Impact:** Severe RAM/battery cost on high-end phones; **OOM crash risk on entry/mid-range devices**, breaking the "ready for all devices" goal.
**Fix:** Load the **base model only by default** and **lazy-load the ensemble on demand** (and dispose after — see Bug F). Note: the models are **float32, not quantized** — there is *no* quantized model in assets, so "use a quantized model" is only an option if you re-export one from the training pipeline. Treat that as out of scope unless you own that pipeline.

> **Trade-off to decide (product, not just perf):** defaulting to base-only changes prediction accuracy and removes the ensemble + temperature-scaling behavior. Decide whether ensemble becomes an opt-in "high accuracy (slower)" toggle.

### B. Image Pre-processing uses nested Dart lists — CONFIRMED INEFFICIENT, **[CORRECTED] cause**
**Issue:** The input tensor is built as `List<List<List<List<double>>>>` at `offline_prediction_service.dart:140-156`.
**[CORRECTED] Impact:** The original draft claimed this "locks up the CPU and freezes the UI for several seconds." **That is inaccurate** — this code already runs inside `Isolate.run()` (`offline_prediction_service.dart:133`), off the main UI thread. The real costs are: (1) millions of boxed `double`s create GC pressure *inside the isolate*, slowing inference start; and (2) the nested structure is **expensive to copy across the isolate boundary** when returned to the main isolate.
**Fix:** Replace the nested lists with a flat `Float32List` buffer. This speeds up preprocessing and cross-isolate transfer — but **do not expect it to fix UI jank**, because the work was never on the UI thread. Profile to find the true source of frame drops.

### C. File I/O & model corruption risk — CONFIRMED (refine the fix)
**Issue:** `_doInit()` copies each `.tflite` from assets to the Documents directory with `writeAsBytes(..., flush: true)` (`offline_prediction_service.dart:69-72, 87-89`). It is kicked off at startup via `unawaited(OfflinePredictionService().preload())` in `main.dart:29`.
**Impact:** Because it's `unawaited`, it does **not** block the first frame — but copying ~53 MB and spawning 6 isolates in the background can still contend for I/O/CPU during early use. More importantly, the copy is **not atomic**: an interrupted write leaves a truncated file that `file.exists()` happily reuses next launch, permanently loading a **corrupt model**.
**Fix:** Write to a temp path then **atomic rename**, and add a **size/checksum check** before trusting an existing file. Keep extraction off the critical path (lazy, or a dedicated init screen).

### D. Monolithic UI ("God Classes") — CONFIRMED
**Issue:** `analyze_page.dart` (**1,500 lines / 51 KB**), `result_page.dart` (**1,369 lines / 47 KB**), `upload_page.dart` (**1,277 lines / 42 KB**) — verified — mix deep widget trees with domain logic and multiple `AnimationController`s. Referenced widgets (`_OceanicBackground`, `_ProcessingOrb`, `_HeroPanel`, `_EvidencePanel`, `UploadDropZone`) all exist.
**Impact:** Small state changes (e.g., a progress tick) reconcile large widget subtrees, dropping frames.
**Fix:** Extract subtrees into smaller stateless widgets; wrap heavy animations in `RepaintBoundary`; isolate `AnimatedBuilder` scopes; move state out of the page files. **Sequence this after the ML fixes and after re-measuring** — it's the highest-effort, highest-risk phase.

### E. Security & Reliability — CONFIRMED (make concrete)
**Security:** No strict image validation; a very large (e.g., 4K) image can bypass resizing and crash. Define a concrete cap (e.g., reject > N MB, downscale longest edge to ≤ 1920 px) and enforce it in `upload_page.dart` before handing bytes onward.
**Reliability:** `online_prediction_service.dart` has one retry (`maxAttempts = 2`) but **no circuit breaker** — repeated timeouts re-queue and can freeze the flow. Add a breaker that fails fast after consecutive failures.

### F. **[NEW]** Interpreters are never disposed (memory leak)
**Issue:** `offline_prediction_service.dart` contains **no `.close()`/dispose** for any of the 6 `Interpreter`s or 6 `IsolateInterpreter`s. Once loaded they live for the whole process.
**Impact:** Native memory is never reclaimed — compounds Bug A and the OOM risk.
**Fix:** Add a disposal lifecycle (`close()` on interpreters + isolate interpreters). Combined with lazy-loading (Bug A), load ensemble on demand and release it after the run.

### G. **[NEW]** Google Fonts fetched over the network at startup
**Issue:** `main.dart:25` sets `GoogleFonts.config.allowRuntimeFetching = true`; fonts aren't bundled, so they're fetched at runtime.
**Impact:** Network dependency + jank/flash on cold start — a real, easy-to-miss source of the "laggy start" feeling, independent of the AI.
**Fix:** Bundle the required font files as assets and disable runtime fetching. Low effort, high perceived-smoothness win.

---

## 2. Proposed Implementation Plan (re-sequenced: low-risk wins first)

> **Why re-sequenced:** the original led with the UI mega-refactor. The ML/startup fixes below are smaller, safer, and likely resolve most of the "terrible/laggy" feel. Do them, re-measure, *then* decide if the UI refactor is still needed.

### Phase 0 — Safety & Measurement
- [ ] git init + baseline commit; `flutter test` green.
- [ ] DevTools timeline + memory baseline on a low-end device. Record numbers.

### Phase 1 — ML Performance & Startup (Priority, low risk)
- **`offline_prediction_service.dart`:**
  - [ ] [MODIFY] Default to **base-only**; **lazy-load ensemble** when requested.
  - [ ] [NEW] Add **dispose/`close()`** for interpreters + isolate interpreters; release ensemble after use (Bug F).
  - [ ] [MODIFY] Replace nested `List<List<List<List<double>>>>` with flat **`Float32List`** (Bug B — for speed/transfer, not UI-freeze).
  - [ ] [MODIFY] **Atomic write** (temp + rename) and **size/checksum** validation for `.tflite` extraction (Bug C).
- **`main.dart`:**
  - [ ] [NEW] **Bundle fonts**, disable `allowRuntimeFetching` (Bug G).
- [ ] **Re-measure against baseline.** Confirm RAM peak and cold-start improved.

### Phase 2 — UI De-coupling & Frame Rate (only if profiling still shows UI jank)
- **`analyze_page.dart`:** extract `_OceanicBackground`, `_ProcessingOrb` into `lib/src/features/assessment/widgets/`; wrap heavy animations in `RepaintBoundary`; isolate `AnimatedBuilder` scopes.
- **`result_page.dart` / `upload_page.dart`:** extract `_HeroPanel`, `_EvidencePanel`, `UploadDropZone`; offload `base64Decode()` to `compute()`/isolates.

### Phase 3 — Reliability & Validation
- **`upload_page.dart`:** enforce concrete image size/dimension cap (Bug E).
- **`online_prediction_service.dart` / `prediction_repository.dart`:** add a timeout **circuit breaker**; ensure resizing happens in isolates.

---

## 3. Definition of Done (acceptance criteria)

Make "buttery smooth" measurable:
- [ ] No OOM crash on a low-end target device (name it, e.g., 2–3 GB RAM) running an offline **ensemble** prediction.
- [ ] Peak RAM during offline run reduced vs. baseline (target a concrete number from Phase 0).
- [ ] Cold-start time reduced; no font flash.
- [ ] Sustained 60 fps on the analyze/result screens (no red frames in DevTools for the common path).
- [ ] `flutter test` green; add at least one regression test around prediction.

---

## 4. System Prompt for Future AI Expansion

Use this to keep the performance standard if the project is handed off:

```markdown
You are an expert Flutter Developer working on "Coral Health AI", an offline/online hybrid ML app.
CRITICAL DIRECTIVES:
1. NEVER use nested Dart lists (`List<List<...>>`) for ML tensors; use flat typed data (`Float32List`/`Uint8List`).
2. NEVER write monolithic UI files. Break any page over ~300 lines into smaller widgets under a `/widgets` folder.
3. ALWAYS use `Isolate.run`/`compute()` for JSON parsing, image decoding (`base64Decode`), and ML pre-processing. Keep the main thread at 60fps.
4. With TFLite on low-memory devices: don't hold multiple large models resident. Lazy-load, and ALWAYS dispose/`close()` interpreters when done.
5. MEASURE before and after (DevTools timeline + memory). Don't "fix" lag you haven't reproduced — preprocessing here already runs in an isolate.
6. Make asset/model file writes atomic (temp + rename) and validate size/checksum before reuse.
```

---

> **Open question for the owner:** Should the ensemble become an **opt-in "high accuracy (slower)"** mode with base-only as the default? This is a product/accuracy decision (Bug A trade-off), not just performance — confirm before Phase 1.
