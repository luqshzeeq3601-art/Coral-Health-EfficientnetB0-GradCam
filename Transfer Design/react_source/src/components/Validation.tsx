import { useState, useId, useEffect, useRef, useContext, createContext } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { AnimatedSpringNumber } from "./ui";
import { getMetrics, type MetricsModelBlock, type ClassificationRow, type MetricsResponse } from "../lib/api";

/* Design tokens (local constants to avoid repetition) */
const T = {
  teal:    "#0891b2",
  tealD:   "#0e7490",
  tealL:   "rgba(8,145,178,.08)",
  tealM:   "rgba(8,145,178,.15)",
  cyan:    "var(--brand-cyan)",
  green:   "#3cab57",
  red:     "#dc2626",
  brand:   "var(--brand-primary)",       // #0057e6
  brandL:  "var(--brand-light)",
  text:    "var(--text-primary)",
  textS:   "var(--text-secondary)",
  textF:   "var(--text-faint)",
  textM:   "var(--text-muted)",
  card:    "var(--bg-card)",
  alt:     "var(--bg-alt)",
  chip:    "var(--bg-chip)",
  border:  "var(--border-subtle)",
  borderB: "var(--border-base)",
  borderF: "var(--border-faint)",
  display: "var(--font-display)",
  body:    "var(--font-body)",
  mono:    "var(--font-mono)",
} as const;

/* Data */
const BASE_METRICS = [
  { label: "Accuracy",  value: "84.91%" },
  { label: "Precision", value: "77.7%" },
  { label: "Recall",    value: "83.6%" },
  { label: "Macro F1",  value: "79.2%" },
] as const;

const ENS_METRICS = [
  { label: "Accuracy",  value: "98.11%" },
  { label: "Precision", value: "98.6%" },
  { label: "Recall",    value: "96.9%" },
  { label: "Macro F1",  value: "97.7%" },
] as const;

/* Real held-out test counts (159 samples: 72 Healthy / 72 Bleached / 15 Dead) */
const BASE_CM = [
  { actual: "Healthy",  vals: [67, 1,  4],  recall: "93.1%" },
  { actual: "Bleached", vals: [8,  56, 8],  recall: "77.8%" },
  { actual: "Dead",     vals: [1,  2,  12], recall: "80.0%" },
];

const ENS_CM = [
  { actual: "Healthy",  vals: [72, 0,  0],  recall: "100%" },
  { actual: "Bleached", vals: [2,  70, 0],  recall: "97.2%" },
  { actual: "Dead",     vals: [0,  1,  14], recall: "93.3%" },
];

const REPORT = [
  { cls: "Healthy",  p: "0.973", r: "1.000", f1: "0.986", n: "72" },
  { cls: "Bleached", p: "0.986", r: "0.972", f1: "0.979", n: "72" },
  { cls: "Dead",     p: "1.000", r: "0.933", f1: "0.966", n: "15" },
];

/* ── Live metrics wiring (GET /api/metrics) ──────────────────────────────
   The static constants above are the fallback/default values. When the
   backend responds, Validation() builds a MetricsView and provides it via
   context; panels read live numbers, falling back to the constants. */

type MetricRibbon = { label: string; value: string }[];
type CMRow = { actual: string; vals: number[]; recall: string };
type ReportRow = { cls: string; p: string; r: string; f1: string; n: string };

interface MetricsView {
  baseMetrics: MetricRibbon;
  ensMetrics: MetricRibbon;
  baseCM: CMRow[];
  ensCM: CMRow[];
  report: ReportRow[];
  reportMacro: string[]; // [precision, recall, f1, support]
  baseAccuracy: string;
}

const DEFAULT_VIEW: MetricsView = {
  baseMetrics: BASE_METRICS.map((m) => ({ ...m })),
  ensMetrics: ENS_METRICS.map((m) => ({ ...m })),
  baseCM: BASE_CM.map((r) => ({ ...r, vals: [...r.vals] })),
  ensCM: ENS_CM.map((r) => ({ ...r, vals: [...r.vals] })),
  report: REPORT.map((r) => ({ ...r })),
  reportMacro: ["0.986", "0.969", "0.977", "159"],
  baseAccuracy: "84.9%",
};

const MetricsContext = createContext<MetricsView>(DEFAULT_VIEW);
const useMetrics = () => useContext(MetricsContext);

const CM_CLASSES = ["Healthy", "Bleached", "Dead"] as const;

function pctStr(v: number | null | undefined): string | null {
  if (v == null || Number.isNaN(v)) return null;
  const pct = v <= 1 ? v * 100 : v;
  return pct.toFixed(2) + "%";
}
function fracStr(v: number | null | undefined): string | null {
  if (v == null || Number.isNaN(v)) return null;
  const frac = v <= 1 ? v : v / 100;
  return frac.toFixed(3);
}
function findMacro(rows?: ClassificationRow[]) {
  return rows?.find((r) => /macro/i.test(r.Class));
}

function ribbonFrom(block: MetricsModelBlock | undefined, fallback: MetricRibbon): MetricRibbon {
  if (!block) return fallback;
  const macro = findMacro(block.classification_report);
  return [
    { label: "Accuracy", value: block.model_info?.accuracy ?? fallback[0].value },
    { label: "Precision", value: pctStr(macro?.precision) ?? fallback[1].value },
    { label: "Recall", value: pctStr(macro?.recall) ?? fallback[2].value },
    { label: "Macro F1", value: pctStr(macro?.["f1-score"]) ?? fallback[3].value },
  ];
}

function cmFrom(block: MetricsModelBlock | undefined, fallback: CMRow[]): CMRow[] {
  const raw = block?.confusion_matrix_data;
  if (!raw || raw.length !== 3) return fallback;
  return raw.map((row, ri) => {
    const sum = row.reduce((a, b) => a + b, 0) || 1;
    return {
      actual: CM_CLASSES[ri],
      vals: [...row], // raw held-out counts, not normalized
      recall: ((row[ri] / sum) * 100).toFixed(1) + "%",
    };
  });
}

function reportFrom(
  block: MetricsModelBlock | undefined
): { rows: ReportRow[]; macro: string[] } {
  const rows = block?.classification_report;
  const perClass = rows?.filter((r) => (CM_CLASSES as readonly string[]).includes(r.Class)) ?? [];
  if (perClass.length === 0) return { rows: DEFAULT_VIEW.report, macro: DEFAULT_VIEW.reportMacro };
  const mapped: ReportRow[] = perClass.map((r) => ({
    cls: r.Class,
    p: fracStr(r.precision) ?? "—",
    r: fracStr(r.recall) ?? "—",
    f1: fracStr(r["f1-score"]) ?? "—",
    n: r.support != null ? String(r.support) : "—",
  }));
  const m = findMacro(rows);
  const macro = m
    ? [
        fracStr(m.precision) ?? DEFAULT_VIEW.reportMacro[0],
        fracStr(m.recall) ?? DEFAULT_VIEW.reportMacro[1],
        fracStr(m["f1-score"]) ?? DEFAULT_VIEW.reportMacro[2],
        m.support != null ? String(m.support) : DEFAULT_VIEW.reportMacro[3],
      ]
    : DEFAULT_VIEW.reportMacro;
  return { rows: mapped, macro };
}

function buildMetricsView(api: MetricsResponse): MetricsView {
  const ensReport = reportFrom(api.ensemble);
  return {
    baseMetrics: ribbonFrom(api.baseline, DEFAULT_VIEW.baseMetrics),
    ensMetrics: ribbonFrom(api.ensemble, DEFAULT_VIEW.ensMetrics),
    baseCM: cmFrom(api.baseline, DEFAULT_VIEW.baseCM),
    ensCM: cmFrom(api.ensemble, DEFAULT_VIEW.ensCM),
    report: ensReport.rows,
    reportMacro: ensReport.macro,
    baseAccuracy: api.baseline?.model_info?.accuracy ?? DEFAULT_VIEW.baseAccuracy,
  };
}

const ARCH_CARDS = [
  { name: "EfficientNetB0", sub: "20.3M params / 15.7 MB", acc: "98.11%", f1: "0.977", lat: "10.4 ms", winner: true,
    strengths: ["Optimal balance of depth, width, and resolution.", "Highest macro F1 at the lowest parameter cost."] },
  { name: "ResNet50", sub: "23.6M params / 98 MB", acc: "98.11%", f1: "0.959", lat: "42.1 ms", winner: false,
    strengths: ["Proven residual architecture.", "Matches accuracy but lags on macro F1 and Dead-class recall."] },
  { name: "ConvNeXtTiny", sub: "27.8M params / 109 MB", acc: "97.48%", f1: "0.972", lat: "38.2 ms", winner: false,
    strengths: ["Modern pure-conv design.", "Largest parameter footprint with lower overall accuracy."] },
];

