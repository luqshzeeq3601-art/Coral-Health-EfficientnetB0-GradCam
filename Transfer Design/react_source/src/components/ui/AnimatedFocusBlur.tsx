import React from 'react';
import { motion } from 'framer-motion';

interface AnimatedFocusBlurProps {
  children: React.ReactNode;
  className?: string;
  duration?: number;
  delay?: number;
  triggerKey?: any; // Forces animate on key change
}

export const AnimatedFocusBlur: React.FC<AnimatedFocusBlurProps> = ({
  children,
  className = "",
  duration = 0.547, // scaled_duration_ms
  delay = 0,
  triggerKey,
}) => {
  const variants = {
    hidden: {
      opacity: 0,
      y: 8.12, // 14px * 0.58 y_travel_multiplier
      filter: 'blur(14px)', // blur_px from spec
      scale: 1.01, // scale from spec
    },
    visible: {
      opacity: 1,
      y: 0,
      filter: 'blur(0px)',
      scale: 1,
      transition: {
        duration: duration,
        ease: [0.22, 1, 0.36, 1] as [number, number, number, number], // signature_easing
        delay: delay,
      },
    },
  };

  return (
    <motion.div
      key={triggerKey}
      className={`inline-block ${className}`}
      variants={variants}
      initial="hidden"
      animate="visible"
      style={{
        willChange: 'transform, opacity, filter',
      }}
    >
      {children}
    </motion.div>
  );
};
