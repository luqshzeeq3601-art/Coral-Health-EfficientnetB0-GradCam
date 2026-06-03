import { useState, useEffect } from "react";
import coralLogo from "../assets/corallogo.png";

interface HeaderProps {
  dark: boolean;
  toggle: () => void;
}

const NAV_LINKS = [
  { label: "Mission", href: "#mission" },
  { label: "Workflow", href: "#workflow" },
  { label: "Technology", href: "#technology" },
  { label: "Performance", href: "#performance" },
  { label: "Grad-CAM", href: "#gradcam-3d" },
] as const;

const SKIP_LINKS = [
  { label: "Skip to Mission", href: "#mission" },
  { label: "Skip to Workflow", href: "#workflow" },
  { label: "Skip to Technology", href: "#technology" },
  { label: "Skip to Performance", href: "#performance" },
  { label: "Skip to Grad-CAM", href: "#gradcam-3d" },
  { label: "Skip to Try Model", href: "#try-model" },
] as const;

function SunIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
      <circle cx="8" cy="8" r="3" fill="currentColor" />
      <path
        d="M8 1v1.5M8 13.5V15M1 8h1.5M13.5 8H15M3.4 3.4l1.1 1.1M11.5 11.5l1.1 1.1M3.4 12.6l1.1-1.1M11.5 4.5l1.1-1.1"
        stroke="currentColor" strokeWidth="1.4" strokeLinecap="round"
      />
    </svg>
  );
}

function MoonIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true">
      <path d="M13.6 10.2a5.5 5.5 0 01-7.8-7.8A6.5 6.5 0 1013.6 10.2z" />
    </svg>
  );
}

