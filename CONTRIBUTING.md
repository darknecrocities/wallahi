# Contributing to Wallahi

Thank you for contributing to Wallahi! This document outlines engineering discipline, code hygiene rules, branching guidelines, and verification requirements.

---

## 1. Engineering Principles & Invariants

All contributions must adhere strictly to these core tenets:

1. **500-Line Physical Limit**:
   - No source file may exceed 500 physical lines of code. Files approaching 350 lines must be decomposed into cohesive domain slices.
   - Max 40 lines per function/method.
   - Max 3 nesting levels (use early return guard clauses).
   - Cyclomatic complexity $\le 10$.
2. **Anti-Slop Craftsmanship**:
   - Zero decorative shields or badges.
   - Zero synthetic mock arrays pretending to be storage; use real SQLite schemas and typed models.
   - No obvious restatement comments (`// increment counter`). Comments must explain *why*, mathematical invariants, or hardware edge cases.
   - Accessible UI with semantic labels and high contrast ratios.
3. **Offline-First Resilience**:
   - Scanning, floor plan generation, RF heatmap interpolation, and local project persistence must function with zero network connectivity.
4. **Calibrated Confidence**:
   - Always report uncertainty alongside measurements. Never present arbitrary heuristics as statistical certainties.

---

## 2. Git Workflow & Commit Standards

### 2.1 Branching Strategy
- Main branch: `main` (production-ready).
- Feature branches: `feat/<feature-name>`.
- Bug fixes: `fix/<issue-name>`.
- Refactoring: `refactor/<target>`.

### 2.2 Commit Format
Every commit must be under **1,000 lines diff** and follow Conventional Commits with a mandatory structured multi-line body:

```text
<type>(<scope>): <short imperative summary under 72 chars>

- Context / Why: Motivation and problem statement.
- Key Changes / What:
  * Detailed bullet points of modifications.
  * Exact files touched and architectural adjustments.
- Verification / Impact: Test results, line limit confirmation, and verification receipt.
```

### 2.3 Pull Requests
- All PRs must target `main` from a dedicated branch.
- Include architectural rationale, verification outputs, and link related documentation.

---

## 3. Directory & Module Boundaries

- `packages/room_format`: Pure Dart domain models and JSON schemas. Zero Flutter UI dependencies.
- `packages/geometry`: Pure computational geometry, vector operations, and bounding hulls.
- `packages/wifi_models`: RF propagation models, IDW interpolation, and RTT ranging.
- `packages/sensor_fusion`: Temporal alignment, pose-sample association, and uncertainty grid computation.
- `apps/mobile`: Flutter UI, Riverpod state controllers, and native Android/iOS platform bridges.
- `processing`: Standalone Python research and evaluation scripts.

---

## 4. Verification & Testing

Before submitting changes:
```bash
# Dart analyzer and test suites
dart analyze --fatal-infos
dart test

# Source line limit audit
python3 /Users/arronkianparejas/SkillBuilder/skills/world-class-engineering/scripts/check_source_line_limits.py --show-tiers
```
