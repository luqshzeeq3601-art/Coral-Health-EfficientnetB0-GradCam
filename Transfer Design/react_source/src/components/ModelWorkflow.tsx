import { useState, useEffect, useRef } from "react";
import CoralPipelineSVG from "./CoralPipelineSVG";
import { AnimatedKineticBuild } from "./ui";

const STEPS = [
  {
    num: "01",
    title: "Input Image",
    subtitle: "224×224 RGB",
    desc: "The uploaded or sample reef image is resized and normalized to a 224×224 RGB tensor before entering the network.",
    icon: (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none" aria-hidden="true">
        <rect x="2" y="2" width="18" height="18" rx="4" stroke="currentColor" strokeWidth="1.6" />
        <path d="M4 16L9 11L13 15L16 11L19 14" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
        <circle cx="15" cy="7" r="2" fill="currentColor" />
      </svg>
    ),
    accent: "var(--brand-primary)",
    accentBg: "var(--brand-light)",
  },
  {
    num: "02",
    title: "Feature Extraction",
    subtitle: "EfficientNet-B0",
    desc: "The CNN backbone extracts multi-scale feature maps capturing coral texture, coloration, and structural patterns.",
    icon: (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none" aria-hidden="true">
        <path d="M11 2L2 7L11 12L20 7L11 2Z" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round" />
        <path d="M2 12L11 17L20 12" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round" />
        <path d="M2 17L11 22L20 17" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round" />
      </svg>
    ),
    accent: "var(--brand-primary)",
    accentBg: "var(--brand-light)",
  },
  {
    num: "03",
    title: "Gradient Computation",
    subtitle: "Last Conv Block",
    desc: "Backpropagation computes class-specific gradients through the final convolutional layer to identify influential activations.",
    icon: (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none" aria-hidden="true">
        <path d="M11 2L20 6.5V15.5L11 20L2 15.5V6.5L11 2Z" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round" />
        <path d="M11 20V11M11 11L20 6.5M11 11L2 6.5" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round" />
      </svg>
    ),
    accent: "var(--brand-primary)",
    accentBg: "var(--brand-light)",
  },
  {
    num: "04",
    title: "Importance Scoring",
    subtitle: "Global Avg Pooling",
    desc: "Gradient magnitudes are globally averaged per channel, producing importance weights that rank each feature map's contribution.",
    icon: (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none" aria-hidden="true">
        <rect x="4" y="14" width="4" height="6" rx="1" fill="currentColor" />
        <rect x="10" y="8" width="4" height="12" rx="1" fill="currentColor" />
        <rect x="16" y="2" width="4" height="18" rx="1" fill="currentColor" />
      </svg>
    ),
    accent: "var(--brand-primary)",
    accentBg: "var(--brand-light)",
  },
  {
    num: "05",
    title: "Attention Heatmap",
    subtitle: "Grad-CAM",
    desc: "Weighted feature maps are combined and ReLU-activated to generate a spatial heatmap highlighting the regions driving the prediction.",
    icon: (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none" aria-hidden="true">
        <path d="M11 4L2 11L11 18L20 11L11 4Z" stroke="currentColor" strokeWidth="1.6" strokeLinejoin="round" />
        <circle cx="11" cy="11" r="3" fill="url(#icon-heat-gradient)" />
        <defs>
          <radialGradient id="icon-heat-gradient">
            <stop offset="0%" stopColor="#ef4444" />
            <stop offset="60%" stopColor="#f59e0b" />
            <stop offset="100%" stopColor="#0ea5e9" stopOpacity="0" />
          </radialGradient>
        </defs>
      </svg>
    ),
    accent: "var(--brand-primary)",
    accentBg: "var(--brand-light)",
  },
  {
    num: "06",
    title: "Prediction Output",
    subtitle: "3-Class Probability",
    desc: "The model outputs confidence scores for Healthy, Bleached, and Dead alongside the localized Grad-CAM attention overlay.",
    icon: (
      <svg width="22" height="22" viewBox="0 0 22 22" fill="none" aria-hidden="true">
        <rect x="3" y="2" width="16" height="18" rx="3" stroke="currentColor" strokeWidth="1.6" />
        <circle cx="11" cy="8" r="4" stroke="currentColor" strokeWidth="1.6" />
        <path d="M9.5 8L10.5 9L12.5 7" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
        <circle cx="7" cy="16" r="1.5" fill="#ef4444" />
        <circle cx="11" cy="16" r="1.5" fill="#f59e0b" />
        <circle cx="15" cy="16" r="1.5" fill="#2DD4BF" />
      </svg>
    ),
    accent: "var(--brand-primary)",
    accentBg: "var(--brand-light)",
  },
] as const;

