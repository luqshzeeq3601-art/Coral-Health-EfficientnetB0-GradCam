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
    </div>
  );
}
