import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";

export function ScanningGrid() {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        overflow: "hidden",
        pointerEvents: "none",
        zIndex: 10,
        mixBlendMode: "screen",
      }}
    >
      {/* Sonar sweep overlay */}
      <motion.div
        initial={{ top: "-100%" }}
        animate={{ top: "100%" }}
        transition={{
          duration: 2.5,
          ease: "linear",
          repeat: Infinity,
        }}
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          height: "150%",
          background: "linear-gradient(to bottom, transparent, rgba(var(--scan-color-rgb), 0.1) 80%, rgba(var(--scan-color-rgb), 0.6) 95%, rgba(var(--scan-color-rgb), 0.8) 100%)",
          boxShadow: "0 4px 20px rgba(var(--scan-color-rgb), 0.3)",
        }}
      />
      {/* Grid overlay */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          backgroundImage: `
            linear-gradient(to right, rgba(var(--scan-color-rgb), 0.1) 1px, transparent 1px),
            linear-gradient(to bottom, rgba(var(--scan-color-rgb), 0.1) 1px, transparent 1px)
          `,
          backgroundSize: "20px 20px",
          opacity: 0.5,
        }}
      />
    </div>
  );
}

export function NeuralNode() {
  return (
    <div style={{ position: "relative", width: "48px", height: "48px", display: "flex", alignItems: "center", justifyContent: "center" }}>
      {/* Central pulsing core */}
      <motion.div
        animate={{
          scale: [1, 1.4, 1],
          opacity: [0.7, 1, 0.7],
        }}
        transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
        style={{
          width: "12px",
          height: "12px",
          borderRadius: "50%",
          background: "var(--text-brand)",
          boxShadow: "0 0 15px var(--text-brand)",
          zIndex: 2,
        }}
      />
      {/* Orbiting nodes */}
      {[0, 1, 2].map((i) => (
        <motion.div
          key={i}
          animate={{ rotate: 360 }}
          transition={{
            duration: 3 + i,
            repeat: Infinity,
            ease: "linear",
          }}
          style={{ position: "absolute", inset: 0 }}
        >
          <motion.div
            animate={{ scale: [1, 1.5, 1], opacity: [0.3, 0.8, 0.3] }}
            transition={{ duration: 2, repeat: Infinity, delay: i * 0.5 }}
            style={{
              position: "absolute",
              top: 0,
              left: "50%",
              width: "6px",
              height: "6px",
              marginLeft: "-3px",
              borderRadius: "50%",
              background: "var(--text-brand)",
              boxShadow: "0 0 8px var(--text-brand)",
            }}
          />
          {/* Connecting line */}
          <div
            style={{
              position: "absolute",
              top: "6px",
              left: "50%",
              width: "1px",
              height: "18px",
              background: "linear-gradient(to bottom, var(--text-brand), transparent)",
              opacity: 0.4,
            }}
          />
        </motion.div>
      ))}
    </div>
  );
}

export function OrganicMesh() {
  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        position: "absolute",
        inset: 0,
        overflow: "hidden",
        opacity: 0.6,
        background: "var(--bg-alt)",
      }}
    >
      <motion.div
        animate={{
          scale: [1, 1.2, 1],
          x: ["-10%", "10%", "-10%"],
          y: ["-10%", "10%", "-10%"],
        }}
        transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
        style={{
          position: "absolute",
          top: "-50%",
          left: "-50%",
          width: "200%",
          height: "200%",
          background: "radial-gradient(circle at 30% 30%, color-mix(in srgb, var(--brand-cyan) 15%, transparent) 0%, transparent 50%), radial-gradient(circle at 70% 70%, color-mix(in srgb, var(--brand-primary) 15%, transparent) 0%, transparent 50%)",
          filter: "blur(20px)",
        }}
      />
    </div>
  );
}

export function CyclingStatusText({ modelMode = "ensemble" }: { modelMode?: string }) {
  const modelName = modelMode === "ensemble" ? "Ensemble Models" : "Base Model";
  const phrases = [
    `Loading ${modelName}...`,
    "Extracting Feature Maps...",
    "Computing Softmax...",
    "Applying Thresholds...",
  ];
  const [index, setIndex] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setIndex((prev) => (prev + 1) % phrases.length);
    }, 1200);
    return () => clearInterval(interval);
  }, [phrases.length]);

  return (
    <div style={{ position: "relative", display: "flex", justifyContent: "center", minHeight: "24px", width: "100%", textAlign: "center" }}>
      <AnimatePresence mode="wait">
        <motion.span
          key={index}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }}
          transition={{ duration: 0.3 }}
          style={{ display: "inline-block", fontFamily: "var(--font-mono)", fontSize: "13px", color: "var(--text-brand)", fontWeight: 600, letterSpacing: "0.02em", whiteSpace: "nowrap" }}
        >
          {phrases[index]}
        </motion.span>
      </AnimatePresence>
    </div>
  );
}

export function WireframePulse() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "18px", padding: "6px 0", width: "100%" }}>
      {[0, 1, 2].map((i) => (
        <div key={i} style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
          <div style={{ display: "flex", justifyContent: "space-between" }}>
            <motion.div
              animate={{ opacity: [0.3, 0.8, 0.3] }}
              transition={{ duration: 1.5, repeat: Infinity, delay: i * 0.2 }}
              style={{ height: "12px", width: "70px", background: "color-mix(in srgb, var(--text-brand) 15%, transparent)", borderRadius: "4px", border: "1px solid color-mix(in srgb, var(--text-brand) 30%, transparent)" }}
            />
            <motion.div
              animate={{ opacity: [0.3, 0.8, 0.3] }}
              transition={{ duration: 1.5, repeat: Infinity, delay: i * 0.2 + 0.1 }}
              style={{ height: "12px", width: "36px", background: "color-mix(in srgb, var(--text-brand) 15%, transparent)", borderRadius: "4px", border: "1px solid color-mix(in srgb, var(--text-brand) 30%, transparent)" }}
            />
          </div>
          <div style={{ position: "relative", height: "6px", background: "var(--border-faint)", borderRadius: "999px", overflow: "hidden" }}>
            <motion.div
              animate={{ x: ["-100%", "200%"] }}
              transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut", delay: i * 0.2 }}
              style={{ position: "absolute", top: 0, bottom: 0, left: 0, width: "50%", background: "linear-gradient(90deg, transparent, var(--text-brand), transparent)", opacity: 0.6 }}
            />
          </div>
        </div>
      ))}
    </div>
  );
}

export function ProcessingScanner() {
  return (
    <div style={{ position: "relative", width: "64px", height: "64px", display: "block", zIndex: 10 }}>
      {[0, 1, 2].map((i) => (
        <motion.div
          key={i}
          animate={{
            scale: [1, 2.5],
            opacity: [0.8, 0],
          }}
          transition={{
            duration: 2,
            repeat: Infinity,
            ease: "easeOut",
            delay: i * 0.6,
          }}
          style={{
            position: "absolute",
            top: "calc(50% - 12px)",
            left: "calc(50% - 12px)",
            width: "24px",
            height: "24px",
            borderRadius: "50%",
            border: "1px solid var(--text-brand)",
          }}
        />
      ))}
      <motion.div
        animate={{ scale: [1, 1.2, 1], opacity: [0.7, 1, 0.7] }}
        transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
        style={{
          position: "absolute",
          top: "calc(50% - 6px)",
          left: "calc(50% - 6px)",
          width: "12px",
          height: "12px",
          borderRadius: "50%",
          background: "var(--text-brand)",
          boxShadow: "0 0 15px var(--text-brand)",
          zIndex: 1,
        }}
      />
    </div>
  );
}
