import { lazy, Suspense, useEffect, useRef, useState } from "react";
import type { ReactNode } from "react";
import { useDarkMode } from "./hooks/useDarkMode";
import Header from "./components/Header";
import Hero from "./components/Hero";
import LogoMarquee from "./components/LogoMarquee";
import Footer from "./components/Footer";

const Mission = lazy(() => import("./components/Mission"));
const ModelWorkflow = lazy(() => import("./components/ModelWorkflow"));
const TechnologyStack = lazy(() => import("./components/TechnologyStack"));
const Validation = lazy(() => import("./components/Validation"));
const AttentionExplorer = lazy(() => import("./components/AttentionExplorer"));
const TryModel = lazy(() => import("./components/TryModel"));
const ChatBot = lazy(() => import("./components/ChatBot"));

function DeferredSection({
  id,
  minHeight,
  rootMargin = "1000px 0px",
  children,
}: {
  id: string;
  minHeight: number;
  rootMargin?: string;
  children: ReactNode;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [shouldRender, setShouldRender] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el || shouldRender) return;

    const renderIfTargeted = () => {
      if (window.location.hash === `#${id}`) {
        setShouldRender(true);
      }
    };
    renderIfTargeted();
    if (window.location.hash === `#${id}`) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setShouldRender(true);
          observer.disconnect();
        }
      },
      { rootMargin }
    );

    observer.observe(el);
    window.addEventListener("hashchange", renderIfTargeted);
    return () => {
      observer.disconnect();
      window.removeEventListener("hashchange", renderIfTargeted);
    };
  }, [id, rootMargin, shouldRender]);

  return (
    <div id={id} ref={ref} style={{ minHeight: shouldRender ? undefined : minHeight }}>
      {shouldRender ? <Suspense fallback={null}>{children}</Suspense> : null}
    </div>
  );
}

function ChatBotOnDemand({ dark }: { dark: boolean }) {
  const [requested, setRequested] = useState(false);

  if (requested) {
    return (
      <Suspense fallback={null}>
        <ChatBot dark={dark} initialOpen />
      </Suspense>
    );
  }

  return (
    <div
      id="chatbot-launcher"
      style={{
        position: "fixed",
        bottom: "24px",
        right: "24px",
        zIndex: 200,
      }}
    >
      <button
        type="button"
        aria-label="Open Coral Assistant chatbot"
        aria-expanded={false}
        onClick={() => setRequested(true)}
        className="focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-2"
        style={{
          width: "56px",
          height: "56px",
          borderRadius: "50%",
          background: dark ? "var(--bg-card)" : "#ffffff",
          border: dark ? "1px solid var(--border-base)" : "1px solid rgba(0, 87, 230, 0.15)",
          cursor: "pointer",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          boxShadow: dark
            ? "0 8px 24px -4px rgba(56, 189, 248, 0.25), 0 2px 8px -2px rgba(0,0,0,0.5)"
            : "0 10px 30px -10px rgba(0, 87, 230, 0.25), 0 2px 8px -2px rgba(0, 87, 230, 0.08)",
          transition: "border-color 180ms ease, box-shadow 180ms ease, transform 180ms ease",
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.transform = "translateY(-1px)";
          e.currentTarget.style.borderColor = dark ? "var(--brand-cyan)" : "rgba(0, 87, 230, 0.35)";
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.transform = "translateY(0)";
          e.currentTarget.style.borderColor = dark ? "var(--border-base)" : "rgba(0, 87, 230, 0.15)";
        }}
      >
        <img
          src="/corallogo.png"
          alt=""
          aria-hidden="true"
          width={36}
          height={36}
          decoding="async"
          style={{
            width: "36px",
            height: "36px",
            borderRadius: "50%",
            objectFit: "cover",
          }}
        />
      </button>
    </div>
  );
}

export default function App() {
  const { dark, toggle } = useDarkMode();

  return (
    <div style={{ background: "var(--bg-page)", minHeight: "100vh", transition: "background-color 250ms ease" }}>
      <Header dark={dark} toggle={toggle} />
      <main id="main-content">
        <Hero />
        <LogoMarquee />
        <DeferredSection id="mission" minHeight={900} rootMargin="850px 0px">
          <Mission sectionId={undefined} />
        </DeferredSection>
        <DeferredSection id="workflow" minHeight={1650} rootMargin="850px 0px">
          <ModelWorkflow sectionId={undefined} />
        </DeferredSection>
        <DeferredSection id="technology" minHeight={900} rootMargin="850px 0px">
          <TechnologyStack sectionId={undefined} />
        </DeferredSection>
        <DeferredSection id="performance" minHeight={1400} rootMargin="900px 0px">
          <Validation sectionId={undefined} />
        </DeferredSection>
        <DeferredSection id="gradcam-3d" minHeight={1300} rootMargin="900px 0px">
          <AttentionExplorer dark={dark} sectionId={undefined} />
        </DeferredSection>
        <DeferredSection id="try-model" minHeight={1100} rootMargin="700px 0px">
          <TryModel sectionId={undefined} />
        </DeferredSection>
      </main>
      <Footer />
      <ChatBotOnDemand dark={dark} />
    </div>
  );
}
