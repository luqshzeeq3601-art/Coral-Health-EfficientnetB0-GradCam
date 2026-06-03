import React from 'react';
import { motion } from 'framer-motion';

interface AnimatedWordFadeProps {
  text: string;
  className?: string;
}

export const AnimatedWordFade: React.FC<AnimatedWordFadeProps> = ({ text, className = "" }) => {
  // Split text by words and whitespace per spec
  const words = text.split(/(\S+|\s+)/g).filter(Boolean);

  const container = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.05, // scaled_stagger_ms from spec (50ms)
      },
    },
  };

  const child = {
    hidden: {
      opacity: 0,
      y: 4.64, // 8px * 0.58 y_travel_multiplier
    },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.504, // scaled_duration_ms
        ease: [0.16, 1, 0.3, 1] as [number, number, number, number], // signature_easing
      },
    },
  };

  return (
    <motion.div
      className={`inline-block ${className}`}
      variants={container}
      initial="hidden"
      animate="visible"
      style={{ perspective: 900 }}
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
              willChange: 'transform, opacity, filter',
            }}
          >
            {word}
          </motion.span>
        );
      })}
    </motion.div>
  );
};
