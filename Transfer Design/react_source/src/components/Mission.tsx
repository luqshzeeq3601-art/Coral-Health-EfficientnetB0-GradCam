import { useEffect, useRef, useState } from "react";
import { AnimatedLineSlide } from "./ui";

const VIDEO_SRC = "/static/video/Laptop_opens_marine_drone_video_202605262357.mp4";

const BENEFITS = [
  {
    icon: (
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
        <path
          d="M2.5 3.5H7.5L13.5 9.5L9.5 13.5L3.5 7.5V3.5H2.5Z"
          stroke="#3cab57"
          strokeWidth="1.5"
          strokeLinejoin="round"
        />
        <circle cx="5.5" cy="5.5" r="0.9" fill="#3cab57" />
      </svg>
    ),
    label: "Coral Health Classification",
    color: "#3cab57",
    bg: "var(--tint-green)",
  },
  {
    icon: (
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
        <path
          d="M1.8 8C3.1 5.6 5.2 4.2 8 4.2C10.8 4.2 12.9 5.6 14.2 8C12.9 10.4 10.8 11.8 8 11.8C5.2 11.8 3.1 10.4 1.8 8Z"
          stroke="var(--brand-primary)"
          strokeWidth="1.5"
          strokeLinejoin="round"
        />
        <circle cx="8" cy="8" r="2" stroke="var(--brand-primary)" strokeWidth="1.5" />
      </svg>
    ),
    label: "Explainable AI with Grad-CAM",
    color: "var(--text-brand)",
    bg: "var(--brand-light)",
  },
  {
    icon: (
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
        <path d="M3 13V9" stroke="var(--brand-primary)" strokeWidth="1.5" strokeLinecap="round" />
        <path d="M8 13V5" stroke="var(--brand-primary)" strokeWidth="1.5" strokeLinecap="round" />
        <path d="M13 13V3" stroke="var(--brand-primary)" strokeWidth="1.5" strokeLinecap="round" />
        <path d="M2 13H14" stroke="var(--brand-primary)" strokeWidth="1.5" strokeLinecap="round" />
      </svg>
    ),
    label: "Performance-Based Assessment",
    color: "var(--text-brand)",
    bg: "var(--brand-light)",
  },
] as const;