export default function Header({ dark, toggle }: HeaderProps) {
  const [menuOpen, setMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);
  const [isOverDarkSection, setIsOverDarkSection] = useState(true);

  // Lightweight scrolled flag — reads scrollY only (no forced layout), rAF-throttled.
  useEffect(() => {
    let ticking = false;
    const update = () => {
      ticking = false;
      setScrolled(window.scrollY > 8);
    };
    const onScroll = () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(update);
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    update();
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // Detect when the header overlaps a dark section using IntersectionObserver.
  // A 1px-tall detection band is positioned at the header's vertical center
  // (~36px from the top); any [data-theme="dark"] section intersecting that
  // band means the header text needs to flip to light. No per-scroll layout reads.
  useEffect(() => {
    const HEADER_CENTER = 36; // half of header height + padding
    const intersecting = new Set<Element>();
    let observer: IntersectionObserver | null = null;

    const build = () => {
      observer?.disconnect();
      const sections = Array.from(document.querySelectorAll('[data-theme="dark"]'));
      if (sections.length === 0) {
        setIsOverDarkSection(false);
        return;
      }
      intersecting.clear();
      // Root margin collapses the viewport to a 1px strip at HEADER_CENTER.
      const bottomInset = Math.max(0, window.innerHeight - HEADER_CENTER - 1);
      observer = new IntersectionObserver(
        (entries) => {
          for (const entry of entries) {
            if (entry.isIntersecting) intersecting.add(entry.target);
            else intersecting.delete(entry.target);
          }
          setIsOverDarkSection(intersecting.size > 0);
        },
        { rootMargin: `-${HEADER_CENTER}px 0px -${bottomInset}px 0px`, threshold: 0 }
      );
      sections.forEach((s) => observer!.observe(s));
    };

    // Build after first paint so target sections exist in the DOM.
    const initId = window.setTimeout(build, 50);

    // Re-create the band on resize (viewport height feeds the rootMargin).
    let resizeRaf = 0;
    const onResize = () => {
      cancelAnimationFrame(resizeRaf);
      resizeRaf = requestAnimationFrame(build);
    };
    window.addEventListener("resize", onResize, { passive: true });

    return () => {
      clearTimeout(initId);
      cancelAnimationFrame(resizeRaf);
      window.removeEventListener("resize", onResize);
      observer?.disconnect();
    };
  }, []);

  const forceLightText = isOverDarkSection && !dark;
  const logoTextColor = forceLightText ? "#ffffff" : "var(--header-text)";
  const navTextColor = forceLightText ? "rgba(255, 255, 255, 0.85)" : "var(--header-nav-text)";
  const navHoverColor = forceLightText ? "rgba(255, 255, 255, 0.12)" : "var(--header-hover)";
  const navActiveColor = forceLightText ? "#ffffff" : "var(--text-primary)";

  return (
    <>
      {/* Skip-to-content links */}
      <div className="sr-only focus-within:not-sr-only focus-within:fixed focus-within:top-0 focus-within:left-0 focus-within:z-[200] focus-within:flex focus-within:gap-2 focus-within:p-2 focus-within:bg-[var(--bg-card)]">
        {SKIP_LINKS.map(({ label, href }) => (
          <a
            key={href}
            href={href}
            className="inline-flex items-center justify-center min-h-[44px] px-4 text-sm font-semibold bg-[var(--brand-primary)] text-white rounded-[8px] focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)] focus:ring-offset-2"
            style={{ fontFamily: "var(--font-body)" }}
          >
            {label}
          </a>
        ))}
      </div>

      {/* Main header */}
      <header role="banner" className="fixed top-0 left-0 right-0 z-50 px-4 pt-3 transition-[padding] duration-300">
        <div
          className="mx-auto flex items-center justify-between"
          style={{
            maxWidth: "1264px",
            paddingLeft: "18px",
            paddingRight: "18px",
            height: "64px",
            borderRadius: "999px",
            border: `1px solid ${scrolled ? "var(--header-border-scrolled)" : "var(--header-border-rest)"}`,
            background: scrolled ? "var(--header-bg-scrolled)" : "var(--header-bg-rest)",
            backdropFilter: scrolled ? "saturate(180%) blur(16px)" : "saturate(180%) blur(12px)",
            WebkitBackdropFilter: scrolled ? "saturate(180%) blur(16px)" : "saturate(180%) blur(12px)",
            boxShadow: scrolled
              ? `0 18px 45px -30px var(--header-shadow-scrolled), inset 0 1px 1px rgba(255, 255, 255, 0.15), inset 0 -1px 1px rgba(0, 0, 0, 0.1)`
              : "0 10px 32px -28px rgba(13,23,56,0.35), inset 0 1px 1px rgba(255, 255, 255, 0.1)",
            transition: "background 250ms ease, border-color 250ms ease, box-shadow 300ms ease",
          }}
        >
          {/* Logo */}
          <a
            href="#"
            className="flex items-center gap-2.5 min-h-[44px] focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-2 rounded-sm"
            aria-label="Coral Health AI — home"
          >
            <span className="flex items-center justify-center w-8 h-8 rounded-[8px] overflow-hidden" aria-hidden="true">
              <img src={coralLogo} alt="" width={32} height={32} decoding="async" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
            </span>
            <span
              className="text-base font-semibold tracking-tight transition-colors duration-300"
              style={{ fontFamily: "var(--font-body)", color: logoTextColor }}
            >
              Coral Health AI
            </span>
          </a>

          {/* Desktop navigation */}
          <nav
            aria-label="Primary navigation"
            className="hidden md:flex items-center gap-1 relative"
          >
            <div className="flex items-center gap-1 relative" onMouseLeave={() => setHoveredIndex(null)}>
              {NAV_LINKS.map(({ label, href }, i) => (
                <a
                  key={href}
                  href={href}
                  onMouseEnter={() => setHoveredIndex(i)}
                  className="relative inline-flex items-center justify-center min-h-[44px] px-4 text-sm font-semibold rounded-[8px] focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-1 transition-colors duration-300"
                  style={{ fontFamily: "var(--font-body)", color: hoveredIndex === i ? navActiveColor : navTextColor }}
                >
                  {hoveredIndex === i && (
                    <div
                      className="absolute inset-0 rounded-[8px]"
                      style={{
                        background: navHoverColor,
                        transition: "background 180ms ease, opacity 180ms ease",
                      }}
                    />
                  )}
                  <span className="relative z-10">{label}</span>
                </a>
              ))}
            </div>

            {/* Theme toggle button */}
            <button
              type="button"
              onClick={toggle}
              aria-label={dark ? "Switch to light mode" : "Switch to dark mode"}
              className="inline-flex items-center justify-center w-[44px] h-[44px] rounded-[8px] transition-colors duration-300 focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-1"
              style={{ color: dark ? "var(--brand-primary)" : navTextColor }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.background = navHoverColor; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.background = "transparent"; }}
            >
              {dark ? <SunIcon /> : <MoonIcon />}
            </button>

            {/* Try Model CTA */}
            <a
              href="#try-model"
              className="inline-flex items-center justify-center min-h-[44px] px-5 ml-1 text-sm font-semibold text-white rounded-[8px] transition-colors duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-2"
              style={{ fontFamily: "var(--font-body)", background: "var(--brand-primary)" }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLAnchorElement).style.background = "var(--brand-hover)"; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLAnchorElement).style.background = "var(--brand-primary)"; }}
            >
              Try Model
            </a>
          </nav>

          {/* Mobile: theme toggle + hamburger */}
          <div className="md:hidden flex items-center gap-1">
            <button
              type="button"
              onClick={toggle}
              aria-label={dark ? "Switch to light mode" : "Switch to dark mode"}
              className="inline-flex items-center justify-center w-[44px] h-[44px] rounded-[8px] transition-colors duration-300 focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
              style={{ color: dark ? "var(--brand-primary)" : navTextColor }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.background = navHoverColor; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.background = "transparent"; }}
            >
              {dark ? <SunIcon /> : <MoonIcon />}
            </button>

            <button
              type="button"
              aria-label={menuOpen ? "Close navigation menu" : "Open navigation menu"}
              aria-expanded={menuOpen}
              aria-controls="mobile-nav"
              onClick={() => setMenuOpen((v) => !v)}
              className="inline-flex items-center justify-center w-[44px] h-[44px] rounded-[8px] transition-colors duration-300 focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
              style={{ color: logoTextColor }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.background = navHoverColor; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.background = "transparent"; }}
            >
              <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                {menuOpen ? (
                  <path fillRule="evenodd" clipRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" />
                ) : (
                  <path fillRule="evenodd" clipRule="evenodd" d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm1 4a1 1 0 100 2h12a1 1 0 100-2H4z" />
                )}
              </svg>
            </button>
          </div>
        </div>

        {/* Mobile navigation drawer */}
        {menuOpen && (
          <nav
            id="mobile-nav"
            aria-label="Mobile navigation"
            className="md:hidden border-t"
            style={{ borderColor: "var(--mobile-nav-border)", background: "var(--mobile-nav-bg)" }}
          >
            <div className="flex flex-col py-2 px-4">
              {NAV_LINKS.map(({ label, href }) => (
                <a
                  key={href}
                  href={href}
                  onClick={() => setMenuOpen(false)}
                  className="flex items-center min-h-[44px] px-4 text-sm font-medium rounded-[8px] transition-colors duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
                  style={{ fontFamily: "var(--font-body)", color: "var(--text-secondary)" }}
                  onMouseEnter={(e) => { (e.currentTarget as HTMLAnchorElement).style.background = "var(--bg-chip)"; }}
                  onMouseLeave={(e) => { (e.currentTarget as HTMLAnchorElement).style.background = "transparent"; }}
                >
                  {label}
                </a>
              ))}
              <a
                href="#try-model"
                onClick={() => setMenuOpen(false)}
                className="flex items-center justify-center min-h-[44px] mt-2 mb-1 px-5 text-sm font-semibold text-white rounded-[8px] transition-colors duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
                style={{ fontFamily: "var(--font-body)", background: "var(--brand-primary)" }}
              >
                Try Model
              </a>
            </div>
          </nav>
        )}
      </header>
    </>
  );
}
