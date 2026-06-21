import { useState, useRef, useCallback, useEffect, useId } from "react";
import { AnimatedTypewriter, AnimatedSharedSwap } from "./ui";
import { ScanningGrid, NeuralNode, OrganicMesh, CyclingStatusText, WireframePulse, ProcessingScanner } from "./DeepSeaAnimations";
import { predict, asPngDataUrl, type PredictResponse } from "../lib/api";
import { setPredictionContext } from "../lib/predictionContext";
import ChatBot from "./ChatBot";
import html2canvas from "html2canvas";

/* ── Per-class display palette (matches the three fixed CoralAI classes) ── */
const CLASS_STYLE: Record<string, { color: string; bg: string }> = {
  Healthy: { color: "#3cab57", bg: "rgba(60, 171, 87, 0.1)" },
  Bleached: { color: "#e07b2a", bg: "rgba(224, 123, 42, 0.1)" },
  Dead: { color: "#b84141", bg: "rgba(184, 65, 65, 0.1)" },
};
const CLASS_ORDER = ["Healthy", "Bleached", "Dead"] as const;

export interface InferenceResult {
  prediction: string;
  predictionColor: string;
  predictionBg: string;
  /** classes sorted highest-score-first; score is a 0..1 fraction */
  classes: Array<{ label: string; score: number; color: string; bg: string }>;
  /** base64 PNG data-URLs from the backend (null when Grad-CAM disabled/failed) */
  originalUrl: string | null;
  overlayUrl: string | null;
  heatmapUrl: string | null;
  modelUsed: string;
  uncertainty: boolean;
  notes: string[];
}

/** Map the Flask /api/predict response into the component's display shape. */
function mapPredictResponse(data: PredictResponse): InferenceResult {
  const classes = CLASS_ORDER.map((label) => {
    const pct = (data.probabilities?.[label] ?? 0) as number;
    const style = CLASS_STYLE[label] ?? { color: "#64748b", bg: "rgba(100,116,139,0.1)" };
    return { label, score: pct / 100, color: style.color, bg: style.bg };
  }).sort((a, b) => b.score - a.score);

  const predStyle = CLASS_STYLE[data.prediction] ?? { color: "#64748b", bg: "rgba(100,116,139,0.1)" };
  const gc = data.gradcam && !data.gradcam.error ? data.gradcam : null;

  return {
    prediction: data.prediction,
    predictionColor: predStyle.color,
    predictionBg: predStyle.bg,
    classes,
    originalUrl: asPngDataUrl(data.original_image),
    overlayUrl: asPngDataUrl(gc?.overlay),
    heatmapUrl: asPngDataUrl(gc?.heatmap),
    modelUsed: data.model_used,
    uncertainty: data.uncertainty,
    notes: data.notes ?? [],
  };
}

type Status = "idle" | "inferring" | "done";

interface ModelOption {
  value: "ensemble" | "base";
  label: string;
  desc: string;
  icon: React.ReactNode;
}

/* ── Confidence bar ── */
function ConfidenceBar({
  label,
  score,
  color,
  animate,
}: {
  label: string;
  score: number;
  color: string;
  bg: string;
  animate: boolean;
}) {
  const [width, setWidth] = useState(0);

  useEffect(() => {
    if (!animate) {
      setWidth(0);
      return;
    }
    const t = setTimeout(() => setWidth(score * 100), 80);
    return () => clearTimeout(t);
  }, [animate, score]);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
          <span
            style={{
              width: "8px",
              height: "8px",
              borderRadius: "50%",
              background: color,
              flexShrink: 0,
            }}
            aria-hidden="true"
          />
          <span
            style={{
              fontFamily: "var(--font-body)",
              fontSize: "13px",
              fontWeight: 500,
              color: "var(--text-primary)",
            }}
          >
            {label}
          </span>
        </div>
        <span
          style={{
            fontFamily: "var(--font-mono)",
            fontSize: "13px",
            fontWeight: 800,
            color: color,
            textShadow: `0 0 12px ${color}80`,
          }}
        >
          {(score * 100).toFixed(1)}%
        </span>
      </div>
      <div style={{ height: "6px", background: "var(--border-faint)", borderRadius: "999px", overflow: "hidden" }}>
        <div
          style={{
            height: "100%",
            width: `${width}%`,
            background: color,
            borderRadius: "999px",
            transition: "width 600ms cubic-bezier(0.22, 1, 0.36, 1)",
          }}
          role="progressbar"
          aria-valuenow={Math.round(score * 100)}
          aria-valuemin={0}
          aria-valuemax={100}
        />
      </div>
    </div>
  );
}

/* ── Toggle switch ── */
function ToggleSwitch({
  checked,
  onChange,
  id,
}: {
  checked: boolean;
  onChange: (v: boolean) => void;
  id: string;
}) {
  return (
    <button
      type="button"
      role="switch"
      id={id}
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      style={{
        position: "relative",
        display: "inline-flex",
        alignItems: "center",
        width: "44px",
        height: "24px",
        borderRadius: "999px",
        border: "none",
        cursor: "pointer",
        background: checked ? "var(--brand-primary)" : "var(--border-subtle)",
        transition: "background 200ms ease",
        flexShrink: 0,
        padding: 0,
      }}
    >
      <span
        style={{
          position: "absolute",
          width: "18px",
          height: "18px",
          borderRadius: "50%",
          background: "#ffffff",
          boxShadow: "0 1px 3px rgba(0,0,0,0.15)",
          left: checked ? "23px" : "3px",
          transition: "left 200ms ease",
        }}
        aria-hidden="true"
      />
    </button>
  );
}

