/**
 * Tiny global store for the most recent prediction, so the floating ChatBot
 * can send `predictionContext` to /api/chat without prop-drilling through App.
 * Mirrors design9's `latestPredictionContext`.
 */
import type { ChatPredictionContext } from "./api";

let latest: ChatPredictionContext | null = null;
const listeners = new Set<(ctx: ChatPredictionContext | null) => void>();

export function setPredictionContext(ctx: ChatPredictionContext | null) {
  latest = ctx;
  listeners.forEach((fn) => fn(latest));
}

export function getPredictionContext(): ChatPredictionContext | null {
  return latest;
}

export function subscribePredictionContext(
  fn: (ctx: ChatPredictionContext | null) => void
): () => void {
  listeners.add(fn);
  return () => listeners.delete(fn);
}
