import { useRef, useEffect, useState } from "react";
import { AnimatedTitle } from "./ui/AnimatedTitle";
import { AnimatedWordFade } from "./ui/AnimatedWordFade";

// ── Particle types ───────────────────────────────────────────────────────────
type ParticleKind = "dust" | "spark" | "bubble";

interface Particle {
  x: number;
  y: number;
  radius: number;
  speedY: number;
  angle: number;
  angleSpeed: number;
  drift: number;
  opacity: number;
  opacityMin: number;
  opacityMax: number;
  opacityDir: number;
  opacitySpeed: number;
  r: number;
  g: number;
  b: number;
  glow: boolean;
  kind: ParticleKind;
}

function initParticle(p: Particle, W: number, H: number, randomY = true) {
  const kinds: ParticleKind[] = ["dust", "dust", "dust", "spark", "spark", "bubble"];
  p.kind = kinds[Math.floor(Math.random() * kinds.length)];

  p.x = Math.random() * W;
  p.y = randomY ? Math.random() * H : H + Math.random() * 40;

  if (p.kind === "bubble") {
    p.radius = 2 + Math.random() * 4;
    p.speedY = 0.12 + Math.random() * 0.18;
    p.opacity = 0.06 + Math.random() * 0.14;
    p.opacityMin = 0.04;
    p.opacityMax = 0.18;
    p.glow = false;
    p.r = 180; p.g = 220; p.b = 255;
  } else if (p.kind === "spark") {
    p.radius = 1 + Math.random() * 1.8;
    p.speedY = 0.25 + Math.random() * 0.35;
    p.opacity = 0.4 + Math.random() * 0.5;
    p.opacityMin = 0.2;
    p.opacityMax = 0.9;
    p.glow = true;
    // bioluminescent cobalt / blue spectrum
    const palette = [
      [60, 79, 224],    // #3c4fe0 (Codex Blue)
      [125, 211, 252],  // #7dd3fc (Light Blue)
      [56, 189, 248],   // #38bdf8 (Marine Cyan)
      [165, 243, 252],  // #a5f3fc (Bright Cyan)
    ];
    const c = palette[Math.floor(Math.random() * palette.length)];
    p.r = c[0]; p.g = c[1]; p.b = c[2];
  } else {
    // dust — tiny, dim, slow
    p.radius = 0.5 + Math.random() * 1.2;
    p.speedY = 0.08 + Math.random() * 0.15;
    p.opacity = 0.08 + Math.random() * 0.22;
    p.opacityMin = 0.04;
    p.opacityMax = 0.3;
    p.glow = false;
    p.r = 200; p.g = 230; p.b = 255;
  }

  p.opacityDir = Math.random() > 0.5 ? 1 : -1;
  p.opacitySpeed = 0.002 + Math.random() * 0.004;
  p.angle = Math.random() * Math.PI * 2;
  p.angleSpeed = 0.003 + Math.random() * 0.006;
  p.drift = 0.4 + Math.random() * 0.8;
}

function createParticles(count: number, W: number, H: number): Particle[] {
  return Array.from({ length: count }, () => {
    const p = {} as Particle;
    initParticle(p, W, H, true);
    return p;
  });
}

