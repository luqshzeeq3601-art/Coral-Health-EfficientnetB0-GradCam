import { useState, useRef, useEffect, useId, useCallback, type ReactNode } from "react";
import { ChevronLeft, ChevronRight, Send, Trash, X, Sparkles, HelpCircle, ArrowUp } from "lucide-react";
import { chat as chatApi } from "../lib/api";
import { getPredictionContext } from "../lib/predictionContext";

/* ── Types ── */
interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  text: string;
}

/* Unique message id — falls back to a monotonic counter so two messages in the
   same millisecond never collide when crypto.randomUUID is unavailable. */
let _idSeq = 0;
const genMessageId = () =>
  (typeof crypto !== "undefined" && crypto.randomUUID?.()) || `msg-${Date.now()}-${_idSeq++}`;

/* ── Suggested prompts ── */
const PROMPTS = [
  { label: "Explain the analysis result", icon: <Sparkles size={14} className="text-[var(--brand-primary)]" /> },
  { label: "What does this mean?", icon: <HelpCircle size={14} className="text-[var(--brand-primary)]" /> },
  { label: "Grad-CAM details", icon: <Sparkles size={14} className="text-[var(--brand-primary)]" /> },
] as const;

/* ── Initial greeting ── */
const INIT: ChatMessage[] = [
  {
    id: "init",
    role: "assistant",
    text: "Hello! I'm Qwen AI, powered by a local model. How can I help you understand your coral analysis?",
  },
];

/* ── Simulated responses ── */
function getResponse(text: string): string {
  const q = text.toLowerCase();
  if (q.includes("explain") || q.includes("result") || q.includes("mean") || q.includes("bleach")) {
    return "Your reef image was classified as **Bleached Coral** with 92.4% confidence. Bleaching occurs when thermal stress causes coral polyps to expel their symbiotic zooxanthellae algae, leaving behind the characteristic white calcium carbonate skeleton. The EfficientNet-B0 backbone detected reduced pigmentation signatures and textural anomalies consistent with bleaching across the highlighted spatial regions.";
  }
  if (q.includes("confidence") || q.includes("score") || q.includes("percent") || q.includes("%") || q.includes("92")) {
    return "Confidence scores represent the softmax probability distribution across all three classes: **Bleached 92.4%**, Dead 4.4%, Healthy 3.2%. A score above 85% in a single class generally indicates a reliable prediction. The 5-Seed SWA Ensemble reduces variance by averaging probabilities across five model checkpoints, improving stability over any single run.";
  }
  if (q.includes("grad") || q.includes("cam") || q.includes("heatmap") || q.includes("heat") || q.includes("why") || q.includes("map") || q.includes("attention")) {
    return "Grad-CAM computes the gradient of the **Bleached** class score with respect to the final convolutional layer activations. The **cyan heatmap hotspots** mark spatial regions with the highest gradient magnitude — areas the model associates with bleaching, typically whitened skeleton patches and colour-desaturated tissue zones. High-intensity regions confirm the model is attending to biologically meaningful features.";
  }
  return "I can help you understand the coral health classification. Try asking **what the Bleached prediction means**, what **confidence scores** represent across the three classes, or how **Grad-CAM** localised the features driving that result. You can also use the prompt cards below.";
}

/* ── Render inline bold and newlines/bullets ── */
function renderText(text: string): ReactNode {
  // Normalize inline bullets to proper newlines (e.g., "explained: - The..." -> "explained:\n- The...")
  const normalizedText = text.replace(/([:;.]\s+)(-\s+)/g, "$1\n$2");

  return normalizedText.split('\n').map((line, idx) => {
    const isBullet = line.trim().startsWith('- ') || line.trim().startsWith('* ');
    const content = line.trim().replace(/^[-*]\s+/, '');
    
    if (content === '') return <div key={idx} style={{ height: "8px" }} />;

    const parts = content.split(/(\*\*[^*]+\*\*)/g);
    const lineContent = parts.map((part, i) =>
      part.startsWith("**") && part.endsWith("**") ? (
        <strong key={i} style={{ fontWeight: 700, color: "var(--text-primary)" }}>
          {part.slice(2, -2)}
        </strong>
      ) : (
        <span key={i}>{part}</span>
      )
    );

    if (isBullet) {
      return (
        <div key={idx} style={{ display: "flex", gap: "8px", marginTop: "6px", marginBottom: "6px", paddingLeft: "4px" }}>
          <span style={{ color: "var(--brand-primary)", fontWeight: "bold", userSelect: "none" }}>•</span>
          <div style={{ flex: 1 }}>{lineContent}</div>
        </div>
      );
    }

    return (
      <div key={idx} style={{ marginTop: idx > 0 ? "8px" : "0" }}>
        {lineContent}
      </div>
    );
  });
}

