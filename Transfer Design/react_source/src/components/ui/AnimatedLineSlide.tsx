import React from 'react';
import { motion } from 'framer-motion';

export interface LineSegment {
  text: string;
  style?: React.CSSProperties;
  className?: string;
}

interface AnimatedLineSlideProps {
  text?: string;
  segments?: LineSegment[];
  className?: string;
  style?: React.CSSProperties;
  triggerOnce?: boolean;
}

export const AnimatedLineSlide: React.FC<AnimatedLineSlideProps> = ({
  text,
  segments,
  className = "",
  style,
  triggerOnce = true,
}) => {
  const contentSegments = segments || (text ? [{ text }] : []);
  
  // Split segments by newline to get explicit lines
  const lines: LineSegment[] = [];
  contentSegments.forEach(segment => {
    const parts = segment.text.split('\n');
    parts.forEach((part, index) => {
      if (index > 0) {
        // Create a blank/newline indicator or start a new line
        lines.push({ text: part, style: segment.style, className: segment.className });
      } else {
        if (lines.length > 0 && !segment.text.startsWith('\n')) {
          // Append to previous line if it was in the same segment or split
          lines[lines.length - 1].text += part;
        } else {
          lines.push({ text: part, style: segment.style, className: segment.className });
        }
      }
    });
  });

  const container = {
    hidden: {},
    visible: {
      transition: {
        staggerChildren: 0.086, // scaled_stagger_ms from spec
      },
    },
  };

  const child = {
    hidden: {
      opacity: 0,
      x: -48, // from spec (enter.from.x_px)
    },
    visible: {
      opacity: 1,
      x: 0,
      transition: {
        duration: 0.648, // scaled_duration_ms
        ease: [0.22, 1, 0.36, 1] as [number, number, number, number], // signature_easing
      },
    },
  };

  return (
    <motion.div
      className={`block ${className}`}
      variants={container}
      initial="hidden"
      whileInView="visible"
      viewport={{ once: triggerOnce, amount: 0.2 }}
      style={style}
    >
      {lines.map((line, index) => (
        <div key={index} className="overflow-hidden py-1 block">
          <motion.span
            className={`inline-block ${line.className || ""}`}
            variants={child}
            style={{
              willChange: 'transform, opacity',
              display: 'inline-block',
              ...line.style,
            }}
          >
            {line.text}
          </motion.span>
        </div>
      ))}
    </motion.div>
  );
};