// ── Canvas hook ─────────────────────────────────────────────────────────────
function useOceanCanvas(canvasRef: React.RefObject<HTMLCanvasElement | null>) {
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let W = 0, H = 0;
    let particles: Particle[] = [];
    let rafId = 0;

    function resize() {
      const parent = canvas!.parentElement;
      W = parent ? parent.offsetWidth : window.innerWidth;
      H = parent ? parent.offsetHeight : window.innerHeight;
      canvas!.width = W;
      canvas!.height = H;
      particles = createParticles(160, W, H);
    }

    function draw() {
      ctx!.clearRect(0, 0, W, H);

      // deep ocean gradient base
      const bg = ctx!.createLinearGradient(0, 0, 0, H);
      bg.addColorStop(0, "#04091a");
      bg.addColorStop(0.4, "#060e1e");
      bg.addColorStop(0.75, "#071226");
      bg.addColorStop(1, "#040c1c");
      ctx!.fillStyle = bg;
      ctx!.fillRect(0, 0, W, H);

      // subtle radial light bloom at center
      const bloom = ctx!.createRadialGradient(W * 0.5, H * 0.42, 0, W * 0.5, H * 0.42, W * 0.55);
      bloom.addColorStop(0, "rgba(14,50,90,0.28)");
      bloom.addColorStop(1, "rgba(4,9,26,0)");
      ctx!.fillStyle = bloom;
      ctx!.fillRect(0, 0, W, H);

      // particles
      for (const p of particles) {
        // opacity pulse
        p.opacity += p.opacityDir * p.opacitySpeed;
        if (p.opacity >= p.opacityMax) { p.opacity = p.opacityMax; p.opacityDir = -1; }
        if (p.opacity <= p.opacityMin) { p.opacity = p.opacityMin; p.opacityDir = 1; }

        // movement
        p.angle += p.angleSpeed;
        p.x += Math.sin(p.angle) * p.drift * 0.3;
        p.y -= p.speedY;

        // wrap to bottom when off top
        if (p.y + p.radius < 0) initParticle(p, W, H, false);

        ctx!.save();

        if (p.kind === "bubble") {
          // hollow circle
          ctx!.beginPath();
          ctx!.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
          ctx!.strokeStyle = `rgba(${p.r},${p.g},${p.b},${p.opacity})`;
          ctx!.lineWidth = 0.8;
          ctx!.stroke();
        } else {
          if (p.glow) {
            ctx!.shadowBlur = 8;
            ctx!.shadowColor = `rgba(${p.r},${p.g},${p.b},0.7)`;
          }
          ctx!.beginPath();
          ctx!.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
          ctx!.fillStyle = `rgba(${p.r},${p.g},${p.b},${p.opacity})`;
          ctx!.fill();
        }

        ctx!.restore();
      }

      rafId = requestAnimationFrame(draw);
    }

    resize();

    // Only animate while the hero canvas is on screen — pausing the 160-particle
    // loop once scrolled past frees the main thread for smoother scrolling below.
    let running = false;
    const start = () => { if (!running) { running = true; draw(); } };
    const stop = () => { running = false; cancelAnimationFrame(rafId); };

    const io = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) start(); else stop(); },
      { threshold: 0 }
    );
    io.observe(canvas.parentElement ?? canvas);

    const ro = new ResizeObserver(resize);
    ro.observe(canvas.parentElement!);

    return () => {
      stop();
      io.disconnect();
      ro.disconnect();
    };
  }, [canvasRef]);
}

