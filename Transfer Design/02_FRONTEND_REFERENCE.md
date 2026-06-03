# Frontend Reference — React SPA (Production Template)

The production frontend is a **compiled React 19 SPA** built with Vite + TypeScript.
It is served by Flask from the `frontend/` directory. No Node.js runtime is needed
in production — only the pre-built bundle.

---

## 1. Technology Stack

| Technology | Version | Purpose |
|---|---|---|
| React | 19.0.0 | UI framework |
| TypeScript | ~5.7.2 | Type safety |
| Vite | ^6.3.5 | Build tool + dev server |
| Tailwind CSS | v4.1.0 | Utility-first CSS (via `@tailwindcss/vite`) |
| GSAP | ^3.15.0 | Scroll-triggered animations |
| Framer Motion | ^12.40.0 | Component transitions |
| Lucide React | ^1.17.0 | Icon set |
| html2canvas | ^1.4.1 | Screenshot export (future) |

---

## 2. Project Structure (React Source)

Source lives at: `Landing Page Ideas/Coral Improve Design Landing Page/Coral AI Landing Page/`

```
src/
├── App.tsx                    # Root component (lazy-loads all sections)
├── main.tsx                   # React DOM mount point
├── index.css                  # Global styles + Tailwind imports + CSS variables
├── vite-env.d.ts              # Vite type declarations
├── components/
│   ├── index.ts               # Barrel exports
│   ├── Header.tsx             # Sticky nav with dark/light toggle
│   ├── Hero.tsx               # Animated hero with video + stats
│   ├── Mission.tsx            # About / mission section
│   ├── TechnologyStack.tsx    # Feature cards (EfficientNet, Ensemble, Grad-CAM)
│   ├── ModelWorkflow.tsx      # Grad-CAM pipeline visualization (animated SVG)
│   ├── Validation.tsx         # Tabbed benchmarks (Basic/Ensemble/Architecture)
│   ├── AttentionExplorer.tsx  # Interactive 3D Grad-CAM simulation
│   ├── TryModel.tsx           # Upload + predict UI (the core user interaction)
│   ├── ChatBot.tsx            # ReefGuide floating assistant
│   ├── Footer.tsx             # Footer with links
│   ├── LogoMarquee.tsx        # Scrolling technology logos
│   ├── NetworkBackground.tsx  # Animated canvas neural network background
│   ├── CoralPipelineSVG.tsx   # Animated CNN pipeline diagram
│   ├── DeepSeaAnimations.tsx  # Ambient underwater particle effects
│   └── ui/                    # Reusable primitives (Button, etc.)
├── lib/
│   ├── api.ts                 # Typed API client (predict, chat, getMetrics)
│   ├── predictionContext.ts   # Global prediction state store
│   └── utils.ts               # Utility functions (cn class merge)
├── hooks/                     # Custom React hooks
└── assets/                    # Static images and media
```

---

## 3. Compiled Build Output (What Flask Serves)

After `npm run build`, the output is in `dist/` and then copied to `04_Web_Application/frontend/`:

```
frontend/
├── index.html                         # SPA entry point (loads theme before render)
├── corallogo.png                      # Logo image
├── efficientnet_logo.png              # EfficientNet brand logo
├── favicon.svg                        # SVG favicon
├── gradcam_logo.png                   # Grad-CAM brand logo
├── lucide_logo.png                    # Lucide icons logo
├── pillow_logo.png                    # Pillow library logo
├── assets/
│   ├── index-rcP0-gzM.js             # Main React bundle (~377KB)
│   ├── index-DdPtA2A6.css            # Main CSS bundle (~79KB)
│   ├── index-BBbBCgnZ.js             # Utility chunk
│   ├── index-Bvu9zNsI.js             # Utility chunk
│   ├── api-59o86u1C.js               # API client chunk
│   ├── predictionContext-uDWn3cAD.js # State management chunk
│   ├── TryModel-Du6gRRtU.js          # Lazy-loaded Try Model section
│   ├── Validation-Cpe76XnA.js        # Lazy-loaded Validation section
│   ├── ChatBot-DEG8R-HH.js           # Lazy-loaded chatbot
│   ├── AttentionExplorer-C5gPjf9K.js # Lazy-loaded 3D simulation
│   ├── Mission-CZYUq0Rd.js           # Lazy-loaded Mission section
│   ├── ModelWorkflow-AdkMAEct.js      # Lazy-loaded workflow section
│   ├── TechnologyStack-qKFZaW7O.js   # Lazy-loaded tech section
│   ├── ScrollTrigger-7Zy99s9Q.js     # GSAP ScrollTrigger chunk
│   ├── corallogo-8RG0Qphu.png        # Hashed logo
│   ├── coral-samples/                 # 6 sample coral images (2 per class)
│   │   ├── 1.png through 6.png
│   └── images/
│       ├── laptop.png                 # Hero section laptop mockup
│       └── laptop-cutout.png          # Transparent laptop cutout
├── static/
│   └── video/
│       ├── Abstract_neural_network_feature_map_*.mp4
│       ├── Laptop_opens_marine_drone_video_*.mp4
│       └── marine-drone-topology-scan.mp4
```

---

## 4. Theme System

Theme is applied **before React renders** to prevent a Flash of Unstyled Content (FOUC):

```html
<!-- In index.html -->
<script>
  (function () {
    var stored = localStorage.getItem("theme");
    var isDark = stored
      ? stored === "dark"
      : window.matchMedia("(prefers-color-scheme: dark)").matches;
    if (isDark) document.documentElement.classList.add("dark");
  })();
</script>
```