export default function TryModel({ sectionId = "try-model" }: { sectionId?: string }) {
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [modelMode, setModelMode] = useState<"ensemble" | "base">("ensemble");
  const [gradcam, setGradcam] = useState(true);
  const [status, setStatus] = useState<Status>("idle");
  const [result, setResult] = useState<InferenceResult | null>(null);
  const [dragActive, setDragActive] = useState(false);
  const [fileError, setFileError] = useState<string | null>(null);
  const [showBars, setShowBars] = useState(false);
  const [dropdownOpen, setDropdownOpen] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const outputRef = useRef<HTMLDivElement>(null);
  // Guards against stale inference results resurrecting after a reset.
  const inferenceToken = useRef(0);
  const toggleId = useId();

  // Close dropdown on click outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setDropdownOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  /* Animate bars after results appear */
  useEffect(() => {
    if (status !== "done") {
      setShowBars(false);
      return;
    }
    const t = setTimeout(() => setShowBars(true), 150);
    return () => clearTimeout(t);
  }, [status]);

  const processFile = useCallback((f: File) => {
    setFileError(null);
    if (!["image/jpeg", "image/png", "image/jpg"].includes(f.type)) {
      setFileError("Only JPG and PNG files are accepted.");
      return;
    }
    if (f.size > 10 * 1024 * 1024) {
      setFileError("File exceeds 10 MB limit.");
      return;
    }
    inferenceToken.current++;
    setFile(f);
    setStatus("idle");
    setShowBars(false);
    setResult(null);
    setPredictionContext(null);
    setPreview((prev) => {
      if (prev) URL.revokeObjectURL(prev);
      return URL.createObjectURL(f);
    });
  }, []);

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      setDragActive(false);
      const dropped = e.dataTransfer.files[0];
      if (dropped) processFile(dropped);
    },
    [processFile]
  );

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    const picked = e.target.files?.[0];
    if (picked) processFile(picked);
    e.target.value = "";
  };

  const handleInfer = async () => {
    if (!file || isInferring) return;
    setStatus("inferring");
    setShowBars(false);
    setFileError(null);

    const token = ++inferenceToken.current;

    try {
      const data = await predict({ file, modelType: modelMode, gradcamEnabled: gradcam });
      if (token !== inferenceToken.current) return;

      const mapped = mapPredictResponse(data);
      setResult(mapped);
      setStatus("done");

      // Publish context for the floating ChatBot (mirrors design9's latestPredictionContext)
      setPredictionContext({
        prediction: data.prediction,
        confidence: data.confidence,
        probabilities: data.probabilities,
        uncertainty: data.uncertainty,
        notes: data.notes,
      });
    } catch (err) {
      if (token !== inferenceToken.current) return;
      setStatus("idle");
      setFileError(err instanceof Error ? err.message : "Inference failed. Please try again.");
    }
  };

  const handleReset = () => {
    inferenceToken.current++;
    setFile(null);
    setPreview((prev) => {
      if (prev) URL.revokeObjectURL(prev);
      return null;
    });
    setStatus("idle");
    setResult(null);
    setShowBars(false);
    setFileError(null);
    setPredictionContext(null);
  };

  const handleExport = async () => {
    if (!result || !outputRef.current) return;

    try {
      const canvas = await html2canvas(outputRef.current, {
        backgroundColor: null,
        scale: 2,
        useCORS: true,
      });
      const url = canvas.toDataURL("image/png");
      const a = document.createElement("a");
      a.href = url;
      a.download = `coral-inference-results-${Date.now()}.png`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
    } catch (err) {
      console.error("Failed to export image", err);
    }
  };

  const isDone = status === "done";
  const isInferring = status === "inferring";

  // Dropdown options matching Image 2
  const modelOptions: ModelOption[] = [
    {
      value: "ensemble",
      label: "Ensemble Model",
      desc: "Highest accuracy",
      icon: (
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
          <circle cx="8" cy="4" r="2.5" stroke="currentColor" strokeWidth="1.2" />
          <circle cx="4" cy="11" r="2.5" stroke="currentColor" strokeWidth="1.2" />
          <circle cx="12" cy="11" r="2.5" stroke="currentColor" strokeWidth="1.2" />
          <path d="M8 6.5V8.5M8 8.5L5.5 10M8 8.5L10.5 10" stroke="currentColor" strokeWidth="1.2" />
        </svg>
      ),
    },
    {
      value: "base",
      label: "Base Model",
      desc: "Faster inference",
      icon: (
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
          <path d="M8 2L13 5V11L8 14L3 11V5L8 2Z" stroke="currentColor" strokeWidth="1.2" strokeLinejoin="round" />
          <path d="M3 5L8 8M8 8L13 5M8 8V14" stroke="currentColor" strokeWidth="1.2" />
        </svg>
      ),
    },
  ];

  const selectedModel = modelOptions.find((o) => o.value === modelMode) || modelOptions[0];

  return (
    <section
      id="try-model"
      aria-labelledby="try-model-heading"
      style={{
        background: "var(--bg-page)",
        paddingTop: "var(--section-space-lg)",
        paddingBottom: "var(--section-space-lg)",
        borderTop: "1px solid var(--border-base)",
        transition: "background-color 250ms ease",
      }}
    >
      <style>{`
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes scan {
          0% { top: 0%; opacity: 0.8; }
          50% { top: 100%; opacity: 0.8; }
          100% { top: 0%; opacity: 0.8; }
        }
        @keyframes dropdownScaleIn {
          from {
            opacity: 0;
            transform: translateY(-8px) scale(0.96);
          }
          to {
            opacity: 1;
            transform: translateY(0) scale(1);
          }
        }
        @keyframes buttonShimmer {
          0% { background-position: -200% 0; }
          100% { background-position: 200% 0; }
        }
        @keyframes pulseGlow {
          0%, 100% { box-shadow: 0 0 0 0 transparent; }
          50% { box-shadow: 0 0 15px 4px var(--brand-glow); }
        }
        .active-pulse-glow {
          animation: pulseGlow 2.5s infinite ease-in-out;
        }
        .shimmer-bg {
          background: linear-gradient(90deg, var(--brand-primary) 0%, var(--brand-hover) 50%, var(--brand-primary) 100%);
          background-size: 200% auto;
          animation: buttonShimmer 6s infinite linear;
        }
        .laser-line {
          position: absolute;
          left: 0;
          right: 0;
          height: 3px;
          background: linear-gradient(90deg, transparent, var(--text-primary), transparent);
          box-shadow: 0 0 12px var(--brand-glow), 0 0 6px var(--brand-glow);
          animation: scan 2.5s linear infinite;
          z-index: 10;
        }
        .dropdown-animate {
          animation: dropdownScaleIn 180ms cubic-bezier(0.16, 1, 0.3, 1) forwards;
          transform-origin: top center;
        }
        @keyframes skeletonShimmer {
          0% { background-position: -200% 0; }
          100% { background-position: 200% 0; }
        }
        .skeleton-shimmer {
          background: linear-gradient(90deg, var(--bg-alt) 25%, var(--border-faint) 50%, var(--bg-alt) 75%);
          background-size: 200% 100%;
          animation: skeletonShimmer 1.5s infinite ease-in-out;
        }
        .workspace-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: 28px;
          align-items: stretch;
        }
        @media (min-width: 768px) {
          .workspace-grid {
            grid-template-columns: repeat(12, minmax(0, 1fr));
          }
          .workspace-col-input {
            grid-column: span 5 / span 5;
          }
          .workspace-col-output {
            grid-column: span 7 / span 7;
          }
          .workspace-col-assistant {
            grid-column: span 12 / span 12;
          }
        }
        @media (min-width: 1280px) {
          .workspace-grid {
            /* minmax(0, …) floors stop the assistant/output tracks from being
               blown out by their content's intrinsic min-width. Without them a
               non-wrapping child (e.g. the ChatBot chip row) forces its track
               wider and collapses the Output card, which then stacks its
               contents much taller — the "cards grow downward" bug. */
            grid-template-columns:
              minmax(300px, 3.6fr)
              minmax(0, 8fr)
              minmax(340px, 4.2fr);
          }
          .workspace-col-input {
            grid-column: auto;
          }
          .workspace-col-output {
            grid-column: auto;
          }
          .workspace-col-assistant {
            grid-column: auto;
          }
        }
      `}</style>

      <div className="mx-auto" style={{ maxWidth: "1680px", paddingLeft: "clamp(24px, 6vw, 48px)", paddingRight: "clamp(24px, 6vw, 48px)" }}>
        {/* Section Intro */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "40px", flexWrap: "wrap", gap: "20px" }}>
          <div style={{ display: "flex", flexDirection: "column", gap: "12px", maxWidth: "680px" }}>
            <h2 id="try-model-heading" style={{ fontFamily: "var(--font-display)", fontSize: "var(--text-section)", fontWeight: 700, lineHeight: "var(--leading-section)", letterSpacing: "var(--tracking-section)", color: "var(--text-primary)", margin: 0 }}>
              Analyze Coral Health
            </h2>
            <p style={{ fontFamily: "var(--font-body)", fontSize: "var(--text-body)", lineHeight: "var(--leading-body)", color: "var(--text-secondary)", margin: 0, maxWidth: "var(--measure-prose)" }}>
              Upload a static coral reef photo to classify it as Healthy, Bleached, or Dead. Run the assessment to generate Grad-CAM interpretability heatmaps highlighting key diagnostic regions.
            </p>
          </div>
        </div>

        {/* Workspace Grid (3 Unified Columns) */}
        <div className="workspace-grid">

          {/* ── CARD 1: INPUT HUB (5 Units Width) ── */}
          <div
            className="workspace-col-input"
            style={{
              background: "var(--bg-card)",
              border: "1px solid var(--border-subtle)",
              borderRadius: "16px",
              padding: "24px",
              display: "flex",
              flexDirection: "column",
              gap: "22px",
              boxShadow: "0 8px 32px rgba(13, 23, 56, 0.05)",
              height: "100%",
            }}
          >
            {/* Input Hub Header */}
            <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
              <div style={{ width: "36px", height: "36px", borderRadius: "50%", background: "color-mix(in srgb, var(--brand-primary) 10%, transparent)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--brand-primary)" strokeWidth="1.8">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </div>
              <div>
                <h3 style={{ fontFamily: "var(--font-body)", fontSize: "16px", fontWeight: 700, color: "var(--text-primary)", margin: 0, textTransform: "capitalize" }}>
                  Input
                </h3>
                <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "var(--brand-primary)", fontWeight: 500, margin: 0 }}>
                  Upload image and configure model settings.
                </p>
              </div>
            </div>

            {/* Upload Zone */}
            <div
              role="button"
              tabIndex={0}
              onClick={() => fileInputRef.current?.click()}
              onKeyDown={(e) => {
                if (e.key === "Enter" || e.key === " ") fileInputRef.current?.click();
              }}
              onDragOver={(e) => {
                e.preventDefault();
                setDragActive(true);
              }}
              onDragLeave={() => setDragActive(false)}
              onDrop={handleDrop}
              style={{
                background: dragActive ? "color-mix(in srgb, var(--brand-primary) 10%, transparent)" : "var(--bg-alt)",
                border: `2px dashed ${dragActive ? "var(--brand-primary)" : "color-mix(in srgb, var(--brand-primary) 20%, transparent)"}`,
                borderRadius: "14px",
                padding: "32px 20px",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                gap: "16px",
                cursor: "pointer",
                transition: "all 200ms ease",
                textAlign: "center",
                boxShadow: dragActive ? "0 0 20px color-mix(in srgb, var(--brand-primary) 20%, transparent)" : "none",
              }}
              onMouseEnter={(e) => {
                if (!dragActive) {
                  e.currentTarget.style.borderColor = "var(--brand-primary)";
                  e.currentTarget.style.background = "color-mix(in srgb, var(--brand-primary) 5%, transparent)";
                  e.currentTarget.style.boxShadow = "0 0 15px color-mix(in srgb, var(--brand-primary) 10%, transparent)";
                }
              }}
              onMouseLeave={(e) => {
                if (!dragActive) {
                  e.currentTarget.style.borderColor = "color-mix(in srgb, var(--brand-primary) 20%, transparent)";
                  e.currentTarget.style.background = "var(--bg-alt)";
                  e.currentTarget.style.boxShadow = "none";
                }
              }}
            >
              <input
                ref={fileInputRef}
                type="file"
                accept=".jpg,.jpeg,.png"
                onChange={handleFileInput}
                style={{ display: "none" }}
              />

              {file && preview ? (
                <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "12px", width: "100%" }}>
                  <div style={{ position: "relative", width: "100%", overflow: "hidden", borderRadius: "10px", display: "flex", justifyContent: "center" }}>
                    <img
                      src={preview}
                      alt="Reef Preview"
                      style={{ width: "100%", maxHeight: "140px", objectFit: "cover", borderRadius: "10px", display: "block" }}
                    />
                    {!isInferring && (
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          handleReset();
                        }}
                        style={{
                          position: "absolute",
                          top: "8px",
                          right: "8px",
                          width: "28px",
                          height: "28px",
                          borderRadius: "50%",
                          background: "var(--bg-card)",
                          border: "1px solid var(--border-subtle)",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          cursor: "pointer",
                          color: "var(--text-secondary)",
                          boxShadow: "0 2px 5px rgba(0,0,0,0.2)",
                          transition: "all 150ms ease",
                          zIndex: 20
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.color = "#ef4444";
                          e.currentTarget.style.borderColor = "#ef4444";
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.color = "var(--text-secondary)";
                          e.currentTarget.style.borderColor = "var(--border-subtle)";
                        }}
                        title="Remove image"
                      >
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                          <line x1="18" y1="6" x2="6" y2="18"></line>
                          <line x1="6" y1="6" x2="18" y2="18"></line>
                        </svg>
                      </button>
                    )}
                    {isInferring && <ScanningGrid />}
                  </div>
                  <div style={{ display: "flex", flexDirection: "column", gap: "2px" }}>
                    <span style={{ fontFamily: "var(--font-body)", fontSize: "13px", fontWeight: 600, color: "var(--text-primary)" }}>
                      {file.name}
                    </span>
                    <span style={{ fontFamily: "var(--font-mono)", fontSize: "11px", color: "var(--text-faint)" }}>
                      {(file.size / 1024).toFixed(0)} KB · Click to replace
                    </span>
                  </div>
                </div>
              ) : (
                <>
                  <div style={{ width: "44px", height: "44px", borderRadius: "12px", background: "color-mix(in srgb, var(--brand-primary) 10%, transparent)", border: "1px solid color-mix(in srgb, var(--brand-primary) 30%, transparent)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--brand-primary)" strokeWidth="1.9">
                      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" strokeLinecap="round" />
                      <polyline points="17 8 12 3 7 8" strokeLinecap="round" strokeLinejoin="round" />
                      <line x1="12" y1="3" x2="12" y2="15" strokeLinecap="round" />
                    </svg>
                  </div>
                  <div>
                    <p style={{ fontFamily: "var(--font-body)", fontSize: "14px", fontWeight: 600, color: "var(--text-primary)", margin: "0 0 4px 0" }}>
                      Drag &amp; drop coral reef image here
                    </p>
                    <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "var(--text-secondary)", margin: 0 }}>
                      JPG or PNG · Max 10 MB
                    </p>
                  </div>
                  <button
                    type="button"
                    style={{
                      fontFamily: "var(--font-body)",
                      fontSize: "13px",
                      fontWeight: 600,
                      color: "var(--text-brand)",
                      background: "var(--bg-card)",
                      border: "1px solid var(--brand-glow)",
                      borderRadius: "8px",
                      padding: "6px 16px",
                      cursor: "pointer",
                      display: "flex",
                      alignItems: "center",
                      gap: "6px",
                      transition: "all 150ms ease",
                    }}
                    onMouseEnter={(e) => {
                      e.stopPropagation();
                      e.currentTarget.style.background = "color-mix(in srgb, var(--brand-primary) 10%, transparent)";
                      e.currentTarget.style.borderColor = "var(--brand-primary)";
                    }}
                    onMouseLeave={(e) => {
                      e.stopPropagation();
                      e.currentTarget.style.background = "var(--bg-card)";
                      e.currentTarget.style.borderColor = "color-mix(in srgb, var(--brand-primary) 30%, transparent)";
                    }}
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z" />
                    </svg>
                    Browse Files
                  </button>
                </>
              )}
            </div>

            {/* Error Message */}
            {fileError && (
              <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "#dc2626", background: "#fef2f2", border: "1px solid #fecaca", borderRadius: "8px", padding: "10px 12px", margin: 0 }}>
                {fileError}
              </p>
            )}

            {/* Model Mode Dropdown (Image 2 style) */}
            <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
              <label style={{ fontFamily: "var(--font-body)", fontSize: "13px", fontWeight: 600, color: "var(--text-secondary)" }}>
                Model Mode
              </label>
              <div ref={dropdownRef} style={{ position: "relative" }}>
                <button
                  type="button"
                  onClick={() => setDropdownOpen(!dropdownOpen)}
                  style={{
                    width: "100%",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    background: "var(--bg-alt)",
                    border: dropdownOpen ? "1px solid var(--brand-primary)" : "1px solid color-mix(in srgb, var(--brand-primary) 20%, transparent)",
                    borderRadius: "10px",
                    padding: "12px 14px",
                    cursor: "pointer",
                    transition: "all 150ms ease",
                    boxShadow: dropdownOpen ? "0 0 15px color-mix(in srgb, var(--brand-primary) 15%, transparent)" : "none",
                  }}
                  onMouseEnter={(e) => {
                    if (!dropdownOpen) {
                      e.currentTarget.style.borderColor = "var(--brand-primary)";
                      e.currentTarget.style.background = "color-mix(in srgb, var(--brand-primary) 5%, transparent)";
                    }
                  }}
                  onMouseLeave={(e) => {
                    if (!dropdownOpen) {
                      e.currentTarget.style.borderColor = "color-mix(in srgb, var(--brand-primary) 20%, transparent)";
                      e.currentTarget.style.background = "var(--bg-alt)";
                    }
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                    <div style={{ color: selectedModel.value === "ensemble" ? "var(--brand-primary)" : "var(--text-faint)", display: "flex", alignItems: "center" }}>
                      {selectedModel.icon}
                    </div>
                    <span style={{ fontFamily: "var(--font-body)", fontSize: "14px", fontWeight: 600, color: "var(--text-primary)" }}>
                      {selectedModel.label}
                    </span>
                  </div>
                  <svg
                    width="14"
                    height="14"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="var(--text-secondary)"
                    strokeWidth="2"
                    style={{ transform: dropdownOpen ? "rotate(180deg)" : "rotate(0deg)", transition: "transform 150ms ease" }}
                  >
                    <polyline points="6 9 12 15 18 9" />
                  </svg>
                </button>

                {dropdownOpen && (
                  <div
                    className="dropdown-animate"
                    style={{
                      position: "absolute",
                      top: "calc(100% + 6px)",
                      left: 0,
                      right: 0,
                      background: "var(--bg-card)",
                      border: "1px solid var(--border-subtle)",
                      borderRadius: "10px",
                      boxShadow: "0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)",
                      zIndex: 50,
                      overflow: "hidden",
                    }}
                  >
                    {modelOptions.map((option) => {
                      const isSelected = option.value === modelMode;
                      return (
                        <button
                          key={option.value}
                          type="button"
                          onClick={() => {
                            setModelMode(option.value);
                            setDropdownOpen(false);
                          }}
                          style={{
                            width: "100%",
                            display: "flex",
                            alignItems: "flex-start",
                            justifyContent: "space-between",
                            gap: "10px",
                            padding: "12px 14px",
                            background: isSelected ? "color-mix(in srgb, var(--brand-primary) 10%, transparent)" : "var(--bg-alt)",
                            border: "none",
                            borderBottom: "1px solid var(--border-faint)",
                            cursor: "pointer",
                            textAlign: "left",
                            transition: "background 150ms ease",
                          }}
                          onMouseEnter={(e) => {
                            if (!isSelected) e.currentTarget.style.background = "color-mix(in srgb, var(--brand-primary) 5%, transparent)";
                          }}
                          onMouseLeave={(e) => {
                            if (!isSelected) e.currentTarget.style.background = "var(--bg-alt)";
                          }}
                        >
                          <div style={{ display: "flex", gap: "10px" }}>
                            <div style={{ marginTop: "2px", color: isSelected ? "var(--brand-primary)" : "var(--text-faint)" }}>
                              {option.icon}
                            </div>
                            <div>
                              <div style={{ fontFamily: "var(--font-body)", fontSize: "13px", fontWeight: 600, color: isSelected ? "var(--brand-primary)" : "var(--text-primary)" }}>
                                {option.label}
                              </div>
                              <div style={{ fontFamily: "var(--font-body)", fontSize: "11px", color: "var(--text-secondary)", marginTop: "2px" }}>
                                {option.desc}
                              </div>
                            </div>
                          </div>
                          {isSelected && (
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--brand-primary)" strokeWidth="3" style={{ marginTop: "4px" }}>
                              <polyline points="20 6 9 17 4 12" />
                            </svg>
                          )}
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>

            {/* Grad-CAM Toggle (Image 1/2 style) */}
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: "12px", borderTop: "1px solid var(--border-faint)", paddingTop: "20px" }}>
              <div>
                <label htmlFor={toggleId} style={{ fontFamily: "var(--font-body)", fontSize: "14px", fontWeight: 600, color: "var(--text-primary)", display: "block", marginBottom: "2px", cursor: "pointer" }}>
                  Grad-CAM
                </label>
                <span style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "var(--text-secondary)" }}>
                  Visualize important regions that influenced the prediction.
                </span>
              </div>
              <ToggleSwitch id={toggleId} checked={gradcam} onChange={setGradcam} />
            </div>

            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1.2fr 0.9fr 0.9fr",
                gap: "1px",
                overflow: "hidden",
                border: "1px solid var(--border-faint)",
                borderRadius: "12px",
                background: "var(--border-faint)",
              }}
            >
              {[
                { label: "Formats", value: "JPG, PNG" },
                { label: "Max Size", value: "10 MB" },
                { label: "Status", value: file ? "Image ready" : "Ready" },
              ].map(({ label, value }) => (
                <div key={label} style={{ background: "var(--bg-alt)", padding: "12px 10px" }}>
                  <div style={{ fontFamily: "var(--font-body)", fontSize: "11px", fontWeight: 600, color: "var(--text-faint)", marginBottom: "4px", textTransform: "capitalize" }}>
                    {label}
                  </div>
                  <div style={{ fontFamily: "var(--font-body)", fontSize: "12px", fontWeight: 600, color: label === "Status" ? "var(--brand-primary)" : "var(--text-primary)", lineHeight: 1.2 }}>
                    {value}
                  </div>
                </div>
              ))}
            </div>

            {/* Run Button Group */}
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "flex-end",
                gap: "14px",
                paddingTop: "24px",
                marginTop: "16px",
                borderTop: "1px solid var(--border-faint)",
                flexWrap: "nowrap"
              }}
            >
              {(file || isDone) && (
                <button
                  type="button"
                  onClick={handleReset}
                  style={{
                    height: "44px",
                    padding: "0 20px",
                    fontFamily: "var(--font-body)",
                    fontSize: "13px",
                    fontWeight: 600,
                    color: "var(--text-secondary)",
                    background: "var(--bg-card)",
                    border: "1px solid var(--border-base)",
                    borderRadius: "12px",
                    cursor: "pointer",
                    transition: "all 200ms cubic-bezier(0.16, 1, 0.3, 1)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    gap: "8px",
                    boxShadow: "0 2px 4px rgba(0,0,0,0.02)"
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.background = "var(--bg-alt)";
                    e.currentTarget.style.borderColor = "var(--text-primary)";
                    e.currentTarget.style.color = "var(--text-primary)";
                    e.currentTarget.style.transform = "translateY(-1px)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.background = "var(--bg-card)";
                    e.currentTarget.style.borderColor = "var(--border-base)";
                    e.currentTarget.style.color = "var(--text-secondary)";
                    e.currentTarget.style.transform = "none";
                  }}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"/>
                  </svg>
                  Reset
                </button>
              )}
              <button
                type="button"
                onClick={handleInfer}
                disabled={!file || isInferring}
                className={file && status === "idle" ? "shimmer-bg active-pulse-glow" : ""}
                style={{
                  minWidth: "160px",
                  height: "44px",
                  padding: "0 24px",
                  fontFamily: "var(--font-body)",
                  fontSize: "14px",
                  fontWeight: 600,
                  color: !file || isInferring ? "var(--text-faint)" : "#ffffff",
                  background: !file || isInferring ? "var(--bg-chip)" : "var(--brand-primary)",
                  border: "none",
                  borderRadius: "12px",
                  cursor: !file || isInferring ? "not-allowed" : "pointer",
                  transition: "all 250ms cubic-bezier(0.16, 1, 0.3, 1)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "10px",
                  boxShadow: file && !isInferring ? "0 6px 16px -2px var(--brand-glow)" : "none",
                }}
                onMouseEnter={(e) => {
                  if (file && !isInferring) {
                    e.currentTarget.style.transform = "translateY(-2px)";
                    e.currentTarget.style.boxShadow = "0 8px 20px -2px var(--brand-glow)";
                    e.currentTarget.style.filter = "brightness(1.08)";
                  }
                }}
                onMouseLeave={(e) => {
                  if (file && !isInferring) {
                    e.currentTarget.style.transform = "none";
                    e.currentTarget.style.boxShadow = "0 6px 16px -2px var(--brand-glow)";
                    e.currentTarget.style.filter = "none";
                  }
                }}
              >
                {isInferring ? (
                  <>
                    <div style={{ width: "16px", height: "16px", borderRadius: "50%", border: "2px solid rgba(255,255,255,0.2)", borderTop: "2px solid #ffffff", animation: "spin 0.8s linear infinite" }} />
                    <span style={{ transform: "translateY(0.5px)" }}>Analyzing...</span>
                  </>
                ) : (
                  <>
                    <svg width="14" height="14" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="3" fill="currentColor" style={{ transform: "translateX(1px)" }}>
                      <polygon points="5 3 19 12 5 21 5 3" />
                    </svg>
                    <span style={{ transform: "translateY(0.5px)" }}>Start Run</span>
                  </>
                )}
              </button>
            </div>
          </div>

          {/* ── CARD 2: OUTPUT STAGE (7 Columns) ── */}
          <div
            ref={outputRef}
            className="workspace-col-output"
            style={{
              background: "var(--bg-card)",
              border: "1px solid var(--border-subtle)",
              borderRadius: "16px",
              padding: "24px",
              display: "flex",
              flexDirection: "column",
              gap: "22px",
              height: "100%",
              boxShadow: "0 8px 32px rgba(13, 23, 56, 0.05)",
            }}
          >
            {/* Header with Export (Image 2 style) */}
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                <div style={{ width: "36px", height: "36px", borderRadius: "50%", background: "color-mix(in srgb, var(--brand-primary) 10%, transparent)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--brand-primary)" strokeWidth="1.8">
                    <line x1="18" y1="20" x2="18" y2="10" strokeLinecap="round" />
                    <line x1="12" y1="20" x2="12" y2="4" strokeLinecap="round" />
                    <line x1="6" y1="20" x2="6" y2="14" strokeLinecap="round" />
                  </svg>
                </div>
                <div>
                  <h3 style={{ fontFamily: "var(--font-body)", fontSize: "16px", fontWeight: 700, color: "var(--text-primary)", margin: 0, textTransform: "capitalize" }}>
                    Output
                  </h3>
                  <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "var(--brand-primary)", fontWeight: 500, margin: 0 }}>
                    Classification results and model interpretability.
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={handleExport}
                style={{
                  width: "36px",
                  height: "36px",
                  borderRadius: "8px",
                  border: "1px solid var(--border-subtle)",
                  background: "var(--bg-card)",
                  color: "var(--text-secondary)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  cursor: isDone ? "pointer" : "not-allowed",
                  opacity: isDone ? 1 : 0.5,
                  transition: "all 150ms ease",
                }}
                onMouseEnter={(e) => {
                  if (isDone) {
                    e.currentTarget.style.background = "color-mix(in srgb, var(--brand-primary) 10%, transparent)";
                    e.currentTarget.style.borderColor = "var(--brand-primary)";
                    e.currentTarget.style.color = "var(--brand-primary)";
                  }
                }}
                onMouseLeave={(e) => {
                  if (isDone) {
                    e.currentTarget.style.background = "var(--bg-card)";
                    e.currentTarget.style.borderColor = "var(--border-subtle)";
                    e.currentTarget.style.color = "var(--text-secondary)";
                  }
                }}
                disabled={!isDone}
                title="Export Results"
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8M16 6l-4-4-4 4M12 2v13" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </button>
            </div>

            {/* Result Blocks Stack */}
            <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: "24px" }}>

              {/* Upper Section: predicted class & confidence score next to each other */}
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
                  gap: "16px",
                }}
              >
                {/* Left Card: Predicted Class */}
                <div
                  style={{
                    background: "var(--bg-alt)",
                    border: "1px solid var(--border-subtle)",
                  borderRadius: "12px",
                  padding: "22px",
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    justifyContent: "center",
                    textAlign: "center",
                    boxShadow: "inset 0 1px 0 rgba(255,255,255,0.05)",
                  }}
                >
                  <span style={{ fontFamily: "var(--font-body)", fontSize: "13px", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "16px" }}>
                    Predicted class
                  </span>

                  {isDone && result ? (
                    <>
                      <div style={{ width: "56px", height: "56px", borderRadius: "50%", background: result.predictionBg, display: "flex", alignItems: "center", justifyContent: "center", marginBottom: "16px", border: `1px solid ${result.predictionColor}` }}>
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke={result.predictionColor} strokeWidth="2.5">
                          <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" fill={result.predictionColor} opacity="0.2" />
                          <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
                          <path d="M12 7v6M9 10h6" strokeWidth="2.2" strokeLinecap="round" />
                        </svg>
                      </div>
                      <h4 style={{ fontFamily: "var(--font-display)", fontSize: "28px", fontWeight: 800, color: "var(--text-primary)", margin: "0 0 8px 0", letterSpacing: "-0.02em" }}>
                        <AnimatedSharedSwap text={result.prediction} />
                      </h4>
                      <span
                        style={{
                          background: result.predictionBg,
                          color: result.predictionColor,
                          border: `1px solid ${result.predictionColor}`,
                          borderRadius: "999px",
                          padding: "6px 14px",
                          fontFamily: "var(--font-body)",
                          fontSize: "13px",
                          fontWeight: 700,
                          boxShadow: `0 0 12px ${result.predictionBg}`,
                        }}
                      >
                        {(result.classes[0].score * 100).toFixed(1)}% confidence
                      </span>
                    </>
                  ) : (
                    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "12px", padding: "12px 0" }}>
                      <div style={{ width: "48px", height: "48px", borderRadius: "50%", background: "var(--bg-chip)", border: "1px dashed var(--border-subtle)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                        {isInferring ? (
                           <NeuralNode />
                        ) : (
                           <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="var(--text-faint)" strokeWidth="2">
                             <circle cx="12" cy="12" r="10" />
                             <line x1="12" y1="8" x2="12" y2="12" />
                             <line x1="12" y1="16" x2="12.01" y2="16" />
                           </svg>
                        )}
                      </div>
                      <div style={{ width: "100%", textAlign: "center" }}>
                        {isInferring ? <CyclingStatusText modelMode={modelMode} /> : (
                          <p style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "var(--text-faint)", margin: 0, fontWeight: 500 }}>
                            Waiting for run...
                          </p>
                        )}
                      </div>
                    </div>
                  )}
                </div>

                {/* Right Card: Confidence Scores */}
                <div
                  style={{
                    background: "var(--bg-alt)",
                    border: "1px solid var(--border-faint)",
                    borderRadius: "12px",
                    padding: "22px",
                    display: "flex",
                    flexDirection: "column",
                  }}
                >
                  <span style={{ fontFamily: "var(--font-body)", fontSize: "13px", fontWeight: 600, color: "var(--text-secondary)", marginBottom: "16px" }}>
                    Confidence score
                  </span>

                  {isDone && result ? (
                    <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
                      {result.classes.map((cls) => (
                        <ConfidenceBar
                          key={cls.label}
                          label={cls.label}
                          score={cls.score}
                          color={cls.color}
                          bg={cls.bg}
                          animate={showBars}
                        />
                      ))}
                    </div>
                  ) : isInferring ? (
                    <WireframePulse />
                  ) : (
                    <div style={{ display: "flex", flexDirection: "column", gap: "18px", padding: "6px 0" }}>
                      {[1, 2, 3].map((i) => (
                        <div key={i} style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
                          <div style={{ display: "flex", justifyContent: "space-between" }}>
                            <div className="skeleton-shimmer" style={{ height: "12px", width: "70px", borderRadius: "4px" }} />
                            <div className="skeleton-shimmer" style={{ height: "12px", width: "36px", borderRadius: "4px" }} />
                          </div>
                          <div className="skeleton-shimmer" style={{ height: "6px", borderRadius: "999px" }} />
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              {/* Lower Section: Grad-CAM side-by-side visualization */}
              <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                <h4 style={{ fontFamily: "var(--font-display)", fontSize: "14px", fontWeight: 700, color: "var(--text-primary)", margin: 0 }}>
                  Grad-CAM Visualization
                </h4>
                <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "var(--text-secondary)", margin: "0 0 4px 0" }}>
                  Highlight regions that contributed most to the prediction.
                </p>

                {!preview && !result ? (
                  <div
                    style={{
                      display: "flex",
                      flexDirection: "column",
                      alignItems: "center",
                      justifyContent: "center",
                      padding: "36px 24px",
                      background: "var(--bg-alt)",
                      border: "1px dashed var(--border-subtle)",
                      borderRadius: "12px",
                      textAlign: "center",
                      gap: "12px",
                    }}
                  >
                    <div
                      style={{
                        width: "42px",
                        height: "42px",
                        borderRadius: "50%",
                        background: "color-mix(in srgb, var(--brand-primary) 8%, transparent)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: "var(--brand-primary)",
                      }}
                    >
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                        <rect x="3" y="3" width="18" height="18" rx="2" />
                        <circle cx="8.5" cy="8.5" r="1.5" />
                        <path d="M21 15l-5-5L5 21" />
                      </svg>
                    </div>
                    <div>
                      <h5 style={{ fontFamily: "var(--font-display)", fontSize: "13px", fontWeight: 600, color: "var(--text-primary)", margin: "0 0 4px 0" }}>
                        Visualizations Pending
                      </h5>
                      <p style={{ fontFamily: "var(--font-body)", fontSize: "11px", color: "var(--text-secondary)", margin: 0, maxWidth: "320px", lineHeight: "1.4" }}>
                        Upload a reef image and run the analysis to generate Grad-CAM overlay and attention heatmap.
                      </p>
                    </div>
                  </div>
                ) : (
                  <div className="grid grid-cols-3 gap-4" style={{ position: "relative" }}>
                    {/* Left Box: Original Image */}
                    <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                      <span style={{ fontFamily: "var(--font-mono)", fontSize: "12px", fontWeight: 700, color: "var(--text-secondary)", letterSpacing: "0.04em" }}>
                        ORIGINAL IMAGE
                      </span>
                      <div
                        style={{
                          aspectRatio: "1.5",
                          background: "var(--bg-alt)",
                          borderRadius: "10px",
                          overflow: "hidden",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          border: "1px solid color-mix(in srgb, var(--brand-primary) 20%, transparent)",
                          position: "relative",
                        }}
                      >
                        {(result?.originalUrl || preview) ? (
                          <>
                            <img src={(isDone && result?.originalUrl) || preview!} alt="Original uploaded reef" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                            {isInferring && <div className="laser-line" />}
                          </>
                        ) : (
                          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "6px" }}>
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="var(--text-secondary)" strokeWidth="1.5">
                              <rect x="3" y="3" width="18" height="18" rx="2" />
                              <circle cx="8.5" cy="8.5" r="1.5" />
                              <path d="M21 15l-5-5L5 21" />
                            </svg>
                            <span style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "var(--text-secondary)", fontWeight: 500 }}>No image</span>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Middle Box: Grad-CAM Overlay */}
                    <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                      <span style={{ fontFamily: "var(--font-mono)", fontSize: "12px", fontWeight: 700, color: "var(--text-secondary)", letterSpacing: "0.04em" }}>
                        GRAD-CAM OVERLAY
                      </span>
                      <div
                        style={{
                          aspectRatio: "1.5",
                          background: "var(--bg-alt)",
                          borderRadius: "10px",
                          overflow: "hidden",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          border: "1px solid color-mix(in srgb, var(--brand-primary) 20%, transparent)",
                          position: "relative",
                        }}
                      >
                        {isDone ? (
                          result && result.overlayUrl ? (
                            <img src={result.overlayUrl} alt="Grad-CAM overlay" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                          ) : (
                            <>
                              {(result?.originalUrl || preview) && (
                                <img src={result?.originalUrl || preview!} alt="Original reef" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                              )}
                              <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", background: "color-mix(in srgb, var(--bg-alt) 80%, transparent)" }}>
                                <span style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "var(--text-secondary)", fontWeight: 600 }}>
                                  {gradcam ? "Overlay Unavailable" : "Overlay Disabled"}
                                </span>
                              </div>
                            </>
                          )
                        ) : isInferring ? (
                          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", width: "100%", height: "100%", position: "relative" }}>
                            <OrganicMesh />
                            <ProcessingScanner />
                          </div>
                        ) : (
                          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "12px", opacity: 0.8 }}>
                            <div style={{ width: "42px", height: "42px", borderRadius: "50%", background: "var(--bg-chip)", border: "1px dashed var(--border-subtle)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--text-secondary)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                                <path d="M3 7V5a2 2 0 0 1 2-2h2" />
                                <path d="M17 3h2a2 2 0 0 1 2 2v2" />
                                <path d="M21 17v2a2 2 0 0 1-2 2h-2" />
                                <path d="M7 21H5a2 2 0 0 1-2-2v-2" />
                                <line x1="7" y1="12" x2="17" y2="12" />
                              </svg>
                            </div>
                            <span style={{ fontFamily: "var(--font-mono)", fontSize: "11px", color: "var(--text-secondary)", letterSpacing: "0.06em", textTransform: "uppercase" }}>
                              Ready to Generate
                            </span>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Right Box: Attention Heatmap */}
                    <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                      <span style={{ fontFamily: "var(--font-mono)", fontSize: "12px", fontWeight: 700, color: "var(--text-secondary)", letterSpacing: "0.04em" }}>
                        ATTENTION HEATMAP
                      </span>
                      <div
                        style={{
                          aspectRatio: "1.5",
                          background: "var(--bg-alt)",
                          borderRadius: "10px",
                          overflow: "hidden",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          border: "1px solid color-mix(in srgb, var(--brand-primary) 20%, transparent)",
                          position: "relative",
                        }}
                      >
                        {isDone ? (
                          result && result.heatmapUrl ? (
                            <img src={result.heatmapUrl} alt="Attention heatmap" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                          ) : (
                            <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", background: "color-mix(in srgb, var(--bg-alt) 80%, transparent)" }}>
                              <span style={{ fontFamily: "var(--font-body)", fontSize: "13px", color: "var(--text-secondary)", fontWeight: 600 }}>
                                {gradcam ? "Heatmap Unavailable" : "Heatmap Disabled"}
                              </span>
                            </div>
                          )
                        ) : isInferring ? (
                          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", width: "100%", height: "100%", position: "relative" }}>
                            <OrganicMesh />
                            <ProcessingScanner />
                          </div>
                        ) : (
                          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "12px", opacity: 0.8 }}>
                            <div style={{ width: "42px", height: "42px", borderRadius: "50%", background: "var(--bg-chip)", border: "1px dashed var(--border-subtle)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--text-secondary)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                                <path d="M3 7V5a2 2 0 0 1 2-2h2" />
                                <path d="M17 3h2a2 2 0 0 1 2 2v2" />
                                <path d="M21 17v2a2 2 0 0 1-2 2h-2" />
                                <path d="M7 21H5a2 2 0 0 1-2-2v-2" />
                                <line x1="7" y1="12" x2="17" y2="12" />
                              </svg>
                            </div>
                            <span style={{ fontFamily: "var(--font-mono)", fontSize: "11px", color: "var(--text-secondary)", letterSpacing: "0.06em", textTransform: "uppercase" }}>
                              Ready to Generate
                            </span>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                )}
              </div>

              {/* Informational Interpretability Banner with Color Scale Indicator */}
              <div
                style={{
                  background: "var(--bg-alt)",
                  border: "1px solid color-mix(in srgb, var(--brand-primary) 20%, transparent)",
                  borderRadius: "12px",
                  padding: "14px 20px",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  flexWrap: "wrap",
                  gap: "16px",
                  marginTop: "16px",
                }}
              >
                {/* Left side: text and info icon */}
                <div style={{ display: "flex", alignItems: "center", gap: "10px", flex: "1 1 280px" }}>
                  <div style={{ width: "20px", height: "20px", borderRadius: "50%", background: "color-mix(in srgb, var(--brand-primary) 20%, transparent)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="var(--brand-primary)" strokeWidth="3">
                      <line x1="12" y1="16" x2="12" y2="12" strokeLinecap="round" />
                      <line x1="12" y1="8" x2="12.01" y2="8" strokeLinecap="round" />
                      <circle cx="12" cy="12" r="10" />
                    </svg>
                  </div>
                  <span style={{ fontFamily: "var(--font-body)", fontSize: "13px", fontWeight: 500, color: "var(--text-primary)", lineHeight: 1.4 }}>
                    Red areas indicate regions that had the strongest influence on the prediction.
                  </span>
                </div>

                {/* Right side: visual gradient color scale matching the user sample */}
                <div style={{ display: "flex", flexDirection: "column", gap: "4px", width: "160px", flexShrink: 0 }}>
                  <div
                    style={{
                      height: "10px",
                      borderRadius: "999px",
                      background: "linear-gradient(90deg, #10b981 0%, #a3e635 50%, #f59e0b 100%)",
                      width: "100%",
                    }}
                  />
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <span style={{ fontFamily: "var(--font-body)", fontSize: "12px", fontWeight: 800, color: "#047857", letterSpacing: "0.02em" }}>
                      LOW
                    </span>
                    <span style={{ fontFamily: "var(--font-body)", fontSize: "12px", fontWeight: 800, color: "#9a3412", letterSpacing: "0.02em" }}>
                      HIGH
                    </span>
                  </div>
                </div>
              </div>

            </div>
          </div>

          {/* ── CARD 3: ASSISTANT CHAT (4 Units Width) ── */}
          <div className="workspace-col-assistant" style={{ minHeight: "500px", height: "100%", display: "flex", flexDirection: "column" }}>
            <ChatBot integrated />
          </div>

        </div>
      </div>
    </section>
  );
}
