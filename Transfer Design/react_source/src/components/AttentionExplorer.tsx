import { useState, useEffect, useId } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { AnimatedFocusBlur } from "./ui";

/* ── Step metadata ── */
const STEPS = [
  {
    num: "01",
    title: "Forward Pass",
    subtitle: "Produces Aᵏ maps",
    desc: "The input image propagates through every convolutional block. Each layer outputs intermediate activation maps Aᵏ capturing spatial features at increasing abstraction.",
    formulaLabel: "Aᵏ ∈ ℝ^(H×W×K)",
  },
  {
    num: "02",
    title: "Backpropagation",
    subtitle: "Trace gradient arrows",
    desc: "The target class score yᶜ is backpropagated through the final convolutional layer. Each gradient ∂yᶜ/∂Aᵏᵢⱼ records how much that unit influenced the prediction.",
    formulaLabel: "∂yᶜ / ∂Aᵏᵢⱼ",
  },
  {
    num: "03",
    title: "Pool αᵏ",
    subtitle: "Global Average Pooling",
    desc: "Global average pooling converts each gradient map into a scalar importance weight αᵏᶜ. A larger α signals that the corresponding feature map was highly relevant to the class decision.",
    formulaLabel: "αᶜᵏ = (1/Z) Σᵢ Σⱼ (∂yᶜ / ∂Aᵏᵢⱼ)",
  },
  {
    num: "04",
    title: "Heatmap + ReLU",
    subtitle: "Merge into colormap",
    desc: "A weighted sum of the activation maps is computed, then passed through ReLU to suppress negative activations. The result is an attention heatmap localizing the coral features driving the classification.",
    formulaLabel: "Lᶜ = ReLU( Σᵏ αᶜᵏ · Aᵏ )",
  },
] as const;

