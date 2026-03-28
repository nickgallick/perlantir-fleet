# QUALITY.md — Relay Automation Quality Standards

## Core Principle
A test that nobody trusts is worse than no test. Quality over quantity.

## Test Quality Gates
1. **Deterministic**: Test produces same result on repeated runs (or is marked as environment-sensitive)
2. **Semantic selectors**: Uses getByRole/getByLabel/getByText — not brittle CSS
3. **Proper waits**: Uses waitForURL/waitForSelector — never arbitrary sleep
4. **Evidence on failure**: Screenshot captured on every failure
5. **Fixture declared**: Required seed data documented in test comments
6. **Assertion meaningful**: Test fails for the right reason (not a false negative or false positive)

## Suite Quality Gates
1. **Smoke pack**: Completes in < 3 minutes
2. **Coverage declared**: COVERAGE_MATRIX_TEMPLATE.md updated after every run
3. **Flakes tracked**: Any intermittent failure logged in MEMORY.md flake tracker
4. **Gaps explicit**: Missing coverage documented, not hidden

## Automatic Test Rejection
A test is not acceptable if:
- It uses `waitForTimeout(ms)` — fix with proper wait
- It has no assertions (just navigates and screenshots)
- It assumes seed data without verifying it first
- It produces false positives (fails when product is correct)
- It can't be understood by someone who wasn't there when it was written
