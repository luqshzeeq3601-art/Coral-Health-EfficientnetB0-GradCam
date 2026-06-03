import { useState } from "react";
import { NetworkBackground } from "./NetworkBackground";

const PILLARS = [
  {
    num: "01",
    tag: "Backbone Architecture",
    tagColor: "var(--brand-cyan)",
    tagBg: "rgba(56, 189, 248, 0.12)",
    title: "EfficientNet-B0 Feature Extractor",
    desc: "Controlled transfer learning optimizes deep model scaling, capturing fine reef textures and bleaching traits without inflating the parameter size budget for deployment cameras.",
    accent: "var(--brand-cyan)",
    accentBg: "rgba(56, 189, 248, 0.12)",
    stats: [
      { label: "Parameters", value: "20.3M" },
      { label: "Input", value: "224×224" },
    ],
    icon: (
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <rect x="2" y="15" width="4" height="7" rx="1" fill="currentColor" opacity="0.35" />
        <rect x="7" y="10" width="4" height="12" rx="1" fill="currentColor" opacity="0.6" />
        <rect x="12" y="6" width="4" height="16" rx="1" fill="currentColor" opacity="0.8" />
        <rect x="17" y="2" width="4" height="20" rx="1" fill="currentColor" />
        <path d="M4 13L9 8L14 4.5L19 1" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" opacity="0.4" />
      </svg>
    ),
  },
  {
    num: "02",
    tag: "Ensemble Method",
    tagColor: "var(--brand-cyan)",
    tagBg: "rgba(56, 189, 248, 0.12)",
    title: "5-Seed SWA Ensemble Inference",
    desc: "Predictions are averaged over five robust stochastic weight averaging checkpoints to minimize variance across Healthy, Bleached, and Dead classification passes.",
    accent: "var(--brand-cyan)",
    accentBg: "rgba(56, 189, 248, 0.12)",
    stats: [
      { label: "Seeds", value: "×5" },
      { label: "Method", value: "SWA" },
    ],
    icon: (
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <circle cx="12" cy="12" r="3" fill="currentColor" />
        <circle cx="4.5" cy="7" r="2.5" stroke="currentColor" strokeWidth="1.5" />
        <circle cx="19.5" cy="7" r="2.5" stroke="currentColor" strokeWidth="1.5" />
        <circle cx="4.5" cy="17" r="2.5" stroke="currentColor" strokeWidth="1.5" />
        <circle cx="19.5" cy="17" r="2.5" stroke="currentColor" strokeWidth="1.5" />
        <path d="M7 7.5L9.5 10.5M14.5 10.5L17 7.5M7 16.5L9.5 13.5M14.5 13.5L17 16.5" stroke="currentColor" strokeWidth="1.25" strokeLinecap="round" opacity="0.6" />
      </svg>
    ),
  },
  {
    num: "03",
    tag: "Explainability",
    tagColor: "var(--brand-cyan)",
    tagBg: "rgba(56, 189, 248, 0.12)",
    title: "Grad-CAM and Audit Workflow",
    desc: "Enables structural backpropagation checking and visual audit trails to guarantee transparent, explainable validation in active field tracking environments.",
    accent: "var(--brand-cyan)",
    accentBg: "rgba(56, 189, 248, 0.12)",
    stats: [
      { label: "Layer", value: "Conv7" },
      { label: "Output", value: "Heatmap" },
    ],
    icon: (
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <rect x="2" y="2" width="9" height="9" rx="2" stroke="currentColor" strokeWidth="1.5" />
        <rect x="13" y="2" width="9" height="9" rx="2" stroke="currentColor" strokeWidth="1.5" />
        <rect x="2" y="13" width="9" height="9" rx="2" stroke="currentColor" strokeWidth="1.5" />
        <rect x="13" y="13" width="9" height="9" rx="2" fill="currentColor" opacity="0.15" stroke="currentColor" strokeWidth="1.5" />
        <path d="M16 18.5C16.5 17 17.5 16 18.5 16.5" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" opacity="0.7" />
        <circle cx="18" cy="19" r="1" fill="currentColor" opacity="0.8" />
      </svg>
    ),
  },
] as const;