/* ── SVG Canvas scenes ── */
function CanvasScene({ step, dark }: { step: number; dark: boolean }) {
  // Feature map grid cells (4×4)
  const fmOpacities = [0.9, 0.5, 0.7, 0.4, 0.6, 0.85, 0.35, 0.9, 0.5, 0.7, 0.9, 0.6, 0.8, 0.4, 0.65, 0.75];
  const layerCols = [230, 350, 470];
  const nodeRows = [175, 205, 230, 255, 285];

  // WCAG AA theme-aware contrast colors for SVG texts and indicators
  const labelColorGreen = dark ? "#34D399" : "#065F46"; // Green labels
  const labelColorAmber = dark ? "#FBBF24" : "#92400E"; // Amber labels
  const activeGreen = dark ? "#10B981" : "#047857";
  const activeAmber = dark ? "#F59E0B" : "#B45309";
  const mutedText = dark ? "#94A3B8" : "#334155";
  const structuralFill = dark ? "#10B981" : "#047857";
  const boxFill = dark ? "#1E293B" : "#FFFFFF";
  const boxBorder = dark ? "#10B981" : "#065F46";

  // Helper to blend any hex color with a background to produce a perfect solid color
  const getSolidAmber = (baseHex: string, intensity: number, isDark: boolean) => {
    const clean = baseHex.replace("#", "");
    const num = parseInt(clean, 16);
    const r = (num >> 16) & 255;
    const g = (num >> 8) & 255;
    const b = num & 255;

    if (isDark) {
      // Dark Mode background is #0F172A.
      // To prevent green-murkiness, we blend with a warm dark charcoal #1E1A16 (30, 26, 22).
      const bgR = 30;
      const bgG = 26;
      const bgB = 22;
      const blendedR = Math.round(intensity * r + (1 - intensity) * bgR);
      const blendedG = Math.round(intensity * g + (1 - intensity) * bgG);
      const blendedB = Math.round(intensity * b + (1 - intensity) * bgB);
      return `#${((1 << 24) + (blendedR << 16) + (blendedG << 8) + blendedB).toString(16).slice(1)}`;
    } else {
      // Light Mode background is #F9FAF6.
      // To prevent muddy/dusty brown tones, we blend with a warm light cream #FFFDF9.
      const bgR = 255;
      const bgG = 253;
      const bgB = 249;
      const blendedR = Math.round(intensity * r + (1 - intensity) * bgR);
      const blendedG = Math.round(intensity * g + (1 - intensity) * bgG);
      const blendedB = Math.round(intensity * b + (1 - intensity) * bgB);
      return `#${((1 << 24) + (blendedR << 16) + (blendedG << 8) + blendedB).toString(16).slice(1)}`;
    }
  };

  const getSolidGreen = (baseHex: string, intensity: number, isDark: boolean) => {
    const clean = baseHex.replace("#", "");
    const num = parseInt(clean, 16);
    const r = (num >> 16) & 255;
    const g = (num >> 8) & 255;
    const b = num & 255;

    if (isDark) {
      // Dark Mode background is #0F172A.
      // We blend with a dark pine #0C1E1A (12, 30, 26) to make the low-intensity green glow like neon!
      const bgR = 12;
      const bgG = 30;
      const bgB = 26;
      const blendedR = Math.round(intensity * r + (1 - intensity) * bgR);
      const blendedG = Math.round(intensity * g + (1 - intensity) * bgG);
      const blendedB = Math.round(intensity * b + (1 - intensity) * bgB);
      return `#${((1 << 24) + (blendedR << 16) + (blendedG << 8) + blendedB).toString(16).slice(1)}`;
    } else {
      // Light Mode background is #F9FAF6.
      // We blend with a very light mint-white #F2FAF6 (242, 250, 246) to keep it clean and crisp.
      const bgR = 242;
      const bgG = 250;
      const bgB = 246;
      const blendedR = Math.round(intensity * r + (1 - intensity) * bgR);
      const blendedG = Math.round(intensity * g + (1 - intensity) * bgG);
      const blendedB = Math.round(intensity * b + (1 - intensity) * bgB);
      return `#${((1 << 24) + (blendedR << 16) + (blendedG << 8) + blendedB).toString(16).slice(1)}`;
    }
  };

  return (
    <svg
      viewBox="0 0 800 450"
      preserveAspectRatio="xMidYMid meet"
      style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }}
      aria-hidden="true"
    >
      <defs>
        <pattern id="cvGrid" width="40" height="40" patternUnits="userSpaceOnUse">
          <path
            d="M 40 0 L 0 0 0 40"
            fill="none"
            stroke={dark ? "rgba(16,185,129,0.06)" : "rgba(6,95,70,0.06)"}
            strokeWidth="0.5"
          />
        </pattern>
        <marker id="aGreen" markerWidth="7" markerHeight="5" refX="6" refY="2.5" orient="auto">
          <polygon points="0 0, 7 2.5, 0 5" fill={dark ? "#10B981" : "#065F46"} />
        </marker>
        <marker id="aAmber" markerWidth="7" markerHeight="5" refX="6" refY="2.5" orient="auto">
          <polygon points="0 0, 7 2.5, 0 5" fill={dark ? "#F59E0B" : "#92400E"} />
        </marker>
        <radialGradient id="heat1" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#F59E0B" stopOpacity="0.95" />
          <stop offset="55%" stopColor="#FBBF24" stopOpacity="0.6" />
          <stop offset="100%" stopColor="#F59E0B" stopOpacity="0" />
        </radialGradient>
        <radialGradient id="heat2" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#F59E0B" stopOpacity="0.75" />
          <stop offset="100%" stopColor="#F59E0B" stopOpacity="0" />
        </radialGradient>
        <linearGradient id="csBar" x1="0" x2="1" y1="0" y2="0">
          <stop offset="0%" stopColor="#10B981" />
          <stop offset="100%" stopColor="#F59E0B" />
        </linearGradient>
      </defs>

      {/* Background */}
      <rect width="800" height="450" fill={dark ? "#0F172A" : "#F9FAF6"} style={{ transition: "fill 300ms ease" }} />
      <rect width="800" height="450" fill="url(#cvGrid)" />

      {/* ── Scene 0: Forward Pass ── */}
      {step === 0 && (
        <g>
          <text x="400" y="28" textAnchor="middle" fill={labelColorGreen}
            fontFamily="var(--font-mono)" fontSize="12" fontWeight="700" letterSpacing="2">
            STEP 01 · FORWARD PASS
          </text>
          {/* Input box */}
          <rect x="40" y="175" width="90" height="100" rx="8"
            fill={boxFill} stroke={boxBorder} strokeWidth="1.5" />
          <rect x="54" y="189" width="24" height="24" rx="3" fill="#c97c3e" opacity="0.85" />
          <rect x="82" y="189" width="24" height="24" rx="3" fill="#5a9e62" opacity="0.85" />
          <rect x="54" y="217" width="24" height="24" rx="3" fill="#d8d0c0" opacity="0.85" />
          <rect x="82" y="217" width="24" height="24" rx="3" fill="#3d4a5a" opacity="0.85" />
          <text x="85" y="294" textAnchor="middle" fill={mutedText}
            fontFamily="var(--font-mono)" fontSize="9" fontWeight="600" letterSpacing="2">INPUT</text>
          {/* Arrow: input → layers */}
          <path d="M 133 225 L 208 225" stroke={activeGreen} strokeWidth="2"
            markerEnd="url(#aGreen)" />
          {/* Conv layer columns */}
          {layerCols.map((cx, ci) => (
            <g key={ci}>
              {nodeRows.map((cy, ri) => (
                <circle key={ri} cx={cx} cy={cy} r="5.5"
                  fill={getSolidGreen(structuralFill, 0.4 + ri * 0.12, dark)} />
              ))}
              {ci < 2 && (
                <path d={`M ${cx + 7} 230 L ${layerCols[ci + 1] - 7} 230`}
                  stroke={dark ? "rgba(16,185,129,0.3)" : "rgba(6,95,70,0.3)"} strokeWidth="1.5" strokeDasharray="4 3"
                  markerEnd="url(#aGreen)" />
              )}
            </g>
          ))}
          <text x="350" y="320" textAnchor="middle" fill={labelColorGreen}
            fontFamily="var(--font-mono)" fontSize="9" fontWeight="600" letterSpacing="2">CONV LAYERS</text>
          {/* Arrow: layers → feature maps */}
          <path d="M 480 225 L 542 225" stroke={activeGreen} strokeWidth="2"
            markerEnd="url(#aGreen)" />
          {/* Feature maps 4×4 */}
          {fmOpacities.map((op, i) => {
            const col = i % 4;
            const row = Math.floor(i / 4);
            return (
              <rect key={i} x={550 + col * 32} y={157 + row * 32}
                width="28" height="28" rx="3" fill={getSolidAmber("#F59E0B", op, dark)} />
            );
          })}
          <text x="614" y="146" textAnchor="middle" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="11" fontWeight="700" letterSpacing="1">A^k</text>
          <text x="614" y="298" textAnchor="middle" fill={mutedText}
            fontFamily="var(--font-mono)" fontSize="9" fontWeight="600" letterSpacing="2">FEATURE MAPS</text>
          <text x="400" y="426" textAnchor="middle" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="13" fontWeight="700" letterSpacing="0.5">
            A^k  ∈  ℝ^(H × W × K)
          </text>
        </g>
      )}

      {/* ── Scene 1: Backpropagation ── */}
      {step === 1 && (
        <g>
          <text x="400" y="28" textAnchor="middle" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="12" fontWeight="700" letterSpacing="2">
            STEP 02 · BACKPROPAGATION
          </text>
          {/* Input box — dimmed */}
          <rect x="40" y="175" width="90" height="100" rx="8"
            fill={dark ? "#131C2E" : "#F1F5F9"} stroke={dark ? "rgba(16,185,129,0.15)" : "rgba(6,95,70,0.15)"} strokeWidth="1" />
          {[189, 217].map((y) =>
            [54, 82].map((x) => (
              <rect key={`${x}${y}`} x={x} y={y} width="24" height="24" rx="3" fill={dark ? "#1E293B" : "#CBD5E1"} opacity="0.35" />
            ))
          )}
          {/* Target class badge */}
          <rect x="538" y="100" width="185" height="26" rx="6"
            fill={dark ? "rgba(245,158,11,0.12)" : "rgba(245,158,11,0.06)"} stroke={activeAmber} strokeWidth="1.5" />
          <text x="630" y="117" textAnchor="middle" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="11" fontWeight="700" letterSpacing="0.5">y^c = Bleached</text>
          {/* Feature maps — Vivid Amber family */}
          {fmOpacities.map((op, i) => {
            const col = i % 4;
            const row = Math.floor(i / 4);
            const amberShades = ["#F59E0B", "#FBBF24", "#D97706", "#F59E0B"];
            return (
              <rect key={i} x={550 + col * 32} y={157 + row * 32}
                width="28" height="28" rx="3" fill={getSolidAmber(amberShades[col], op * 0.95, dark)} />
            );
          })}
          <text x="614" y="298" textAnchor="middle" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="9" fontWeight="600" letterSpacing="2">∂y^c/∂A^k_ij</text>
          {/* Conv layers — warm active signal flow */}
          {layerCols.map((cx, ci) => (
            <g key={ci}>
              {nodeRows.map((cy, ri) => (
                <circle key={ri} cx={cx} cy={cy} r="5.5"
                  fill={getSolidAmber("#F59E0B", 0.4 + ri * 0.12, dark)} />
              ))}
              {ci > 0 && (
                <path d={`M ${cx - 7} 230 L ${layerCols[ci - 1] + 7} 230`}
                  stroke={activeAmber} strokeWidth="2"
                  markerEnd="url(#aAmber)" />
              )}
            </g>
          ))}
          {/* Backward arrow: feature maps → layers */}
          <path d="M 545 225 L 482 225" stroke={activeAmber} strokeWidth="2"
            markerEnd="url(#aAmber)" />
          {/* Backward arrow: layers → input */}
          <path d="M 223 225 L 138 225" stroke={dark ? "rgba(245,158,11,0.5)" : "rgba(146,64,14,0.5)"} strokeWidth="1.5"
            markerEnd="url(#aAmber)" />
          <text x="350" y="320" textAnchor="middle" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="9" fontWeight="600" letterSpacing="2">GRADIENT FLOW ←</text>
          <text x="400" y="426" textAnchor="middle" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="13" fontWeight="700" letterSpacing="0.5">
            ∂y^c / ∂A^k_ij
          </text>
        </g>
      )}

      {/* ── Scene 2: Pool alpha_k ── */}
      {step === 2 && (
        <g>
          <text x="400" y="28" textAnchor="middle" fill={labelColorGreen}
            fontFamily="var(--font-mono)" fontSize="12" fontWeight="700" letterSpacing="2">
            STEP 03 · POOL α^k
          </text>
          {/* Small feature maps left */}
          {fmOpacities.map((op, i) => {
            const col = i % 4;
            const row = Math.floor(i / 4);
            return (
              <rect key={i} x={40 + col * 30} y={157 + row * 30}
                width="26" height="26" rx="3" fill={getSolidAmber("#F59E0B", op, dark)} />
            );
          })}
          <text x="100" y="298" textAnchor="middle" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="9" fontWeight="600" letterSpacing="2">A^k MAPS</text>
          {/* Converging arrows to GAP box */}
          {[170, 200, 245, 275].map((y) => (
            <path key={y} d={`M 162 ${y} L 275 230`}
              stroke={dark ? "rgba(16,185,129,0.3)" : "rgba(6,95,70,0.3)"} strokeWidth="1" />
          ))}
          {/* GAP box */}
          <rect x="280" y="193" width="120" height="64" rx="8"
            fill={dark ? "rgba(16,185,129,0.12)" : "rgba(6,95,70,0.06)"} stroke={activeGreen} strokeWidth="2" />
          <text x="340" y="222" textAnchor="middle" fill={labelColorGreen}
            fontFamily="var(--font-mono)" fontSize="12" fontWeight="700" letterSpacing="1">GAP</text>
          <text x="340" y="242" textAnchor="middle" fill={mutedText}
            fontFamily="var(--font-mono)" fontSize="10" fontWeight="600">(1/Z) Σᵢⱼ</text>
          {/* Arrow GAP → alpha bars */}
          <path d="M 403 225 L 445 225" stroke={activeGreen} strokeWidth="2"
            markerEnd="url(#aGreen)" />
          {/* Alpha weight bars — 8 bars */}
          {[0.73, 0.88, 0.45, 0.61, 0.92, 0.38, 0.55, 0.79].map((w, i) => {
            const y = 140 + i * 24;
            const maxBarW = 200;
            return (
              <g key={i}>
                <text x="452" y={y + 14} fill={labelColorAmber}
                  fontFamily="var(--font-mono)" fontSize="11" fontWeight="600">α{i + 1}</text>
                <rect x="476" y={y + 2} width={w * maxBarW} height="14" rx="3"
                  fill={getSolidAmber("#F59E0B", 0.4 + w * 0.55, dark)} />
                <text x={480 + w * maxBarW} y={y + 14} fill={labelColorAmber}
                  fontFamily="var(--font-mono)" fontSize="10" fontWeight="700"> {w.toFixed(2)}</text>
              </g>
            );
          })}
          <text x="340" y="320" textAnchor="middle" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="9" fontWeight="600" letterSpacing="2">IMPORTANCE WEIGHTS</text>
          <text x="400" y="426" textAnchor="middle" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="11" fontWeight="700" letterSpacing="0.3">
            α^c_k = (1/Z) Σᵢ Σⱼ ( ∂y^c / ∂A^k_ij )
          </text>
        </g>
      )}

      {/* ── Scene 3: Heatmap + ReLU ── */}
      {step === 3 && (
        <g>
          <text x="400" y="28" textAnchor="middle" fill={labelColorGreen}
            fontFamily="var(--font-mono)" fontSize="12" fontWeight="700" letterSpacing="2">
            STEP 04 · HEATMAP + ReLU
          </text>
          {/* Original image frame */}
          <rect x="40" y="95" width="300" height="255" rx="10"
            fill={boxFill} stroke={dark ? "rgba(16,185,129,0.3)" : "rgba(6,95,70,0.3)"} strokeWidth="1.5" />
          <ellipse cx="135" cy="220" rx="52" ry="38" fill={dark ? "#162E25" : "#E2E8F0"} opacity="0.85" />
          <ellipse cx="255" cy="195" rx="42" ry="28" fill={dark ? "#1E3A2F" : "#CBD5E1"} opacity="0.75" />
          <ellipse cx="210" cy="272" rx="58" ry="22" fill={dark ? "#224235" : "#94A3B8"} opacity="0.9" />
          <text x="190" y="372" textAnchor="middle" fill={mutedText}
            fontFamily="var(--font-mono)" fontSize="9" fontWeight="600" letterSpacing="2">ORIGINAL</text>
          {/* Arrow between panels */}
          <path d="M 352 225 L 406 225" stroke={activeGreen} strokeWidth="2.5"
            markerEnd="url(#aGreen)" />
          {/* Heatmap frame */}
          <rect x="420" y="95" width="338" height="255" rx="10"
            fill={boxFill} stroke={boxBorder} strokeWidth="2" />
          {/* Heatmap hotspots */}
          <ellipse cx="540" cy="200" rx="78" ry="60" fill="url(#heat1)" />
          <ellipse cx="660" cy="255" rx="55" ry="44" fill="url(#heat2)" />
          <ellipse cx="485" cy="278" rx="44" ry="32" fill="url(#heat2)" opacity="0.6" />
          {/* ReLU badge */}
          <rect x="648" y="105" width="80" height="24" rx="6"
            fill={dark ? "rgba(245,158,11,0.15)" : "rgba(245,158,11,0.06)"} stroke={activeAmber} strokeWidth="1.5" />
          <text x="688" y="121" textAnchor="middle" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="10" fontWeight="700" letterSpacing="1">ReLU</text>
          <text x="589" y="372" textAnchor="middle" fill={mutedText}
            fontFamily="var(--font-mono)" fontSize="9" fontWeight="600" letterSpacing="2">GRAD-CAM HEATMAP</text>
          {/* Color scale legend (overlay inside bottom-left of the Heatmap card) */}
          <rect x="436" y="322" width="100" height="8" rx="4" fill="url(#csBar)" />
          <text x="436" y="338" fill={labelColorGreen}
            fontFamily="var(--font-mono)" fontSize="8" fontWeight="600">LOW</text>
          <text x="536" y="338" textAnchor="end" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="8" fontWeight="700">HIGH</text>
          <text x="400" y="426" textAnchor="middle" fill={labelColorAmber}
            fontFamily="var(--font-mono)" fontSize="13" fontWeight="700" letterSpacing="0.5">
            L^c = ReLU( Σ_k  α^c_k · A^k )
          </text>
        </g>
      )}
    </svg>
  );
}