type ScrollStepProps = (typeof STEPS)[number] & { isActive: boolean; isLast: boolean };

function ScrollStep({ num, title, subtitle, desc, icon, accent, isActive, isLast }: ScrollStepProps) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "stretch",
        gap: "24px",
        flex: 1,
      }}
      aria-current={isActive ? "step" : undefined}
    >
      {/* Step indicator column */}
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", alignSelf: "stretch" }}>
        <div className="step-number" style={{ color: isActive ? accent : "inherit" }}>
          <span style={{ fontFamily: "var(--font-mono)", fontSize: "11px", fontWeight: 700 }}>
            {num}
          </span>
        </div>
        {/* Connecting line */}
        {!isLast && (
          <div className="step-connector" style={{ color: isActive ? accent : "inherit", marginLeft: 0 }} />
        )}
      </div>

      {/* Content column */}
      <div style={{ paddingBottom: isLast ? "150px" : "120px", flex: 1, paddingTop: "2px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "12px", marginBottom: "8px" }}>
          <span
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              width: "32px",
              height: "32px",
              borderRadius: "8px",
              background: isActive ? `${accent}15` : "transparent",
              color: isActive ? accent : "var(--text-faint)",
              transition: "all 300ms ease",
            }}
          >
            {icon}
          </span>
          <h3 className="step-title" style={{ fontFamily: "var(--font-display)", fontSize: "20px", fontWeight: 600, margin: 0, letterSpacing: "var(--tracking-tight)" }}>
            {title}
          </h3>
        </div>

        <div className="step-desc">
          <span
            style={{
              display: "inline-flex",
              alignItems: "center",
              background: `${accent}15`,
              color: accent,
              borderRadius: "999px",
              padding: "3px 10px",
              fontFamily: "var(--font-mono)",
              fontSize: "11px",
              fontWeight: 600,
              letterSpacing: "0.04em",
              marginBottom: "12px",
            }}
          >
            {subtitle}
          </span>
          <p style={{ fontFamily: "var(--font-body)", fontSize: "15px", lineHeight: "1.6", color: "var(--text-secondary)", margin: 0 }}>
            {desc}
          </p>
        </div>
      </div>
    </div>
  );
}