export default function TechnologyStack({ sectionId = "technology" }: { sectionId?: string }) {
  return (
    <section
      id={sectionId}
      data-theme="dark"
      aria-labelledby="technology-heading"
      style={{
        background: "#06111f",
        paddingTop: "clamp(48px, 6vw, 72px)",
        paddingBottom: "clamp(48px, 6vw, 72px)",
        borderTop: "1px solid rgba(255, 255, 255, 0.08)",
        position: "relative",
        overflow: "hidden",
        transition: "background-color 250ms ease",
      }}
    >
      <style>{`
        .glass-hero-card {
          background: rgba(8, 14, 28, 0.18);
          backdrop-filter: blur(12px) saturate(160%) brightness(1.03);
          -webkit-backdrop-filter: blur(12px) saturate(160%) brightness(1.03);
          border: 1px solid rgba(255, 255, 255, 0.09);
          box-shadow:
            inset 0 1px 0 rgba(255, 255, 255, 0.08),
            inset 0 -1px 0 rgba(0, 0, 0, 0.15),
            0 4px 24px rgba(0, 0, 0, 0.28);
          transition: background 0.35s ease, border-color 0.35s ease, box-shadow 0.35s ease;
          position: relative;
          overflow: hidden;
        }
        .glass-hero-card::before {
          content: '';
          position: absolute;
          inset: 0;
          background: radial-gradient(ellipse 80% 60% at 20% 40%, rgba(60, 79, 224, 0.05) 0%, transparent 70%);
          pointer-events: none;
        }
        .glass-hero-card:hover {
          background: rgba(8, 14, 28, 0.26);
          border-color: rgba(60, 79, 224, 0.20);
          box-shadow:
            inset 0 1px 0 rgba(255, 255, 255, 0.12),
            inset 0 -1px 0 rgba(0, 0, 0, 0.15),
            0 0 0 1px rgba(60, 79, 224, 0.10),
            0 8px 32px rgba(60, 79, 224, 0.08);
        }
        .glass-pillar-card {
          background: rgba(8, 14, 28, 0.20);
          backdrop-filter: blur(12px) saturate(150%) brightness(1.02);
          -webkit-backdrop-filter: blur(12px) saturate(150%) brightness(1.02);
          border: 1px solid rgba(255, 255, 255, 0.07);
          border-left: 2px solid var(--accent-glow);
          box-shadow:
            inset 0 1px 0 rgba(255, 255, 255, 0.06),
            0 2px 12px rgba(0, 0, 0, 0.22);
          transition: background 0.30s ease, border-color 0.30s ease, box-shadow 0.30s ease, transform 0.30s ease;
          position: relative;
          overflow: hidden;
        }
        .glass-pillar-card::before {
          content: '';
          position: absolute;
          top: 0; left: 0; right: 0; height: 1px;
          background: linear-gradient(90deg, var(--accent-glow) 0%, transparent 60%);
          opacity: 0.45;
          pointer-events: none;
        }
        .glass-pillar-card::after {
          content: '';
          position: absolute;
          inset: 0;
          background: radial-gradient(ellipse 50% 100% at 0% 50%, var(--accent-shadow-strong) 0%, transparent 60%);
          pointer-events: none;
          opacity: 0;
          transition: opacity 0.30s ease;
        }
        .glass-pillar-card:hover {
          background: rgba(8, 14, 28, 0.30);
          border-left-color: var(--accent-glow);
          border-color: rgba(255, 255, 255, 0.10);
          border-left: 2px solid var(--accent-glow);
          box-shadow:
            inset 0 1px 0 rgba(255, 255, 255, 0.10),
            0 0 0 1px var(--accent-ring),
            0 4px 20px var(--accent-shadow);
          transform: translateY(-1px) translateX(2px);
        }
        .glass-pillar-card:hover::after {
          opacity: 1;
        }
        .stat-chip {
          position: relative;
          z-index: 2;
          background: rgba(4, 9, 20, 0.92);
          border: 1px solid rgba(255, 255, 255, 0.13);
          border-radius: 6px;
          padding: 5px 9px;
          text-align: right;
          transition: background 0.2s ease, border-color 0.2s ease;
        }
        .glass-pillar-card:hover .stat-chip {
          background: rgba(4, 9, 20, 0.96);
          border-color: var(--accent-ring);
        }
        /* Right-edge calmer gradient: kills the orange ambient bleed under the stats */
        .glass-pillar-card .right-veil {
          position: absolute;
          top: 0; right: 0; bottom: 0;
          width: 130px;
          background: linear-gradient(270deg, rgba(6, 12, 26, 0.78) 0%, rgba(6, 12, 26, 0.45) 55%, rgba(6, 12, 26, 0) 100%);
          pointer-events: none;
          z-index: 1;
        }
        @media (max-width: 639px) {
          .pillar-inner {
            display: grid !important;
            grid-template-columns: 36px 1fr !important;
            grid-template-rows: auto auto !important;
            gap: 8px 12px !important;
          }
          .pillar-stats {
            grid-column: 1 / -1;
            display: flex !important;
            flex-direction: row !important;
            gap: 6px;
            width: auto !important;
          }
          .pillar-stats .stat-chip { flex: 1; text-align: center; }
          .pillar-icon { width: 36px !important; height: 36px !important; border-radius: 9px !important; }
        }
        @media (min-width: 640px) and (max-width: 1023px) {
          .pillar-inner {
            grid-template-columns: 40px minmax(0,1fr) auto !important;
          }
        }
      `}</style>

      {/* Immersive 3D Parallax Animated Backdrop */}
      <NetworkBackground />

      <div
        className="mx-auto"
        style={{
          maxWidth: "1264px",
          paddingLeft: "clamp(24px, 6vw, 48px)",
          paddingRight: "clamp(24px, 6vw, 48px)",
          position: "relative",
          zIndex: 10,
          pointerEvents: "none",
        }}
      >
        {/* ── Section intro ── */}
        <div style={{ display: "flex", flexDirection: "column", gap: "10px", marginBottom: "36px", maxWidth: "560px", pointerEvents: "auto" }}>
          <h2
            id="technology-heading"
            style={{ fontFamily: "var(--font-display)", fontSize: "var(--text-section)", fontWeight: 700, lineHeight: "var(--leading-section)", letterSpacing: "var(--tracking-section)", color: "#ffffff", margin: 0, overflowWrap: "anywhere" }}
          >
            Technology Stack
          </h2>
          <p
            style={{ fontFamily: "var(--font-body)", fontSize: "var(--text-body)", lineHeight: "var(--leading-body)", color: "#94a3b8", margin: 0, maxWidth: "var(--measure-prose)" }}
          >
            EfficientNet-B0 backbone extracts reef features, 5-Seed SWA ensemble
            stabilizes predictions, and Grad-CAM provides transparent visual explanations.
          </p>
        </div>

        {/* ── Layout grid ── */}
        <div
          className="grid grid-cols-1 md:grid-cols-[minmax(0,0.42fr)_minmax(0,1.18fr)]"
          style={{ gap: "16px", alignItems: "start", maxWidth: "900px" }}
          role="list"
          aria-label="Technology pillars"
        >
          {/* Left hero card — compact */}
          <div
            role="listitem"
            className="glass-hero-card"
            style={{
              borderRadius: "16px",
              padding: "clamp(14px, 2.5vw, 20px)",
              display: "flex",
              flexDirection: "column",
              gap: "10px",
              pointerEvents: "auto",
            }}
          >
            <span style={{ fontFamily: "var(--font-mono)", fontSize: "11px", fontWeight: 700, color: "var(--brand-cyan)", letterSpacing: "0.08em" }}>
              MODEL STACK
            </span>
            <h3
              style={{ fontFamily: "var(--font-display)", fontSize: "clamp(18px, 2.2vw, 26px)", fontWeight: 680, lineHeight: 1.22, letterSpacing: "var(--tracking-tight)", color: "#ffffff", margin: 0 }}
            >
              From reef pixels to auditable attention.
            </h3>
            <p style={{ fontFamily: "var(--font-body)", fontSize: "13px", lineHeight: 1.55, color: "#94a3b8", margin: 0 }}>
              Compact features, stabilized ensemble voting, and Grad-CAM evidence — one reviewable pipeline.
            </p>
          </div>

          {/* Right pillar rows — slimmed */}
          <div style={{ display: "grid", gap: "8px", pointerEvents: "none" }}>
            {PILLARS.map(({ num, tag, title, desc, accent, accentBg, stats, icon }) => (
              <article
                key={num}
                role="listitem"
                className="glass-pillar-card"
                style={{
                  borderRadius: "14px",
                  padding: "14px 14px 14px 13px",
                  pointerEvents: "auto",
                  overflow: "hidden",
                  ["--accent-glow" as any]: accent,
                  ["--accent-shadow" as any]: `${accent}28`,
                  ["--accent-shadow-strong" as any]: `${accent}0a`,
                  ["--accent-ring" as any]: `${accent}35`,
                }}
              >
                <span className="right-veil" aria-hidden="true" />
                <div
                  className="pillar-inner"
                  style={{
                    position: "relative",
                    zIndex: 2,
                    display: "grid",
                    gridTemplateColumns: "40px minmax(0,1fr) 78px",
                    gap: "14px",
                    alignItems: "center",
                  }}
                >
                  <span
                    className="pillar-icon"
                    style={{
                      display: "flex", alignItems: "center", justifyContent: "center",
                      width: "40px", height: "40px", borderRadius: "10px",
                      background: accentBg, color: accent,
                      border: `1px solid ${accent}28`,
                      boxShadow: `0 0 10px ${accent}18, inset 0 1px 0 rgba(255,255,255,0.08)`,
                      flexShrink: 0,
                    }}
                  >
                    <span style={{ transform: "scale(0.85)", display: "flex" }}>{icon}</span>
                  </span>
                  <div>
                    <p style={{ margin: "0 0 3px", fontFamily: "var(--font-mono)", fontSize: "10px", fontWeight: 700, letterSpacing: "0.08em", color: accent }}>
                      {num} / {tag}
                    </p>
                    <h3 style={{ margin: "0 0 4px", fontFamily: "var(--font-display)", fontSize: "15px", fontWeight: 620, color: "#ffffff", letterSpacing: "var(--tracking-tight)", lineHeight: 1.2 }}>
                      {title}
                    </h3>
                    <p style={{ margin: 0, fontFamily: "var(--font-body)", fontSize: "12px", lineHeight: 1.5, color: "#9aaec1", maxWidth: "48ch" }}>
                      {desc}
                    </p>
                  </div>
                  <div className="pillar-stats" style={{ display: "grid", gap: "4px", width: "80px" }}>
                    {stats.map(({ label, value }) => (
                      <div key={label} className="stat-chip">
                        <p style={{ margin: 0, fontFamily: "var(--font-mono)", fontSize: "12px", fontWeight: 800, color: accent, letterSpacing: "0.02em" }}>
                          {value}
                        </p>
                        <p style={{ margin: "1px 0 0", fontFamily: "var(--font-body)", fontSize: "9px", fontWeight: 600, color: "#8da0b0", letterSpacing: "0.05em", textTransform: "uppercase" }}>
                          {label}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>
              </article>
            ))}
          </div>
        </div>

      </div>
    </section>
  );
}
