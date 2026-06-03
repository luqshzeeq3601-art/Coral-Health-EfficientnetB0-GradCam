/**
 * Typed client for the CoralAI Flask backend (04_Web_Application/app.py).
 *
 * All image fields come back as raw base64 PNG strings (no data: prefix).
 * Use `asPngDataUrl()` before assigning to an <img src>.
 *
 * In dev, `npm run dev` proxies /api/* to http://localhost:5000 (see vite.config.ts).
 * In production the built SPA is served by Flask itself, so relative /api paths work.
 */

export const CLASS_NAMES = ["Healthy", "Bleached", "Dead"] as const;
export type CoralClass = (typeof CLASS_NAMES)[number];

/** Prefix a raw base64 PNG (as returned by the backend) for use in an <img src>. */
export function asPngDataUrl(b64: string | null | undefined): string | null {
  if (!b64) return null;
  return `data:image/png;base64,${b64}`;
}

/* ── /api/predict ── */

export interface PredictProbabilities {
  Healthy: number;
  Bleached: number;
  Dead: number;
}

export interface GradcamData {
  heatmap?: string; // base64 png
  overlay?: string; // base64 png
  error?: string;
}

export interface PredictResponse {
  prediction: CoralClass;
  confidence: number; // percent (0-100)
  probabilities: PredictProbabilities; // percents (0-100)
  individual_models: Array<{
    fold: number;
    prediction: string;
    confidence: number;
    probabilities: Record<string, number>;
  }>;
  gradcam: GradcamData | null;
  original_image: string; // base64 png
  status: {
    severity?: string;
    icon?: string;
    description?: string;
    recommendation?: string;
  };
  uncertainty: boolean;
  notes: string[];
  model_used: string;
}

export async function predict(opts: {
  file: File;
  modelType: "ensemble" | "base";
  gradcamEnabled: boolean;
}): Promise<PredictResponse> {
  const form = new FormData();
  form.append("file", opts.file);
  form.append("model_type", opts.modelType);
  form.append("gradcam_enabled", String(opts.gradcamEnabled));

  const res = await fetch("/api/predict", { method: "POST", body: form });
  const data = await res.json().catch(() => ({}));
  if (!res.ok || data?.error) {
    throw new Error(data?.error || `Prediction failed (${res.status})`);
  }
  return data as PredictResponse;
}

/* ── /api/chat ── */

export interface ChatPredictionContext {
  prediction?: string;
  confidence?: number;
  probabilities?: Record<string, number> | PredictProbabilities;
  uncertainty?: boolean;
  notes?: string[];
}

export interface ChatResponse {
  reply: string;
  source: "gemini" | "fallback";
}

export async function chat(opts: {
  message: string;
  history: Array<{ role: "user" | "assistant"; content: string }>;
  predictionContext?: ChatPredictionContext | null;
}): Promise<ChatResponse> {
  const res = await fetch("/api/chat", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      message: opts.message,
      history: opts.history,
      predictionContext: opts.predictionContext ?? null,
    }),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok && !data?.reply) {
    throw new Error(data?.error || `Chat failed (${res.status})`);
  }
  return data as ChatResponse;
}

/* ── /api/metrics ── */

export interface ClassificationRow {
  Class: string;
  precision: number | null;
  recall: number | null;
  "f1-score": number | null;
  support: number | null;
}

export interface MetricsModelBlock {
  model_info?: {
    accuracy?: string;
    total_errors?: number;
    total_samples?: number;
    total_models?: number;
    inference_time_ms?: number;
    total_params_display?: string;
  };
  classification_report?: ClassificationRow[];
  confusion_matrix_data?: number[][];
}

export interface MetricsResponse {
  baseline?: MetricsModelBlock;
  ensemble?: MetricsModelBlock;
  architecture_comparison?: {
    summary?: Record<string, unknown>;
    [k: string]: unknown;
  };
  research?: unknown;
  deployment?: unknown;
}

export async function getMetrics(): Promise<MetricsResponse> {
  const res = await fetch("/api/metrics");
  const data = await res.json().catch(() => ({}));
  if (!res.ok || data?.error) {
    throw new Error(data?.error || `Metrics failed (${res.status})`);
  }
  return data as MetricsResponse;
}
