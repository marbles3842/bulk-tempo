<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: Correct Weight Entry

- **Plan**: context/changes/correct-weight-entry/plan.md
- **Scope**: Full plan
- **Reviewed phases**: 1, 2, 3
- **Date**: 2026-10-11
- **Verdict**: NEEDS ATTENTION
- **Findings**: 0 critical, 2 warnings, 2 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | PASS |
| Scope Discipline | PASS |
| Safety & Quality | WARNING |
| Architecture | PASS |
| Pattern Consistency | PASS |
| Success Criteria | PASS |

## Findings

### F1 — Re-entrant Provider State Mutation Inside ref.listen
- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: bulk_tempo/lib/features/weight/presentation/views/weight_history_view.dart:60
- **Detail**: In WeightHistoryView.build(), ref.listen<WeightHistoryState> listens to background refresh errors to present a SnackBar. Calling clearRefreshError() synchronously inside this listener mutates weightHistoryViewModelProvider while Riverpod is mid-dispatch, triggering a secondary re-entrant notification and unnecessary widget rebuild.
- **Fix**: Defer clearRefreshError() via WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(weightHistoryViewModelProvider.notifier).clearRefreshError()).
  - Strength: Eliminates re-entrant state modification while preserving error cleanup.
  - Tradeoff: None; idiomatic Flutter/Riverpod pattern.
  - Confidence: HIGH — cleanly separates dispatch from cleanup.
  - Blind spot: None significant.
- **Decision**: PENDING

### F2 — Missing Loaded History Guard on Entry Deletion
- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: bulk_tempo/lib/features/weight/presentation/view_models/weight_entry_view_model.dart:270
- **Detail**: WeightEntryViewModel.submit() guards against saving when history is not loaded (if (historyState is! WeightHistoryLoaded) return false;). However, delete() lacks this check. If delete() executes when weightHistoryViewModelProvider is uninitialized or loading, applyDeletedEntry defaults local entries to empty and sets WeightHistoryLoaded with no data.
- **Fix**: Add check in WeightEntryViewModel.delete(): final historyState = ref.read(weightHistoryViewModelProvider); if (historyState is! WeightHistoryLoaded) return false;.
  - Strength: Protects local history consistency and mirrors the existing guard in submit().
  - Tradeoff: None.
  - Confidence: HIGH — identical to submit() pattern in the same class.
  - Blind spot: None significant.
- **Decision**: PENDING

### F3 — Missing Defense-in-Depth Path Validation on Remote Data Source Deletion
- **Severity**: ℹ️ OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: bulk_tempo/lib/features/weight/data/datasources/weight_remote_data_source.dart:143
- **Detail**: deleteWeightEntry removes users/$userId/weight_entries/$dateIso. While repository validates dateIso, the data source does not assert that dateIso is non-empty, leaving open accidental full-node deletion if called directly with a blank key.
- **Fix**: Add assert(dateIso.trim().isNotEmpty && !dateIso.contains('/')) before constructing database reference.
- **Decision**: PENDING

### F4 — ScaffoldMessenger Context Access After Route Pop
- **Severity**: ℹ️ OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Reliability
- **Location**: bulk_tempo/lib/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart:280
- **Detail**: When mutation succeeds, Navigator.of(context).pop() is called before ScaffoldMessenger.of(context).showSnackBar(...), accessing the context of a route that has already started popping.
- **Fix**: Capture final messenger = ScaffoldMessenger.of(context); before calling Navigator.of(context).pop().
- **Decision**: PENDING
