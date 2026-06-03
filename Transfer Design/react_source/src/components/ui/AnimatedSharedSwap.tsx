import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface AnimatedSharedSwapProps {
  text: string;
  className?: string;
  style?: React.CSSProperties;
}

export const AnimatedSharedSwap: React.FC<AnimatedSharedSwapProps> = ({
  text,
  className = "",
  style,
}) => {
  // Split by words and spaces
  const words = text.split(/(\S+|\s+)/g).filter(Boolean);

  const container = {
    hidden: {},
    visible: {
      transition: {
        staggerChildren: 0.056, // scaled_stagger_ms
      },
    },
    exit: {
      transition: {
        staggerChildren: 0.056,
        staggerDirection: -1 as const, // Exit in reverse for staircase flow
      },
    },
  };

  const child = {
    hidden: {
      opacity: 0,
      y: 0,
    },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.14, // scaled_duration_ms
        ease: "linear" as any, // signature_easing (stepped cut)
      },
    },
    exit: {
      opacity: 0,
      y: 0,
      transition: {
        duration: 0.14,
        ease: "linear" as any,
      },
    },
  };

  return (
    <AnimatePresence mode="wait">
      <motion.span
        key={text}
        className={`inline-block ${className}`}
        variants={container}
        initial="hidden"
        animate="visible"
        exit="exit"
        style={{
          display: 'inline-block',
          willChange: 'opacity',
          ...style,
        }}
      >
        {words.map((word, index) => {
          const isWhitespace = /^\s+$/.test(word);

          if (isWhitespace) {
            return (
              <span key={index} style={{ whiteSpace: 'pre' }}>
                {word}
              </span>
            );
          }

          return (
            <motion.span
              key={index}
              variants={child}
              style={{
                display: 'inline-block',
                whiteSpace: 'pre',
                willChange: 'opacity',
              }}
            >
              {word}
            </motion.span>
          );
        })}
      </motion.span>
    </AnimatePresence>
  );
};