const BENCH_ROWS = [
  { model: "EfficientNetB0", best: true,  acc: "98.11%", f1: "0.977", errors: "3 / 159",  size: "15.7 MB", lat: "10.4 ms" },
  { model: "ConvNeXtTiny",   best: false, acc: "97.48%", f1: "0.972", errors: "4 / 159",  size: "109 MB",  lat: "38.2 ms" },
  { model: "ResNet50",       best: false, acc: "98.11%", f1: "0.959", errors: "3 / 159",  size: "98 MB",   lat: "42.1 ms" },
];

const FINDINGS = [
  { title: "Compound Scaling Wins",
    body: "EfficientNetB0's compound scaling law simultaneously expands depth, width, and input resolution. It matches ResNet50's top accuracy while achieving a higher macro F1 (0.977 vs 0.959) with 14% fewer parameters, confirming superior architectural efficiency." },
  { title: "Field Deployment Feasibility",
    body: "At 10.4ms ensemble inference and a 15.7MB per-model footprint, EfficientNetB0 is viable for edge deployment on underwater drones and diver cameras, a practical advantage the heavier baselines cannot match at field scale." },
  { title: "Ensemble Amplification",
    body: "5-seed SWA ensemble training elevates accuracy to 98.11% and reduces total classification errors by 87.5% (24 → 3 on 159 held-out samples) versus the single-model baseline, confirming that ensemble diversity is the critical second optimization lever." },
];

/* Icon components (SVG only, 2px stroke, rounded caps) */
function IconClock() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="8" cy="8" r="6.25" />
      <path d="M8 5v3.25l2 1.5" />
    </svg>
  );
}
function IconNodes() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round">
      <circle cx="4" cy="8" r="2" />
      <circle cx="12" cy="4" r="2" />
      <circle cx="12" cy="12" r="2" />
      <path d="M6 7.5l4-2.5M6 8.5l4 2.5" />
    </svg>
  );
}
function IconBox() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M8 2l5.5 3v6L8 14 2.5 11V5L8 2z" />
      <path d="M8 2v12M2.5 5l5.5 3 5.5-3" />
    </svg>
  );
}
function IconZap() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9.5 2L4 9h4.5L6.5 14 13 7H8.5L9.5 2z" />
    </svg>
  );
}
function IconCheck() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
      <path d="M2.5 7.5L5.5 10.5L11.5 4" />
    </svg>
  );
}
function IconShield() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M7 1.5L12 3.5v4C12 10.5 9.5 12.5 7 13c-2.5-.5-5-2.5-5-5.5v-4L7 1.5z" />
      <path d="M4.5 7l2 2 3-3.5" />
    </svg>
  );
}
function IconTrend() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round">
      <path d="M1.5 10.5L5 6.5l3 2.5 4-5.5" />
    </svg>
  );
}
function IconScatter() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round">
      <circle cx="3.5" cy="10" r="1.25" fill="currentColor" stroke="none" />
      <circle cx="7.5" cy="6.5" r="1.25" fill="currentColor" stroke="none" />
      <circle cx="11" cy="3.5" r="1.25" fill="currentColor" stroke="none" />
      <path d="M1 13h12M1 1v12" strokeWidth="1.25" />
    </svg>
  );
}
function IconGrid() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round">
      <rect x="1.5" y="1.5" width="4" height="4" rx="0.75" />
      <rect x="8.5" y="1.5" width="4" height="4" rx="0.75" />
      <rect x="1.5" y="8.5" width="4" height="4" rx="0.75" />
      <rect x="8.5" y="8.5" width="4" height="4" rx="0.75" />
    </svg>
  );
}
function IconTable() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round">
      <rect x="1.5" y="1.5" width="11" height="11" rx="1.25" />
      <path d="M1.5 5h11M5.5 5v7.5" />
    </svg>
  );
}
function IconFlask() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 1.5h4M5.5 1.5V6L2 11.5a1 1 0 0 0 .88 1.5h8.24A1 1 0 0 0 12 11.5L8.5 6V1.5" />
    </svg>
  );
}
function IconStar() {
  return (
    <svg width="10" height="10" viewBox="0 0 10 10" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 1l1.2 2.5L9 4l-2 1.9.5 2.7L5 7.4l-2.5 1.2.5-2.7L1 4l2.8-.5L5 1z" />
    </svg>
  );
}
function IconBranch() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round">
      <circle cx="4" cy="3" r="1.5" />
      <circle cx="10" cy="3" r="1.5" />
      <circle cx="7" cy="11" r="1.5" />
      <path d="M4 4.5v1.5a2 2 0 0 0 2 2h2a2 2 0 0 0 2-2V4.5M7 8v1.5" />
    </svg>
  );
}
function IconArrow() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2.5 7h9M8 3.5l3.5 3.5L8 10.5" />
    </svg>
  );
}

/* Micro icons for status badges */
function MicroCrosshair() {
  return (
    <div className="relative w-3.5 h-3.5 flex items-center justify-center flex-shrink-0">
      <motion.svg
        animate={{ rotate: 360 }}
        transition={{ duration: 12, repeat: Infinity, ease: "linear" }}
        className="absolute inset-0 w-full h-full text-[var(--text-brand)]"
        viewBox="0 0 14 14"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.2"
      >
        <circle cx="7" cy="7" r="5" strokeDasharray="2 2" />
        <path d="M7 1v2M7 11v2M1 7h2M11 7h2" strokeLinecap="round" />
      </motion.svg>
      <span className="w-1.5 h-1.5 rounded-full bg-[var(--text-primary)] shadow-[0_0_8px_var(--brand-glow)] animate-pulse" />
    </div>
  );
}

function MicroCluster() {
  return (
    <div className="relative w-3.5 h-3.5 flex items-center justify-center flex-shrink-0">
      <motion.svg
        animate={{ rotate: -360 }}
        transition={{ duration: 15, repeat: Infinity, ease: "linear" }}
        className="absolute inset-0 w-full h-full text-[var(--brand-cyan)]"
        viewBox="0 0 14 14"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.2"
      >
        <circle cx="7" cy="1.75" r="0.75" fill="currentColor" stroke="none" />
        <circle cx="2" cy="9.5" r="0.75" fill="currentColor" stroke="none" />
        <circle cx="12" cy="9.5" r="0.75" fill="currentColor" stroke="none" />
        <path d="M7 3.5l-3 4.5M7 3.5l3 4.5M3.5 8.5h7" stroke="currentColor" strokeOpacity="0.3" strokeDasharray="1 1" />
      </motion.svg>
      <span className="w-1.5 h-1.5 rounded-full bg-[var(--text-primary)] shadow-[0_0_8px_var(--brand-glow)] animate-pulse" />
    </div>
  );
}

/* Primitive components */
function PanelLabel({ icon, children }: { icon: React.ReactNode; children: React.ReactNode }) {
  return (
    <div className="flex items-center gap-3 mb-4">
      <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-gradient-to-br from-[color-mix(in_srgb,var(--brand-technical)_10%,transparent)] to-[color-mix(in_srgb,var(--brand-cyan)_10%,transparent)] text-[var(--text-brand)] shadow-[inset_0_1px_0_rgba(255,255,255,0.6)]">
        {icon}
      </span>
      <h3 className="font-body text-sm font-bold text-gray-900 tracking-tight">{children}</h3>
    </div>
  );
}

function Rule() {
  return <div className="h-px w-full bg-gradient-to-r from-transparent via-[var(--border-base)] to-transparent my-2 opacity-60" />;
}

/* Sparkline */
function Sparkline({ id }: { id: string }) {
  return (
    <svg viewBox="0 0 160 24" preserveAspectRatio="none" className="w-full h-5 block">
      <defs>
        <linearGradient id={`spark-${id}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="var(--brand-cyan)" stopOpacity="0.3" />
          <stop offset="100%" stopColor="var(--brand-cyan)" stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d="M0,20 C30,17 60,13 90,9 C115,6 135,4 160,3 L160,24 L0,24 Z" fill={`url(#spark-${id})`} />
      <path d="M0,20 C30,17 60,13 90,9 C115,6 135,4 160,3" stroke="var(--brand-primary)" strokeWidth="1.5" fill="none" strokeLinecap="round" />
      <circle cx="160" cy="3" r="2.5" fill="var(--brand-cyan)" className="animate-pulse" />
    </svg>
  );
}

/* Metric card */
function MetricCard({ label, value, delay = 0 }: { label: string; value: string; delay?: number }) {
  const sid = useId();
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, delay, ease: [0.22, 1, 0.36, 1] }}
      whileHover={{ y: -4, transition: { duration: 0.2 } }}
      className="relative p-6 bg-[var(--bg-card)]/80 backdrop-blur-xl rounded-2xl shadow-[0_8px_30px_rgba(0,0,0,0.04)] ring-1 ring-black/[0.03] overflow-hidden group"
    >
      <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-[var(--brand-technical)] to-[var(--brand-cyan)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
            <span className="block font-body text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-3">
        {label}
      </span>
      <div className="font-display text-3xl font-bold text-gray-900 tracking-tight mb-4">
        <AnimatedSpringNumber value={value} delay={delay} />
      </div>
      <Sparkline id={sid} />
    </motion.div>
  );
}

