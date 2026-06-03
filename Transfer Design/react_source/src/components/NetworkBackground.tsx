import React, { useMemo, useEffect, useRef, useState } from 'react';

const randG = () => (Math.random() + Math.random() + Math.random() - 1.5) * 2;
const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

interface CanvasParticle {
    cx: number; cy: number; tx: number; ty: number;
    rx: number; ry: number; r: number; color: string;
    rVal: number; gVal: number; bVal: number;
    op: number; animDelay: number; animDur: number;
}
interface CanvasFlowLine {
    startX: number; startY: number; cp1X: number; cp1Y: number;
    cp2X: number; cp2Y: number; endX: number; endY: number;
    color: string; delay: number; dur: number; w: number; op: number;
}
interface CanvasMote {
    cx: number; cy: number; r: number; op: number;
    animDel: number; animDur: number; tx: number; ty: number;
}
interface CanvasConnection {
    x1: number; y1: number; x2: number; y2: number;
    color: string; delay: number; dur: number;
}

export const NetworkBackground: React.FC = () => {
    const [activePlate, setActivePlate] = useState<number | null>(null);
    const containerRef = useRef<HTMLDivElement>(null);
    const canvasRef = useRef<HTMLCanvasElement>(null);
    const svgRef = useRef<SVGSVGElement>(null);
    const platesGroupRef = useRef<SVGGElement>(null);
    const mousePos = useRef({ x: -1000, y: -1000 });
    const targetTilt = useRef({ x: 0, y: 0 });
    const currentTilt = useRef({ x: 0, y: 0 });

    useEffect(() => {
        const handleMouseMove = (e: MouseEvent) => {
            if (!svgRef.current) return;
            const rect = svgRef.current.getBoundingClientRect();
            const scale = Math.max(rect.width / 1920, rect.height / 1080);
            const svgW = 1920 * scale;
            const svgH = 1080 * scale;
            const offsetX = (rect.width - svgW) / 2;
            const offsetY = (rect.height - svgH) / 2;
            const mx = (e.clientX - rect.left - offsetX) / scale;
            const my = (e.clientY - rect.top - offsetY) / scale;
            mousePos.current = { x: mx, y: my };
            targetTilt.current = {
                x: Math.max(-1, Math.min(1, (mx - 960) / 960)),
                y: Math.max(-1, Math.min(1, (my - 540) / 540))
            };
        };
        window.addEventListener('mousemove', handleMouseMove);
        return () => window.removeEventListener('mousemove', handleMouseMove);
    }, []);

    const cloudParticles = useMemo<CanvasParticle[]>(() => {
        return Array.from({ length: 50 }).map((_, i) => {
            const t = Math.random();
            const cx = -150 + t * 650;
            const spreadY = (1 - t) * 700 + 40;
            const cy = 540 + randG() * spreadY;
            const r = 1.5 + Math.random() * 2 * (1 - t) + (Math.random() > 0.95 ? 1.5 : 0);
            const isCoral = Math.random() > 0.65;
            const isData = t > 0.75;
            let color = isCoral ? '#E07B2A' : '#3CAB57';
            if (isData && Math.random() > 0.4) color = '#0284C7';
            const rVal = color === '#E07B2A' ? 224 : (color === '#3CAB57' ? 60 : 2);
            const gVal = color === '#E07B2A' ? 123 : (color === '#3CAB57' ? 171 : 132);
            const bVal = color === '#E07B2A' ? 42 : (color === '#3CAB57' ? 87 : 199);
            const op = 0.15 + Math.random() * 0.85;
            const animDelay = Math.random() * -16;
            const animDur = 6 + Math.random() * 8;
            const targetX = 580;
            const targetY = 540 + (Math.random() - 0.5) * 200;
            const tx = (targetX - cx) * (0.4 + Math.random() * 0.3);
            const ty = (targetY - cy) * (0.4 + Math.random() * 0.3);
            return { cx, cy, tx, ty, rx: 0, ry: 0, r, color, rVal, gVal, bVal, op, animDelay, animDur };
        });
    }, []);

    const flowLines = useMemo<CanvasFlowLine[]>(() => {
        return Array.from({ length: 25 }).map(() => {
            const startX = -200 + Math.random() * 300;
            const startY = 540 + randG() * 600;
            const endX = 540; const endY = 540 + (Math.random() - 0.5) * 80;
            const cp1X = startX + 400 * Math.random(); const cp1Y = startY + (Math.random() - 0.5) * 300;
            const cp2X = endX - 200 * Math.random(); const cp2Y = endY + (Math.random() - 0.5) * 100;
            const isCoral = Math.random() > 0.7; const isBlue = Math.random() > 0.5;
            const color = isCoral ? '#E07B2A' : (isBlue ? '#0284C7' : '#3CAB57');
            const delay = Math.random() * -10; const dur = 3 + Math.random() * 4;
            const w = Math.random() > 0.85 ? 2.5 : 1.5; const op = 0.15 + Math.random() * 0.6;
            return { startX, startY, cp1X, cp1Y, cp2X, cp2Y, endX, endY, color, delay, dur, w, op };
        });
    }, []);

    const dustMotes = useMemo<CanvasMote[]>(() => {
        return Array.from({ length: 30 }).map(() => {
            const cx = Math.random() * 1920; const cy = Math.random() * 1080;
            const r = Math.random() > 0.8 ? 2.5 + Math.random() * 2.5 : 0.5 + Math.random() * 1.5;
            const op = Math.random() * 0.25 + 0.05;
            const animDel = Math.random() * -80; const animDur = 30 + Math.random() * 50;
            const tx = (Math.random() - 0.5) * 250; const ty = (Math.random() - 0.5) * 150;
            return { cx, cy, r, op, animDel, animDur, tx, ty };
        });
    }, []);

    const beamDashes = useMemo(() => {
        return Array.from({ length: 8 }).map(() => ({
            yOffset: (Math.random() - 0.5) * 30,
            isAltColor: Math.random() > 0.5,
            width: Math.random() > 0.6 ? 2 : 1,
            dur: 1.5 + Math.random() * 2,
            del: Math.random() * -4,
            op: 0.5 + Math.random() * 0.4
        }));
    }, []);

    const COLORS = ['#3B82F6', '#2563EB', '#0284C7', '#0EA5E9', '#06B6D4', '#0D9488'];
    const activeBeamColor = activePlate === 99 ? '#E07B2A' : (activePlate !== null ? COLORS[activePlate] || '#0284C7' : '#0284C7');

    // Mirror interactive state into refs so the RAF loop reads the latest value
    // without being torn down and recreated on every plate click.
    const activePlateRef = useRef(activePlate);
    activePlateRef.current = activePlate;
    const activeBeamColorRef = useRef(activeBeamColor);
    activeBeamColorRef.current = activeBeamColor;

    const getGridPath = (w: number, h: number, skew: number, numH: number, numV: number) => {
        let d = "";
        for (let i = 1; i < numH; i++) {
            const t = i / numH;
            const ly = lerp(540 - h / 2 - skew, 540 + h / 2 - skew, t);
            const ry = lerp(540 - h / 2 + skew, 540 + h / 2 + skew, t);
            d += `M ${-w},${ly} L ${w},${ry} `;
        }
        for (let i = 1; i < numV; i++) {
            const t = i / numV;
            const tx = lerp(-w, w, t);
            const topY = lerp(540 - h / 2 - skew, 540 - h / 2 + skew, t);
            const botY = lerp(540 + h / 2 - skew, 540 + h / 2 + skew, t);
            d += `M ${tx},${topY} L ${tx},${botY} `;
        }
        return d;
    };

    const plates = useMemo(() => {
        return [600, 750, 900, 1050, 1200, 1350].map((x, i) => {
            const w = 45; const h = 480 - i * 18; const skew = 60 - i * 2.5;
            const depth = 20; const depthY = 16;
            const pFront = `${x - w},${540 - h / 2 - skew} ${x + w},${540 - h / 2 + skew} ${x + w},${540 + h / 2 + skew} ${x - w},${540 + h / 2 - skew}`;
            const pRight = `${x + w},${540 - h / 2 + skew} ${x + w + depth},${540 - h / 2 + skew - depthY} ${x + w + depth},${540 + h / 2 + skew - depthY} ${x + w},${540 + h / 2 + skew}`;
            const pTop = `${x - w},${540 - h / 2 - skew} ${x + w},${540 - h / 2 + skew} ${x + w + depth},${540 - h / 2 + skew - depthY} ${x - w + depth},${540 - h / 2 - skew - depthY}`;
            const baseColor = COLORS[i] || '#0284C7';
            const hoverDelay = i * -1.2;
            const gridPath = getGridPath(w, h, skew, 12, 4);
            const neurons = Array.from({ length: 12 }).map(() => {
                const tX = Math.random(); const tY = Math.random();
                const nx = lerp(x - w, x + w, tX);
                const nyTop = lerp(540 - h / 2 - skew, 540 - h / 2 + skew, tX);
                const nyBot = lerp(540 + h / 2 - skew, 540 + h / 2 + skew, tX);
                const ny = lerp(nyTop, nyBot, tY);
                return { nx, ny, delay: Math.random() * -6, dur: 1.5 + Math.random() * 2 };
            });
            return { x, w, h, skew, depth, depthY, pFront, pRight, pTop, baseColor, hoverDelay, gridPath, neurons };
        });
    }, []);

    const plateConnections = useMemo<CanvasConnection[]>(() => {
        const conns: CanvasConnection[] = [];
        for (let i = 0; i < plates.length - 1; i++) {
            const p1 = plates[i]; const p2 = plates[i + 1];
            for (let j = 0; j < 6; j++) {
                const n1 = p1.neurons[Math.floor(Math.random() * p1.neurons.length)];
                const n2 = p2.neurons[Math.floor(Math.random() * p2.neurons.length)];
                conns.push({ x1: n1.nx, y1: n1.ny, x2: n2.nx, y2: n2.ny, color: i === plates.length - 2 ? '#0D9488' : '#0284C7', delay: n1.delay, dur: n1.dur });
            }
        }
        return conns;
    }, [plates]);

    const gradCamPlate = useMemo(() => {
        const x = 1680; const w = 150; const h = 680; const skew = 110;
        const depth = 25; const depthY = 20;
        const pFront = `${x - w},${540 - h / 2 - skew} ${x + w},${540 - h / 2 + skew} ${x + w},${540 + h / 2 + skew} ${x - w},${540 + h / 2 - skew}`;
        const pRight = `${x + w},${540 - h / 2 + skew} ${x + w + depth},${540 - h / 2 + skew - depthY} ${x + w + depth},${540 + h / 2 + skew - depthY} ${x + w},${540 + h / 2 + skew}`;
        const pTop = `${x - w},${540 - h / 2 - skew} ${x + w},${540 - h / 2 + skew} ${x + w + depth},${540 - h / 2 + skew - depthY} ${x - w + depth},${540 - h / 2 - skew - depthY}`;
        const gridPath = getGridPath(w, h, skew, 20, 10);
        const createContour = (cx: number, cy: number, r: number, points: number = 8) => {
            let d = "";
            for (let i = 0; i < points; i++) {
                const ang = (i / points) * Math.PI * 2;
                const nextAng = ((i + 1) % points) * Math.PI * 2;
                const rad1 = r * (0.85 + Math.random() * 0.3);
                const x1 = cx + Math.cos(ang) * rad1; const y1 = cy + Math.sin(ang) * rad1;
                const rad2 = r * (0.85 + Math.random() * 0.3);
                const x2 = cx + Math.cos(nextAng) * rad2; const y2 = cy + Math.sin(nextAng) * rad2;
                const cp1x = x1 + Math.cos(ang + Math.PI / 2) * (rad1 * 0.3);
                const cp1y = y1 + Math.sin(ang + Math.PI / 2) * (rad1 * 0.3);
                const cp2x = x2 - Math.cos(nextAng + Math.PI / 2) * (rad2 * 0.3);
                const cp2y = y2 - Math.sin(nextAng + Math.PI / 2) * (rad2 * 0.3);
                if (i === 0) d += `M ${x1},${y1} `;
                d += `C ${cp1x},${cp1y} ${cp2x},${cp2y} ${x2},${y2} `;
            }
            return d;
        };
        const contours = [
            { d: createContour(1630, 380, 110), color: "rgba(255,255,255,0.7)", w: 1, dash: "4 4" },
            { d: createContour(1630, 380, 70), color: "rgba(255,100,100,0.8)", w: 1.5, dash: "none" },
            { d: createContour(1630, 380, 35), color: "rgba(255,200,100,0.9)", w: 2, dash: "2 6" },
            { d: createContour(1670, 620, 140), color: "rgba(255,255,255,0.4)", w: 1, dash: "5 5" },
            { d: createContour(1670, 620, 90), color: "rgba(100,255,150,0.6)", w: 1.5, dash: "none" },
            { d: createContour(1670, 620, 50), color: "rgba(255,200,100,0.9)", w: 2, dash: "8 4" },
            { d: createContour(1680, 500, 200), color: "rgba(100,200,255,0.3)", w: 1, dash: "12 12" },
        ];
        const techMarkers = Array.from({ length: 15 }).map(() => ({
            x: 1530 + Math.random() * 250, y: 250 + Math.random() * 600,
            op: 0.2 + Math.random() * 0.6, dur: 2 + Math.random() * 4, del: Math.random() * -5
        }));
        return { x, w, h, skew, depth, depthY, pFront, pRight, pTop, gridPath, contours, techMarkers };
    }, []);

    // ── Single unified RAF loop: canvas + tilt update ──────────────────────────
    useEffect(() => {
        const canvas = canvasRef.current;
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        if (!ctx) return;
        let frameId: number;

        const render = () => {
            const time = performance.now();

            // Tilt update (merged — eliminates second rAF loop)
            if (platesGroupRef.current) {
                currentTilt.current.x += (targetTilt.current.x - currentTilt.current.x) * 0.1;
                currentTilt.current.y += (targetTilt.current.y - currentTilt.current.y) * 0.1;
                const diffX = Math.abs(currentTilt.current.x - targetTilt.current.x);
                const diffY = Math.abs(currentTilt.current.y - targetTilt.current.y);
                if (diffX > 0.0005 || diffY > 0.0005) {
                    platesGroupRef.current.style.transform = `translateZ(0) perspective(2000px) rotateY(${currentTilt.current.x * 5}deg) rotateX(${-currentTilt.current.y * 3}deg)`;
                }
            }

            ctx.clearRect(0, 0, 1920, 1080);
            const mx = mousePos.current.x;
            const my = mousePos.current.y;

            // 1. Dust motes — batch same fillStyle
            ctx.setLineDash([]);
            ctx.fillStyle = "#FFFFFF";
            dustMotes.forEach(m => {
                const phase = (time / 1000 - m.animDel) * (Math.PI * 2 / m.animDur);
                const offsetX = m.tx * Math.sin(phase) * 0.5;
                const offsetY = m.ty * Math.sin(phase) * 0.5;
                ctx.globalAlpha = m.op * 0.8;
                ctx.beginPath();
                ctx.arc(m.cx + offsetX, m.cy + offsetY, m.r, 0, Math.PI * 2);
                ctx.fill();
            });

            // 2. Flow lines — setLineDash ONCE before loop
            ctx.setLineDash([4, 24]);
            flowLines.forEach(fl => {
                ctx.beginPath();
                ctx.moveTo(fl.startX, fl.startY);
                ctx.bezierCurveTo(fl.cp1X, fl.cp1Y, fl.cp2X, fl.cp2Y, fl.endX, fl.endY);
                ctx.strokeStyle = fl.color;
                ctx.lineWidth = fl.w;
                ctx.globalAlpha = fl.op * 0.7;
                ctx.lineDashOffset = -((time / 1000) * 80) * (10 / fl.dur);
                ctx.stroke();
            });

            // 3. Cloud particles — reset dash state first
            ctx.setLineDash([]);
            cloudParticles.forEach(p => {
                const elapsed = (time / 1000) - p.animDelay;
                const progress = (elapsed % p.animDur) / p.animDur;
                let opacity = 0; let scale = 1.0; let txRatio = 0;
                if (progress < 0.15) {
                    const t = progress / 0.15;
                    opacity = t * p.op; scale = 1.5 + (1.2 - 1.5) * t; txRatio = 0.15 * t;
                } else if (progress < 0.45) {
                    const t = (progress - 0.15) / 0.30;
                    opacity = p.op; scale = 1.2 + (0.85 - 1.2) * t; txRatio = 0.15 + (0.6 - 0.15) * t;
                } else if (progress < 0.55) {
                    opacity = p.op; scale = 0.85; txRatio = 0.6;
                } else if (progress < 0.80) {
                    const t = (progress - 0.55) / 0.25;
                    opacity = p.op; scale = 0.85 + (0.65 - 0.85) * t; txRatio = 0.6 + (0.85 - 0.6) * t;
                } else if (progress < 0.90) {
                    const t = (progress - 0.80) / 0.10;
                    opacity = p.op + (1.0 - p.op) * t; scale = 0.65 + (0.3 - 0.65) * t; txRatio = 0.85 + (0.95 - 0.85) * t;
                } else {
                    const t = (progress - 0.90) / 0.10;
                    opacity = 1.0 - t; scale = 0.3 * (1.0 - t); txRatio = 0.95 + (1.0 - 0.95) * t;
                }
                const baseX = p.cx + p.tx * txRatio;
                const baseY = p.cy + p.ty * txRatio;
                const dx = baseX - mx; const dy = baseY - my;
                const dist = Math.sqrt(dx * dx + dy * dy);
                let targetRx = 0; let targetRy = 0;
                if (dist < 350) {
                    const force = Math.pow((350 - dist) / 350, 1.5);
                    targetRx = (dx / dist) * force * 150;
                    targetRy = (dy / dist) * force * 150;
                }
                p.rx += (targetRx - p.rx) * 0.1;
                p.ry += (targetRy - p.ry) * 0.1;
                const finalX = baseX + p.rx; const finalY = baseY + p.ry;
                let drawColor = `rgba(${p.rVal}, ${p.gVal}, ${p.bVal}, ${opacity})`;
                if (progress >= 0.8 && progress < 0.9) {
                    const t = (progress - 0.8) / 0.10;
                    drawColor = `rgba(${Math.round(p.rVal + (255 - p.rVal) * t)}, ${Math.round(p.gVal + (255 - p.gVal) * t)}, ${Math.round(p.bVal + (255 - p.bVal) * t)}, ${opacity})`;
                } else if (progress >= 0.9) {
                    drawColor = `rgba(255, 255, 255, ${opacity})`;
                }
                ctx.beginPath();
                ctx.arc(finalX, finalY, p.r * scale, 0, Math.PI * 2);
                ctx.fillStyle = drawColor;
                ctx.globalAlpha = 1.0;
                ctx.fill();
            });

            // 4. Central beam
            ctx.setLineDash([]);
            const beamColor = activeBeamColorRef.current;
            ctx.beginPath(); ctx.moveTo(300, 540); ctx.lineTo(1650, 540);
            ctx.strokeStyle = beamColor; ctx.lineWidth = 28; ctx.globalAlpha = 0.1; ctx.stroke();
            ctx.beginPath(); ctx.moveTo(450, 540); ctx.lineTo(1550, 540);
            ctx.strokeStyle = beamColor; ctx.lineWidth = 10; ctx.globalAlpha = 0.35; ctx.stroke();
            ctx.beginPath(); ctx.moveTo(500, 540); ctx.lineTo(1500, 540);
            ctx.strokeStyle = "#FFFFFF"; ctx.lineWidth = 2; ctx.globalAlpha = 0.85; ctx.stroke();

            // 5. Beam dashes — setLineDash ONCE before loop
            ctx.setLineDash([40, 80]);
            beamDashes.forEach(b => {
                ctx.beginPath();
                ctx.moveTo(550, 540 + b.yOffset); ctx.lineTo(1600, 540 + b.yOffset);
                ctx.strokeStyle = activePlateRef.current !== null ? beamColor : (b.isAltColor ? '#0284C7' : '#0D9488');
                ctx.lineWidth = b.width; ctx.globalAlpha = b.op * 0.45;
                ctx.lineDashOffset = -((time / 1000) * 120) * (1.5 / b.dur) - b.del * 10;
                ctx.stroke();
            });

            // 6. Plate connections — setLineDash ONCE, lineDashOffset is same for all
            ctx.setLineDash([4, 8]);
            const connDashOffset = -(time / 1000) * 20;
            plateConnections.forEach(c => {
                ctx.beginPath(); ctx.moveTo(c.x1, c.y1); ctx.lineTo(c.x2, c.y2);
                ctx.strokeStyle = c.color; ctx.lineWidth = 1.0;
                const linkPhase = (time / 1000 - c.delay) * (Math.PI * 2 / c.dur);
                ctx.globalAlpha = 0.04 + 0.35 * (Math.sin(linkPhase) * 0.5 + 0.5);
                ctx.lineDashOffset = connDashOffset;
                ctx.stroke();
            });

            // 7. Neurons on canvas (replaces 72 SVG CSS-animated circles)
            ctx.setLineDash([]);
            ctx.globalCompositeOperation = 'screen';
            plates.forEach(plate => {
                plate.neurons.forEach(n => {
                    const phase = (time / 1000 - n.delay) * (Math.PI * 2 / n.dur);
                    const t = Math.sin(phase) * 0.5 + 0.5;
                    ctx.globalAlpha = 0.3 + t * 0.7;
                    ctx.fillStyle = t > 0.7 ? '#FFFFFF' : plate.baseColor;
                    ctx.beginPath();
                    ctx.arc(n.nx, n.ny, 2.5 * (0.6 + t * 0.8), 0, Math.PI * 2);
                    ctx.fill();
                });
            });
            ctx.globalCompositeOperation = 'source-over';

            // Reset state for next frame
            ctx.globalAlpha = 1.0;
            ctx.setLineDash([]);

            frameId = requestAnimationFrame(render);
        };

        // Pause the loop while the background is scrolled out of view so it
        // doesn't keep repainting a full canvas and stealing the scroll compositor.
        let running = false;
        const start = () => {
            if (running) return;
            running = true;
            frameId = requestAnimationFrame(render);
        };
        const stop = () => {
            running = false;
            cancelAnimationFrame(frameId);
        };

        const target = containerRef.current;
        const observer = new IntersectionObserver(
            ([entry]) => { if (entry.isIntersecting) start(); else stop(); },
            { threshold: 0 }
        );
        if (target) observer.observe(target);
        else start();

        return () => {
            observer.disconnect();
            stop();
        };
    }, [cloudParticles, flowLines, dustMotes, beamDashes, plateConnections, plates]);

    return (
        <div
            ref={containerRef}
            className="absolute inset-0 w-full h-full z-0 bg-[#0b0f19] overflow-hidden flex items-center justify-center"
        >
            <canvas
                ref={canvasRef}
                width={1920}
                height={1080}
                style={{
                    position: "absolute", inset: 0, width: "100%", height: "100%",
                    pointerEvents: "none", mixBlendMode: "screen",
                }}
            />

            <svg
                ref={svgRef}
                viewBox="0 0 1920 1080"
                preserveAspectRatio="xMidYMid slice"
                className="w-full h-full relative z-10"
                xmlns="http://www.w3.org/2000/svg"
                onClick={() => setActivePlate(null)}
            >
                <defs>
                    <linearGradient id="plateGlass" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" stopColor="rgba(255,255,255,0.05)" />
                        <stop offset="30%" stopColor="rgba(15,23,42,0.85)" />
                        <stop offset="100%" stopColor="rgba(2,132,199,0.15)" />
                    </linearGradient>
                    <linearGradient id="plateGlassTeal" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" stopColor="rgba(255,255,255,0.05)" />
                        <stop offset="30%" stopColor="rgba(15,23,42,0.85)" />
                        <stop offset="100%" stopColor="rgba(13,148,136,0.15)" />
                    </linearGradient>
                    <radialGradient id="blobRed" cx="50%" cy="50%" r="50%">
                        <stop offset="0%" stopColor="rgba(239,68,68,0.9)" />
                        <stop offset="50%" stopColor="rgba(239,68,68,0.4)" />
                        <stop offset="100%" stopColor="rgba(239,68,68,0)" />
                    </radialGradient>
                    <radialGradient id="blobYellow" cx="50%" cy="50%" r="50%">
                        <stop offset="0%" stopColor="rgba(234,179,8,0.9)" />
                        <stop offset="60%" stopColor="rgba(234,179,8,0.3)" />
                        <stop offset="100%" stopColor="rgba(234,179,8,0)" />
                    </radialGradient>
                    <radialGradient id="blobBlue" cx="50%" cy="50%" r="50%">
                        <stop offset="0%" stopColor="rgba(59,130,246,0.7)" />
                        <stop offset="70%" stopColor="rgba(59,130,246,0.2)" />
                        <stop offset="100%" stopColor="rgba(59,130,246,0)" />
                    </radialGradient>
                    <radialGradient id="centerHighlight" cx="50%" cy="50%" r="50%">
                        <stop offset="0%" stopColor="rgba(255,255,255,0.03)" />
                        <stop offset="100%" stopColor="rgba(15,23,42,0)" />
                    </radialGradient>
                    <clipPath id="gradCamClip">
                        <polygon points={gradCamPlate.pFront} />
                    </clipPath>
                    <pattern id="globalGrid" width="40" height="40" patternUnits="userSpaceOnUse">
                        <line x1="40" y1="0" x2="40" y2="40" stroke="rgba(255,255,255,0.015)" strokeWidth="1" />
                        <line x1="0" y1="40" x2="40" y2="40" stroke="rgba(255,255,255,0.015)" strokeWidth="1" />
                    </pattern>
                    <pattern id="scanlines" width="4" height="4" patternUnits="userSpaceOnUse">
                        <rect width="4" height="2" fill="rgba(0,0,0,0.12)" />
                    </pattern>
                </defs>

                <style>{`
                    @keyframes nodePulse {
                        0%, 100% { transform: scale3d(0.6,0.6,1); opacity: 0.3; }
                        50% { transform: scale3d(1.4,1.4,1); opacity: 1; }
                    }
                    @keyframes edgeHighlight {
                        0%, 100% { stroke-opacity: 0.1; stroke-width: 0.5; stroke: rgba(255,255,255,0.2); }
                        50% { stroke-opacity: 1; stroke-width: 2.5; stroke: #FFFFFF; }
                    }
                    @keyframes plateHover {
                        0%, 100% { transform: translate3d(0px, 0px, 0); }
                        50% { transform: translate3d(0px, -6px, 0); }
                    }
                    @keyframes heatPulse {
                        0%, 100% { transform: scale3d(1,1,1); opacity: 0.8; }
                        50% { transform: scale3d(1.05,1.05,1); opacity: 1; }
                    }
                    .edge-highlight {
                        animation: edgeHighlight var(--dur) var(--del) infinite ease-in-out;
                    }
                    .plate-group {
                        will-change: transform;
                        animation: plateHover 8s ease-in-out infinite;
                    }
                    .heat-blob {
                        will-change: transform, opacity;
                        animation: heatPulse var(--dur) var(--del) ease-in-out infinite alternate;
                        transform-origin: center;
                    }
                `}</style>

                <rect width="1920" height="1080" fill="url(#centerHighlight)" />
                <rect width="1920" height="1080" fill="url(#globalGrid)" pointerEvents="none" />

                <g ref={platesGroupRef} style={{ transformOrigin: '960px 540px', transformStyle: 'preserve-3d', willChange: 'transform' }}>

                    {plates.map((plate, pIdx) => (
                        <g
                            key={`plate-${pIdx}`}
                            className="plate-group cursor-pointer transition-opacity duration-500"
                            style={{
                                animationDelay: `${plate.hoverDelay}s`,
                                opacity: activePlate === null ? 1 : (activePlate === pIdx ? 1 : 0.15)
                            }}
                            onClick={(e) => {
                                e.stopPropagation();
                                setActivePlate(activePlate === pIdx ? null : pIdx);
                            }}
                        >
                            <polygon points={plate.pRight} fill={`rgba(${pIdx === 5 ? '13,148,136' : '2,132,199'},0.2)`} stroke={`rgba(${pIdx === 5 ? '13,148,136' : '2,132,199'},0.5)`} />
                            <polygon points={plate.pTop} fill="rgba(255,255,255,0.08)" stroke="rgba(255,255,255,0.25)" />
                            <polygon points={plate.pFront} fill={pIdx === 5 ? 'url(#plateGlassTeal)' : 'url(#plateGlass)'} />
                            <g transform={`translate(${plate.x}, 0)`}>
                                <path d={plate.gridPath} fill="none" stroke="rgba(255,255,255,0.12)" strokeWidth="1" />
                            </g>
                            <polygon points={plate.pFront} fill="none" stroke={plate.baseColor} strokeWidth="2.5" />
                            <polygon points={plate.pFront} fill="none" className="edge-highlight" style={{ '--dur': '4s', '--del': `${plate.hoverDelay}s` } as any} />
                            <circle cx={plate.x} cy="540" r="3" fill="#FFFFFF" />
                            <circle cx={plate.x} cy="540" r="16" fill="none" stroke={plate.baseColor} strokeWidth="1.5" />
                            <circle cx={plate.x} cy="540" r="16" fill="none" stroke={plate.baseColor} strokeWidth="5" opacity="0.3" />
                            <circle cx={plate.x} cy="540" r="16" fill="none" stroke={plate.baseColor} strokeWidth="10" opacity="0.1" />
                            {/* Neurons rendered on canvas — SVG nodes removed (72 CSS animations eliminated) */}
                        </g>
                    ))}

                    <g
                        className="plate-group cursor-pointer transition-opacity duration-500"
                        style={{ animationDelay: '0.5s', opacity: activePlate === null ? 1 : (activePlate === 99 ? 1 : 0.15) }}
                        onClick={(e) => { e.stopPropagation(); setActivePlate(activePlate === 99 ? null : 99); }}
                    >
                        <polygon points={gradCamPlate.pRight} fill="rgba(13,148,136,0.15)" stroke="rgba(13,148,136,0.4)" strokeWidth="1.5" />
                        <polygon points={gradCamPlate.pTop} fill="rgba(255,255,255,0.08)" stroke="rgba(255,255,255,0.25)" strokeWidth="1.5" />
                        <polygon points={gradCamPlate.pFront} fill="rgba(15,23,42,0.9)" />
                        <polygon points={gradCamPlate.pFront} fill="rgba(13,148,136,0.05)" />
                        <g clipPath="url(#gradCamClip)">
                            <g transform={`translate(${gradCamPlate.x}, 0)`}>
                                <path d={gradCamPlate.gridPath} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="1" />
                            </g>
                            <g style={{ mixBlendMode: 'screen' }}>
                                <circle cx="1650" cy="540" r="450" fill="url(#blobBlue)" className="heat-blob" style={{ '--dur': '15s', '--del': '0s', transformOrigin: '1650px 540px' } as any} />
                                <circle cx="1680" cy="320" r="320" fill="url(#blobBlue)" className="heat-blob" style={{ '--dur': '11s', '--del': '-3s', transformOrigin: '1680px 320px' } as any} />
                                <circle cx="1600" cy="350" r="240" fill="url(#blobBlue)" className="heat-blob" style={{ '--dur': '12s', '--del': '-2s', transformOrigin: '1600px 350px' } as any} />
                                <circle cx="1620" cy="370" r="160" fill="url(#blobYellow)" className="heat-blob" style={{ '--dur': '8s', '--del': '-5s', transformOrigin: '1620px 370px' } as any} />
                                <circle cx="1630" cy="380" r="100" fill="url(#blobRed)" className="heat-blob" style={{ '--dur': '6s', '--del': '-1s', transformOrigin: '1630px 380px' } as any} />
                                <circle cx="1700" cy="650" r="280" fill="url(#blobBlue)" className="heat-blob" style={{ '--dur': '16s', '--del': '-7s', transformOrigin: '1700px 650px' } as any} />
                                <circle cx="1680" cy="630" r="200" fill="url(#blobYellow)" className="heat-blob" style={{ '--dur': '10s', '--del': '-4s', transformOrigin: '1680px 630px' } as any} />
                                <circle cx="1670" cy="620" r="130" fill="url(#blobRed)" className="heat-blob" style={{ '--dur': '7s', '--del': '-2s', transformOrigin: '1670px 620px' } as any} />
                            </g>
                            {gradCamPlate.contours.map((c, idx) => (
                                <path key={`cntr-${idx}`} d={c.d} fill="none" stroke={c.color} strokeWidth={c.w} strokeDasharray={c.dash} opacity="0.8" />
                            ))}
                            <g style={{ mixBlendMode: 'screen' }}>
                                {gradCamPlate.techMarkers.map((tm, idx) => (
                                    <path
                                        key={`tm-${idx}`}
                                        d={`M ${tm.x - 5},${tm.y} L ${tm.x + 5},${tm.y} M ${tm.x},${tm.y - 5} L ${tm.x},${tm.y + 5}`}
                                        stroke="rgba(255,255,255,0.6)" strokeWidth="1.5"
                                        className="heat-blob"
                                        style={{ '--dur': `${tm.dur}s`, '--del': `${tm.del}s`, transformOrigin: `${tm.x}px ${tm.y}px` } as any}
                                    />
                                ))}
                            </g>
                        </g>
                        <polygon points={gradCamPlate.pFront} fill="none" stroke="#0D9488" strokeWidth="4" />
                        <polygon points={gradCamPlate.pFront} fill="none" stroke="rgba(255,255,255,0.4)" strokeWidth="1" />
                        <g transform="scale(1.025) translate(-40, -12)">
                            <polygon points={gradCamPlate.pFront} fill="none" stroke="rgba(13,148,136,0.3)" strokeWidth="4" />
                            <polygon points={gradCamPlate.pFront} fill="none" stroke="rgba(13,148,136,0.1)" strokeWidth="8" />
                            <polygon points={gradCamPlate.pFront} fill="none" stroke="rgba(255,255,255,0.15)" strokeWidth="1" />
                        </g>
                    </g>
                </g>

                <rect width="1920" height="1080" fill="url(#scanlines)" style={{ mixBlendMode: 'multiply', pointerEvents: 'none' }} opacity="0.6" />
            </svg>
        </div>
    );
};