export default function ModelWorkflow({ sectionId = "workflow" }: { sectionId?: string }) {
  const [activeStep, setActiveStep] = useState(0);
  const stepRefs = useRef<(HTMLDivElement | null)[]>([]);

  // Active-step detection via IntersectionObserver instead of reading
  // getBoundingClientRect for every step on every scroll event. A thin
  // detection band ~35% down the viewport marks which step is current;
  // when several overlap it, the last (deepest) one wins — matching the
  // previous "last step to cross the trigger line" behaviour.
  useEffect(() => {
    const steps = stepRefs.current.filter(Boolean) as HTMLDivElement[];
    if (steps.length === 0) return;

    const intersecting = new Set<number>();
    const indexOf = new Map<Element, number>();
    steps.forEach((el) => {
      const idx = stepRefs.current.indexOf(el);
      indexOf.set(el, idx);
    });

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          const idx = indexOf.get(entry.target);
          if (idx == null) continue;
          if (entry.isIntersecting) intersecting.add(idx);
          else intersecting.delete(idx);
        }
        if (intersecting.size > 0) {
          // Deepest step currently in the trigger band wins.
          setActiveStep(Math.max(...intersecting));
        }
      },
      // Collapse the viewport to a ~1% band centred near 35% from the top.
      { rootMargin: "-35% 0px -64% 0px", threshold: 0 }
    );

    steps.forEach((el) => observer.observe(el));
    return () => observer.disconnect();
  }, []);

  return (
    <section
      id={sectionId}
      aria-labelledby="workflow-heading"
      style={{
        background: "var(--bg-alt)",
        paddingTop: "var(--section-space-lg)",
        paddingBottom: "var(--section-space-lg)",
        borderTop: "1px solid var(--border-base)",
        transition: "background-color 250ms ease",
      }}
    >
      <div className="mx-auto" style={{ maxWidth: "1264px", paddingLeft: "clamp(24px, 6vw, 48px)", paddingRight: "clamp(24px, 6vw, 48px)" }}>
        {/* ── Section intro ── */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr", gap: "48px", marginBottom: "56px" }} className="md:grid-flow-col md:auto-cols-fr">
          <div style={{ maxWidth: "640px" }}>
            {/* Heading */}
            <h2
              id="workflow-heading"
              style={{ fontFamily: "var(--font-display)", fontSize: "var(--text-section)", fontWeight: 700, lineHeight: "var(--leading-section)", letterSpacing: "var(--tracking-section)", color: "var(--text-primary)", margin: "0 0 16px 0", overflowWrap: "anywhere" }}
            >
              <AnimatedKineticBuild text="How the CNN Pipeline Works" />
            </h2>
            <p
              style={{ fontFamily: "var(--font-body)", fontSize: "var(--text-body)", fontWeight: 400, lineHeight: "var(--leading-body)", color: "var(--text-secondary)", margin: 0, maxWidth: "var(--measure-prose)" }}
            >
              Each inference pass runs through six transparent stages — from raw image
              input to localized Grad-CAM attention heatmap output. This staged
              architecture supports AI transparency and explainability for field-use
              marine biologists.
            </p>
          </div>
        </div>

        {/* ── Scrollytelling Section ── */}
        <div className="scrollytelling-container">

          {/* Left: Scrollable Text Steps */}
          <div className="scrollytelling-steps" role="list" aria-label="CNN pipeline stages">
            {STEPS.map((step, index) => (
              <div
                key={step.num}
                ref={(el) => {
                  stepRefs.current[index] = el;
                }}
                role="listitem"
                className={`scroll-step ${activeStep === index ? "active" : ""}`}
              >
                <ScrollStep
                  {...step}
                  isActive={activeStep === index}
                  isLast={index === STEPS.length - 1}
                />
              </div>
            ))}
          </div>

          {/* Right: Sticky Pipeline Visualization */}
          <div className="scrollytelling-visual" aria-label="Live CNN Pipeline Visualization">
            <div className="pipeline-dark-banner">
              <div className="pipeline-label">Live Pipeline Visualization</div>
              <CoralPipelineSVG activeStep={activeStep} />
            </div>
          </div>

        </div>

        {/* ── EfficientNet-B0 detail strip ── */}
        <div
          style={{
            marginTop: "36px",
            background: "var(--bg-card)",
            border: "1px solid var(--border-subtle)",
            borderRadius: "12px",
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(120px, 1fr))",
            alignItems: "stretch",
            overflow: "hidden",
            boxShadow: "0 14px 40px -34px rgba(13, 23, 56, 0.22)",
            transition: "background-color 250ms ease",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "12px", minWidth: 0, padding: "16px 18px", gridColumn: "span 2" }}>
            <span
              style={{ display: "flex", alignItems: "center", justifyContent: "center", width: "34px", height: "34px", borderRadius: "9px", background: "var(--brand-light)", border: "1px solid rgba(0,87,230,0.12)", flexShrink: 0 }}
              aria-hidden="true"
            >
              <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
                <path d="M9 2L16 5.5V12.5L9 16L2 12.5V5.5L9 2Z" stroke="var(--brand-primary)" strokeWidth="1.45" strokeLinejoin="round" />
                <circle cx="9" cy="9" r="2" fill="var(--brand-primary)" />
              </svg>
            </span>
            <div style={{ minWidth: 0 }}>
              <p style={{ fontFamily: "var(--font-mono)", fontSize: "9px", fontWeight: 700, color: "var(--text-brand)", letterSpacing: "0.12em", textTransform: "uppercase", margin: "0 0 5px 0", lineHeight: 1 }}>
                Model Spec
              </p>
              <p style={{ fontFamily: "var(--font-body)", fontSize: "15px", fontWeight: 700, color: "var(--text-primary)", margin: 0, lineHeight: 1.15, overflowWrap: "anywhere" }}>
                EfficientNet-B0 / 5-Seed SWA Ensemble
              </p>
              <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "var(--text-secondary)", margin: "3px 0 0 0", overflowWrap: "anywhere" }}>
                Backbone with stochastic weight averaging
              </p>
            </div>
          </div>

          <>
            {[
              { label: "Parameters", value: "20.3M", color: "var(--text-brand)" },
              { label: "Input", value: "224 x 224", color: "var(--text-brand)" },
              { label: "Macro F1", value: "0.98", color: "#3cab57" },
              { label: "Grad-CAM", value: "Layer 7", color: "var(--text-brand)" },
            ].map(({ label, value, color }) => (
              <div
                key={label}
                style={{
                  borderLeft: "1px solid var(--border-faint)",
                  padding: "16px 14px",
                  display: "flex",
                  flexDirection: "column",
                  justifyContent: "center",
                  minWidth: 0,
                }}
              >
                <p style={{ fontFamily: "var(--font-mono)", fontSize: "16px", fontWeight: 800, color, margin: 0, lineHeight: 1, whiteSpace: "nowrap" }}>
                  {value}
                </p>
                <p style={{ fontFamily: "var(--font-body)", fontSize: "11px", fontWeight: 600, color: "var(--text-faint)", margin: "5px 0 0 0", letterSpacing: "0" }}>
                  {label}
                </p>
              </div>
            ))}
          </>
        </div>
      </div>
    </section>
  );
}