The `Header.tsx` component provides a toggle button that:
1. Toggles `document.documentElement.classList` between `dark` and light.
2. Saves the preference to `localStorage.setItem("theme", "dark" | "light")`.

CSS variables in `index.css` define both light and dark palettes.

---

## 5. Page Sections (Render Order)

| # | Component | Section ID | Purpose |
|---|---|---|---|
| 1 | `Header` | — | Sticky navigation + theme toggle |
| 2 | `NetworkBackground` | — | Animated canvas neural net background |
| 3 | `Hero` | `#hero` | Animated headline + video + key stats |
| 4 | `Mission` | `#mission` | About the project / the problem |
| 5 | `LogoMarquee` | — | Scrolling technology logos |
| 6 | `TechnologyStack` | `#technology` | Feature cards (EfficientNet, Ensemble, XAI) |
| 7 | `ModelWorkflow` | `#workflow` | Animated Grad-CAM pipeline SVG |
| 8 | `Validation` | `#validation` | Tabbed benchmarks (3 tabs) |
| 9 | `AttentionExplorer` | `#attention` | Interactive 3D Grad-CAM simulation |
| 10 | `TryModel` | `#try-model` | **Core feature:** upload + predict + results |
| 11 | `Footer` | — | Links and credits |
| 12 | `ChatBot` | — | Floating ReefGuide assistant (fixed position) |

---

## 6. API Integration (`src/lib/api.ts`)

The typed API client provides three main functions:

### `predict(opts)` → `POST /api/predict`

```typescript
export async function predict(opts: {
  file: File;
  modelType: "ensemble" | "base";
  gradcamEnabled: boolean;
}): Promise<PredictResponse>
```

Sends `FormData` with `file`, `model_type`, `gradcam_enabled`. Returns full prediction.

### `chat(opts)` → `POST /api/chat`

```typescript
export async function chat(opts: {
  message: string;
  history: Array<{ role: "user" | "assistant"; content: string }>;
  predictionContext?: ChatPredictionContext | null;
}): Promise<ChatResponse>
```

Sends JSON with message, conversation history, and current prediction context.

### `getMetrics()` → `GET /api/metrics`

```typescript
export async function getMetrics(): Promise<MetricsResponse>
```

Fetches all benchmark data for the Validation section tabs.

### Base64 Helper

```typescript
export function asPngDataUrl(b64: string | null | undefined): string | null {
  if (!b64) return null;
  return `data:image/png;base64,${b64}`;
}
```

> **All images cross the wire as raw base64 PNG strings.** The frontend prefixes them
> with `data:image/png;base64,` before assigning to `<img src>`.

---

## 7. TryModel Component — The Core User Interaction

`TryModel.tsx` (~65KB) implements the complete upload → predict → display flow:

### 7.1 User Flow

1. User selects model type (Ensemble or Base) via radio buttons.
2. User toggles Grad-CAM on/off.
3. User drags/drops or clicks to upload a coral image.
4. Image preview is shown with file name and size.
5. User clicks "Run Assessment".
6. Loading animation plays (scripted multi-step stepper).
7. `predict()` API call fires.
8. Results display:
   - Predicted class with confidence badge.
   - 3 probability bars (Healthy/Bleached/Dead).
   - Grad-CAM heatmap, overlay, and original image (if enabled).
   - Status card with severity, description, recommendation.
   - Uncertainty banner (if confidence < 75%).
9. Prediction context is stored globally for the chatbot.

### 7.2 State Management

- `predictionContext.ts` provides a simple pub/sub store:
  - `setPredictionContext(ctx)` — stores the latest result.
  - `getPredictionContext()` — retrieves it (used by ChatBot).

---

## 8. Validation Component — Tabbed Benchmarks

`Validation.tsx` (~70KB) fetches `/api/metrics` and renders three tabs:

| Tab | Data Key | Content |
|---|---|---|
| Basic Model | `baseline` | Single model metrics, confusion matrix, training curves |
| Ensemble Model | `ensemble` | Ensemble metrics from deployment audit CSV |
| Architecture Comparison | `architecture_comparison` | Scatter chart, summary table |

Each tab shows:
- **4 metric cards:** Accuracy, Precision, Recall, Macro F1 (with animated progress bars).
- **4 stat cards:** Total Errors, Latency, Model Scale, Parameters.
- **Confusion matrix:** Interactive 3×3 grid with correct/misclassification coloring.
- **Classification report table:** Per-class precision/recall/F1/support.

---

## 9. ChatBot Component — ReefGuide

`ChatBot.tsx` (~24KB) is a floating assistant panel:

- **Position:** Fixed bottom-right corner.
- **Toggle:** Circular button with coral logo.
- **Features:**
  - Conversation history persisted in `localStorage` key `coralChatHistory`.
  - Quick-prompt buttons for common questions.
  - Markdown-lite rendering in assistant responses.
  - Source pill shows "Gemini API" or "Local fallback".
  - Prediction context automatically included in chat requests.
  - Disclaimer note: "I'm decision support, not a final field diagnosis."

---

## 10. Build & Deploy Process

### Development

```bash
cd "Landing Page Ideas/Coral Improve Design Landing Page/Coral AI Landing Page"
npm install
npm run dev     # Starts Vite dev server with proxy to Flask :5000
```

The `vite.config.ts` proxy configuration:
```typescript
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:5000',
      changeOrigin: true,
    },
  },
}
```

### Production Build

```bash
npm run build   # Outputs to dist/
```

Then copy `dist/` contents to `04_Web_Application/frontend/`:
```bash
xcopy /E /Y dist\* ..\..\..\04_Web_Application\frontend\
```