/* ── Playback icon buttons ── */
function PbBtn({
  label,
  onClick,
  active,
  dark,
  children,
}: {
  label: string;
  onClick: () => void;
  active?: boolean;
  dark: boolean;
  children: React.ReactNode;
}) {
  // Dynamic contrast colors for the button
  const bg = active
    ? (dark ? "rgba(245,158,11,0.18)" : "#FFF8E1")
    : (dark ? "#1E293B" : "#ffffff");
  const border = active
    ? (dark ? "#F59E0B" : "#D97706")
    : "var(--border-subtle)";
  const color = active
    ? (dark ? "#FBBF24" : "#D97706")
    : "var(--text-secondary)";

  return (
    <button
      type="button"
      aria-label={label}
      onClick={onClick}
      style={{
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        width: "36px",
        height: "36px",
        minWidth: "36px",
        minHeight: "36px",
        padding: "0",
        background: bg,
        border: `1px solid ${border}`,
        borderRadius: "8px",
        color: color,
        cursor: "pointer",
        transition: "all 150ms ease",
        fontFamily: "var(--font-body)",
        fontSize: "13px",
        fontWeight: 500,
        gap: "0",
      }}
      className="hover:bg-[var(--bg-chip)] focus-visible:ring-2 focus-visible:ring-[#F59E0B] focus-visible:ring-offset-1"
      onMouseEnter={(e) => {
        if (!active) (e.currentTarget as HTMLButtonElement).style.background = "var(--bg-chip)";
      }}
      onMouseLeave={(e) => {
        (e.currentTarget as HTMLButtonElement).style.background = bg;
      }}
    >
      {children}
    </button>
  );
}

