import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";
import coralLogo from "../assets/corallogo.png";

const NAV_GROUPS = [
  {
    label: "Platform",
    links: [
      { text: "Mission", href: "#mission" },
      { text: "Workflow", href: "#workflow" },
      { text: "Technology", href: "#technology" },
      { text: "Validation", href: "#performance" },
    ],
  },
  {
    label: "Developers",
    links: [
      { text: "Documentation", href: "#" },
      { text: "API Reference", href: "#" },
      { text: "GitHub", href: "#" },
      { text: "Grad-CAM Engine", href: "#gradcam-3d" },
    ],
  },
  {
    label: "Connect",
    links: [
      { text: "Research Papers", href: "#" },
      { text: "Twitter / X", href: "#" },
      { text: "LinkedIn", href: "#" },
      { text: "Contact", href: "#" },
    ],
  },
] as const;

export default function Footer() {
  const containerRef = useRef<HTMLElement>(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end end"]
  });
  // Map scroll progress to background position (gradient sweeps left to right)
  const bgPosition = useTransform(scrollYProgress, [0, 1], ["100%", "0%"]);
  // Map scroll progress to horizontal translation (slides right and rests perfectly centered at the bottom)
  const textX = useTransform(scrollYProgress, [0, 1], ["-12vw", "0vw"]);

  return (
    <footer
      id="footer"
      ref={containerRef}
      aria-label="Site footer"
      style={{
        background: "var(--bg-card)",
        borderTop: "1px solid var(--border-subtle)",
        transition: "background-color 250ms ease",
      }}
    >
      {/* Main footer body */}
      <div className="mx-auto flex flex-col lg:flex-row justify-between gap-16 lg:gap-8" style={{ maxWidth: "1264px", padding: "96px 48px 64px" }}>
        
        {/* ── Brand & Technical Statement ── */}
        <div style={{ display: "flex", flexDirection: "column", gap: "40px", flex: "1 1 auto", maxWidth: "540px" }}>
          <a
            href="#"
            aria-label="Coral Health AI — back to top"
            style={{ display: "inline-flex", alignItems: "center", gap: "12px", textDecoration: "none", alignSelf: "flex-start" }}
            className="focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-2 rounded-sm group"
          >
            <span
              aria-hidden="true"
              style={{ display: "flex", alignItems: "center", justifyContent: "center", width: "40px", height: "40px", borderRadius: "10px", overflow: "hidden", flexShrink: 0 }}
              className="bg-[var(--bg-alt)] border border-[var(--border-subtle)] group-hover:border-[var(--brand-primary)] transition-colors"
            >
              <img src={coralLogo} alt="" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
            </span>
            <span
              style={{ fontFamily: "var(--font-body)", fontSize: "18px", fontWeight: 800, color: "var(--text-primary)", letterSpacing: "0" }}
            >
              Coral Health AI
            </span>
          </a>

          <h2 style={{ fontFamily: "var(--font-display)", fontSize: "28px", fontWeight: 650, color: "var(--text-primary)", lineHeight: 1.3, letterSpacing: "0", margin: 0 }}>
            Automating reef conservation with <span style={{ color: "var(--text-brand)" }}>explainable computer vision</span> and edge inference.
          </h2>

          {/* Technical Readout (Replaces generic pills) */}
          <div style={{ display: "flex", flexDirection: "column", gap: "16px", borderLeft: "2px solid var(--brand-primary)", paddingLeft: "20px" }}>
            
            <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
              <span style={{ fontFamily: "var(--font-mono)", fontSize: "12px", textTransform: "uppercase", letterSpacing: "0.15em", color: "var(--text-secondary)", fontWeight: 700 }}>Architecture</span>
              <span style={{ fontFamily: "var(--font-mono)", fontSize: "14px", color: "var(--text-primary)" }}>EfficientNet-B0 + 5-Seed SWA Ensemble</span>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
              <span style={{ fontFamily: "var(--font-mono)", fontSize: "12px", textTransform: "uppercase", letterSpacing: "0.15em", color: "var(--text-secondary)", fontWeight: 700 }}>Performance</span>
              <span style={{ fontFamily: "var(--font-mono)", fontSize: "14px", color: "var(--text-primary)", display: "flex", alignItems: "center", gap: "8px" }}>
                <span style={{ color: "var(--text-brand)", fontWeight: 700 }}>98.11%</span> Held-out Accuracy
              </span>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: "8px", marginTop: "4px" }}>
              <span style={{ fontFamily: "var(--font-mono)", fontSize: "12px", textTransform: "uppercase", letterSpacing: "0.15em", color: "var(--text-secondary)", fontWeight: 700 }}>Target Classes</span>
              <div style={{ display: "flex", gap: "16px", flexWrap: "wrap" }}>
                {[
                  { 
                    label: "Healthy", 
                    color: "#3cab57",
                    icon: (
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                        <polyline points="22 4 12 14.01 9 11.01" />
                      </svg>
                    )
                  },
                  { 
                    label: "Bleached", 
                    color: "#e07b2a",
                    icon: (
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
                        <line x1="12" y1="9" x2="12" y2="13" />
                        <line x1="12" y1="17" x2="12.01" y2="17" />
                      </svg>
                    )
                  },
                  { 
                    label: "Dead", 
                    color: "#b84141",
                    icon: (
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                        <circle cx="12" cy="12" r="10" />
                        <line x1="15" y1="9" x2="9" y2="15" />
                        <line x1="9" y1="9" x2="15" y2="15" />
                      </svg>
                    )
                  },
                ].map(({ label, color, icon }) => (
                  <div key={label} style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                    <div style={{ color, display: "flex", alignItems: "center", justifyContent: "center" }}>
                      {icon}
                    </div>
                    <span style={{ fontFamily: "var(--font-mono)", fontSize: "13px", color: "var(--text-primary)" }}>{label}</span>
                  </div>
                ))}
              </div>
            </div>

          </div>
        </div>

        {/* ── Nav link groups ── */}
        <div style={{ display: "flex", flexWrap: "wrap", gap: "64px", flex: "0 1 auto" }}>
          {NAV_GROUPS.map(({ label, links }) => (
            <nav key={label} aria-label={`Footer: ${label}`} style={{ minWidth: "120px" }}>
              <p
                style={{ fontFamily: "var(--font-mono)", fontSize: "13px", fontWeight: 700, letterSpacing: "0.15em", textTransform: "uppercase", color: "var(--text-primary)", margin: "0 0 24px 0" }}
              >
                {label}
              </p>
              <ul style={{ listStyle: "none", margin: 0, padding: 0, display: "flex", flexDirection: "column", gap: "16px" }}>
                {links.map(({ text, href }) => (
                  <li key={text}>
                    <a
                      href={href}
                      className="group relative inline-flex overflow-hidden rounded-sm focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-2"
                      style={{ fontFamily: "var(--font-body)", fontSize: "14px", fontWeight: 500, color: "var(--text-secondary)", textDecoration: "none" }}
                    >
                      <span className="inline-block transition-transform duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] group-hover:-translate-y-[110%]">
                        {text}
                      </span>
                      <span aria-hidden="true" className="absolute left-0 top-0 inline-block transition-transform duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] translate-y-[110%] group-hover:translate-y-0 text-[var(--text-primary)] font-semibold">
                        {text}
                      </span>
                    </a>
                  </li>
                ))}
              </ul>
            </nav>
          ))}
        </div>
      </div>

      {/* ── Animated Brand Text ── */}
      <div className="w-full overflow-hidden flex justify-center pb-12 pt-8 pointer-events-none select-none">
         <motion.h1 
            className="text-[11.5vw] leading-none m-0 font-black tracking-[-0.05em] whitespace-nowrap bg-[linear-gradient(90deg,rgba(0,87,230,0.9)_0%,rgba(56,189,248,1)_16%,rgba(30,28,26,0.15)_33%,rgba(0,87,230,0.9)_50%,rgba(56,189,248,1)_66%,rgba(30,28,26,0.15)_83%,rgba(0,87,230,0.9)_100%)] dark:bg-[linear-gradient(90deg,rgba(34,78,238,0.9)_0%,rgba(56,189,248,1)_16%,rgba(255,255,255,0.1)_33%,rgba(34,78,238,0.9)_50%,rgba(56,189,248,1)_66%,rgba(255,255,255,0.1)_83%,rgba(34,78,238,0.9)_100%)] bg-[length:200%_100%]"
            style={{ 
              fontFamily: "'Plus Jakarta Sans', var(--font-body), sans-serif",
              backgroundPositionX: bgPosition,
              x: textX,
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "var(--bg-card)",
              WebkitTextStroke: "0.025em transparent"
            }}
         >
            Coral Health AI
         </motion.h1>
      </div>
      {/* ── Bottom bar ── */}
      <div style={{ borderTop: "1px solid var(--border-base)", background: "var(--bg-alt)", transition: "background-color 250ms ease" }}>
        <div
          className="mx-auto flex flex-col sm:flex-row items-center justify-between"
          style={{ maxWidth: "1264px", padding: "16px 48px", gap: "12px" }}
        >
          <p
            style={{ fontFamily: "var(--font-mono)", fontSize: "12px", fontWeight: 500, color: "var(--text-secondary)", margin: 0, letterSpacing: "0.02em" }}
          >
            Copyright 2026 Coral Health AI Initiative. Built for marine conservation.
          </p>
          <div style={{ display: "flex", alignItems: "center", gap: "6px", flexWrap: "wrap" as const, justifyContent: "flex-end" }}>
            <span style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "var(--text-secondary)", letterSpacing: "0.03em" }}>
              Powered by
            </span>
            {["EfficientNet-B0", "5-Seed SWA", "Grad-CAM", "React + Vite"].map((item) => (
              <span
                key={item}
                style={{ fontFamily: "var(--font-mono)", fontSize: "12px", fontWeight: 600, color: "var(--text-secondary)", background: "var(--bg-chip)", borderRadius: "4px", padding: "4px 8px", whiteSpace: "nowrap" as const }}
              >
                {item}
              </span>
            ))}
          </div>
        </div>
      </div>
    </footer>
  );
}