// ── Component ───────────────────────────────────────────────────────────────
function PipelineDiagram() {
  const diagramRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let ctx: { revert: () => void } | null = null;
    let cancelled = false;

    const run = async () => {
      const { default: gsap } = await import("gsap");
      if (cancelled || !diagramRef.current) return;

      ctx = gsap.context(() => {
      const q = gsap.utils.selector(diagramRef);
      const blocks = q(".net-block");
      const blockFills = q(".net-block-fill");
      const particles = q(".data-particle");
      const heatNodes = q(".heat-node");

      gsap.set(blocks, { transformOrigin: "50% 50%" });
      gsap.set(blockFills, { opacity: 0 });
      gsap.set(particles, { opacity: 0, scale: 0.6, transformOrigin: "50% 50%" });
      gsap.set(q(".white-pulse"), { opacity: 0, x: -42 });
      gsap.set(q(".flow-main"), { strokeDasharray: 360, strokeDashoffset: 360 });
      gsap.set(q(".flow-verdict"), { strokeDasharray: 40, strokeDashoffset: 40 });
      gsap.set(q(".flow-return"), { strokeDasharray: 420, strokeDashoffset: 420 });
      gsap.set(q(".ticker-shell"), { opacity: 0, scaleX: 0.72, transformOrigin: "left center" });
      gsap.set(q(".ticker-text"), { opacity: 0, y: 8 });
      gsap.set(heatNodes, { opacity: 0, scale: 0.45, transformOrigin: "50% 50%" });

      const tl = gsap.timeline({
        repeat: -1,
        repeatDelay: 0.55,
        defaults: { ease: "power2.inOut" },
      });

      tl.to(q(".white-pulse"), { opacity: 1, x: 0, duration: 0.32 }, 0)
        .to(q(".white-pulse"), { x: 112, duration: 0.92, ease: "power3.inOut" }, 0.16)
        .to(q(".coral-line"), { strokeWidth: 2.8, duration: 0.2, stagger: 0.03, yoyo: true, repeat: 1 }, 0.7)
        .to(q(".flow-main"), { strokeDashoffset: 0, duration: 1.45 }, 0.58)
        .to(
          particles,
          {
            opacity: 1,
            scale: 1,
            x: (i) => 122 + i * 38,
            duration: 0.58,
            stagger: 0.07,
            ease: "power3.in",
          },
          0.78
        )
        .to(particles, { opacity: 0, scale: 0.35, duration: 0.22, stagger: 0.05 }, 1.35)
        .to(blockFills, { opacity: 0.72, duration: 0.2, stagger: 0.16 }, 0.92)
        .to(
          blocks,
          {
            scale: 1.045,
            filter: "url(#hero-diagram-blue-glow)",
            duration: 0.2,
            stagger: 0.16,
            yoyo: true,
            repeat: 1,
          },
          0.92
        )
        .to(q(".flow-verdict"), { strokeDashoffset: 0, duration: 0.82, ease: "power2.out" }, 2.05)
        .to(q(".ticker-shell"), { opacity: 1, scaleX: 1, duration: 0.34, ease: "power3.out" }, 2.3)
        .to(q(".ticker-text"), { opacity: 1, y: 0, duration: 0.32, ease: "power3.out" }, 2.44)
        .to(q(".flow-return"), { strokeDashoffset: 0, duration: 1.06 }, 2.26)
        .to(heatNodes, { opacity: 0.82, scale: 1, duration: 0.42, stagger: 0.09, ease: "power3.out" }, 2.82)
        .to(heatNodes, { opacity: 0.28, scale: 1.32, duration: 0.7, stagger: 0.07, yoyo: true, repeat: 1, ease: "sine.inOut" }, 3.2)
        .to(q(".ticker-text"), { opacity: 0, y: -8, duration: 0.3 }, 4.25)
        .to(q(".ticker-shell"), { opacity: 0, scaleX: 0.82, duration: 0.34 }, 4.35)
        .to(q(".flow-main, .flow-verdict, .flow-return"), { strokeDashoffset: 360, duration: 0.42 }, 4.45)
        .to(blockFills, { opacity: 0, duration: 0.34, stagger: 0.04 }, 4.45)
        .to(heatNodes, { opacity: 0, scale: 0.55, duration: 0.35, stagger: 0.04 }, 4.45)
        .to(q(".white-pulse"), { opacity: 0, duration: 0.25 }, 4.55);
      }, diagramRef);
    };

    run();
    return () => {
      cancelled = true;
      ctx?.revert();
    };
  }, []);

  return (
    <div
      ref={diagramRef}
      style={{
        width: "100%",
        height: "100%",
        minHeight: "430px",
        borderRadius: "24px",
        background: "#0d1738", // Deep contrast surface token
        border: "1px solid rgba(255,255,255,0.08)",
        boxShadow: "0 24px 60px -20px rgba(0,0,0,0.5), inset 0 0 100px rgba(0,87,230,0.1)",
        overflow: "hidden",
        position: "relative"
      }}
    >
      <svg
        viewBox="0 0 664 520"
        width="100%"
        height="100%"
        role="img"
        aria-label="Animated Image to Explanation pipeline showing coral input, EfficientNet processing, classification verdict, and Grad-CAM attention return"
        style={{ display: "block", position: "relative", zIndex: 2 }}
      >
        <defs>
          <filter id="hero-diagram-blue-glow" x="-100%" y="-100%" width="300%" height="300%">
            <feGaussianBlur stdDeviation="12" result="blur" />
            <feFlood floodColor="#0057e6" floodOpacity="0.9" />
            <feComposite in2="blur" operator="in" result="glow" />
            <feComponentTransfer in="glow" result="intensifiedGlow">
              <feFuncA type="linear" slope="1.5" />
            </feComponentTransfer>
            <feMerge>
              <feMergeNode in="intensifiedGlow" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          <filter id="hero-diagram-cyan-glow" x="-100%" y="-100%" width="300%" height="300%">
            <feGaussianBlur stdDeviation="12" result="blur" />
            <feFlood floodColor="#38bdf8" floodOpacity="0.9" />
            <feComposite in2="blur" operator="in" result="glow" />
            <feComponentTransfer in="glow" result="intensifiedGlow">
              <feFuncA type="linear" slope="1.5" />
            </feComponentTransfer>
            <feMerge>
              <feMergeNode in="intensifiedGlow" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>

          <filter id="motion-blur" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="8 0" />
          </filter>

          <linearGradient id="hero-diagram-blue-fade" x1="0" x2="1" y1="0" y2="0">
            <stop offset="0%" stopColor="#0057e6" stopOpacity="0" />
            <stop offset="45%" stopColor="#0057e6" stopOpacity="1" />
            <stop offset="100%" stopColor="#0057e6" stopOpacity="0.2" />
          </linearGradient>

          <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
             <path d="M 40 0 L 0 0 0 40" fill="none" stroke="rgba(255,255,255,0.03)" strokeWidth="1"/>
          </pattern>
        </defs>

        <rect width="100%" height="100%" fill="url(#grid)" />

        <text x="42" y="48" fill="#FFFFFF" opacity="0.9" fontFamily="var(--font-mono)" fontSize="12" letterSpacing="4">
          IMAGE TO EXPLANATION
        </text>
        <text x="42" y="474" fill="#FFFFFF" opacity="0.4" fontFamily="var(--font-mono)" fontSize="10" letterSpacing="2">
          INPUT / EFFICIENTNET-B0 / GRAD-CAM
        </text>

        <g transform="translate(86 210)">
          {/* Main central data spine for the input pulse */}
          <path className="coral-line" d="M -28 92 L 174 92" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />

          {/* Top branching canopy */}
          <path className="coral-line" d="M 10 92 Q 20 60 50 50 Q 70 40 80 30" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
          <path className="coral-line" d="M 60 92 Q 80 50 120 40 Q 140 35 150 25" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
          <path className="coral-line" d="M 120 92 Q 130 70 150 75 Q 165 80 170 60" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />

          {/* Lower branching roots */}
          {/* This branch perfectly meets the flow-return Grad-CAM cyan line! */}
          <path className="coral-line" d="M 40 92 Q 60 120 88 114" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
          <path className="coral-line" d="M 100 92 Q 120 130 140 125" fill="none" stroke="#FFFFFF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />

          {/* Heat nodes exactly at branch tips and I/O nodes */}
          <circle className="heat-node" cx="80" cy="30" r="14" fill="#38bdf8" opacity="0" filter="url(#hero-diagram-cyan-glow)" />
          {/* Output node connecting to flow-main */}
          <circle className="heat-node" cx="174" cy="92" r="16" fill="#38bdf8" opacity="0" filter="url(#hero-diagram-cyan-glow)" />
          {/* Grad-CAM receiving node connecting to flow-return */}
          <circle className="heat-node" cx="88" cy="114" r="18" fill="#38bdf8" opacity="0" filter="url(#hero-diagram-cyan-glow)" />

          <circle className="white-pulse" cx="-28" cy="92" r="8" fill="#FFFFFF" filter="url(#hero-diagram-blue-glow)" />
        </g>

        <path className="flow-main" d="M260 302 C318 302 322 124 384 124" fill="none" stroke="url(#hero-diagram-blue-fade)" strokeWidth="3" strokeLinecap="round" />
        {/* Adjusted flow-return to exit from the bottom block and sweep smoothly to the coral */ }
        <path className="flow-return" d="M422 372 C422 430 250 430 174 324" fill="none" stroke="#38bdf8" strokeWidth="3" strokeLinecap="round" filter="url(#hero-diagram-cyan-glow)" opacity="0.8" />
        {/* Extended flow-verdict to meet the shifted classification box */ }
        <path className="flow-verdict" d="M470 166 L485 166" fill="none" stroke="#f43f5e" strokeWidth="3" strokeLinecap="round" />

        {/* STRUCTURALLY ALIGNED 2D BLOCKS */}
        <g>
          {[0, 1, 2, 3, 4].map((i) => (
            <g key={i} transform={`translate(374 ${102 + i * 58})`}>
              {/* Premium Glassmorphic Layering */}
              <rect className="net-block" x="-4" y="-4" width="104" height="46" rx="12" fill="rgba(0, 87, 230, 0.05)" stroke="rgba(255,255,255,0.15)" strokeWidth="1" />
              <rect className="net-block" x="0" y="0" width="96" height="38" rx="10" fill="rgba(13, 23, 56, 0.8)" stroke="#FFFFFF" strokeWidth="1.5" />
              <rect className="net-block-fill" x="4" y="4" width="88" height="30" rx="8" fill="#0057e6" opacity="0" />
              <line x1="18" x2="78" y1="19" y2="19" stroke="#FFFFFF" strokeWidth="1" opacity="0.55" />
            </g>
          ))}
        </g>

        {[0, 1, 2, 3, 4, 5].map((i) => (
          <circle
            key={i}
            className="data-particle"
            cx="244"
            cy={302 - i * 7}
            r={3 + (i % 2)}
            fill={i % 2 ? "#FFFFFF" : "#0057e6"}
            filter="url(#motion-blur)"
          />
        ))}

        <g opacity="0.8">
          <circle cx="386" cy="488" r="4" fill="#0057e6" />
          <circle cx="410" cy="488" r="4" fill="#FFFFFF" opacity="0.4" />
          <circle cx="434" cy="488" r="4" fill="#38bdf8" />
        </g>
      </svg>

      {/* PERFECTLY ALIGNED GLASSMORPHISM TICKER WITH ARROW */}
      <svg style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", pointerEvents: "none" }} viewBox="0 0 664 520">
        <foreignObject x="485" y="126" width="170" height="82" className="ticker-shell">
          <div style={{
            position: "relative",
            width: "100%",
            height: "100%",
            background: "rgba(255, 255, 255, 0.04)",
            backdropFilter: "blur(12px)",
            border: "1px solid rgba(255,255,255,0.1)",
            borderRadius: "16px",
            boxShadow: "0 8px 32px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.2)",
            display: "flex",
            flexDirection: "column",
            gap: "8px",
            padding: "16px",
            boxSizing: "border-box"
          }}>
            {/* Directional Arrow joining to flow-verdict */}
            <div style={{
              position: "absolute",
              left: "-7px",
              top: "34px",
              width: 0,
              height: 0,
              borderTop: "6px solid transparent",
              borderBottom: "6px solid transparent",
              borderRight: "7px solid #f43f5e",
              filter: "drop-shadow(-2px 0 4px rgba(244,63,94,0.5))"
            }} />

            <div style={{ width: "100%", height: "4px", background: "#f43f5e", borderRadius: "4px", opacity: 0.6 }} />
            <div style={{ display: "flex", flexDirection: "column", gap: "2px", marginTop: "4px" }}>
              <span className="ticker-text" style={{ color: "#FFFFFF", fontFamily: "var(--font-mono)", fontSize: "10px", fontWeight: 700, letterSpacing: "1px", opacity: 0.8 }}>
                CLASSIFICATION
              </span>
              <span className="ticker-text" style={{ color: "#f43f5e", fontFamily: "var(--font-mono)", fontSize: "13px", fontWeight: 700, textShadow: "0 0 12px rgba(244,63,94,0.5)", whiteSpace: "nowrap" }}>
                BLEACHED (92.4%)
              </span>
            </div>
          </div>
        </foreignObject>
      </svg>

    </div>
  );
}

