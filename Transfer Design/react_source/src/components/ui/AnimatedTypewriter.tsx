import React from 'react';
import { motion } from 'framer-motion';

interface AnimatedTypewriterProps {
  text: string;
  className?: string;
  delay?: number;
  showCursor?: boolean;
}

export const AnimatedTypewriter: React.FC<AnimatedTypewriterProps> = ({
  text,
  className = "",
  delay = 0,
  showCursor = true,
}) => {
  const chars = Array.from(text);

  const container = {
    hidden: {},
    visible: {
      transition: {
        staggerChildren: 0.033, // scaled_stagger_ms
        delayChildren: delay,
      },
    },
  };

  const child = {
    hidden: {
      opacity: 0,
    },
    visible: {
      opacity: 1,
      transition: {
        duration: 0.173, // scaled_duration_ms
        ease: "easeInOut" as const, // steps(1, end) emulated via rapid opacity switch
      },
    },
  };

  const cursorVariants = {
    blink: {
      opacity: [1, 0, 1],
      transition: {
        duration: 0.8,
        repeat: Infinity,
        ease: "linear" as const,
      },
    },
  };

  return (
    <motion.span
      className={`inline-flex items-center ${className}`}
      variants={container}
      initial="hidden"
      animate="visible"
    >
      {chars.map((char, index) => (
        <motion.span
          key={index}
          variants={child}
          style={{
            whiteSpace: char === ' ' ? 'pre' : 'normal',
            willChange: 'opacity',
          }}
        >
          {char}
        </motion.span>
      ))}
      {showCursor && (
        <motion.span
          variants={cursorVariants}
          animate="blink"
          style={{
            display: 'inline-block',
            marginLeft: '2px',
            width: '6px',
            height: '14px',
            background: 'currentColor',
            willChange: 'opacity',
          }}
        />
      )}
    </motion.span>
  );
};