export default function Mission({ sectionId = "mission" }: { sectionId?: string }) {
  const sectionRef = useRef<HTMLDivElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  // Defer attaching the video source until the section approaches the viewport
  // so the .mp4 isn't fetched on initial page load.
  const [shouldLoad, setShouldLoad] = useState(false);

  // Begin loading the video only when the section is close to view.
  useEffect(() => {
    const section = sectionRef.current;
    if (!section || shouldLoad) return;

    const loadObserver = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setShouldLoad(true);
          loadObserver.disconnect();
        }
      },
      { rootMargin: "250px 0px" }
    );
    loadObserver.observe(section);
    return () => loadObserver.disconnect();
  }, [shouldLoad]);

  // Once the source is attached, clip playback to 6s and play/pause with visibility.
  useEffect(() => {
    const video = videoRef.current;
    if (!video || !shouldLoad) return;

    // Time update listener to clip video playback to exactly 6.0 seconds
    const handleTimeUpdate = () => {
      if (video.currentTime >= 6.0) {
        video.currentTime = 0;
        video.play().catch(() => {});
      }
    };

    video.addEventListener("timeupdate", handleTimeUpdate);

    // High-performance IntersectionObserver to trigger play/pause dynamically
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          video.play().catch(() => {});
        } else {
          video.pause();
        }
      },
      { threshold: 0.1 }
    );

    if (sectionRef.current) {
      observer.observe(sectionRef.current);
    }

    return () => {
      video.removeEventListener("timeupdate", handleTimeUpdate);
      observer.disconnect();
    };
  }, [shouldLoad]);

  return (
    <section
      id={sectionId}
      ref={sectionRef}
      aria-labelledby="mission-heading"
      style={{
        background: "var(--bg-card)",
        paddingTop: "var(--section-space-lg)",
        paddingBottom: "var(--section-space-lg)",
        transition: "background-color 250ms ease",
      }}
    >
      <div
        className="mx-auto"
        style={{
          maxWidth: "1264px",
          paddingLeft: "clamp(24px, 6vw, 48px)",
          paddingRight: "clamp(24px, 6vw, 48px)",
        }}
      >
        <div className="grid grid-cols-1 md:grid-cols-2 items-start" style={{ gap: "64px" }}>
          <div className="flex flex-col" style={{ gap: "32px" }}>
            <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
              <h2
                id="mission-heading"
                style={{
                  fontFamily: "var(--font-display)",
                  fontSize: "var(--text-section)",
                  fontWeight: 700,
                  lineHeight: "var(--leading-section)",
                  letterSpacing: "var(--tracking-section)",
                  color: "var(--text-primary)",
                  margin: 0,
                  maxWidth: "780px",
                  overflowWrap: "anywhere",
                }}
              >
                Automating Coral Reef Health Assessment{" "}
                <span style={{ display: "block", color: "var(--text-brand)" }}>
                  with Explainable AI
                </span>
              </h2>

              <AnimatedLineSlide
                style={{
                  fontFamily: "var(--font-body)",
                  fontSize: "var(--text-body)",
                  fontWeight: 400,
                  lineHeight: "var(--leading-body)",
                  color: "var(--text-secondary)",
                  margin: 0,
                  maxWidth: "var(--measure-prose)",
                }}
                text={"This system uses CNN-based image analysis to classify coral reef images as\nHealthy, Bleached, or Dead. It also provides confidence scores and Grad-CAM\nvisual explanations, helping users understand predictions and support faster\nreef monitoring decisions."}
              />
            </div>

            <div className="flex flex-col" style={{ gap: "10px" }}>
              {BENEFITS.map(({ icon, label, color, bg }) => (
                <div key={label} className="flex items-center" style={{ gap: "12px" }}>
                  <span
                    className="flex items-center justify-center shrink-0"
                    style={{ width: "36px", height: "36px", borderRadius: "10px", background: bg }}
                  >
                    {icon}
                  </span>
                  <span
                    style={{
                      fontFamily: "var(--font-body)",
                      fontSize: "14px",
                      fontWeight: 500,
                      color: "var(--text-primary)",
                    }}
                  >
                    {label}
                  </span>
                </div>
              ))}
            </div>

            <div
              style={{
                borderTop: "1px solid var(--border-subtle)",
                paddingTop: "24px",
                display: "flex",
                alignItems: "center",
                gap: "32px",
              }}
            >
              <div>
                <p
                  style={{
                    fontFamily: "var(--font-mono)",
                    fontSize: "28px",
                    fontWeight: 700,
                    color: "var(--text-brand)",
                    lineHeight: 1,
                    margin: 0,
                  }}
                >
                  98.11%
                </p>
                <p
                  style={{
                    fontFamily: "var(--font-body)",
                    fontSize: "12px",
                    color: "var(--text-faint)",
                    margin: "4px 0 0 0",
                    lineHeight: 1.4,
                  }}
                >
                  Held-out validation accuracy
                </p>
              </div>
              <div
                style={{ width: "1px", height: "40px", background: "var(--border-subtle)", flexShrink: 0 }}
                aria-hidden="true"
              />
              <div>
                <p
                  style={{
                    fontFamily: "var(--font-mono)",
                    fontSize: "28px",
                    fontWeight: 700,
                    color: "var(--text-brand)",
                    lineHeight: 1,
                    margin: 0,
                  }}
                >
                  3-Class
                </p>
                <p
                  style={{
                    fontFamily: "var(--font-body)",
                    fontSize: "12px",
                    color: "var(--text-faint)",
                    margin: "4px 0 0 0",
                    lineHeight: 1.4,
                  }}
                >
                  Healthy / Bleached / Dead
                </p>
              </div>
            </div>
          </div>

          <div aria-hidden="true" className="w-full md:mt-[104px]" style={{ width: "100%" }}>
            <video
              ref={videoRef}
              src={shouldLoad ? VIDEO_SRC : undefined}
              muted
              playsInline
              preload="metadata"
              style={{
                width: "100%",
                height: "auto",
                display: "block",
                borderRadius: "16px",
                filter: "drop-shadow(0 28px 42px rgba(13,23,56,0.15))",
                border: "1px solid var(--border-subtle)",
              }}
            />
          </div>
        </div>
      </div>
    </section>
  );
}
