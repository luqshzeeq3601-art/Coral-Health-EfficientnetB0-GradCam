import { useState, useRef, useEffect, useId, useCallback, type ReactNode } from "react";
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
  { label: "Explain result", sub: "What does this mean?" },
  { label: "Confidence", sub: "What do scores mean?" },
  { label: "Grad-CAM", sub: "Why this prediction?" },
] as const;

/* ── Initial greeting ── */
const INIT: ChatMessage[] = [
  {
    id: "init",
    role: "assistant",
    text: "Hi! I'm Coral Assistant. I can help you understand your coral health result. Ask me about your prediction, confidence score, or Grad-CAM.",
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

/* ── Render inline bold from **text** markers ── */
function renderText(text: string): ReactNode {
  const parts = text.split(/(\*\*[^*]+\*\*)/g);
  return parts.map((part, i) =>
    part.startsWith("**") && part.endsWith("**") ? (
      <strong key={i} style={{ fontWeight: 700 }}>
        {part.slice(2, -2)}
      </strong>
    ) : (
      <span key={i}>{part}</span>
    )
  );
}

/* ── Animated typing indicator ── */
function TypingDots() {
  return (
    <div
      aria-label="Coral Assistant is typing"
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: "4px",
        padding: "10px 14px",
        background: "var(--bg-chip)",
        borderRadius: "12px 12px 12px 3px",
      }}
    >
      <style>{`
        @keyframes chatDot {
          0%,60%,100% { transform: translateY(0); opacity: 0.35; }
          30% { transform: translateY(-5px); opacity: 1; }
        }
      `}</style>
      {[0, 1, 2].map((i) => (
        <span
          key={i}
          aria-hidden="true"
          style={{
            width: "6px",
            height: "6px",
            borderRadius: "50%",
            background: "#a8a39c",
            display: "inline-block",
            animation: `chatDot 1.1s ${i * 0.16}s ease-in-out infinite`,
          }}
        />
      ))}
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
        marginBottom: "10px",
      }}
    >
      {!isUser && (
        <img
          src="/corallogo.png"
          alt=""
          aria-hidden="true"
          style={{
            width: "28px",
            height: "28px",
            borderRadius: "50%",
            objectFit: "cover",
            flexShrink: 0,
            marginRight: "8px",
            marginTop: "2px",
          }}
        />
      )}
      <div
        style={{
          maxWidth: "82%",
          padding: "10px 13px",
          borderRadius: isUser ? "14px 14px 3px 14px" : "14px 14px 14px 3px",
          background: isUser ? "var(--brand-primary)" : "var(--bg-chip)",
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
export default function ChatBot({ dark = false, initialOpen = false }: { dark?: boolean; initialOpen?: boolean }) {
  const [open, setOpen] = useState(initialOpen);
  const [messages, setMessages] = useState<ChatMessage[]>(INIT);
  const [input, setInput] = useState("");
  const [typing, setTyping] = useState(false);

  const inputRef = useRef<HTMLTextAreaElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const headingId = useId();
  const inputId = useId();

  /* Auto-scroll on new messages or typing */
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, typing]);

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
      if (e.key === "Escape") setOpen(false);
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open]);

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

  return (
    /* Fixed anchor: bottom-right of viewport */
    <div
      id="chatbot"
      style={{
        position: "fixed",
        bottom: "24px",
        right: "24px",
        zIndex: 200,
      }}
    >
      {/* ── FAB button (closed state) ── */}
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
          border: dark ? "1px solid var(--border-base)" : "1px solid rgba(0, 87, 230, 0.15)",
          cursor: "pointer",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          boxShadow: dark
            ? "0 8px 24px -4px rgba(56, 189, 248, 0.25), 0 2px 8px -2px rgba(0,0,0,0.5)"
            : "0 10px 30px -10px rgba(0, 87, 230, 0.25), 0 2px 8px -2px rgba(0, 87, 230, 0.08)",
          opacity: open ? 0 : 1,
          pointerEvents: open ? "none" : "auto",
          transform: open ? "scale(0.75)" : "scale(1)",
          transition: "all 250ms cubic-bezier(0.4, 0, 0.2, 1)",
        }}
        className="focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-2"
        onMouseEnter={(e) => {
          if (!dark) {
            e.currentTarget.style.borderColor = "rgba(0, 87, 230, 0.35)";
            e.currentTarget.style.boxShadow = "0 12px 35px -8px rgba(0, 87, 230, 0.3), 0 3px 10px -1px rgba(0, 87, 230, 0.12)";
          } else {
            e.currentTarget.style.borderColor = "var(--brand-cyan)";
            e.currentTarget.style.boxShadow = "0 12px 35px -8px rgba(56, 189, 248, 0.4), 0 3px 10px -1px rgba(56, 189, 248, 0.2)";
          }
        }}
        onMouseLeave={(e) => {
          if (!dark) {
            e.currentTarget.style.borderColor = "rgba(0, 87, 230, 0.15)";
            e.currentTarget.style.boxShadow = "0 10px 30px -10px rgba(0, 87, 230, 0.25), 0 2px 8px -2px rgba(0, 87, 230, 0.08)";
          } else {
            e.currentTarget.style.borderColor = "var(--border-base)";
            e.currentTarget.style.boxShadow = "0 8px 24px -4px rgba(56, 189, 248, 0.25), 0 2px 8px -2px rgba(0,0,0,0.5)";
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
            boxShadow: dark ? "none" : "0 2px 6px rgba(0, 87, 230, 0.08)",
            transition: "all 250ms ease",
          }}
        />
      </button>

      {/* ── Chat drawer panel ── */}
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={headingId}
        aria-hidden={!open}
        style={{
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
        }}
      >
        {/* Header */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "10px",
            padding: "0 16px",
            minHeight: "52px",
            borderBottom: "1px solid var(--border-faint)",
            flexShrink: 0,
          }}
        >
          <img
            src="/corallogo.png"
            alt=""
            aria-hidden="true"
            style={{
              width: "32px",
              height: "32px",
              borderRadius: "50%",
              objectFit: "cover",
              flexShrink: 0,
            }}
          />
          <div style={{ flex: 1, minWidth: 0 }}>
            <h2
              id={headingId}
              style={{
                fontFamily: "var(--font-body)",
                fontSize: "14px",
                fontWeight: 700,
                color: "var(--text-primary)",
                margin: 0,
                lineHeight: 1.2,
              }}
            >
              Coral Assistant
            </h2>
            <p
              style={{
                fontFamily: "var(--font-body)",
                fontSize: "11px",
                color: "var(--text-faint)",
                margin: 0,
                lineHeight: 1.3,
              }}
            >
              Explain your coral result
            </p>
          </div>
          {/* Online indicator */}
          <span
            style={{
              display: "flex",
              alignItems: "center",
              gap: "4px",
              fontFamily: "var(--font-body)",
              fontSize: "11px",
              color: "#3cab57",
              fontWeight: 500,
              marginRight: "4px",
            }}
            aria-label="Assistant is online"
          >
            <span
              style={{ width: "6px", height: "6px", borderRadius: "50%", background: "#3cab57", flexShrink: 0 }}
              aria-hidden="true"
            />
            Online
          </span>
          {/* Close button */}
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
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true">
              <path d="M3 3L11 11M11 3L3 11" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" />
            </svg>
          </button>
        </div>

        {/* Messages area */}
        <div
          role="log"
          aria-label="Conversation"
          aria-live="polite"
          style={{
            flex: 1,
            overflowY: "auto" as const,
            padding: "16px",
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
              <img
                src="/corallogo.png"
                alt=""
                aria-hidden="true"
                style={{
                  width: "28px",
                  height: "28px",
                  borderRadius: "50%",
                  objectFit: "cover",
                  flexShrink: 0,
                  marginRight: "8px",
                  marginTop: "2px",
                }}
              />
              <TypingDots />
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Disclaimer */}
        <div
          style={{
            margin: "0 12px",
            padding: "8px 12px",
            background: "var(--tint-orange)",
            border: "1px solid rgba(224,123,42,0.18)",
            borderRadius: "8px",
            flexShrink: 0,
          }}
          role="note"
          aria-label="Decision support disclaimer"
        >
          <p
            style={{
              fontFamily: "var(--font-body)",
              fontSize: "11px",
              lineHeight: 1.5,
              color: "var(--text-secondary)",
              margin: 0,
            }}
          >
            <strong style={{ color: "var(--text-primary)", fontWeight: 600 }}>Note:</strong> I provide explanations to help you understand the model output. I&apos;m decision support, not a final field diagnosis.
          </p>
        </div>

        {/* Suggested prompt cards */}
        <div
          style={{
            display: "flex",
            gap: "8px",
            padding: "10px 12px",
            overflowX: "auto" as const,
            flexShrink: 0,
            scrollbarWidth: "none" as const,
          }}
          aria-label="Suggested questions"
          role="group"
        >
          {PROMPTS.map(({ label, sub }) => (
            <button
              key={label}
              type="button"
              onClick={() => sendMessage(label)}
              disabled={typing}
              style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "flex-start",
                flexShrink: 0,
                padding: "8px 11px",
                minHeight: "44px",
                background: "var(--bg-alt)",
                border: "1px solid var(--border-base)",
                borderRadius: "10px",
                cursor: typing ? "not-allowed" : "pointer",
                transition: "all 150ms ease",
                opacity: typing ? 0.5 : 1,
                textAlign: "left" as const,
              }}
              className="hover:bg-[var(--brand-light)] hover:border-[var(--brand-glow)] focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-1"
              aria-label={`Ask: ${label} — ${sub}`}
            >
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
              <span
                style={{
                  fontFamily: "var(--font-body)",
                  fontSize: "10px",
                  color: "var(--text-muted)",
                  whiteSpace: "nowrap" as const,
                  marginTop: "2px",
                }}
              >
                {sub}
              </span>
            </button>
          ))}
        </div>

        {/* Input area */}
        <div
          style={{
            padding: "8px 12px 12px",
            borderTop: "1px solid var(--border-faint)",
            flexShrink: 0,
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "flex-end",
              gap: "8px",
              background: "var(--bg-alt)",
              border: "1px solid var(--border-subtle)",
              borderRadius: "12px",
              padding: "8px 8px 8px 12px",
              transition: "border-color 150ms ease",
            }}
            onFocusCapture={(e) => {
              (e.currentTarget as HTMLDivElement).style.borderColor = "var(--brand-primary)";
            }}
            onBlurCapture={(e) => {
              (e.currentTarget as HTMLDivElement).style.borderColor = "var(--border-subtle)";
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
              placeholder="Ask a question… (Enter to send)"
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
                width: "32px",
                height: "32px",
                borderRadius: "8px",
                background: !input.trim() || typing ? "var(--bg-chip)" : "var(--brand-primary)",
                border: "none",
                cursor: !input.trim() || typing ? "not-allowed" : "pointer",
                color: !input.trim() || typing ? "var(--text-muted)" : "#ffffff",
                transition: "all 150ms ease",
                flexShrink: 0,
              }}
              className="focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-1"
            >
              <svg width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true">
                <path d="M2 7H12M8 3L12 7L8 11" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
          </div>
          <p
            style={{
              fontFamily: "var(--font-body)",
              fontSize: "10px",
              color: "var(--text-muted)",
              margin: "5px 0 0 2px",
            }}
          >
            Enter to send · Shift+Enter for new line
          </p>
        </div>
      </div>
    </div>
  );
}