/* ── Animated typing indicator ── */
function TypingDots() {
  return (
    <div
      aria-label="Qwen AI is thinking"
      style={{
        display: "inline-flex",
        alignItems: "center",
        padding: "12px 16px",
        background: "var(--bg-alt)",
        borderRadius: "4px 16px 16px 16px",
        fontFamily: "var(--font-body)",
        fontSize: "13px",
        fontWeight: 500,
        border: "1px solid var(--border-subtle)",
        boxShadow: "0 4px 12px rgba(0,0,0,0.03)",
      }}
    >
      <style>{`
        @keyframes text-glow-pulse {
          0%, 100% { 
            opacity: 0.5; 
            text-shadow: 0 0 0 transparent;
            color: var(--text-secondary);
          }
          50% { 
            opacity: 1; 
            text-shadow: 0 0 8px var(--brand-glow);
            color: var(--text-primary);
          }
        }
        .glowing-thinking-text {
          animation: text-glow-pulse 1.6s ease-in-out infinite;
        }
      `}</style>
      <span className="glowing-thinking-text">Thinking...</span>
    </div>
  );
}

/* ── Message bubble ── */
function MessageBubble({ msg }: { msg: ChatMessage }) {
  const isUser = msg.role === "user";
  return (
    <div
      style={{
        display: "flex",
        justifyContent: isUser ? "flex-end" : "flex-start",
        marginBottom: "16px",
      }}
    >
      {!isUser && (
        <div style={{
          width: "32px", height: "32px", borderRadius: "50%", background: "color-mix(in srgb, var(--brand-primary) 10%, transparent)",
          display: "flex", alignItems: "center", justifyContent: "center",
          flexShrink: 0, marginRight: "10px", marginTop: "2px", overflow: "hidden"
        }}>
          <img
            src="/qwen_logo.png"
            alt=""
            aria-hidden="true"
            style={{ width: "100%", height: "100%", objectFit: "cover" }}
          />
        </div>
      )}
      <div
        style={{
          maxWidth: "85%",
          padding: "14px 18px",
          borderRadius: isUser ? "16px 16px 4px 16px" : "4px 16px 16px 16px",
          background: isUser ? "var(--brand-primary)" : "var(--bg-alt)",
          border: isUser ? "none" : "1px solid var(--border-subtle)",
          boxShadow: isUser ? "0 4px 14px -4px var(--brand-glow)" : "none",
          color: isUser ? "#ffffff" : "var(--text-primary)",
          fontFamily: "var(--font-body)",
          fontSize: "13px",
          lineHeight: 1.6,
          wordBreak: "break-word" as const,
        }}
      >
        {renderText(msg.text)}
      </div>
    </div>
  );
}