/* Donut chart */
function Donut({ pct, label }: { pct: string; label: string }) {
  const gid = useId();
  const circumference = 2 * Math.PI * 40;
  const numPct = parseFloat(pct) || 0;
  const targetDash = (numPct / 100) * circumference;
  const visualDash = Math.max(0, targetDash - 6); // visually compensate for strokeLinecap="round" (6px strokeWidth)

  return (
    <div className="relative w-32 h-32 flex-shrink-0 group">
      <div className="absolute inset-0 bg-[color-mix(in_srgb,var(--brand-cyan)_5%,transparent)] rounded-full blur-xl group-hover:bg-[color-mix(in_srgb,var(--brand-cyan)_15%,transparent)] transition-colors duration-700" />
      <svg viewBox="0 0 96 96" className="relative w-full h-full -rotate-90">
        <defs>
          <linearGradient id={`dg-${gid}`} x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="var(--brand-technical)" />
            <stop offset="100%" stopColor="var(--brand-cyan)" />
          </linearGradient>
          <filter id={`glow-${gid}`} x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur stdDeviation="2.5" result="blur" />
            <feComposite in="SourceGraphic" in2="blur" operator="over" />
          </filter>
        </defs>
        <circle cx="48" cy="48" r="40" fill="none" className="stroke-gray-100" strokeWidth="6" />
        <motion.circle cx="48" cy="48" r="40" fill="none"
          stroke={`url(#dg-${gid})`} strokeWidth="6"
          strokeLinecap="round"
          filter={`url(#glow-${gid})`}
          initial={{ strokeDasharray: `0 ${circumference}` }}
          animate={{ strokeDasharray: `${visualDash} ${circumference}` }}
          transition={{ duration: 1.5, ease: "easeOut", delay: 0.2 }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className="font-display text-[22px] font-bold text-gray-900 tracking-tight">{pct}</span>
        <span className="font-body text-[8px] font-bold text-gray-400 tracking-widest uppercase mt-1">{label}</span>
      </div>
    </div>
  );
}

/* Hero band */
function HeroBand({ badge, name, sub, desc, donut, extra }: {
  badge: string; name: string; sub: string; desc: string;
  donut: React.ReactNode; extra?: React.ReactNode;
}) {
  return (
    <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-[var(--bg-card)] to-[#f9fafb] p-8 md:p-12 mb-8 shadow-[0_12px_40px_rgba(0,0,0,0.04)] ring-1 ring-black/[0.02]">
      <div className="absolute -top-40 -right-40 w-[500px] h-[500px] bg-[color-mix(in_srgb,var(--brand-cyan)_10%,transparent)] rounded-full blur-[80px] pointer-events-none" />
      <div className="absolute -bottom-40 -left-40 w-[500px] h-[500px] bg-[color-mix(in_srgb,var(--brand-technical)_5%,transparent)] rounded-full blur-[80px] pointer-events-none" />

      <div className="relative z-10 flex flex-col md:flex-row items-center gap-10">
        <div className="flex-1 space-y-4">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-gradient-to-r from-[color-mix(in_srgb,var(--brand-technical)_10%,transparent)] to-[color-mix(in_srgb,var(--brand-cyan)_10%,transparent)] text-[var(--text-brand)] text-[10px] font-bold tracking-widest uppercase border border-[var(--brand-primary)]/10">
            <span className="w-1.5 h-1.5 rounded-full bg-[var(--brand-cyan)] animate-pulse" />
            {badge}
          </div>
          <h3 className="font-display text-3xl md:text-4xl font-bold tracking-tight text-gray-900 leading-tight">
            {name}
          </h3>
          <p className="font-body text-[15px] font-semibold text-transparent bg-clip-text bg-gradient-to-r from-[var(--brand-primary)] to-[var(--brand-cyan)]">
            {sub}
          </p>
          <p className="font-body text-sm text-gray-500 leading-relaxed max-w-2xl">
            {desc}
          </p>
        </div>
        <div className="flex-shrink-0 flex items-center gap-8">
          {donut}
          {extra}
        </div>
      </div>
    </div>
  );
}

/* Confusion matrix */
function ConfMatrix({ rows }: { rows: CMRow[] }) {
  const classes = ["Healthy", "Bleached", "Dead"];
  return (
    <div className="relative">
      <div className="absolute -inset-4 bg-gradient-to-b from-[var(--bg-alt)]/50 to-transparent rounded-2xl -z-10 pointer-events-none" />
      <div className="flex justify-between items-end mb-6">
        <p className="font-body text-[12px] text-gray-400 leading-relaxed">
          159 held-out samples / 72 Healthy / 72 Bleached / 15 Dead<br/>
          Rows = <span className="font-medium text-gray-600">Actual</span> / Columns = <span className="font-medium text-gray-600">Predicted</span>
        </p>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full border-collapse">
          <thead>
            <tr>
              <th className="pb-4 text-left font-body text-[11px] font-bold uppercase tracking-widest text-gray-400 border-b border-[var(--border-subtle)]">Actual \ Pred.</th>
              {classes.map(c => <th key={c} className="pb-4 text-center font-body text-[11px] font-bold uppercase tracking-widest text-gray-400 border-b border-[var(--border-subtle)]">{c}</th>)}
              <th className="pb-4 text-center font-body text-[11px] font-bold uppercase tracking-widest text-gray-400 border-b border-[var(--border-subtle)]">Recall</th>
            </tr>
          </thead>
          <tbody>
            {rows.map(({ actual, vals, recall }, ri) => {
              const rowSum = vals.reduce((a, b) => a + b, 0) || 1;
              return (
              <tr key={actual} className="group">
                <td className="py-4 text-left font-body text-[13px] font-semibold text-gray-600 border-b border-[var(--border-subtle)] group-hover:text-gray-900 transition-colors">{actual}</td>
                {vals.map((v, ci) => {
                  const diag = ri === ci;
                  const miss = !diag && v > 0;
                  const intensity = v / rowSum;
                  return (
                    <td key={ci} className="py-2 px-1 border-b border-[var(--border-subtle)]">
                      <div className={`
                        mx-auto w-14 h-10 flex items-center justify-center rounded-lg font-mono text-[13px] transition-all duration-300
                        ${diag ? 'text-[var(--text-brand)] font-bold ring-1 ring-[color-mix(in_srgb,var(--brand-cyan)_20%,transparent)] shadow-[0_0_15px_color-mix(in_srgb,var(--brand-cyan)_15%,transparent)]' :
                          miss ? 'bg-red-50/50 text-red-500 font-semibold ring-1 ring-red-100' :
                          'text-gray-300'}
                      `}
                      style={diag ? { backgroundColor: `color-mix(in srgb, var(--brand-cyan) ${Math.round((0.03 + intensity * 0.15) * 100)}%, transparent)` } : {}}>
                        {v}
                      </div>
                    </td>
                  );
                })}
                <td className="py-4 text-center font-mono text-[13px] font-bold text-[#3cab57] border-b border-[var(--border-subtle)]">{recall}</td>
              </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* Classification report */
function ClassReport() {
  const { report, reportMacro } = useMetrics();
  return (
    <div>
      <p className="font-body text-[12px] text-gray-400 mb-6">
        Per-class precision, recall, and F1 / 159 held-out samples
      </p>
      <table className="w-full border-collapse">
        <thead>
          <tr>
            {["Class","Precision","Recall","F1","Support"].map((h, i) => (
              <th key={h} className={`pb-4 ${i === 0 ? 'text-left' : 'text-right'} font-body text-[11px] font-bold uppercase tracking-widest text-gray-400 border-b border-[var(--border-subtle)]`}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {report.map(({ cls, p, r, f1, n }) => (
            <tr key={cls} className="group">
              <td className="py-3 text-left font-body text-[13px] font-semibold text-gray-600 border-b border-[var(--border-subtle)] group-hover:text-gray-900 transition-colors">{cls}</td>
              {[p, r, f1, n].map((v, i) => (
                <td key={i} className="py-3 text-right font-mono text-[12px] text-gray-500 border-b border-[var(--border-subtle)]">{v}</td>
              ))}
            </tr>
          ))}
          <tr>
            <td className="py-4 text-left font-body text-[13px] font-bold text-gray-900 border-t border-[var(--border-base)]">Macro Avg</td>
            {reportMacro.map((v, i) => (
              <td key={i} className="py-4 text-right font-mono text-xs font-bold text-[var(--text-brand)] border-t border-[var(--border-base)]">{v}</td>
            ))}
          </tr>
        </tbody>
      </table>
    </div>
  );
}

/* Training chart */
function TrainChart({ title, lines }: { title: string; lines: { path: string; stroke: string; dash?: string; label: string }[] }) {
  return (
    <div className="relative p-6 bg-[var(--bg-card)]/60 backdrop-blur-md rounded-2xl shadow-[0_4px_20px_rgba(0,0,0,0.02)] ring-1 ring-black/[0.03]">
      <div className="flex items-center justify-between mb-8">
        <span className="font-body text-[13px] font-bold text-gray-800 tracking-tight">{title}</span>
        <div className="flex gap-4">
          {lines.map(l => (
            <div key={l.label} className="flex items-center gap-2">
              <svg width="20" height="2"><line x1="0" y1="1" x2="20" y2="1" stroke={l.stroke} strokeWidth="2" strokeDasharray={l.dash} strokeLinecap="round" /></svg>
              <span className="font-body text-[9px] font-bold text-gray-400 uppercase tracking-widest">{l.label}</span>
            </div>
          ))}
        </div>
      </div>
      <svg viewBox="0 0 380 120" className="w-full h-[120px] overflow-visible">
        <defs>
          <filter id="glow-chart" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur stdDeviation="3" result="blur" />
            <feComposite in="SourceGraphic" in2="blur" operator="over" />
          </filter>
        </defs>
        {[20, 50, 80, 108].map(y => (
          <line key={y} x1="36" y1={y} x2="378" y2={y} className="stroke-gray-100" strokeWidth="1" />
        ))}
        <line x1="36" y1="10" x2="36" y2="110" className="stroke-gray-200" strokeWidth="1" />
        <line x1="36" y1="110" x2="378" y2="110" className="stroke-gray-200" strokeWidth="1" />
        {[["0","110"],["50","79"],["75","49"],["100","19"]].map(([v, y]) => (
          <text key={v} x="32" y={+y + 3} className="text-[8px] fill-gray-400 font-mono" textAnchor="end">{v}</text>
        ))}
        <text x="207" y="126" className="text-[8px] fill-gray-400 font-mono tracking-widest uppercase" textAnchor="middle">Epoch</text>
        {lines.map((l, i) => (
          <motion.path
            key={l.label}
            d={l.path}
            stroke={l.stroke}
            strokeWidth={l.dash ? "1.5" : "2.5"}
            fill="none"
            strokeDasharray={l.dash}
            strokeLinecap="round"
            strokeLinejoin="round"
            filter={!l.dash ? "url(#glow-chart)" : undefined}
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ pathLength: 1, opacity: 1 }}
            transition={{ duration: 1.5, delay: i * 0.2, ease: "easeOut" }}
          />
        ))}
      </svg>
    </div>
  );
}

/* Base model panel */
/* BASE MODEL PANEL                                                        */
/* End base model panel header */
function BaseModelPanel() {
  const { baseMetrics, baseCM, baseAccuracy } = useMetrics();
  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
      className="grid grid-cols-12 gap-px bg-[var(--border-base)] border border-[var(--border-base)] overflow-hidden rounded-xl shadow-[0_8px_30px_rgba(0,0,0,0.04)]"
    >
      {/* Hero Section */}
      <div className="col-span-12 lg:col-span-8 bg-[var(--bg-card)] p-8 md:p-12 flex flex-col md:flex-row items-center gap-10">
        <div className="flex-1 space-y-4">
          <div className="inline-flex items-center gap-2.5 px-3 py-1.5 rounded-full bg-gradient-to-r from-[var(--brand-primary)]/5 via-[var(--brand-primary)]/5 to-transparent text-[var(--text-brand)] text-[9px] font-mono font-bold tracking-[0.18em] uppercase border border-[var(--brand-primary)]/10 shadow-[inset_0_1px_0_rgba(255,255,255,0.8),0_2px_8px_rgba(0,0,0,0.01)]">
            <MicroCrosshair />
            <span>Single Model Evaluation</span>
          </div>
          <h3 className="font-display text-4xl md:text-5xl font-bold tracking-tight text-gray-900 leading-tight">
            EfficientNetB0-Base
          </h3>
          <p className="font-mono text-xs font-semibold text-[var(--text-brand)] uppercase tracking-widest">
            Coral Health Classification / CNN
          </p>
          <p className="font-body text-sm text-gray-500 leading-relaxed max-w-lg mt-2">
            Evaluated on a held-out test set across three health conditions. Metrics reflect model performance and generalization under field deployment constraints.
          </p>
        </div>
        <div className="flex-shrink-0">
          <Donut pct={baseAccuracy} label="Accuracy" />
        </div>
      </div>

      {/* Deploy Specs */}
      <div className="col-span-12 lg:col-span-4 bg-[var(--bg-card)] p-8 md:p-10 flex flex-col justify-center">
        <div className="font-mono text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-6">Deployment Specs</div>
        <div className="space-y-6">
          {[
            { label: "Latency (avg)", value: "9.6 ms", icon: <IconClock /> },
            { label: "Parameters", value: "4.05 M", icon: <IconNodes /> },
            { label: "Model size", value: "15.7 MB", icon: <IconBox /> },
            { label: "Inference speed", value: "~104 img/s", icon: <IconZap /> },
          ].map(({ label, value, icon }, i) => (
            <motion.div key={label} initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.1 }} className="flex items-center gap-4">
              <div className="w-8 h-8 rounded flex items-center justify-center bg-[var(--bg-card)] border border-[var(--border-subtle)] text-[var(--text-brand)] shadow-sm">{icon}</div>
              <div>
                <div className="font-mono text-[9px] text-gray-500 uppercase tracking-widest">{label}</div>
                <div className="font-mono text-sm font-bold text-gray-900">{value}</div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Data Ribbon (Metrics) */}
      <div className="col-span-12 bg-[var(--bg-card)] flex flex-col md:flex-row divide-y md:divide-y-0 md:divide-x divide-[var(--border-subtle)]">
        {baseMetrics.map((m, i) => (
          <motion.div key={m.label} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }} className="flex-1 p-6 relative group overflow-hidden">
            <div className="absolute bottom-0 left-0 w-full h-0.5 bg-[var(--brand-primary)] opacity-0 group-hover:opacity-100 transition-opacity" />
            <span className="block font-mono text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-2">{m.label}</span>
            <div className="font-mono text-3xl font-bold text-[var(--text-brand)] mb-2">
              <AnimatedSpringNumber value={m.value} delay={i * 0.05} />
            </div>
          </motion.div>
        ))}
      </div>

      {/* Matrix */}
      <div className="col-span-12 lg:col-span-7 bg-[var(--bg-card)] p-8">
        <PanelLabel icon={<IconGrid />}>Confusion Matrix</PanelLabel>
        <div className="mt-8"><ConfMatrix rows={baseCM} /></div>
      </div>

      {/* Report */}
      <div className="col-span-12 lg:col-span-5 bg-[var(--bg-card)] p-8">
        <PanelLabel icon={<IconTable />}>Classification Report</PanelLabel>
        <div className="mt-8"><ClassReport /></div>
      </div>

      {/* Charts */}
      <div className="col-span-12 lg:col-span-6 bg-[var(--bg-card)] p-8">
        <TrainChart
          title="Training vs Validation Accuracy"
          lines={[
            { path: "M36,106 C80,86 130,56 170,30 C210,13 250,10 290,10 C330,10 360,10 378,10", stroke: "var(--brand-primary)", label: "Train" },
            { path: "M36,108 C80,90 130,60 170,34 C210,17 250,13 290,12 C330,11 360,11 378,11", stroke: "var(--brand-cyan)", dash: "4,3", label: "Val" },
          ]}
        />
      </div>
      <div className="col-span-12 lg:col-span-6 bg-[var(--bg-card)] p-8">
        <TrainChart
          title="Training vs Validation Loss"
          lines={[
            { path: "M36,12 C80,28 130,56 170,76 C210,90 250,102 290,107 C330,111 360,113 378,114", stroke: "var(--brand-primary)", label: "Train" },
            { path: "M36,16 C80,33 130,60 170,80 C210,94 250,105 290,109 C330,112 360,114 378,115", stroke: "var(--brand-cyan)", dash: "4,3", label: "Val" },
          ]}
        />
      </div>
    </motion.div>
  );
}

/* Ensemble panel */
/* ENSEMBLE PANEL                                                          */
/* End ensemble panel header */
function EnsemblePanel() {
  const { ensMetrics, ensCM } = useMetrics();
  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
      className="grid grid-cols-12 gap-px bg-[var(--border-base)] border border-[var(--border-base)] overflow-hidden rounded-xl shadow-[0_8px_30px_rgba(0,0,0,0.04)]"
    >
      {/* Light Mode Hero Section */}
      <div className="col-span-12 lg:col-span-8 bg-[var(--bg-card)] p-8 md:p-12 flex flex-col md:flex-row items-center gap-10">
        <div className="absolute top-0 right-0 w-96 h-96 bg-[var(--brand-primary)]/5 rounded-full blur-[100px] pointer-events-none" />
        <div className="relative flex-1 space-y-4">
          <div className="inline-flex items-center gap-2.5 px-3 py-1.5 rounded-full bg-gradient-to-r from-[color-mix(in_srgb,var(--brand-technical)_5%,transparent)] via-[color-mix(in_srgb,var(--brand-cyan)_5%,transparent)] to-transparent text-[var(--text-brand)] text-[9px] font-mono font-bold tracking-[0.18em] uppercase border border-[var(--brand-primary)]/10 shadow-[inset_0_1px_0_rgba(255,255,255,0.8),0_2px_8px_rgba(0,0,0,0.01)]">
            <MicroCluster />
            <span>Ensemble Evaluation</span>
          </div>
          <h3 className="font-display text-4xl md:text-5xl font-bold tracking-tight text-gray-900 leading-tight">
            5-Seed Ensemble Model
          </h3>
          <p className="font-mono text-xs font-semibold text-[var(--text-brand)] uppercase tracking-widest">
            Stronger Together / More Stable / More Accurate
          </p>
          <p className="font-body text-sm text-gray-500 leading-relaxed max-w-lg mt-2">
            Our 5-seed ensemble leverages diversity across five independently trained models to deliver superior performance and exceptional prediction stability.
          </p>
        </div>
        <div className="flex-shrink-0">
          <Donut pct="98.7%" label="Stability" />
        </div>
      </div>

      {/* Ensemble Specs */}
      <div className="col-span-12 lg:col-span-4 bg-[var(--bg-card)] p-8 md:p-10 flex flex-col justify-center">
        <div className="font-mono text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-6">Ensemble Specs</div>
        <div className="space-y-6">
          {[
            { label: "Total Models", value: "5 CNNs", icon: <IconBranch /> },
            { label: "Aggregation", value: "Soft Voting", icon: <IconGrid /> },
            { label: "Parameters", value: "20.3 M", icon: <IconNodes /> },
            { label: "Inference Speed", value: "~96.3 img/s", icon: <IconZap /> },
          ].map(({ label, value, icon }, i) => (
            <motion.div key={label} initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: i * 0.1 }} className="flex items-center gap-4">
              <div className="w-8 h-8 rounded flex items-center justify-center bg-[var(--bg-card)] border border-[var(--border-subtle)] text-[var(--text-brand)] shadow-sm">{icon}</div>
              <div>
                <div className="font-mono text-[9px] text-gray-500 uppercase tracking-widest">{label}</div>
                <div className="font-mono text-sm font-bold text-gray-900">{value}</div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Data Ribbon (Metrics) */}
      <div className="col-span-12 bg-[var(--bg-card)] flex flex-col md:flex-row divide-y md:divide-y-0 md:divide-x divide-[var(--border-subtle)]">
        {ensMetrics.map((m, i) => (
          <motion.div key={m.label} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }} className="flex-1 p-6 relative group overflow-hidden">
            <div className="absolute bottom-0 left-0 w-full h-0.5 bg-[var(--brand-primary)] opacity-0 group-hover:opacity-100 transition-opacity" />
            <span className="block font-mono text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-2">{m.label}</span>
            <div className="font-mono text-3xl font-bold text-[var(--text-brand)] mb-2">
              <AnimatedSpringNumber value={m.value} delay={i * 0.05} />
            </div>
          </motion.div>
        ))}
      </div>

      {/* Ensemble Workflow Pipeline (Full Bleed Cinematic Light) */}
      <div className="col-span-12 relative overflow-hidden bg-[var(--bg-card)] border-y border-[var(--border-base)] py-16 px-8">
        {/* Subtle Ambient Lighting */}
        <div className="absolute top-1/2 left-0 w-[400px] h-[400px] -translate-y-1/2 bg-[var(--brand-primary)]/5 rounded-full blur-[100px] pointer-events-none" />
        <div className="absolute top-1/2 right-0 w-[400px] h-[400px] -translate-y-1/2 bg-[color-mix(in_srgb,var(--brand-cyan)_10%,transparent)] rounded-full blur-[100px] pointer-events-none" />
        <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGNpcmNsZSBjeD0iMSIgY3k9IjEiIHI9IjEiIGZpbGw9InJnYmEoMCw4NywyMzAsMC4wNCkiLz48L3N2Zz4=')] opacity-50 pointer-events-none" />

        <div className="relative mb-12 flex justify-center">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-[var(--bg-alt)] border border-[var(--border-base)] text-[var(--text-brand)] shadow-sm">
            <IconBranch />
            <span className="font-mono text-[9px] font-bold uppercase tracking-[0.2em]">Neural Ensemble Architecture</span>
          </div>
        </div>

        <div className="relative z-10 flex flex-col lg:flex-row items-center justify-between gap-8 lg:gap-0 w-full max-w-[1150px] mx-auto">

          {/* 1. Input Node */}
          <motion.div initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="relative flex flex-col items-center w-32 shrink-0">
            <div className="relative w-20 h-20 rounded-2xl bg-[var(--bg-card)] border border-[var(--border-base)] shadow-xl">
              <div className="relative w-full h-full flex items-center justify-center rounded-2xl overflow-hidden group">
                <div className="absolute inset-0 bg-[var(--bg-alt)] opacity-0 group-hover:opacity-100 transition-opacity" />
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--brand-primary)" strokeWidth="1.2"><rect x="3" y="3" width="18" height="18" rx="3" /><path d="M3 9h18M9 3v18" /></svg>
                {/* Laser scan line */}
                <motion.div className="absolute top-0 left-0 right-0 h-[3px] bg-[var(--text-primary)] shadow-[0_0_8px_var(--brand-glow)]" animate={{ top: ["0%", "100%", "0%"] }} transition={{ duration: 3, repeat: Infinity, ease: "linear" }} />
              </div>
            </div>
            <div className="absolute top-[calc(100%+16px)] text-center w-[150%]">
              <div className="font-mono text-[10px] font-bold text-gray-900 uppercase tracking-widest">Input Scan</div>
              <div className="font-mono text-[8px] text-gray-500 uppercase tracking-widest mt-1">224x224x3</div>
            </div>
          </motion.div>

          {/* Connector 1 */}
          <div className="hidden lg:flex flex-1 items-center justify-center px-2">
             <div className="w-full h-[2px] rounded-full bg-[var(--border-base)] relative overflow-hidden">
                <motion.div className="absolute top-0 left-0 w-1/3 h-full bg-gradient-to-r from-transparent via-[var(--brand-primary)] to-transparent" animate={{ x: ["-100%", "300%"] }} transition={{ duration: 2, repeat: Infinity, ease: "linear" }} />
             </div>
          </div>

          {/* 2. Parallel Seeds */}
          <motion.div initial={{ opacity: 0, scale: 0.95 }} whileInView={{ opacity: 1, scale: 1 }} viewport={{ once: true }} transition={{ delay: 0.2 }} className="flex flex-col gap-3 w-56 shrink-0 bg-[var(--bg-card)] border border-[var(--border-base)] rounded-2xl p-6 shadow-xl relative">
            <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-[var(--bg-card)] px-3 py-0.5 font-mono text-[8px] font-bold text-[var(--text-brand)] uppercase tracking-[0.2em] whitespace-nowrap border border-[var(--border-base)] rounded-full shadow-sm">
              5 Independent Seeds
            </div>
            {[1, 2, 3, 4, 5].map((seed, i) => (
              <div key={seed} className="flex items-center gap-3 group">
                <span className="font-mono text-[9px] text-gray-400 group-hover:text-[var(--text-brand)] transition-colors w-4">S{seed}</span>
                <div className="flex-1 h-1.5 bg-[var(--bg-alt)] rounded-full overflow-hidden relative border border-[var(--border-base)]/50">
                  <motion.div className="absolute top-0 left-0 bottom-0 bg-gradient-to-r from-[var(--brand-technical)] to-[var(--brand-cyan)] rounded-full"
                    initial={{ width: "0%" }} whileInView={{ width: "100%" }} viewport={{ once: true }}
                    transition={{ duration: 1, delay: 0.4 + (i * 0.1) }}
                  />
                </div>
              </div>
            ))}
          </motion.div>

          {/* Connector 2 */}
          <div className="hidden lg:flex flex-1 items-center justify-center px-2">
             <div className="w-full h-[2px] rounded-full bg-[var(--border-base)] relative overflow-hidden">
                <motion.div className="absolute top-0 left-0 w-1/3 h-full bg-gradient-to-r from-transparent via-[var(--brand-cyan)] to-transparent" animate={{ x: ["-100%", "300%"] }} transition={{ duration: 2, repeat: Infinity, ease: "linear", delay: 0.5 }} />
             </div>
          </div>

          {/* 3. Soft Voting Node */}
          <motion.div initial={{ opacity: 0, y: -20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: 0.6 }} className="relative flex flex-col items-center w-36 shrink-0">
            <div className="relative flex items-center justify-center w-28 h-28">
              {/* SVG Spinner for perfect centering and thickness */}
              <svg className="absolute inset-0 w-full h-full animate-[spin_2s_linear_infinite]" viewBox="0 0 112 112">
                {/* Static background track */}
                <circle cx="56" cy="56" r="54" fill="none" stroke="#f1f5f9" strokeWidth="4" />
                {/* Animated primary orbit */}
                <circle cx="56" cy="56" r="54" fill="none" stroke="var(--brand-primary)" strokeWidth="4" strokeLinecap="round" strokeDasharray="90 250" />
              </svg>

              {/* Inner dashed counter-rotating orbit */}
              <svg className="absolute inset-0 w-full h-full animate-[spin_4s_linear_infinite_reverse]" viewBox="0 0 112 112">
                <circle cx="56" cy="56" r="42" fill="none" stroke="var(--brand-cyan)" strokeWidth="1.5" strokeDasharray="6 6" opacity="0.6" />
              </svg>

              {/* Glowing energy core */}
              <div className="absolute inset-6 rounded-full bg-gradient-to-tr from-[var(--brand-primary)]/20 to-[color-mix(in_srgb,var(--brand-cyan)_20%,transparent)] blur-md animate-pulse" />

              {/* Solid center node */}
              <div className="relative w-14 h-14 bg-[var(--bg-card)] border-2 border-[var(--brand-primary)] rounded-full flex items-center justify-center shadow-[0_0_25px_var(--brand-glow)] text-[var(--text-brand)] z-10">
                <IconNodes />
              </div>
            </div>
            <div className="absolute top-[calc(100%+20px)] text-center w-[150%]">
              <div className="font-mono text-[10px] font-bold text-gray-900 uppercase tracking-widest">Soft Voting</div>
              <div className="font-mono text-[8px] text-gray-500 uppercase tracking-widest mt-1">Probability Avg</div>
            </div>
          </motion.div>

          {/* Connector 3 */}
          <div className="hidden lg:flex flex-1 items-center justify-center px-2">
             <div className="w-full h-[2px] rounded-full bg-[var(--border-base)] relative overflow-hidden">
                <motion.div className="absolute top-0 left-0 w-1/3 h-full bg-gradient-to-r from-transparent via-[var(--brand-primary)] to-transparent" animate={{ x: ["-100%", "300%"] }} transition={{ duration: 1.5, repeat: Infinity, ease: "linear", delay: 1 }} />
             </div>
          </div>

          {/* 4. Output Node (Remains dark for contrast/focus) */}
          <motion.div initial={{ opacity: 0, scale: 0.95 }} whileInView={{ opacity: 1, scale: 1 }} viewport={{ once: true }} transition={{ delay: 1, type: "spring" }} className="w-56 shrink-0 relative group">
             <div className="absolute -inset-1 bg-gradient-to-r from-[var(--brand-primary)] to-[var(--brand-cyan)] rounded-2xl blur-lg opacity-10 group-hover:opacity-20 transition-opacity duration-500" />
             <div className="relative bg-[var(--bg-card)] border border-[var(--brand-primary)]/20 rounded-2xl p-6 shadow-xl flex flex-col gap-2">
               <span className="font-mono text-[8px] font-bold text-[var(--text-brand)] uppercase tracking-[0.15em]">Final Output</span>
               <span className="font-display text-2xl font-bold text-gray-900 tracking-tight leading-none mb-1">Healthy<br/>Coral</span>
               <div className="flex items-center justify-between font-mono text-[10px] uppercase tracking-widest bg-[var(--bg-alt)] px-3 py-2 rounded-lg border border-[var(--border-subtle)] mb-2">
                  <span className="text-gray-500">Conf:</span>
                  <span className="text-[var(--text-brand)] font-bold">98.7%</span>
               </div>
               <div className="flex flex-col gap-2">
                 <div className="flex items-start gap-2 text-gray-500 text-[9px] font-medium leading-tight uppercase tracking-wider">
                   <span className="mt-0.5 text-[var(--text-brand)]"><IconCheck /></span>Reduces variance
                 </div>
                 <div className="flex items-start gap-2 text-gray-500 text-[9px] font-medium leading-tight uppercase tracking-wider">
                   <span className="mt-0.5 text-[var(--text-brand)]"><IconCheck /></span>Mitigates overfitting
                 </div>
               </div>
             </div>
          </motion.div>

        </div>
      </div>

      {/* Matrix and Error Reduction side by side in Bento */}
      <div className="col-span-12 lg:col-span-7 bg-[var(--bg-card)] p-8">
        <PanelLabel icon={<IconGrid />}>Confusion Matrix (Improved)</PanelLabel>
        <div className="mt-8"><ConfMatrix rows={ensCM} /></div>
      </div>

      <div className="col-span-12 lg:col-span-5 bg-[var(--bg-card)] p-8">
        <PanelLabel icon={<IconTrend />}>Error Reduction vs. Baseline</PanelLabel>
        <div className="mt-12 flex items-baseline gap-4 mb-10">
          <motion.span initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: 0.6, type: "spring", bounce: 0.5 }} className="font-mono text-7xl font-bold text-[var(--brand-cyan)] tracking-tighter" style={{ textShadow: "0 0 16px rgba(56, 189, 248, 0.45)" }}>
            87.5%
          </motion.span>
          <span className="font-mono text-xs font-semibold text-gray-400 uppercase tracking-widest leading-tight">reduction in<br />total errors</span>
        </div>
        <div className="space-y-5">
          {[
            { label: "Baseline", val: "24", pct: 100, color: "bg-[var(--border-base)]", text: "text-gray-500" },
            { label: "5-Seed Ens.", val: "3", pct: 12.5, color: "bg-[var(--brand-primary)]", text: "text-[var(--text-brand)]" },
            { label: "Difference", val: "-21", pct: 87.5, color: "bg-[var(--brand-cyan)]", text: "text-[var(--brand-cyan)]" },
          ].map(({ label, val, pct, color, text }) => (
            <div key={label} className="grid grid-cols-[80px_1fr_50px] items-center gap-4">
              <span className="font-mono text-[10px] font-bold text-gray-500 uppercase tracking-widest">{label}</span>
              <div className="h-1 bg-[var(--bg-alt)] overflow-hidden">
                <motion.div initial={{ width: 0 }} animate={{ width: `${pct}%` }} transition={{ duration: 1, delay: 0.3 }} className={`h-full ${color}`} />
              </div>
              <span className={`font-mono text-xs font-bold text-right ${text}`}>{val}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Charts */}
      <div className="col-span-12 lg:col-span-6 bg-[var(--bg-card)] p-8">
        <TrainChart
          title="Ensemble Training vs Validation Accuracy"
          lines={[
            { path: "M36,106 C80,82 130,50 170,26 C210,12 250,10 290,10 C330,10 360,10 378,10", stroke: "var(--brand-primary)", label: "Train" },
            { path: "M36,108 C80,85 130,53 170,30 C210,15 250,11 290,11 C330,10 360,10 378,10", stroke: "var(--brand-cyan)", dash: "4,3", label: "Val" },
          ]}
        />
      </div>
      <div className="col-span-12 lg:col-span-6 bg-[var(--bg-card)] p-8">
        <TrainChart
          title="Ensemble Training vs Validation Loss"
          lines={[
            { path: "M36,12 C80,34 130,66 170,86 C210,100 250,108 290,112 C330,114 360,115 378,115", stroke: "var(--brand-primary)", label: "Train" },
            { path: "M36,16 C80,38 130,70 170,90 C210,102 250,109 290,113 C330,115 360,115 378,115", stroke: "var(--brand-cyan)", dash: "4,3", label: "Val" },
          ]}
        />
      </div>
    </motion.div>
  );
}

/* Architecture comparison panel */
/* ARCHITECTURE COMPARISON PANEL                                           */
/* End architecture comparison panel header */
function ArchPanel() {
  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
      className="grid grid-cols-12 gap-px bg-[var(--border-base)] border border-[var(--border-base)] overflow-hidden rounded-xl shadow-[0_8px_30px_rgba(0,0,0,0.04)]"
    >
      {/* Radar Screen Hero (Scatter Plot) */}
      <div className="col-span-12 bg-[var(--bg-card)] p-8 md:p-12 relative overflow-hidden">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-[color-mix(in_srgb,var(--brand-primary)_5%,transparent)] via-transparent to-transparent opacity-50" />
        <div className="relative mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <PanelLabel icon={<IconScatter />}><span className="text-gray-900">Accuracy vs. Parameter Efficiency</span></PanelLabel>

          <div className="inline-flex items-center gap-4 px-4 py-2 rounded-full bg-[var(--bg-alt)] border border-[var(--border-base)] text-[9px] font-mono font-bold uppercase tracking-widest shadow-sm">
            <div className="flex items-center gap-2">
               <span className="w-2 h-2 rounded-full bg-[var(--brand-primary)] shadow-[0_0_8px_color-mix(in_srgb,var(--brand-primary)_50%,transparent)]" />
               <span className="text-[var(--text-brand)]">Best Performer</span>
            </div>
            <div className="flex items-center gap-2">
               <span className="w-2 h-2 rounded-full bg-[#94a3b8]" />
               <span className="text-gray-500">Baseline Models</span>
            </div>
          </div>
        </div>
        <svg viewBox="0 0 660 190" className="w-full h-[240px] overflow-visible mt-4">
          <defs>
             <filter id="glow-point-light" x="-50%" y="-50%" width="200%" height="200%">
               <feGaussianBlur stdDeviation="3" result="blur" />
               <feComposite in="SourceGraphic" in2="blur" operator="over" />
             </filter>
             <linearGradient id="area-fade" x1="0" y1="0" x2="0" y2="1">
               <stop offset="0%" stopColor="var(--brand-primary)" stopOpacity="0.15" />
               <stop offset="100%" stopColor="var(--brand-primary)" stopOpacity="0" />
             </linearGradient>
             <linearGradient id="line-grad" x1="0" y1="0" x2="1" y2="0">
               <stop offset="0%" stopColor="var(--brand-primary)" />
               <stop offset="100%" stopColor="#94a3b8" />
             </linearGradient>
          </defs>

          {/* Subtle Shaded Area under Frontier */}
          <motion.path
            d="M414,148 L414,47 Q505,47 596,53 L596,148 Z"
            fill="url(#area-fade)"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 1.5, delay: 0.5 }}
          />

          {/* Grid lines (Light Mode) */}
          {[148,118,88,58,28].map(y => <line key={y} x1="48" y1={y} x2="648" y2={y} stroke="#e2e8f0" strokeWidth="1" strokeDasharray="2 4" />)}
          {[48,168,288,408,528,648].map(x => <line key={x} x1={x} y1="20" x2={x} y2="148" stroke="#e2e8f0" strokeWidth="1" strokeDasharray="2 4" />)}
          <line x1="48" y1="148" x2="648" y2="148" stroke="#94a3b8" strokeWidth="1.5" />
          <line x1="48" y1="20" x2="48" y2="148" stroke="#94a3b8" strokeWidth="1.5" />

          {/* Y-axis labels */}
          <text transform="rotate(-90)" x="-84" y="14" className="text-[8px] fill-gray-400 font-mono uppercase tracking-[0.2em] font-bold" textAnchor="middle">Accuracy (%)</text>
          {[["88%","148"],["91%","115"],["94%","80"],["97%","45"],["99%","30"]].map(([l,y]) => (
            <text key={l} x="38" y={+y+3} className="text-[9px] fill-gray-400 font-mono font-semibold" textAnchor="end">{l}</text>
          ))}
          {/* X-axis labels */}
          <text x="168" y="166" className="text-[10px] fill-gray-400 font-mono font-semibold" textAnchor="middle">10M</text>
          <text x="288" y="166" className="text-[10px] fill-gray-400 font-mono font-semibold" textAnchor="middle">15M</text>
          <text x="408" y="166" className="text-[10px] fill-gray-400 font-mono font-semibold" textAnchor="middle">20M</text>
          <text x="528" y="166" className="text-[10px] fill-gray-400 font-mono font-semibold" textAnchor="middle">25M</text>
          <text x="348" y="184" className="text-[8px] fill-gray-400 font-mono uppercase tracking-[0.2em] font-bold" textAnchor="middle">Parameters (M)</text>

          {/* Efficiency frontier dashed background underlay */}
          <path
            d="M414,47 Q505,47 596,53"
            fill="none"
            stroke="#e2e8f0"
            strokeWidth="1.5"
            strokeDasharray="4 4"
          />

          {/* Efficiency frontier dashed */}
          <motion.path
            d="M414,47 Q505,47 596,53"
            fill="none"
            stroke="url(#line-grad)"
            strokeWidth="2.5"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: 1 }}
            transition={{ duration: 1.5, ease: "easeOut" }}
          />

          {/* ConvNeXtTiny - 27.8M, 97.48% */}
          <g className="group cursor-pointer">
            <motion.circle cx="596" cy="53" r="6" fill="#6366f1" whileHover={{ scale: 1.3 }} />
            <rect x="542" y="63" width="85" height="20" rx="10" fill="white" stroke="#e2e8f0" strokeWidth="1" />
            <text x="584.5" y="76.5" className="text-[9px] fill-gray-600 font-mono font-bold" textAnchor="middle">ConvNeXtTiny</text>
          </g>

          {/* ResNet50 - 23.6M, 98.11% */}
          <g className="group cursor-pointer">
            <motion.circle cx="494" cy="47" r="6" fill="#94a3b8" whileHover={{ scale: 1.3 }} />
            <rect x="457" y="57" width="75" height="20" rx="10" fill="white" stroke="#e2e8f0" strokeWidth="1" />
            <text x="494.5" y="70.5" className="text-[9px] fill-gray-500 font-mono font-bold" textAnchor="middle">ResNet50</text>
          </g>

          {/* EfficientNetB0 - 20.3M, 98.11% (Winner) */}
          <g className="group cursor-pointer">
            <motion.circle cx="414" cy="47" r="32" fill="var(--brand-primary)" opacity="0.04" />
            <motion.circle cx="414" cy="47" r="16" fill="var(--brand-primary)" opacity="0.1" />
            <motion.circle cx="414" cy="47" r="6" fill="var(--brand-primary)" filter="url(#glow-point-light)" whileHover={{ scale: 1.5 }} />

            <rect x="340" y="20" width="90" height="20" rx="10" fill="var(--brand-primary)" />
            <text x="385" y="33.5" className="text-[9px] fill-white font-mono font-bold" textAnchor="middle">EfficientNetB0</text>
          </g>

        </svg>
      </div>

      {/* Vertical Spec Sheets Grid */}
      <div className="col-span-12 grid grid-cols-1 md:grid-cols-3 divide-y md:divide-y-0 md:divide-x divide-[var(--border-base)]">
        {ARCH_CARDS.map(({ name, sub, acc, f1, lat, winner, strengths }, index) => {
          const rowData = BENCH_ROWS.find(r => r.model.includes(name.split(" ")[0])) || BENCH_ROWS[index];
          return (
            <div key={name} className={`flex flex-col ${winner ? 'bg-[color-mix(in_srgb,var(--brand-primary)_3%,var(--bg-card))]' : 'bg-[var(--bg-card)]'}`}>
              {/* Card Header */}
              <div className="p-8 pb-6 border-b border-[var(--border-subtle)]">
                <div className="flex justify-between items-start mb-4">
                  <h3 className="font-display text-2xl font-bold text-gray-900 tracking-tight">{name}</h3>
                  {winner && (
                    <span className="inline-flex items-center gap-1.5 bg-[color-mix(in_srgb,var(--brand-primary)_10%,transparent)] text-[var(--text-brand)] text-[10px] font-bold uppercase tracking-widest px-2.5 py-1 rounded-sm border border-[color-mix(in_srgb,var(--brand-primary)_20%,transparent)]">
                      <IconStar /> Best
                    </span>
                  )}
                </div>
                <p className="font-mono text-[11px] uppercase tracking-[0.15em] text-gray-400 mb-6">{sub}</p>
                <div className={`font-mono text-5xl font-bold tracking-tighter mb-4 ${winner ? 'text-[var(--text-brand)]' : 'text-gray-900'}`}>
                  {acc}
                </div>
                <div className="flex gap-6">
                  <div className="flex flex-col gap-0.5">
                    <span className="font-mono text-[10px] text-gray-400 uppercase tracking-widest">F1 Score</span>
                    <strong className="font-mono text-sm text-gray-800">{f1}</strong>
                  </div>
                  <div className="flex flex-col gap-0.5">
                    <span className="font-mono text-[10px] text-gray-400 uppercase tracking-widest">Latency</span>
                    <strong className="font-mono text-sm text-gray-800">{lat}</strong>
                  </div>
                </div>
              </div>

              {/* Benchmark specs - dotted leader table */}
              <div className="p-8 pt-6 border-b border-[var(--border-subtle)]">
                <div className="font-mono text-[11px] font-bold text-gray-400 uppercase tracking-[0.15em] mb-5">Detailed Specs</div>
                <div className="space-y-4">
                  <div className="flex items-baseline gap-2">
                    <span className="font-mono text-xs text-gray-500 shrink-0">Total Errors</span>
                    <span className="flex-1 border-b border-dotted border-[var(--border-subtle)]" />
                    <span className="font-mono text-xs font-bold text-gray-900 shrink-0">{rowData.errors}</span>
                  </div>
                  <div className="flex items-baseline gap-2">
                    <span className="font-mono text-xs text-gray-500 shrink-0">Model Size</span>
                    <span className="flex-1 border-b border-dotted border-[var(--border-subtle)]" />
                    <span className="font-mono text-xs font-bold text-gray-900 shrink-0">{rowData.size}</span>
                  </div>
                </div>
              </div>

              {/* Strengths */}
              <div className="p-8 pt-6 flex-1">
                <div className="font-mono text-[11px] font-bold text-gray-400 uppercase tracking-[0.15em] mb-5">Verdict</div>
                <ul className="space-y-3.5">
                  {strengths.map(s => (
                    <li key={s} className="flex items-start gap-3 font-body text-[13px] text-gray-500 leading-relaxed">
                      <span className={`shrink-0 mt-0.5 ${winner ? 'text-[var(--text-brand)]' : 'text-gray-400'}`}>
                        <IconCheck />
                      </span>
                      {s}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          );
        })}
      </div>

      {/* Research findings Ribbon */}
      <div className="col-span-12 bg-[var(--bg-card)] flex flex-col md:flex-row divide-y md:divide-y-0 md:divide-x divide-[var(--border-subtle)]">
        {FINDINGS.map(({ title, body }) => (
          <div key={title} className="flex-1 p-8 group">
            <div className="font-mono text-[11px] font-bold text-gray-900 tracking-[0.15em] uppercase mb-3 group-hover:text-[var(--text-brand)] transition-colors">{title}</div>
            <div className="font-body text-[13px] text-gray-500 leading-relaxed">{body}</div>
          </div>
        ))}
      </div>
    </motion.div>
  );
}

/* Tab navigation */
/* TAB NAVIGATION                                                          */
/* End tab navigation header */
type Tab = "base" | "ensemble" | "arch";

const TABS: { id: Tab; label: string; shortLabel: string; icon: React.ReactNode }[] = [
  { id: "base",     label: "Base Model",             shortLabel: "Base",         icon: <IconShield /> },
  { id: "ensemble", label: "Ensemble Model",          shortLabel: "Ensemble",     icon: <IconBranch /> },
  { id: "arch",     label: "Architecture Comparison", shortLabel: "Architecture", icon: <IconScatter /> },
];

/* Main export */
/* MAIN EXPORT                                                             */
/* End main export header */
export default function Validation({ sectionId = "performance" }: { sectionId?: string }) {
  const [active, setActive] = useState<Tab>("base");
  const [view, setView] = useState<MetricsView>(DEFAULT_VIEW);
  const sectionRef = useRef<HTMLElement>(null);

  /* Pull live numbers from /api/metrics, but only once the Performance section
     approaches the viewport — keeps the ~0.7 MB payload off the initial load.
     Silently keeps static fallback values on failure. */
  useEffect(() => {
    const section = sectionRef.current;
    if (!section) return;
    let cancelled = false;
    let fetched = false;

    const fetchMetrics = () => {
      if (fetched) return;
      fetched = true;
      getMetrics()
        .then((data) => {
          if (!cancelled) setView(buildMetricsView(data));
        })
        .catch(() => {
          /* offline / backend down → static fallback values remain */
        });
    };

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          fetchMetrics();
          observer.disconnect();
        }
      },
      { rootMargin: "800px 0px" }
    );
    observer.observe(section);

    return () => {
      cancelled = true;
      observer.disconnect();
    };
  }, []);

  return (
    <MetricsContext.Provider value={view}>
    <section
      ref={sectionRef}
      id={sectionId}
      aria-labelledby="performance-heading"
      className="relative pt-24 pb-32 overflow-hidden"
      style={{
        background: "var(--bg-page)",
        borderTop: "1px solid var(--border-base)",
        transition: "background-color 250ms ease",
      }}
    >
      {/* Premium ambient background */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            "radial-gradient(ellipse at top, color-mix(in srgb, var(--brand-cyan) 10%, transparent) 0%, transparent 62%)",
        }}
      />

      <div className="relative max-w-[1264px] mx-auto px-6 md:px-12">

        {/* Section header */}
        <div className="mb-16">
          <h2 id="performance-heading" className="font-display text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight text-gray-900 mb-6">
            Rigorous Benchmarking
          </h2>
          <p className="font-body text-lg md:text-xl text-gray-500 leading-relaxed max-w-2xl">
            Model performance validated on a held-out test split unseen during training or hyperparameter tuning.
          </p>
        </div>

        {/* Tab navigation */}
        <div role="tablist" aria-label="Benchmark views" className="inline-flex max-w-full rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-card)] p-1.5 mb-10 overflow-x-auto overflow-y-hidden no-scrollbar shadow-[0_8px_24px_rgba(0,0,0,0.035)] gap-1">
          {TABS.map(({ id, label, shortLabel, icon }) => {
            const isActive = active === id;
            return (
              <button
                key={id}
                id={`tab-${id}`}
                role="tab"
                aria-label={label}
                aria-selected={isActive}
                aria-controls={`panel-${id}`}
                onClick={() => setActive(id)}
                className={`
                  relative flex min-h-10 items-center gap-2.5 rounded-lg px-4 py-2 transition-colors duration-300 whitespace-nowrap z-10
                  ${isActive ? 'text-[var(--brand-primary)]' : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'}
                `}
              >
                {isActive && (
                  <motion.div
                    layoutId="activeTabIndicator"
                    className="absolute inset-0 rounded-lg bg-[color-mix(in_srgb,var(--brand-primary)_15%,transparent)] border border-[color-mix(in_srgb,var(--brand-primary)_30%,transparent)] shadow-[0_0_15px_color-mix(in_srgb,var(--brand-primary)_10%,transparent)] -z-10"
                    transition={{ type: "spring", bounce: 0.2, duration: 0.6 }}
                  />
                )}
                {!isActive && (
                  <div className="absolute inset-0 rounded-lg bg-[var(--bg-alt)] opacity-0 hover:opacity-100 transition-opacity duration-300 -z-10" />
                )}
                <span className={`flex transition-transform duration-300 ${isActive ? 'scale-110' : ''}`}>{icon}</span>
                <span className="font-body text-sm font-semibold sm:hidden">{shortLabel}</span>
                <span className="hidden font-body text-sm font-semibold sm:inline">{label}</span>
              </button>
            );
          })}
        </div>

        {/* Animated panels */}
        <div className="min-h-[800px]">
          <AnimatePresence mode="wait">
            <motion.div
              key={active}
              id={`panel-${active}`}
              role="tabpanel"
              aria-labelledby={`tab-${active}`}
              initial={{ opacity: 0, y: 15, filter: 'blur(4px)' }}
              animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
              exit={{ opacity: 0, y: -10, filter: 'blur(4px)' }}
              transition={{ duration: 0.4, ease: [0.25, 0.46, 0.45, 0.94] }}
            >
              {active === "base"     && <BaseModelPanel />}
              {active === "ensemble" && <EnsemblePanel />}
              {active === "arch"     && <ArchPanel />}
            </motion.div>
          </AnimatePresence>
        </div>

      </div>
    </section>
    </MetricsContext.Provider>
  );
}