/* ── Math formula panel ── */
const MATH_STEPS = [
  {
    label: "Step 1 · Forward Pass",
    formula: "Aᵏ ∈ ℝ^(H × W × K)",
  },
  {
    label: "Step 2 · Backpropagation",
    formula: "∂yᶜ / ∂Aᵏᵢⱼ",
  },
  {
    label: "Step 3 · Pool αᵏ",
    formula: "αᶜᵏ = (1/Z) Σᵢ Σⱼ ( ∂yᶜ / ∂Aᵏᵢⱼ )",
  },
  {
    label: "Step 4 · Heatmap + ReLU",
    formula: "Lᶜ = ReLU( Σᵏ αᶜᵏ · Aᵏ )",
  },
];

/* ── Main export ── */
export default function AttentionExplorer({ dark: propDark, sectionId = "gradcam-3d" }: { dark?: boolean; sectionId?: string }) {
  const [step, setStep] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [mathOpen, setMathOpen] = useState(true);
  const mathId = useId();

  // Internal state that synchronizes with DOM element class if prop isn't passed
  const [localDark, setLocalDark] = useState(() => {
    if (typeof window !== "undefined") {
      return document.documentElement.classList.contains("dark");
    }
    return false;
  });

  useEffect(() => {
    if (propDark === undefined) {
      setLocalDark(document.documentElement.classList.contains("dark"));

      const observer = new MutationObserver(() => {
        setLocalDark(document.documentElement.classList.contains("dark"));
      });
      observer.observe(document.documentElement, { attributes: true, attributeFilter: ["class"] });
      return () => observer.disconnect();
    }
  }, [propDark]);

  const dark = propDark !== undefined ? propDark : localDark;

  useEffect(() => {
    if (!isPlaying) return;
    const id = setInterval(() => {
      setStep((s) => {
        if (s >= 3) {
          setIsPlaying(false);
          return s;
        }
        return s + 1;
      });
    }, 2400);
    return () => clearInterval(id);
  }, [isPlaying]);

  const prev = () => setStep((s) => Math.max(0, s - 1));
  const next = () => setStep((s) => Math.min(3, s + 1));
  const reset = () => { setStep(0); setIsPlaying(false); };
  const togglePlay = () => {
    if (step >= 3) { setStep(0); setIsPlaying(true); return; }
    setIsPlaying((v) => !v);
  };

  const currentStep = STEPS[step];

  // Dynamic colors matching Emerald Green and Vivid Amber with proper WCAG AA contrast
  const accentColor = (step === 0 || step === 2)
    ? (dark ? "#34D399" : "#047857") // Structural (Green)
    : (dark ? "#F59E0B" : "#92400E"); // Active (Amber)

  return (
    <section
      id={sectionId}
      aria-labelledby="explorer-heading"
      style={{
        background: dark ? "var(--bg-card)" : "var(--bg-alt)",
        paddingTop: "var(--section-space-lg)",
        paddingBottom: "var(--section-space-lg)",
        transition: "background-color 250ms ease",
        borderTop: "1px solid var(--border-base)",
      }}
    >
      <div
        className="mx-auto"
        style={{ maxWidth: "1264px", paddingLeft: "clamp(12px, 6vw, 48px)", paddingRight: "clamp(12px, 6vw, 48px)" }}
      >
        {/* Section intro */}
        <div style={{ display: "flex", flexDirection: "column", gap: "16px", marginBottom: "40px", maxWidth: "600px" }}>
          <div className="flex items-center" style={{ display: "none", gap: "12px" }}>
            <span style={{ display: "inline-block", width: "32px", height: "2px", background: "#10B981", borderRadius: "999px", flexShrink: 0 }} aria-hidden="true" />
            <span style={{ fontFamily: "var(--font-mono)", fontSize: "11px", fontWeight: 600, letterSpacing: "0.12em", textTransform: "uppercase" as const, color: "#10B981" }}>
              07 — Grad-CAM Explorer
            </span>
          </div>
          <h2 id="explorer-heading" style={{ fontFamily: "var(--font-display)", fontSize: "var(--text-section)", fontWeight: 700, lineHeight: "var(--leading-section)", letterSpacing: "var(--tracking-section)", color: "var(--text-primary)", margin: 0, overflowWrap: "anywhere" }}>
            How Grad-CAM Explainability Works
          </h2>
          <p style={{ fontFamily: "var(--font-body)", fontSize: "var(--text-body)", lineHeight: "var(--leading-body)", color: "var(--text-secondary)", margin: 0, maxWidth: "var(--measure-prose)" }}>
            Step through the four-stage Grad-CAM pipeline — from feature extraction to localized heatmap output. Each stage shows which spatial regions drove the coral health classification.
          </p>
        </div>

        {/* Stacked interactive container */}
        <div style={{ display: "flex", flexDirection: "column", gap: "24px", width: "100%" }}>

          {/* SVG Canvas Container - Full Width */}
          <div style={{ width: "100%", minWidth: 0 }}>
            {/* 16:9 Canvas */}
            <div
              role="img"
              aria-label={`Grad-CAM visualization: ${currentStep.title} — ${currentStep.subtitle}`}
              style={{
                position: "relative",
                aspectRatio: "16 / 9",
                borderRadius: "16px",
                overflow: "hidden",
                background: dark ? "#0F172A" : "#F9FAF6",
                boxShadow: dark
                  ? "0 16px 40px -8px rgba(16, 185, 129, 0.15), 0 4px 16px -4px rgba(15, 23, 42, 0.5)"
                  : "0 16px 40px -8px rgba(6, 95, 70, 0.1), 0 4px 16px -4px rgba(6, 95, 70, 0.05)",
                border: dark ? "1px solid rgba(255,255,255,0.1)" : "2px solid #065F46",
                transition: "all 300ms ease",
              }}
            >
              <AnimatePresence mode="wait">
                <motion.div
                  key={step}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  transition={{ duration: 0.35, ease: "easeInOut" }}
                  style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }}
                >
                  <CanvasScene step={step} dark={dark} />
                </motion.div>
              </AnimatePresence>
            </div>
          </div>

          {/* Centered Timeline Progress Indicator with mathematically equidistant nodes */}
          <div style={{ display: "flex", justifyContent: "center", width: "100%", marginTop: "8px" }}>
            <div
              style={{
                position: "relative",
                width: "100%",
                maxWidth: "800px",
                padding: "0 14px",
                height: "64px",
              }}
              role="tablist"
              aria-label="Pipeline steps"
            >
              {/* Background Track Line */}
              <div
                aria-hidden="true"
                style={{
                  position: "absolute",
                  top: "16px",
                  left: "16px",
                  right: "16px",
                  height: "2px",
                  background: dark ? "rgba(56, 189, 248, 0.15)" : "rgba(0, 87, 230, 0.15)",
                  zIndex: 1,
                }}
              />

              {/* Active Filled Progress Line */}
              <div
                aria-hidden="true"
                style={{
                  position: "absolute",
                  top: "16px",
                  left: "16px",
                  width: `calc((${step} / 3) * (100% - 32px))`,
                  height: "2px",
                  background: dark ? "#38bdf8" : "#0057e6",
                  boxShadow: dark ? "0 0 12px rgba(56, 189, 248, 0.8)" : "0 0 8px rgba(0, 87, 230, 0.4)",
                  zIndex: 2,
                  transition: "width 400ms cubic-bezier(0.22, 1, 0.36, 1)",
                }}
              />

              {/* Step Nodes Row */}
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  position: "relative",
                  zIndex: 3,
                }}
              >
                {STEPS.map((s, i) => {
                  const isActive = i === step;
                  const isDone = i < step;

                  const cyanColor = dark ? "#38bdf8" : "#0057e6";
                  const faintBorder = dark ? "rgba(255,255,255,0.12)" : "var(--border-base)";

                  const pillBorder = isActive
                    ? cyanColor
                    : isDone
                    ? cyanColor
                    : faintBorder;

                  const pillBg = isActive
                    ? cyanColor
                    : (dark ? "#121620" : "#ffffff");

                  const pillShadow = isActive
                    ? (dark ? "0 0 16px rgba(56, 189, 248, 0.4)" : "0 0 12px rgba(0, 87, 230, 0.3)")
                    : "none";

                  const nodeTextColor = isActive
                    ? (dark ? "#0f172a" : "#ffffff")
                    : isDone
                    ? cyanColor
                    : (dark ? "#8ba3b8" : "#64748b");

                  return (
                    <div
                      key={s.num}
                      style={{
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                        position: "relative",
                        width: "32px",
                      }}
                    >
                      <button
                        type="button"
                        role="tab"
                        aria-selected={isActive}
                        aria-label={`Step ${s.num}: ${s.title}`}
                        onClick={() => {
                          setIsPlaying(false);
                          setStep(i);
                        }}
                        style={{
                          width: "32px",
                          height: "32px",
                          borderRadius: "50%",
                          background: pillBg,
                          border: `2px solid ${pillBorder}`,
                          boxShadow: pillShadow,
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          cursor: "pointer",
                          transition: "all 300ms ease",
                          padding: 0,
                          boxSizing: "border-box",
                        }}
                        className="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#38bdf8] focus-visible:ring-offset-2 rounded-full"
                      >
                        <span style={{ 
                          fontFamily: "var(--font-mono)", 
                          fontSize: "11px", 
                          fontWeight: 700, 
                          color: nodeTextColor,
                          transition: "color 300ms ease"
                        }}>
                          {s.num}
                        </span>
                      </button>
                      
                      {/* Technical Readout Labels underneath */}
                      <div
                        style={{
                          position: "absolute",
                          top: "42px",
                          left: "50%",
                          transform: "translateX(-50%)",
                          display: "flex",
                          flexDirection: "column",
                          alignItems: "center",
                          gap: "6px",
                          whiteSpace: "nowrap",
                        }}
                      >
                        <span
                          style={{
                            fontFamily: "var(--font-mono)",
                            fontSize: "11px",
                            fontWeight: 600,
                            textTransform: "uppercase",
                            letterSpacing: "0.12em",
                            color: isActive
                              ? cyanColor
                              : (dark ? "#607386" : "#64748b"),
                            textShadow: isActive && dark ? `0 0 8px rgba(56,189,248,0.4)` : "none",
                            transition: "all 300ms ease",
                          }}
                        >
                          {s.title}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Centered Playback controls directly below Timeline */}
          {/* Centered Playback controls directly below Timeline - Sleek Floating Pill */}
          <div style={{ display: "flex", justifyContent: "center", width: "100%", marginTop: "12px", marginBottom: "16px" }}>
            <div
              className="flex items-center justify-center"
              style={{
                gap: "16px",
                padding: "8px 24px",
                background: "var(--bg-alt)",
                border: "1px solid var(--border-base)",
                borderRadius: "999px",
                boxShadow: dark
                  ? "0 4px 12px rgba(0,0,0,0.15)"
                  : "0 4px 12px rgba(0,0,0,0.03)",
                width: "fit-content",
                display: "inline-flex",
              }}
            >
              {/* Step counter indicator */}
              <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                <span style={{
                  fontFamily: "var(--font-mono)",
                  fontSize: "11px",
                  fontWeight: 700,
                  color: accentColor,
                  background: (step === 0 || step === 2)
                    ? (dark ? "rgba(52,211,153,0.15)" : "#E6F4EA")
                    : (dark ? "rgba(245,158,11,0.15)" : "#FFF8E1"),
                  padding: "2px 8px",
                  borderRadius: "999px",
                  transition: "all 200ms ease",
                }}>
                  {step + 1} / 4
                </span>
                <span style={{ fontFamily: "var(--font-body)", fontSize: "12px", fontWeight: 600, color: "var(--text-muted)" }}>
                  Step
                </span>
              </div>

              {/* Vertical divider */}
              <div aria-hidden="true" style={{ width: "1px", height: "18px", background: "var(--border-subtle)" }} />

              {/* Playback Buttons Group */}
              <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                <PbBtn label="Previous step" onClick={prev} dark={dark}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="m15 18-6-6 6-6" /></svg>
                </PbBtn>
                <PbBtn label={isPlaying ? "Pause" : "Play"} onClick={togglePlay} active={isPlaying} dark={dark}>
                  {isPlaying ? (
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="14" y="4" width="4" height="16" rx="1" /><rect x="6" y="4" width="4" height="16" rx="1" /></svg>
                  ) : (
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polygon points="6 3 20 12 6 21 6 3" /></svg>
                  )}
                </PbBtn>
                <PbBtn label="Next step" onClick={next} dark={dark}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="m9 18 6-6-6-6" /></svg>
                </PbBtn>
                <PbBtn label="Reset to step 1" onClick={reset} dark={dark}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8" /><path d="M3 3v5h5" /></svg>
                </PbBtn>
              </div>
            </div>
          </div>

          {/* Stacked Landscape Panels: Active Step Details + Full Formula Breakdown */}
          <div style={{ display: "flex", flexDirection: "column", gap: "20px", width: "100%", marginTop: "8px" }}>
            
            {/* Current step detail card - Full Width Landscape */}
            <div style={{ background: "var(--bg-alt)", border: "1px solid var(--border-subtle)", borderRadius: "16px", padding: "24px", display: "flex", flexDirection: "column" }}>
              <AnimatePresence mode="wait">
                <motion.div
                  key={step}
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -8 }}
                  transition={{ duration: 0.25, ease: "easeInOut" }}
                  className="grid grid-cols-1 md:grid-cols-3 gap-6"
                  style={{ width: "100%" }}
                >
                  {/* Left side: Badge, Title, and Formula (1/3 width) */}
                  <div className="md:col-span-1 flex flex-col gap-4">
                    <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                      <span style={{
                        background: dark ? "rgba(16,185,129,0.15)" : "#E6F4EA",
                        color: dark ? "#34D399" : "#047857",
                        borderRadius: "999px",
                        padding: "4px 12px",
                        fontFamily: "var(--font-mono)",
                        fontSize: "12px",
                        fontWeight: 700
                      }}>
                        {currentStep.num}
                      </span>
                      <span style={{ fontFamily: "var(--font-body)", fontSize: "16px", fontWeight: 700, color: "var(--text-primary)" }}>
                        <AnimatedFocusBlur triggerKey={step}>{currentStep.title}</AnimatedFocusBlur>
                      </span>
                    </div>
                    
                    <div style={{ background: "var(--bg-card)", border: "1px solid var(--border-subtle)", borderRadius: "8px", padding: "12px 16px" }}>
                      <p style={{
                        fontFamily: "var(--font-mono)",
                        fontSize: "14px",
                        fontWeight: 600,
                        color: accentColor,
                        margin: 0,
                        wordBreak: "break-all" as const
                      }}>
                        <AnimatedFocusBlur triggerKey={step}>{currentStep.formulaLabel}</AnimatedFocusBlur>
                      </p>
                    </div>
                  </div>

                  {/* Right side: Detailed Prose Description (2/3 width) */}
                  <div className="md:col-span-2 flex flex-col justify-center">
                    <h4 style={{ fontFamily: "var(--font-body)", fontSize: "11px", fontWeight: 600, color: "var(--text-muted)", textTransform: "uppercase", letterSpacing: "0.08em", marginBottom: "8px" }}>
                      Explanation & pipeline significance
                    </h4>
                      <p style={{ fontFamily: "var(--font-body)", fontSize: "15px", lineHeight: 1.6, color: "var(--text-secondary)", margin: 0 }}>
                        <AnimatedFocusBlur triggerKey={step}>{currentStep.desc}</AnimatedFocusBlur>
                      </p>
                  </div>
                </motion.div>
              </AnimatePresence>
            </div>

            {/* Expandable full math breakdown - Horizontal Tray */}
            <div style={{ background: "var(--bg-card)", border: "1px solid var(--border-subtle)", borderRadius: "16px", overflow: "hidden", height: "fit-content" }}>
              <button
                type="button"
                onClick={() => setMathOpen((v) => !v)}
                aria-expanded={mathOpen}
                aria-controls={mathId}
                style={{
                  width: "100%", display: "flex", alignItems: "center", justifyContent: "space-between",
                  minHeight: "48px", padding: "0 16px", background: "transparent", border: "none",
                  cursor: "pointer", borderBottom: mathOpen ? "1px solid var(--border-base)" : "none",
                }}
                className="hover:bg-[var(--bg-alt)] focus-visible:ring-2 focus-visible:ring-[#F59E0B] focus-visible:ring-inset"
              >
                <span style={{ fontFamily: "var(--font-body)", fontSize: "13px", fontWeight: 600, color: "var(--text-primary)" }}>
                  Full Formula Breakdown
                </span>
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true"
                  style={{ flexShrink: 0, transition: "transform 220ms ease", transform: mathOpen ? "rotate(180deg)" : "rotate(0deg)" }}>
                  <path d="M4 6L8 10L12 6" stroke="var(--text-faint)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </button>
              {mathOpen && (
                <div id={mathId} style={{ padding: "16px" }}>
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                    {MATH_STEPS.map(({ label, formula }, i) => {
                      const isStepActive = i === step;
                      // Alternate between Emerald and Vivid Amber color schemes
                      const cardColor = i % 2 === 0
                        ? (dark ? "#34D399" : "#047857") // Structural (Green)
                        : (dark ? "#FBBF24" : "#92400E"); // Active (Amber)

                      const cardBg = i % 2 === 0
                        ? (dark ? "rgba(16,185,129,0.05)" : "#E6F4EA")
                        : (dark ? "rgba(245,158,11,0.05)" : "#FFF8E1");

                      const cardBorder = isStepActive
                        ? `1px solid ${cardColor}`
                        : "1px solid var(--border-subtle)";

                      const cardShadow = isStepActive
                        ? (dark ? `0 0 12px ${cardColor}15` : `0 4px 12px ${cardColor}10`)
                        : "none";

                      return (
                        <div
                          key={label}
                          style={{
                            background: cardBg,
                            borderRadius: "8px",
                            padding: "16px",
                            border: cardBorder,
                            boxShadow: cardShadow,
                            transition: "all 200ms ease",
                            display: "flex",
                            flexDirection: "column",
                            gap: "8px",
                          }}
                        >
                          <div style={{ display: "flex", alignItems: "center", width: "100%" }}>
                            <p style={{
                              fontFamily: "var(--font-mono)",
                              fontSize: "11px",
                              fontWeight: 700,
                              color: cardColor,
                              letterSpacing: "0.06em",
                              textTransform: "uppercase" as const,
                              margin: 0
                            }}>
                              {label.split(" · ")[0]}
                            </p>
                            {isStepActive && (
                              <span style={{
                                background: cardColor,
                                color: "#ffffff",
                                borderRadius: "999px",
                                padding: "2px 8px",
                                fontFamily: "var(--font-mono)",
                                fontSize: "9px",
                                fontWeight: 700,
                                marginLeft: "auto",
                              }}>
                                ACTIVE
                              </span>
                            )}
                          </div>
                          
                          <p style={{
                            fontFamily: "var(--font-body)",
                            fontSize: "13px",
                            fontWeight: 700,
                            color: "var(--text-primary)",
                            margin: 0
                          }}>
                            {label.split(" · ")[1]}
                          </p>

                          <div style={{ background: "var(--bg-card)", border: "1px solid var(--border-subtle)", borderRadius: "6px", padding: "8px 10px" }}>
                            <p style={{
                              fontFamily: "var(--font-mono)",
                              fontSize: "13px",
                              fontWeight: 600,
                              color: cardColor,
                              margin: 0,
                              wordBreak: "break-all" as const
                            }}>
                              {formula}
                            </p>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
