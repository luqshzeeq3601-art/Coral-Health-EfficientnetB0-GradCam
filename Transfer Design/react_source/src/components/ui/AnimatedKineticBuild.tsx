import React, { useEffect, useState, useRef } from 'react';
import { motion } from 'framer-motion';

interface AnimatedKineticBuildProps {
  text: string;
  className?: string;
  wordGap?: number;
  triggerOnce?: boolean;
}

export const AnimatedKineticBuild: React.FC<AnimatedKineticBuildProps> = ({
  text,
  className = "",
  wordGap = 10,
  triggerOnce = true,
}) => {
  const words = text.split(/\s+/).filter(Boolean);
  const [visibleCount, setVisibleCount] = useState(0);
  const [inView, setInView] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;

    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        setInView(true);
        if (triggerOnce) {
          observer.unobserve(el);
        }
      } else if (!triggerOnce) {
        setInView(false);
        setVisibleCount(0); // Reset count on scroll out if not triggerOnce
      }
    }, { threshold: 0.1 });

    observer.observe(el);
    return () => observer.disconnect();
  }, [triggerOnce]);

  useEffect(() => {
    if (inView && visibleCount === 0) {
      // Start sequential word build
      let count = 0;
      let timer: ReturnType<typeof setTimeout>;
      const runBuild = () => {
        if (count < words.length) {
          count++;
          setVisibleCount(count);

          // Wait duration based on spec: first word is 245ms, pushes are 310ms
          const nextDelay = count === 1 ? 245 : 310;
          timer = setTimeout(runBuild, nextDelay);
        }
      };

      // Initial delay before first word
      timer = setTimeout(runBuild, 150);
      return () => clearTimeout(timer);
    }
    // visibleCount is intentionally NOT a dependency: the build must run once
    // when it enters view. Including it would re-run cleanup on every word and
    // clear the in-flight recursive timer, freezing the animation after one word.
  }, [inView, words.length]);

  // Framer Motion spring config matching the spec's physical push characteristics
  const springTransition = {
    type: "spring" as const,
    stiffness: 220,
    damping: 24,
    mass: 0.8,
  };

  const incomingWordVariants = {
    hidden: {
      opacity: 0,
      x: 88, // entry_offset_px from spec
      scale: 0.992, // entry_scale
      filter: 'blur(3.5px)', // entry_blur_px
    },
    visible: {
      opacity: 1,
      x: 0,
      scale: 1,
      filter: 'blur(0px)',
      transition: {
        duration: 0.31, // push_duration_ms scaled
        ease: [0.2, 0.8, 0.2, 1] as [number, number, number, number], // signature_easing
      },
    },
  };

  return (
    <div
      ref={containerRef}
      className={`inline-flex flex-wrap justify-center items-center ${className}`}
      style={{
        gap: `${wordGap}px`,
        position: 'relative',
      }}
    >
      {words.slice(0, visibleCount).map((word, index) => {
        const isLatest = index === visibleCount - 1;

        return (
          <motion.span
            key={index}
            layout
            variants={isLatest ? incomingWordVariants : undefined}
            initial={isLatest ? "hidden" : undefined}
            animate={isLatest ? "visible" : undefined}
            transition={springTransition}
            style={{
              display: 'inline-block',
              whiteSpace: 'nowrap',
              // will-change applied only while this word is actively animating in;
              // settled words drop the compositor hint to avoid permanent layers.
              willChange: isLatest ? 'transform, opacity, filter' : 'auto',
            }}
          >
            {word}
          </motion.span>
        );
      })}
    </div>
  );
};
