import React, { useEffect, useRef } from 'react';
import gsap from 'gsap';

interface CoralPipelineSVGProps {
    activeStep?: number;
}

// Computes the 3 visible card indices based on the active step
const getVisibleCards = (step: number): number[] => {
    if (step <= 1) return [0, 1, 2];
    if (step >= 4) return [3, 4, 5];
    return [step - 1, step, step + 1];
};

export default function CoralPipelineSVG({ activeStep = 0 }: CoralPipelineSVGProps) {
    const svgRef = useRef<SVGSVGElement>(null);

    const steps = [
        { title: "Input Image" },
        { title: "Feature Extraction" },
        { title: "Gradient Computation" },
        { title: "Importance Scoring" },
        { title: "Attention Heatmap" },
        { title: "Prediction Output" }
    ];

    const visibleIndices = getVisibleCards(activeStep);

    // Initial position for React render to prevent FOUC
    const getInitialX = (index: number) => {
        const slots = [45, 235, 425];
        const slotIndex = visibleIndices.indexOf(index);
        if (slotIndex !== -1) {
            return slots[slotIndex];
        }
        if (index < visibleIndices[0]) {
            return -145; // Offscreen left
        }
        return 425 + (index - visibleIndices[2]) * 190; // Offscreen right
    };

    const getInitialOpacity = (index: number) => {
        return visibleIndices.includes(index) ? 1 : 0;
    };

    const getInitialChevronX = (index: number) => {
        if (index === visibleIndices[0]) return 215;
        if (index === visibleIndices[1]) return 405;
        if (index < visibleIndices[0]) return -100;
        return 720;
    };

    const getInitialChevronOpacity = (index: number) => {
        return (index === visibleIndices[0] || index === visibleIndices[1]) ? 0.2 : 0;
    };

    useEffect(() => {
        if (activeStep === undefined || !svgRef.current) return;
        
        const ctx = gsap.context(() => {
            const visible = getVisibleCards(activeStep);
            const slots = [45, 235, 425];

            // 1. Move and fade step groups to their target slot position and opacity
            steps.forEach((_, i) => {
                const slotIndex = visible.indexOf(i);
                let targetX = 0;
                let targetOpacity = 0;

                if (slotIndex !== -1) {
                    targetX = slots[slotIndex];
                    targetOpacity = 1;
                } else {
                    targetOpacity = 0;
                    if (i < visible[0]) {
                        targetX = -145;
                    } else {
                        targetX = 425 + (i - visible[2]) * 190;
                    }
                }

                gsap.to(`.pipeline-step-group-${i}`, {
                    x: targetX,
                    opacity: targetOpacity,
                    duration: 0.6,
                    ease: 'power2.out',
                    overwrite: 'auto'
                });
            });

            // 2. Move and fade chevrons
            steps.forEach((_, i) => {
                if (i === 5) return; // Only 5 arrows
                
                let targetX = 0;
                let targetOpacity = 0;

                if (i === visible[0]) {
                    targetX = 215;
                    targetOpacity = 0.2;
                } else if (i === visible[1]) {
                    targetX = 405;
                    targetOpacity = 0.2;
                } else if (i < visible[0]) {
                    targetX = -100;
                    targetOpacity = 0;
                } else {
                    targetX = 720;
                    targetOpacity = 0;
                }

                gsap.to(`.arrow-${i}`, {
                    x: targetX,
                    opacity: targetOpacity,
                    stroke: '#334155',
                    duration: 0.6,
                    ease: 'power2.out',
                    overwrite: 'auto'
                });
            });

            // 3. Reset all active states to baseline
            gsap.to('.card-bg', { stroke: '#1E293B', fill: '#0F172A', duration: 0.4 });
            gsap.to('.card-glow', { opacity: 0, duration: 0.4 });
            gsap.to('.icon-highlight', { opacity: 0.2, y: 15, duration: 0.4 });
            gsap.to('.badge-bg', { fill: '#1E293B', duration: 0.4 });
            gsap.to('.badge-text', { fill: '#64748B', duration: 0.4 });

            // 4. Illuminate the currently active card
            const i = activeStep;
            const activeColor = '#3c4fe0';
            const activeDarkBg = '#080d33'; 

            gsap.to(`.card-bg-${i}`, { stroke: activeColor, fill: activeDarkBg, duration: 0.5, delay: 0.1, ease: 'power2.out' });
            gsap.to(`.card-glow-${i}`, { opacity: 1, duration: 0.5, delay: 0.1, ease: 'power2.out' });
            gsap.to(`.icon-highlight-${i}`, { opacity: 1, y: 0, duration: 0.6, delay: 0.1, ease: 'back.out(1.2)' });
            gsap.to(`.badge-bg-${i}`, { fill: activeColor, duration: 0.5, delay: 0.1 });
            gsap.to(`.badge-text-${i}`, { fill: '#0F172A', duration: 0.5, delay: 0.1 });

            // 5. Light up arrows leading up to this step
            for (let a = 0; a < i; a++) {
                if (a === visible[0] || a === visible[1]) {
                    gsap.to(`.arrow-${a}`, { opacity: 0.6, stroke: '#64748B', duration: 0.4, delay: 0.2 });
                }
            }
        }, svgRef);

        return () => ctx.revert();
    }, [activeStep]);

    return (
        <div className="pipeline-svg-wrapper">
            <svg ref={svgRef} viewBox="0 0 620 400" className="w-full h-auto drop-shadow-2xl overflow-visible max-w-full" style={{ fontFamily: 'var(--font-display)' }}>
                <defs>
                    <filter id="glowBlue" x="-50%" y="-50%" width="200%" height="200%">
                        <feGaussianBlur stdDeviation="8" result="blur" />
                        <feComponentTransfer in="blur" result="glow">
                            <feFuncA type="linear" slope="0.5"/>
                        </feComponentTransfer>
                        <feMerge>
                            <feMergeNode in="glow"/>
                            <feMergeNode in="SourceGraphic"/>
                        </feMerge>
                    </filter>
                    <filter id="glowTeal" x="-50%" y="-50%" width="200%" height="200%">
                        <feGaussianBlur stdDeviation="8" result="blur" />
                        <feComponentTransfer in="blur" result="glow">
                            <feFuncA type="linear" slope="0.5"/>
                        </feComponentTransfer>
                        <feMerge>
                            <feMergeNode in="glow"/>
                            <feMergeNode in="SourceGraphic"/>
                        </feMerge>
                    </filter>
                    <radialGradient id="heatGradient" cx="50%" cy="50%" r="50%">
                        <stop offset="0%" stopColor="#EF4444" />
                        <stop offset="35%" stopColor="#F59E0B" />
                        <stop offset="70%" stopColor="#3c4fe0" stopOpacity="0.6"/>
                        <stop offset="100%" stopColor="#3c4fe0" stopOpacity="0" />
                    </radialGradient>
                </defs>

                {/* Render all 6 cards, positioned and animated dynamically relative to x=0 */}
                {steps.map((step, i) => {
                    const cx = 75; // Center of the 150px wide card relative to x=0
                    const primaryColor = "#3c4fe0";
                    
                    return (
                        <g 
                            key={i} 
                            className={`pipeline-step-group pipeline-step-group-${i}`} 
                            style={{ 
                                transform: `translateX(${getInitialX(i)}px)`,
                                opacity: getInitialOpacity(i),
                                transformOrigin: `${cx}px 200px` 
                            }}
                        >
                            {/* Card Background & Glow */}
                            <rect className={`card-glow card-glow-${i}`} x="0" y="80" width="150" height="240" rx="16" fill="none" strokeWidth="3" stroke={primaryColor} filter="url(#glowBlue)" />
                            <rect className={`card-bg card-bg-${i} card`} x="0" y="80" width="150" height="240" rx="16" fill="#0F172A" stroke="#1E293B" strokeWidth="2" />
                            
                            {/* Step Badge */}
                            <circle className={`badge-bg badge-bg-${i}`} cx="28" cy="108" r="14" fill="#1E293B" />
                            <text className={`badge-text badge-text-${i}`} x="28" y="112" fontSize="11" fill="#64748B" textAnchor="middle" fontWeight="700">0{i + 1}</text>
                            
                            {/* Card Title */}
                            <text x={cx} y="290" fontSize="13" fill="#E2E8F0" textAnchor="middle" fontWeight="600" className="drop-shadow-sm">{step.title.split(' ')[0]}</text>
                            <text x={cx} y="306" fontSize="13" fill="#E2E8F0" textAnchor="middle" fontWeight="400" className="drop-shadow-sm">{step.title.split(' ')[1]}</text>
                            
                            {/* Interactive Graphics Area */}
                            <g>
                                {/* 1. Input Image */}
                                {i === 0 && (
                                    <g>
                                        <rect x="39" y="150" width="72" height="72" rx="8" fill="#1E293B" className={`icon-highlight icon-highlight-${i}`} opacity="0.3"/>
                                        <rect x="35" y="146" width="76" height="76" rx="10" fill="none" stroke={primaryColor} strokeWidth="2" className={`icon-highlight icon-highlight-${i}`}/>
                                        {/* Mountains */}
                                        <path d="M 35 210 L 60 175 L 75 195 L 85 180 L 111 210 Z" fill="#0F172A" stroke={primaryColor} strokeWidth="1.5" className={`icon-highlight icon-highlight-${i}`}/>
                                        {/* Sun */}
                                        <circle cx="90" cy="165" r="7" fill={primaryColor} className={`icon-highlight icon-highlight-${i}`}/>
                                    </g>
                                )}

                                {/* 2. Feature Extraction */}
                                {i === 1 && (
                                    <g>
                                        <path d="M 30 180 L 75 155 L 120 180 L 75 205 Z" fill="#1E293B" stroke={primaryColor} strokeWidth="1" opacity="0.4"/>
                                        <path d="M 30 170 L 75 145 L 120 170 L 75 195 Z" fill="#1E293B" stroke={primaryColor} strokeWidth="1.5" className={`icon-highlight icon-highlight-${i}`} opacity="0.6"/>
                                        <path d="M 30 160 L 75 135 L 120 160 L 75 185 Z" fill="#082f49" stroke={primaryColor} strokeWidth="2" className={`icon-highlight icon-highlight-${i}`}/>
                                        <circle cx="75" cy="160" r="2.5" fill={primaryColor} className={`icon-highlight icon-highlight-${i}`}/>
                                        <circle cx="60" cy="170" r="2" fill={primaryColor} className={`icon-highlight icon-highlight-${i}`}/>
                                        <circle cx="90" cy="150" r="2" fill={primaryColor} className={`icon-highlight icon-highlight-${i}`}/>
                                    </g>
                                )}

                                {/* 3. Gradient Computation */}
                                {i === 2 && (
                                    <g>
                                        {/* Cube Faces */}
                                        <path d="M 45 165 L 75 185 L 75 225 L 45 205 Z" fill="#1E293B" stroke={primaryColor} strokeWidth="1.5" className={`icon-highlight icon-highlight-${i}`}/>
                                        <path d="M 75 185 L 105 165 L 105 205 L 75 225 Z" fill="#0F172A" stroke={primaryColor} strokeWidth="1.5" className={`icon-highlight icon-highlight-${i}`}/>
                                        <path d="M 75 185 L 105 165 L 75 145 L 45 165 Z" fill="#082f49" stroke={primaryColor} strokeWidth="1.5" className={`icon-highlight icon-highlight-${i}`}/>
                                        <path d="M 60 155 L 90 175 M 90 155 L 60 175" stroke={primaryColor} strokeWidth="1" opacity="0.5" className={`icon-highlight icon-highlight-${i}`}/>
                                        <path d="M 60 185 L 60 215 M 90 185 L 90 215" stroke={primaryColor} strokeWidth="1" opacity="0.5" className={`icon-highlight icon-highlight-${i}`}/>
                                    </g>
                                )}

                                {/* 4. Importance Scoring */}
                                {i === 3 && (
                                    <g>
                                        <rect x="40" y="200" width="12" height="20" rx="3" fill="#1E293B" className={`icon-highlight icon-highlight-${i}`} />
                                        <rect x="60" y="175" width="12" height="45" rx="3" fill="#3c4fe0" opacity="0.5" className={`icon-highlight icon-highlight-${i}`} />
                                        <rect x="80" y="160" width="12" height="60" rx="3" fill="#3c4fe0" opacity="0.8" className={`icon-highlight icon-highlight-${i}`} />
                                        <rect x="100" y="135" width="12" height="85" rx="3" fill="#3c4fe0" className={`icon-highlight icon-highlight-${i}`} />
                                        <line x1="30" y1="225" x2="120" y2="225" stroke="#1E293B" strokeWidth="4" strokeLinecap="round" className={`icon-highlight icon-highlight-${i}`} />
                                    </g>
                                )}

                                {/* 5. Attention Heatmap */}
                                {i === 4 && (
                                    <g>
                                        <path d="M 30 180 L 75 150 L 120 180 L 75 210 Z" fill="#082f49" stroke={primaryColor} strokeWidth="2" className={`icon-highlight icon-highlight-${i}`}/>
                                        {/* Squashed circle to imply perspective */}
                                        <ellipse className={`icon-highlight icon-highlight-${i}`} cx="75" cy="180" rx="35" ry="18" fill="url(#heatGradient)"/>
                                        <line x1="75" y1="150" x2="75" y2="210" stroke={primaryColor} strokeWidth="0.5" strokeDasharray="3 3" opacity="0.3" className={`icon-highlight icon-highlight-${i}`}/>
                                        <line x1="30" y1="180" x2="120" y2="180" stroke={primaryColor} strokeWidth="0.5" strokeDasharray="3 3" opacity="0.3" className={`icon-highlight icon-highlight-${i}`}/>
                                    </g>
                                )}

                                {/* 6. Prediction Output */}
                                {i === 5 && (
                                    <g>
                                        <rect x="45" y="145" width="60" height="75" rx="6" fill="#1E293B" className={`icon-highlight icon-highlight-${i}`} opacity="0.3" />
                                        <rect x="42" y="140" width="66" height="82" rx="6" fill="#042F2E" stroke={primaryColor} strokeWidth="2.5" className={`icon-highlight icon-highlight-${i}`} />
                                        
                                        <circle cx="75" cy="165" r="12" fill={primaryColor} className={`icon-highlight icon-highlight-${i}`} />
                                        <path d="M 71 165 L 74 168 L 80 161" fill="none" stroke="#0F172A" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={`icon-highlight icon-highlight-${i}`} />
                                        
                                        <rect x="60" y="188" width="30" height="4" rx="2" fill={primaryColor} opacity="0.6" className={`icon-highlight icon-highlight-${i}`} />
                                        <rect x="60" y="198" width="18" height="4" rx="2" fill={primaryColor} opacity="0.3" className={`icon-highlight icon-highlight-${i}`} />
                                        
                                        <circle cx="63" cy="210" r="2.5" fill="#EF4444" className={`icon-highlight icon-highlight-${i}`} />
                                        <circle cx="75" cy="210" r="2.5" fill="#F59E0B" className={`icon-highlight icon-highlight-${i}`} />
                                        <circle cx="87" cy="210" r="2.5" fill={primaryColor} className={`icon-highlight icon-highlight-${i}`} />
                                    </g>
                                )}
                            </g>
                        </g>
                    );
                })}

                {/* Connection Chevrons (Only 5 arrows, dynamically positioned and animated) */}
                {steps.map((_, i) => {
                    if (i === 5) return null;
                    return (
                        <path 
                            key={`arrow-${i}`} 
                            className={`arrow arrow-${i}`} 
                            d="M -5 190 L 5 200 L -5 210" 
                            fill="none" 
                            stroke="#334155" 
                            strokeWidth="4" 
                            strokeLinecap="round" 
                            strokeLinejoin="round" 
                            style={{
                                transform: `translateX(${getInitialChevronX(i)}px)`,
                                opacity: getInitialChevronOpacity(i)
                            }}
                        />
                    );
                })}

                {/* Sleek 6-Dot Progress Indicator */}
                <g className="progress-dots" opacity="0.8">
                    {steps.map((_, d) => {
                        const isActive = d === activeStep;
                        const activeColor = "#3c4fe0";
                        
                        return (
                            <circle
                                key={d}
                                cx={260 + d * 20}
                                cy={365}
                                r={isActive ? 5 : 3.5}
                                fill={isActive ? activeColor : "#334155"}
                                className="transition-all duration-300"
                            />
                        );
                    })}
                </g>
            </svg>
        </div>
    );
}
