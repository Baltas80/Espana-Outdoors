/// Deterministic route-readiness evaluation.
///
/// This is a decision-support layer, not a safety guarantee. Providers must
/// supply verified, time-bounded facts; the evaluator only combines them.
library;

enum RouteReadiness { suitable, caution, notRecommended }

enum ReadinessFactorLevel { clear, caution, blocker }

class ReadinessFactor {
  const ReadinessFactor({
    required this.id,
    required this.label,
    required this.level,
    required this.reason,
    required this.source,
  });

  final String id;
  final String label;
  final ReadinessFactorLevel level;
  final String reason;
  final String source;
}

class RouteReadinessAssessment {
  const RouteReadinessAssessment({
    required this.result,
    required this.factors,
  });

  final RouteReadiness result;
  final List<ReadinessFactor> factors;

  List<ReadinessFactor> get actionableFactors =>
      List.unmodifiable(factors.where((factor) =>
          factor.level != ReadinessFactorLevel.clear));
}

class RouteReadinessEvaluator {
  const RouteReadinessEvaluator();

  RouteReadinessAssessment evaluate(Iterable<ReadinessFactor> factors) {
    final normalized = List<ReadinessFactor>.unmodifiable(factors);
    final hasBlocker = normalized.any(
      (factor) => factor.level == ReadinessFactorLevel.blocker,
    );
    final hasCaution = normalized.any(
      (factor) => factor.level == ReadinessFactorLevel.caution,
    );

    final result = hasBlocker
        ? RouteReadiness.notRecommended
        : hasCaution
            ? RouteReadiness.caution
            : RouteReadiness.suitable;

    return RouteReadinessAssessment(
      result: result,
      factors: normalized,
    );
  }
}
