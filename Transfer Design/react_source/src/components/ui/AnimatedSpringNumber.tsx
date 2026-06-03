import React, { useEffect, useState, useRef } from 'react';
import { motion, useMotionValue, useTransform, animate } from 'framer-motion';

interface AnimatedSpringNumberProps {
  value: string;
  className?: string;
  delay?: number;
  triggerOnce?: boolean;
}

export const AnimatedSpringNumber: React.FC<AnimatedSpringNumberProps> = ({
  value,
  className = "",
  delay = 0,
  triggerOnce = true,
}) => {
  const [inView, setInView] = useState(false);
  const containerRef = useRef<HTMLSpanElement>(null);

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
      }
    }, { threshold: 0.1 });

    observer.observe(el);
    return () => observer.disconnect();
  }, [triggerOnce]);

  // Extract number and suffix if present (e.g. "98.11%" -> { num: 98.11, suffix: "%" })
  const match = value.match(/^([\d.]+)(.*)$/);
  const isNumeric = match !== null;
  const matchNum = match ? match[1] : "0";
  const numValue = isNumeric ? parseFloat(matchNum) : 0;
  const suffix = match ? match[2] : "";

  // Framer Motion motion value for the count-up effect
  const count = useMotionValue(0);
  const roundedCount = useTransform(count, (latest) => {
    // Format to match original precision (e.g. "98.11" has 2 decimal places)
    const decimals = match ? (match[1].split('.')[1]?.length || 0) : 0;
    return latest.toFixed(decimals) + suffix;
  });

  useEffect(() => {
    if (inView) {
      if (isNumeric) {
        const controls = animate(count, numValue, {
          duration: 1.1, // count-up slightly longer than pop for premium feel
          ease: "easeOut",
          delay: delay + 0.1, // wait until pop overshoot finishes
        });
        return () => controls.stop();
      }
    }
  }, [inView, isNumeric, numValue, delay, count]);

  const variants = {
    hidden: {
      opacity: 0,
      scale: 0.7, // from spec
    },
    visible: {
      opacity: 1,
      scale: 1,
      transition: {
        duration: 0.259, // scaled_duration_ms
        ease: [0.34, 1.56, 0.64, 1] as [number, number, number, number], // signature_easing (spring overshoot)
        delay: delay,
      },
    },
  };

  return (
    <motion.span
      ref={containerRef}
      className={`inline-block ${className}`}
      variants={variants}
      initial="hidden"
      animate={inView ? "visible" : "hidden"}
      style={{
        display: 'inline-block',
        transformOrigin: 'bottom left',
        willChange: 'transform, opacity',
      }}
    >
      {isNumeric ? (
        <motion.span>{roundedCount}</motion.span>
      ) : (
        <span>{value}</span>
      )}
    </motion.span>
  );
};