export default function Hero() {
  const sectionRef = useRef<HTMLElement>(null);
  const bgWrapRef = useRef<HTMLDivElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const [shouldLoadVideo, setShouldLoadVideo] = useState(false);

  // Let the first paint and critical app code settle before fetching/decoding
  // the decorative hero video. The gradient/mesh background carries the hero
  // while the video attaches shortly after idle.
  useEffect(() => {
    let timeoutId = 0;
    const idleId =
      "requestIdleCallback" in window
        ? window.requestIdleCallback(() => setShouldLoadVideo(true), { timeout: 1600 })
        : undefined;

    if (idleId === undefined) {
      timeoutId = window.setTimeout(() => setShouldLoadVideo(true), 1200);
    }

    return () => {
      if (idleId !== undefined) window.cancelIdleCallback(idleId);
      clearTimeout(timeoutId);
    };
  }, []);

  // Pause the background video while the hero is scrolled out of view so the
  // browser isn't decoding/compositing 4.4MB of video behind lower sections.
  useEffect(() => {
    const video = videoRef.current;
    const section = sectionRef.current;
    if (!video || !section || !shouldLoadVideo) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) video.play().catch(() => {});
        else video.pause();
      },
      { threshold: 0 }
    );
    observer.observe(section);
    return () => observer.disconnect();
  }, [shouldLoadVideo]);

  useEffect(() => {
    let ctx: { revert: () => void } | null = null;
    let cancelled = false;

    const run = async () => {
      const [{ default: gsap }, scrollTriggerModule] = await Promise.all([
        import("gsap"),
        import("gsap/ScrollTrigger"),
      ]);
      if (cancelled || !sectionRef.current) return;

      gsap.registerPlugin(scrollTriggerModule.ScrollTrigger);
      ctx = gsap.context(() => {
      // ── Entrance sequence ─────────────────────────────────────────────────
      const tl = gsap.timeline({ defaults: { ease: "power3.out" } });

      tl.fromTo(
        "[data-hero='badge']",
        { y: 24, opacity: 0 },
        { y: 0, opacity: 1, duration: 0.75 },
        0.3
      )
        // Headline animated via Framer Motion
        .fromTo(
          "[data-hero='copy']",
          { y: 24, opacity: 0 },
          { y: 0, opacity: 1, duration: 0.7 },
          0.65
        )
        .fromTo(
          "[data-hero='cta']",
          { y: 20, opacity: 0 },
          { y: 0, opacity: 1, duration: 0.65 },
          0.82
        );

      // ── Parallax: canvas field slowly zooms on scroll ─────────────────────
      gsap.to(bgWrapRef.current, {
        scale: 1.12,
        ease: "none",
        scrollTrigger: {
          trigger: sectionRef.current,
          start: "top top",
          end: "bottom top",
          scrub: true,
        },
      });

      // ── Content drifts up + fades on scroll ───────────────────────────────
      gsap.to(contentRef.current, {
        y: -60,
        opacity: 0,
        ease: "none",
        scrollTrigger: {
          trigger: sectionRef.current,
          start: "30% top",
          end: "80% top",
          scrub: true,
        },
      });
      }, sectionRef);
    };

    run();
    return () => {
      cancelled = true;
      ctx?.revert();
    };
  }, []);

  return (
    <section
      ref={sectionRef}
      id="hero"
      data-theme="dark"
      aria-labelledby="hero-heading"
      className="paper-grain ambient-oceanic-mesh"
      style={{
        position: "relative",
        width: "100%",
        minHeight: "88svh",
        display: "flex",
        flexDirection: "column",
        alignItems: "stretch",
        justifyContent: "center",
        overflow: "hidden",
        backgroundColor: "var(--hero-bg-base)",
        paddingTop: "96px",
        paddingBottom: "112px",
        transition: "background-color 250ms ease, padding 250ms ease",
      }}
    >
      {/* ── Canvas background (scaled by ScrollTrigger) ───────────────────── */}
      <div
        ref={bgWrapRef}
        aria-hidden="true"
        style={{
          position: "absolute",
          inset: "-10%",
          transformOrigin: "center center",
          willChange: "transform",
        }}
      >
        <video
          ref={videoRef}
          aria-hidden="true"
          autoPlay
          muted
          loop
          playsInline
          preload="metadata"
          src={shouldLoadVideo ? "/static/video/Abstract_neural_network_feature_map_202605262149.mp4" : undefined}
          style={{
            display: "block",
            width: "100%",
            height: "100%",
            objectFit: "cover",
            opacity: "var(--hero-video-opacity)",
            mixBlendMode: "var(--hero-video-blend)" as any,
            transition: "opacity 250ms ease",
          }}
        />
      </div>

      {/* ── Overlay stack ───────────────────────────────────────────────────── */}
      {/* Radial vignette */}
      <div
        aria-hidden="true"
        style={{
          position: "absolute",
          inset: 0,
          background: "var(--hero-vignette)",
          zIndex: 2,
          transition: "background 250ms ease",
        }}
      />
      {/* Bottom gradient bleed */}
      <div
        aria-hidden="true"
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          height: "38%",
          background: "var(--hero-bleed)",
          zIndex: 3,
          transition: "background 250ms ease",
        }}
      />
      {/* Top fade for nav */}
      <div
        aria-hidden="true"
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          height: "18%",
          background: "var(--hero-top-fade)",
          zIndex: 3,
          transition: "background 250ms ease",
        }}
      />

      {/* Cyan scan-line */}
      <div
        aria-hidden="true"
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          height: "1px",
          background:
            "linear-gradient(90deg, transparent 0%, rgba(56,189,248,0.45) 30%, rgba(14,165,233,0.65) 50%, rgba(56,189,248,0.45) 70%, transparent 100%)",
          zIndex: 10,
        }}
      />

      {/* ── Content ─────────────────────────────────────────────────────────── */}
      <div
        ref={contentRef}
        style={{
          position: "relative",
          zIndex: 5,
          width: "100%",
          maxWidth: "1280px",
          margin: "0 auto",
          padding: "0 clamp(24px, 6vw, 48px)",
          display: "flex",
          flexDirection: "column",
          alignItems: "flex-start",
          textAlign: "left",
          gap: "32px",
        }}
      >
        {/* Architecture Badge */}
        <div data-hero="badge" style={{ opacity: 0 }}>
          <span className="research-stamp">
            <span
              style={{
                display: "inline-block",
                width: "6px",
                height: "6px",
                borderRadius: "50%",
                background: "#38bdf8",
                boxShadow: "0 0 8px rgba(56, 189, 248, 0.65)",
                flexShrink: 0,
              }}
              aria-hidden="true"
            />
            Coral Health AI Research · Vol. 26.5 · EfficientNet-B0 Ensemble
          </span>
        </div>

        {/* H1 Headline */}
        <div data-hero="headline">
          <h1
            id="hero-heading"
            style={{
              fontFamily: "var(--font-display)",
              fontSize: "var(--text-hero)",
              fontWeight: 600,
              lineHeight: "var(--leading-hero)",
              letterSpacing: "var(--tracking-display)",
              color: "var(--hero-text-title)",
              margin: 0,
              maxWidth: "720px",
              overflowWrap: "anywhere",
              transition: "color 250ms ease",
            }}
          >
            <AnimatedTitle
              segments={[
                { text: "Coral Health " },
                {
                  text: "Assessment",
                  style: {
                    fontStyle: "italic",
                    fontFamily: "var(--font-display)",
                    color: "#38bdf8",
                    fontWeight: 400,
                    textShadow: "0 0 20px rgba(56, 189, 248, 0.4)"
                  }
                },
                { text: "\nVia CNN" }
              ]}
            />
          </h1>
        </div>

        {/* Supporting copy */}
        <div
          data-hero="copy"
          style={{
            opacity: 0,
            display: "flex",
            flexDirection: "column",
            alignItems: "flex-start",
            gap: "20px",
          }}
        >
          <p
            style={{
              fontFamily: "var(--font-body)",
              fontSize: "var(--text-body-lg)",
              fontWeight: 400,
              lineHeight: "var(--leading-body)",
              color: "var(--hero-text-copy)",
              margin: 0,
              maxWidth: "var(--measure-hero)",
              transition: "color 250ms ease",
            }}
          >
            EfficientNet-B0 CNN classifying reef images into{" "}
            <span style={{ color: "#10b981", fontWeight: 650 }}>Healthy</span>,{" "}
            <span style={{ color: "#d97706", fontWeight: 650 }}>Bleached</span>, and{" "}
            <span style={{ color: "#dc2626", fontWeight: 650 }}>Dead</span> coral
            classes — reporting{" "}
            <span
              style={{
                fontFamily: "var(--font-mono)",
                fontWeight: 600,
                color: "#38bdf8",
                textShadow: "0 0 15px rgba(56, 189, 248, 0.25)",
              }}
            >
              98.11%
            </span>{" "}
            held-out accuracy.
          </p>

          {/* Accuracy chip */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "12px",
              flexWrap: "wrap",
              justifyContent: "flex-start",
            }}
          >
            <div
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: "10px",
                background: "var(--hero-metric-bg)",
                border: "1px solid var(--hero-metric-border)",
                backdropFilter: "blur(12px)",
                borderRadius: "12px",
                padding: "10px 18px",
                transition: "all 250ms ease",
              }}
            >
              <span
                style={{
                  fontFamily: "var(--font-mono)",
                  fontSize: "24px",
                  fontWeight: 700,
                  color: "#38bdf8",
                  lineHeight: 1,
                  textShadow: "0 0 15px rgba(56, 189, 248, 0.3)",
                }}
              >
                98.11%
              </span>
              <span
                style={{
                  borderLeft: "1px solid var(--hero-metric-border)",
                  paddingLeft: "10px",
                  fontFamily: "var(--font-body)",
                  fontSize: "13px",
                  fontWeight: 500,
                  color: "var(--hero-metric-label)",
                  lineHeight: 1.4,
                  transition: "all 250ms ease",
                }}
              >
                Held-out
                <br />
                Accuracy
              </span>
              <span
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  width: "26px",
                  height: "26px",
                  borderRadius: "50%",
                  background: "var(--hero-stamp-bg)",
                  flexShrink: 0,
                  transition: "all 250ms ease",
                }}
                aria-hidden="true"
              >
                <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
                  <path d="M2 6.5L5 10L11 3" stroke="#38bdf8" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </span>
            </div>
          </div>
        </div>

        {/* CTA Row */}
        <div
          data-hero="cta"
          style={{
            opacity: 0,
            display: "flex",
            flexWrap: "wrap",
            alignItems: "center",
            justifyContent: "flex-start",
            gap: "12px",
          }}
        >
          <a
            href="#try-model"
            style={{
              display: "inline-flex",
              alignItems: "center",
              justifyContent: "center",
              gap: "8px",
              minHeight: "48px",
              padding: "0 28px",
              background: "linear-gradient(135deg, var(--brand-primary) 0%, var(--brand-hover) 100%)",
              color: "#ffffff",
              fontFamily: "var(--font-body)",
              fontSize: "15px",
              fontWeight: 600,
              borderRadius: "10px",
              textDecoration: "none",
              whiteSpace: "nowrap",
              border: "1px solid rgba(255,255,255,0.12)",
              transition:
                "transform 200ms ease, box-shadow 200ms ease",
              willChange: "transform, box-shadow",
            }}
            onMouseEnter={(e) => {
              const el = e.currentTarget as HTMLAnchorElement;
              el.style.transform = "scale(1.03)";
              el.style.boxShadow = "0 0 24px var(--brand-glow), 0 6px 20px rgba(16,163,127,0.25)";
            }}
            onMouseLeave={(e) => {
              const el = e.currentTarget as HTMLAnchorElement;
              el.style.transform = "scale(1)";
              el.style.boxShadow = "none";
            }}
          >
            Try the Model
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true">
              <path d="M3 7H11M8 4L11 7L8 10" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </a>

          <a
            href="#performance"
            style={{
              display: "inline-flex",
              alignItems: "center",
              justifyContent: "center",
              minHeight: "48px",
              padding: "0 28px",
              background: "var(--hero-btn-sec-bg)",
              color: "var(--hero-btn-sec-text)",
              fontFamily: "var(--font-body)",
              fontSize: "15px",
              fontWeight: 500,
              borderRadius: "10px",
              textDecoration: "none",
              whiteSpace: "nowrap",
              border: "1px solid var(--hero-btn-sec-border)",
              backdropFilter: "blur(10px)",
              transition: "all 150ms ease",
            }}
            onMouseEnter={(e) => {
              const el = e.currentTarget as HTMLAnchorElement;
              el.style.background = "var(--hero-btn-sec-hover)";
              el.style.borderColor = "var(--hero-btn-sec-border)";
            }}
            onMouseLeave={(e) => {
              const el = e.currentTarget as HTMLAnchorElement;
              el.style.background = "var(--hero-btn-sec-bg)";
              el.style.borderColor = "var(--hero-btn-sec-border)";
            }}
          >
            View Metrics
          </a>
        </div>
      </div>

      <aside
        aria-label="Animated image to explanation pipeline"
        className="hidden xl:block"
        style={{
          position: "absolute",
          zIndex: 4,
          right: "max(24px, calc((100vw - 1280px) / 2 + 12px))",
          top: "50%",
          width: "min(46vw, 520px)",
          transform: "translateY(-45%)",
        }}
      >
        <PipelineDiagram />
        <div style={{ padding: "18px", display: "none", gap: "16px" }}>
          <div
            aria-hidden="true"
            style={{
              position: "relative",
              height: "220px",
              borderRadius: "20px",
              overflow: "hidden",
              background:
                "radial-gradient(circle at 35% 35%, rgba(253,186,116,0.9) 0 8%, transparent 9%), radial-gradient(circle at 64% 38%, rgba(134,239,172,0.75) 0 7%, transparent 8%), radial-gradient(circle at 54% 66%, rgba(252,165,165,0.7) 0 10%, transparent 11%), linear-gradient(135deg, #10223e 0%, #0a1630 58%, #071226 100%)",
            }}
          >
            <div
              style={{
                position: "absolute",
                inset: 0,
                background:
                  "linear-gradient(90deg, transparent, rgba(56,189,248,0.18), transparent), repeating-linear-gradient(0deg, rgba(255,255,255,0.04) 0 1px, transparent 1px 22px)",
                mixBlendMode: "screen",
              }}
            />
            <div
              style={{
                position: "absolute",
                left: "24px",
                bottom: "22px",
                padding: "10px 12px",
                borderRadius: "14px",
                background: "rgba(4,9,26,0.68)",
                border: "1px solid rgba(125,211,252,0.24)",
              }}
            >
              <p style={{ margin: 0, fontFamily: "var(--font-mono)", fontSize: "11px", color: "#a5f3fc" }}>Prediction</p>
              <p style={{ margin: "3px 0 0", fontFamily: "var(--font-body)", fontSize: "18px", fontWeight: 800, color: "#ffffff" }}>
                Bleached Coral · 98.7%
              </p>
            </div>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(3, minmax(0, 1fr))", gap: "10px" }}>
            {[
              ["Healthy", "0.8%", "#86efac"],
              ["Bleached", "98.7%", "#fdba74"],
              ["Dead", "0.5%", "#fca5a5"],
            ].map(([label, value, color]) => (
              <div key={label} style={{ borderRadius: "14px", background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.08)", padding: "10px" }}>
                <p style={{ margin: 0, fontFamily: "var(--font-mono)", fontSize: "10px", color: "rgba(255,255,255,0.55)" }}>{label}</p>
                <p style={{ margin: "4px 0 0", fontFamily: "var(--font-mono)", fontSize: "15px", fontWeight: 800, color }}>{value}</p>
              </div>
            ))}
          </div>
        </div>
      </aside>
    </section>
  );
}
