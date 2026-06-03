import React from 'react';
import { motion } from 'framer-motion';

export interface TextSegment {
  text: string;
  style?: React.CSSProperties;
  className?: string;
}

interface AnimatedTitleProps {
  text?: string;
  segments?: TextSegment[];
  className?: string;
}

export const AnimatedTitle: React.FC<AnimatedTitleProps> = ({ text, segments, className = "" }) => {
  const contentSegments = segments || (text ? [{ text }] : []);
  
  // Group characters into words, spaces, and newlines to prevent mid-word breaks
  type CharData = { char: string; style?: React.CSSProperties; className?: string };
  const tokens: { type: 'word' | 'space' | 'newline', chars: CharData[] }[] = [];
  
  contentSegments.forEach(segment => {
    const chars = Array.from(segment.text);
    let currentWord: CharData[] = [];
    
    chars.forEach(char => {
      if (char === '\n') {
        if (currentWord.length > 0) tokens.push({ type: 'word', chars: currentWord });
        currentWord = [];
        tokens.push({ type: 'newline', chars: [{ char, style: segment.style, className: segment.className }] });
      } else if (char === ' ') {
        if (currentWord.length > 0) tokens.push({ type: 'word', chars: currentWord });
        currentWord = [];
        tokens.push({ type: 'space', chars: [{ char, style: segment.style, className: segment.className }] });
      } else {
        currentWord.push({ char, style: segment.style, className: segment.className });
      }
    });
    
    if (currentWord.length > 0) {
      tokens.push({ type: 'word', chars: currentWord });
    }
  });

  const container = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.018, // scaled_stagger_ms from spec
      },
    },
  };

  const child = {
    hidden: {
      opacity: 0,
      y: 9.28, // 16px * 0.58 y_travel_multiplier
      filter: 'blur(12px)',
    },
    visible: {
      opacity: 1,
      y: 0,
      filter: 'blur(0px)',
      transition: {
        duration: 0.648, // scaled_duration_ms
        ease: [0.22, 1, 0.36, 1] as [number, number, number, number], // signature_easing
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
      {tokens.map((token, tokenIndex) => {
        if (token.type === 'newline') {
          return <br key={tokenIndex} />;
        }
        
        if (token.type === 'space') {
          return (
            <motion.span
              key={tokenIndex}
              className={token.chars[0].className}
              variants={child}
              style={{
                display: 'inline-block',
                whiteSpace: 'pre',
                willChange: 'transform, opacity, filter',
                ...token.chars[0].style
              }}
            >
              {token.chars[0].char}
            </motion.span>
          );
        }
        
        // Wrap word in a span to prevent breaking mid-word
        return (
          <span key={tokenIndex} style={{ display: 'inline-block', whiteSpace: 'nowrap' }}>
            {token.chars.map((item, charIndex) => (
              <motion.span
                key={charIndex}
                className={item.className}
                variants={child}
                style={{
                  display: 'inline-block',
                  whiteSpace: 'pre',
                  willChange: 'transform, opacity, filter',
                  ...item.style
                }}
              >
                {item.char}
              </motion.span>
            ))}
          </span>
        );
      })}
    </motion.div>
  );
};