/* ── Main export ── */
export default function ChatBot({ dark = false, initialOpen = false, integrated = false }: { dark?: boolean; initialOpen?: boolean; integrated?: boolean }) {
  const [open, setOpen] = useState(integrated ? true : initialOpen);
  const [messages, setMessages] = useState<ChatMessage[]>(INIT);
  const [input, setInput] = useState("");
  const [typing, setTyping] = useState(false);

  const inputRef = useRef<HTMLTextAreaElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const promptScrollerRef = useRef<HTMLDivElement>(null);
  const headingId = useId();
  const inputId = useId();
  const [promptOverflow, setPromptOverflow] = useState({ left: false, right: false });

  /* Auto-scroll on new messages or typing */
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }, [messages, typing]);

  const updatePromptOverflow = useCallback(() => {
    const el = promptScrollerRef.current;
    if (!el) return;

    const maxScroll = Math.max(0, el.scrollWidth - el.clientWidth);
    setPromptOverflow({
      left: el.scrollLeft > 4,
      right: el.scrollLeft < maxScroll - 4,
    });
  }, []);

  useEffect(() => {
    if (!open) return;

    updatePromptOverflow();
    const el = promptScrollerRef.current;
    const onResize = () => updatePromptOverflow();

    el?.addEventListener("scroll", updatePromptOverflow, { passive: true });
    window.addEventListener("resize", onResize);

    return () => {
      el?.removeEventListener("scroll", updatePromptOverflow);
      window.removeEventListener("resize", onResize);
    };
  }, [open, updatePromptOverflow]);

  /* Focus input when drawer opens */
  useEffect(() => {
    if (!open) return;
    const t = setTimeout(() => inputRef.current?.focus(), 340);
    return () => clearTimeout(t);
  }, [open]);

  /* Escape closes drawer */
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !integrated) setOpen(false);
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open, integrated]);

  const sendMessage = useCallback(
    (override?: string) => {
      const text = (override ?? input).trim();
      if (!text || typing) return;

      const userMsg: ChatMessage = {
        id: genMessageId(),
        role: "user",
        text,
      };

      /* History sent to the backend = the conversation so far (excludes greeting). */
      const history = messages
        .filter((m) => m.id !== "init")
        .map((m) => ({ role: m.role, content: m.text }));

      setMessages((prev) => [...prev, userMsg]);
      setInput("");
      /* reset textarea height */
      if (inputRef.current) inputRef.current.style.height = "auto";
      setTyping(true);

      const pushReply = (replyText: string) => {
        const botMsg: ChatMessage = {
          id: genMessageId(),
          role: "assistant",
          text: replyText,
        };
        setTyping(false);
        setMessages((prev) => [...prev, botMsg]);
      };

      chatApi({ message: text, history, predictionContext: getPredictionContext() })
        .then((res) => pushReply(res.reply))
        /* Network/backend failure → graceful local fallback so the UI never stalls. */
        .catch(() => pushReply(getResponse(text)));
    },
    [input, typing, messages]
  );

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  const handleTextareaChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setInput(e.target.value);
    const el = e.target;
    el.style.height = "auto";
    el.style.height = Math.min(el.scrollHeight, 96) + "px";
  };

  const resetChat = () => {
    if (typing) return;
    setMessages(INIT);
    setInput("");
    if (inputRef.current) inputRef.current.style.height = "auto";
  };

  return (
    <div
      id="chatbot"
      style={
        integrated
          ? {
              display: "flex",
              width: "100%",
              flex: 1,
            }
          : {
              position: "fixed",
              bottom: "24px",
              right: "24px",
              zIndex: 200,
            }
      }
    >
      {/* ── FAB button (closed state) ── */}
      {!integrated && (
        <button
          type="button"
          aria-label="Open Coral Assistant chatbot"
          aria-expanded={open}
          onClick={() => setOpen(true)}
          style={{
            position: "absolute",
            bottom: 0,
            right: 0,
            width: "56px",
            height: "56px",
            borderRadius: "50%",
            background: dark
              ? "var(--bg-card)"
              : "#ffffff",
            border: dark ? "1px solid var(--border-base)" : "1px solid rgba(0, 0, 0, 0.15)",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            boxShadow: dark
              ? "0 8px 24px -4px rgba(255, 255, 255, 0.25), 0 2px 8px -2px rgba(0,0,0,0.5)"
              : "0 10px 30px -10px rgba(0, 0, 0, 0.25), 0 2px 8px -2px rgba(0, 0, 0, 0.08)",
            opacity: open ? 0 : 1,
            pointerEvents: open ? "none" : "auto",
            transform: open ? "scale(0.75)" : "scale(1)",
            transition: "all 250ms cubic-bezier(0.4, 0, 0.2, 1)",
          }}
          className="focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-2"
          onMouseEnter={(e) => {
            if (!dark) {
              e.currentTarget.style.borderColor = "rgba(0, 0, 0, 0.35)";
              e.currentTarget.style.boxShadow = "0 12px 35px -8px rgba(0, 0, 0, 0.3), 0 3px 10px -1px rgba(0, 0, 0, 0.12)";
            } else {
              e.currentTarget.style.borderColor = "#ffffff";
              e.currentTarget.style.boxShadow = "0 12px 35px -8px rgba(255, 255, 255, 0.4), 0 3px 10px -1px rgba(255, 255, 255, 0.2)";
            }
          }}
          onMouseLeave={(e) => {
            if (!dark) {
              e.currentTarget.style.borderColor = "rgba(0, 0, 0, 0.15)";
              e.currentTarget.style.boxShadow = "0 10px 30px -10px rgba(0, 0, 0, 0.25), 0 2px 8px -2px rgba(0, 0, 0, 0.08)";
            } else {
              e.currentTarget.style.borderColor = "var(--border-base)";
              e.currentTarget.style.boxShadow = "0 8px 24px -4px rgba(255, 255, 255, 0.25), 0 2px 8px -2px rgba(0,0,0,0.5)";
            }
          }}
        >
          <img
            src="/corallogo.png"
            alt=""
            aria-hidden="true"
            style={{
              width: "36px",
              height: "36px",
              borderRadius: "50%",
              objectFit: "cover",
              boxShadow: dark ? "none" : "0 2px 6px rgba(0, 0, 0, 0.08)",
              transition: "all 250ms ease",
            }}
          />
        </button>
      )}

      {/* ── Chat drawer panel ── */}
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={headingId}
        aria-hidden={!open}
        style={
          integrated
            ? {
                display: "flex",
                flexDirection: "column",
                flex: 1,
                width: "100%",
                height: "100%",
                background: "color-mix(in srgb, var(--bg-card) 90%, transparent)",
                backdropFilter: "blur(20px)",
                WebkitBackdropFilter: "blur(20px)",
                border: "1px solid color-mix(in srgb, var(--brand-cyan) 20%, var(--border-subtle))",
                borderRadius: "16px",
                boxShadow: "inset 0 1px 0 rgba(255,255,255,0.05), 0 18px 50px -20px rgba(0, 0, 0, 0.5)",
                overflow: "hidden",
                opacity: 1,
                pointerEvents: "auto",
                maxHeight: "none",
                transform: "translateY(0)",
              }
            : {
                position: "absolute",
                bottom: 0,
                right: 0,
                width: "380px",
                maxWidth: "calc(100vw - 32px)",
                background: "var(--bg-card)",
                border: "1px solid var(--border-subtle)",
                borderRadius: "20px",
                boxShadow: "0 24px 64px -12px var(--brand-glow), 0 8px 24px -4px rgba(0,0,0,0.12)",
                display: "flex",
                flexDirection: "column",
                overflow: "hidden",
                maxHeight: "520px",
                transform: open ? "translateY(0)" : "translateY(calc(100% + 32px))",
                opacity: open ? 1 : 0,
                pointerEvents: open ? "auto" : "none",
                transition: "transform 320ms cubic-bezier(0.32,0.72,0,1), opacity 200ms ease",
              }
        }
      >
        {/* Header */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: "20px 24px",
            borderBottom: "1px solid var(--border-faint)",
            flexShrink: 0,
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            <div style={{ width: "36px", height: "36px", borderRadius: "50%", background: "color-mix(in srgb, var(--brand-primary) 10%, transparent)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, overflow: "hidden" }}>
              <img src="/qwen_logo.png" alt="" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
            </div>
            <div>
              <h3 style={{ fontFamily: "var(--font-body)", fontSize: "16px", fontWeight: 700, color: "var(--text-primary)", margin: 0 }}>
                Qwen AI
              </h3>
              <p style={{ fontFamily: "var(--font-body)", fontSize: "12px", color: "var(--brand-primary)", fontWeight: 500, margin: 0 }}>
                Local LLM Assistant
              </p>
            </div>
          </div>
          {/* Header Actions */}
          <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
            {/* Delete chat button */}
            <button
              type="button"
              aria-label="Delete chat history"
              title="Delete chat"
              onClick={resetChat}
              disabled={typing || messages.length === INIT.length}
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                minWidth: "32px",
                minHeight: "32px",
                padding: 0,
                background: "transparent",
                border: "1px solid transparent",
                borderRadius: "8px",
                color: "#ef4444",
                cursor: typing || messages.length === INIT.length ? "not-allowed" : "pointer",
                opacity: typing || messages.length === INIT.length ? 0.35 : 0.9,
                transition: "all 150ms ease",
                flexShrink: 0,
              }}
              className="hover:bg-[var(--bg-chip)] hover:border-[var(--border-subtle)] focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
            >
              <Trash size={15} strokeWidth={1.9} aria-hidden="true" />
            </button>
            {/* Close button */}
            {!integrated && (
              <button
                type="button"
                aria-label="Close Coral Assistant"
                onClick={() => setOpen(false)}
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  minWidth: "32px",
                  minHeight: "32px",
                  padding: 0,
                  background: "transparent",
                  border: "1px solid transparent",
                  borderRadius: "8px",
                  color: "var(--text-faint)",
                  cursor: "pointer",
                  transition: "all 150ms ease",
                  flexShrink: 0,
                }}
                className="hover:bg-[#f3f4f6] hover:border-[#d1d5db] focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
              >
                <X size={15} strokeWidth={1.9} aria-hidden="true" />
              </button>
            )}
          </div>
        </div>

        {/* Messages area */}
        <div
          role="log"
          aria-label="Conversation"
          aria-live="polite"
          className="chat-scroll"
          style={{
            flex: 1,
            overflowY: "auto" as const,
            padding: "24px 24px",
            display: "flex",
            flexDirection: "column",
            minHeight: 0,
          }}
        >
          {messages.map((msg) => (
            <MessageBubble key={msg.id} msg={msg} />
          ))}
          {typing && (
            <div style={{ display: "flex", marginBottom: "10px" }}>
              <div style={{
                width: "32px", height: "32px", borderRadius: "50%", background: "color-mix(in srgb, var(--brand-primary) 10%, transparent)",
                display: "flex", alignItems: "center", justifyContent: "center",
                flexShrink: 0, marginRight: "10px", marginTop: "2px"
              }}>
                <img
                  src="/qwen.png"
                  alt=""
                  aria-hidden="true"
                  style={{ width: "20px", height: "20px", objectFit: "contain" }}
                />
              </div>
              <TypingDots />
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>



        {/* Suggested prompt cards */}
        <div
          style={{
            position: "relative",
            flexShrink: 0,
          }}
          aria-label="Suggested questions"
        >
          {promptOverflow.left && (
            <button
              type="button"
              aria-label="Scroll left"
              onClick={() => promptScrollerRef.current?.scrollBy({ left: -200, behavior: "smooth" })}
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                bottom: 0,
                width: "34px",
                zIndex: 1,
                display: "flex",
                alignItems: "center",
                justifyContent: "flex-start",
                paddingLeft: "8px",
                color: "var(--text-faint)",
                background: "transparent",
                border: "none",
                cursor: "pointer",
              }}
            >
              <span
                style={{
                  width: "22px",
                  height: "22px",
                  borderRadius: "999px",
                  border: "1px solid var(--border-base)",
                  background: "var(--bg-card)",
                  boxShadow: "0 4px 12px rgba(0,0,0,0.08)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <ChevronLeft size={15} strokeWidth={2.2} />
              </span>
            </button>
          )}
          <div
            ref={promptScrollerRef}
            onScroll={updatePromptOverflow}
            style={{
              display: "flex",
              gap: "8px",
              padding: "10px 24px",
              overflowX: "auto" as const,
              scrollbarWidth: "none" as const,
              scrollBehavior: "smooth",
            }}
            className="no-scrollbar"
            role="group"
          >
          {PROMPTS.map(({ label, icon }) => (
            <button
              key={label}
              type="button"
              onClick={() => sendMessage(label)}
              disabled={typing}
              style={{
                display: "flex",
                flexDirection: "row",
                alignItems: "center",
                flexShrink: 0,
                padding: "8px 14px",
                minHeight: "36px",
                background: "var(--bg-alt)",
                border: "1px solid var(--border-subtle)",
                borderRadius: "999px",
                cursor: typing ? "not-allowed" : "pointer",
                transition: "all 150ms ease",
                opacity: typing ? 0.5 : 1,
                gap: "6px"
              }}
              className="hover:bg-[var(--bg-chip)] focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-1"
              aria-label={`Ask: ${label}`}
            >
              {icon}
              <span
                style={{
                  fontFamily: "var(--font-body)",
                  fontSize: "12px",
                  fontWeight: 600,
                  color: "var(--text-primary)",
                  whiteSpace: "nowrap" as const,
                  lineHeight: 1.2,
                }}
              >
                {label}
              </span>
            </button>
          ))}
          </div>
          {promptOverflow.right && (
            <button
              type="button"
              aria-label="Scroll right"
              onClick={() => promptScrollerRef.current?.scrollBy({ left: 200, behavior: "smooth" })}
              style={{
                position: "absolute",
                right: 0,
                top: 0,
                bottom: 0,
                width: "42px",
                zIndex: 1,
                display: "flex",
                alignItems: "center",
                justifyContent: "flex-end",
                paddingRight: "8px",
                color: "var(--brand-primary)",
                background: "transparent",
                border: "none",
                cursor: "pointer",
              }}
            >
              <span
                style={{
                  width: "22px",
                  height: "22px",
                  borderRadius: "999px",
                  border: "1px solid var(--border-base)",
                  background: "var(--bg-card)",
                  boxShadow: "0 4px 12px rgba(0,0,0,0.08)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <ChevronRight size={15} strokeWidth={2.2} />
              </span>
            </button>
          )}
        </div>

        {/* Input area */}
        <div
          style={{
            padding: "16px 24px 28px",
            borderTop: "1px solid var(--border-faint)",
            flexShrink: 0,
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "8px",
              background: "var(--bg-alt)",
              border: "1px solid var(--border-subtle)",
              borderRadius: "24px",
              padding: "6px 6px 6px 16px",
              transition: "border-color 150ms ease",
            }}
            onFocusCapture={(e) => {
              (e.currentTarget as HTMLDivElement).style.borderColor = "var(--brand-primary)";
              (e.currentTarget as HTMLDivElement).style.boxShadow = "0 4px 14px -2px var(--brand-glow)";
            }}
            onBlurCapture={(e) => {
              (e.currentTarget as HTMLDivElement).style.borderColor = "var(--border-subtle)";
              (e.currentTarget as HTMLDivElement).style.boxShadow = "none";
            }}
          >
            <label htmlFor={inputId} className="sr-only">
              Type your question
            </label>
            <textarea
              ref={inputRef}
              id={inputId}
              value={input}
              onChange={handleTextareaChange}
              onKeyDown={handleKeyDown}
              placeholder="Ask a question..."
              rows={1}
              disabled={typing}
              style={{
                flex: 1,
                background: "transparent",
                border: "none",
                outline: "none",
                resize: "none" as const,
                fontFamily: "var(--font-body)",
                fontSize: "13px",
                color: "var(--text-primary)",
                lineHeight: 1.5,
                padding: 0,
                minHeight: "20px",
                maxHeight: "96px",
                overflowY: "auto" as const,
                scrollbarWidth: "none" as const,
              }}
              aria-label="Type your question for Coral Assistant"
            />
            <button
              type="button"
              onClick={() => sendMessage()}
              disabled={!input.trim() || typing}
              aria-label="Send message"
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                width: "36px",
                height: "36px",
                borderRadius: "50%",
                background: !input.trim() || typing ? "var(--bg-chip)" : "var(--brand-primary)",
                border: "none",
                cursor: !input.trim() || typing ? "not-allowed" : "pointer",
                color: !input.trim() || typing ? "var(--text-muted)" : "#ffffff",
                transition: "all 150ms ease",
                flexShrink: 0,
            }}
            className="focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-1"
          >
              <ArrowUp size={18} strokeWidth={2.5} aria-hidden="true" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
