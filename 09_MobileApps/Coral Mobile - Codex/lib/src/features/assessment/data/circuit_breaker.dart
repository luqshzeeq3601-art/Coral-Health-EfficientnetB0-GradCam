/// A minimal circuit breaker used to stop hammering an unreachable backend.
///
/// After [failureThreshold] consecutive connectivity failures (timeouts /
/// socket errors) the breaker "opens" and [isOpen] returns `true` for the
/// [cooldown] window. While open, callers should fail fast instead of issuing
/// another request that would just time out and freeze the flow. Any success
/// (or a request that at least reached the backend) resets it.
class CircuitBreaker {
  CircuitBreaker({
    this.failureThreshold = 3,
    this.cooldown = const Duration(seconds: 30),
  });

  final int failureThreshold;
  final Duration cooldown;

  int _consecutiveFailures = 0;
  DateTime? _openedAt;

  /// Whether the breaker is currently open (requests should fail fast).
  /// Automatically transitions to half-open once the cooldown has elapsed.
  bool get isOpen {
    final openedAt = _openedAt;
    if (openedAt == null) return false;
    if (DateTime.now().difference(openedAt) >= cooldown) {
      // Cooldown elapsed: allow a single trial request through (half-open).
      return false;
    }
    return true;
  }

  /// Time left before the breaker stops failing fast. Zero when closed.
  Duration get remainingCooldown {
    final openedAt = _openedAt;
    if (openedAt == null) return Duration.zero;
    final left = cooldown - DateTime.now().difference(openedAt);
    return left.isNegative ? Duration.zero : left;
  }

  /// Records a healthy interaction with the backend and closes the breaker.
  void recordSuccess() {
    _consecutiveFailures = 0;
    _openedAt = null;
  }

  /// Records a connectivity failure. Opens the breaker once the threshold of
  /// consecutive failures is reached.
  void recordFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= failureThreshold) {
      _openedAt = DateTime.now();
    }
  }

  /// Forcibly returns the breaker to its initial closed state.
  void reset() {
    _consecutiveFailures = 0;
    _openedAt = null;
  }
}
