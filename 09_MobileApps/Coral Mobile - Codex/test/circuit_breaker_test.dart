import 'package:coral_health_ai/src/features/assessment/data/circuit_breaker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts closed', () {
    final breaker = CircuitBreaker();
    expect(breaker.isOpen, isFalse);
    expect(breaker.remainingCooldown, Duration.zero);
  });

  test('opens after reaching the consecutive failure threshold', () {
    final breaker = CircuitBreaker(failureThreshold: 3);

    breaker.recordFailure();
    breaker.recordFailure();
    expect(breaker.isOpen, isFalse, reason: 'below threshold');

    breaker.recordFailure();
    expect(breaker.isOpen, isTrue, reason: 'threshold reached');
  });

  test('a success resets the failure count and closes the breaker', () {
    final breaker = CircuitBreaker(failureThreshold: 2);

    breaker.recordFailure();
    breaker.recordSuccess();
    breaker.recordFailure();
    expect(breaker.isOpen, isFalse,
        reason: 'success should have cleared the earlier failure');
  });

  test('transitions to half-open (closed) once the cooldown elapses', () async {
    final breaker = CircuitBreaker(
      failureThreshold: 1,
      cooldown: const Duration(milliseconds: 50),
    );

    breaker.recordFailure();
    expect(breaker.isOpen, isTrue);
    expect(breaker.remainingCooldown.inMilliseconds, greaterThan(0));

    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(breaker.isOpen, isFalse, reason: 'cooldown elapsed');
  });

  test('reset() forces the breaker back to closed', () {
    final breaker = CircuitBreaker(failureThreshold: 1);
    breaker.recordFailure();
    expect(breaker.isOpen, isTrue);

    breaker.reset();
    expect(breaker.isOpen, isFalse);
  });
}
