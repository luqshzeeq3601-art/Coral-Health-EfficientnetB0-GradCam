import { useState } from "react";

interface Tool {
  name: string;
  devicon?: string;
  customUrl?: string;
  color: string;
  initials: string;
  needsWhiteBg?: boolean;
}

const TOOLS: Tool[] = [
  { name: "Python", devicon: "python/python-original.svg", color: "#3776AB", initials: "Py" },
  { name: "TensorFlow", devicon: "tensorflow/tensorflow-original.svg", color: "#FF6F00", initials: "TF" },
  { name: "Keras", devicon: "keras/keras-original.svg", color: "#D00000", initials: "Ke" },
  { name: "Scikit-learn", devicon: "scikitlearn/scikitlearn-original.svg", color: "#F7931E", initials: "Sk" },
  { name: "OpenCV", devicon: "opencv/opencv-original.svg", color: "#5C3EE8", initials: "CV" },
  { name: "NumPy", devicon: "numpy/numpy-original.svg", color: "#013243", initials: "Np" },
  { name: "Pandas", devicon: "pandas/pandas-original.svg", color: "#150458", initials: "Pd" },
  { name: "Matplotlib", devicon: "matplotlib/matplotlib-original.svg", color: "#11557C", initials: "Pl" },
  { name: "Kaggle", devicon: "kaggle/kaggle-original.svg", color: "#20BEFF", initials: "Kg" },
  { name: "NVIDIA GPU", customUrl: "https://cdn.simpleicons.org/nvidia/76B900", color: "#76B900", initials: "NV" },
  { name: "CUDA Toolkit", customUrl: "https://cdn.simpleicons.org/nvidia/76B900", color: "#76B900", initials: "CU" },
  { name: "cuDNN", customUrl: "https://cdn.simpleicons.org/nvidia/76B900", color: "#76B900", initials: "DN" },
  { name: "EfficientNetB0", customUrl: "/efficientnet_logo.png", color: "#0F6E56", initials: "EN", needsWhiteBg: true },
  { name: "Grad-CAM", customUrl: "/gradcam_logo.png", color: "#993C1D", initials: "GC", needsWhiteBg: true },
  { name: "Seaborn", customUrl: "https://seaborn.pydata.org/_images/logo-mark-lightbg.svg", color: "#4C78A8", initials: "Sb" },
  { name: "Pillow", customUrl: "/pillow_logo.png", color: "#306998", initials: "PIL", needsWhiteBg: true },
  { name: "Flask", devicon: "flask/flask-original.svg", color: "#000000", initials: "Fl", needsWhiteBg: true },
  { name: "Flask-CORS", devicon: "flask/flask-original.svg", color: "#000000", initials: "FC", needsWhiteBg: true },
  { name: "HTML5", devicon: "html5/html5-original.svg", color: "#E34F26", initials: "H5" },
  { name: "CSS3", devicon: "css3/css3-original.svg", color: "#1572B6", initials: "C3" },
  { name: "JavaScript", devicon: "javascript/javascript-original.svg", color: "#F7DF1E", initials: "JS" },
  { name: "TailwindCSS", devicon: "tailwindcss/tailwindcss-plain.svg", color: "#06B6D4", initials: "TW" },
  { name: "Chart.js", customUrl: "https://cdn.simpleicons.org/chartdotjs/FF6384", color: "#FF6384", initials: "Ch" },
  { name: "Lucide Icons", customUrl: "/lucide_logo.png", color: "#F97316", initials: "Lu", needsWhiteBg: true }
];

const ToolIcon = ({ tool }: { tool: Tool }) => {
  const [error, setError] = useState(false);

  const iconUrl = tool.customUrl || (tool.devicon ? `https://cdn.jsdelivr.net/gh/devicons/devicon@v2.16.0/icons/${tool.devicon}` : null);

  if (!iconUrl || error) {
    return (
      <div
        style={{ backgroundColor: tool.color }}
        className="w-6 h-6 rounded flex items-center justify-center text-[10px] font-bold text-white shrink-0"
        aria-hidden="true"
      >
        {tool.initials}
      </div>
    );
  }

  return (
    <div className={`shrink-0 w-6 h-6 flex items-center justify-center ${tool.needsWhiteBg ? "bg-white p-0.5 rounded" : ""}`}>
      <img
        src={iconUrl}
        alt={`${tool.name} icon`}
        width={24}
        height={24}
        loading="lazy"
        decoding="async"
        className="w-full h-full object-contain"
        onError={() => setError(true)}
      />
    </div>
  );
};

export default function LogoMarquee() {
  return (
    <section
      className="border-y px-2 py-8 overflow-hidden"
      aria-label="Software and Tools Used"
      style={{ background: "var(--bg-card)", borderColor: "var(--border-base)", transition: "background-color 250ms ease" }}
    >
      <div className="container mx-auto border-x max-sm:px-0 py-2" style={{ borderColor: "var(--border-base)" }}>
        <div className="marquee-container transition-opacity duration-700 ease-out group cursor-default">
          <div className="marquee-content">
            {TOOLS.map((tool, index) => (
              <div
                key={`tool-1-${index}`}
                className="flex items-center justify-center pr-6 mr-6 whitespace-nowrap transition-transform duration-300 hover:scale-105"
                style={{ borderRight: "1px solid var(--border-subtle)" }}
              >
                <div className="flex items-center gap-3">
                  <ToolIcon tool={tool} />
                  <span className="text-[15px] font-body font-semibold tracking-tight" style={{ color: "var(--text-primary)" }}>
                    {tool.name}
                  </span>
                </div>
              </div>
            ))}
          </div>
          {/* Duplicate for seamless infinite scrolling */}
          <div className="marquee-content" aria-hidden="true">
            {TOOLS.map((tool, index) => (
              <div
                key={`tool-2-${index}`}
                className="flex items-center justify-center pr-6 mr-6 whitespace-nowrap transition-transform duration-300 hover:scale-105"
                style={{ borderRight: "1px solid var(--border-subtle)" }}
              >
                <div className="flex items-center gap-3">
                  <ToolIcon tool={tool} />
                  <span className="text-[15px] font-body font-semibold tracking-tight" style={{ color: "var(--text-primary)" }}>
                    {tool.name}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
