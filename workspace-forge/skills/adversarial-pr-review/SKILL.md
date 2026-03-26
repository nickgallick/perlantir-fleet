---
name: adversarial-pr-review
description: Adversarial review methodology for code PRs — treats every PR as potentially malicious until proven clean. Use when reviewing any PR from external contributors, dependency updates, refactors of security-sensitive code, PRs claiming "no functional changes", or any code that handles authentication, authorization, secrets, or user data. Goes beyond bug-finding to detect intentional concealment, deceptive commit messages, scattered payloads, environment-gated backdoors, and social engineering in PR descriptions. Complements standard code review (which assumes good faith) with an attacker-mindset review (which assumes hostile intent).
---

# Adversarial PR Review

## Philosophy

Standard code review asks: "Does this code work correctly?"
Adversarial code review asks: "Is this code trying to deceive me?"

**When to use adversarial review**:
- PRs from external/new contributors
- Dependency updates (especially major version bumps)
- Refactors of security infrastructure (auth, crypto, sanitization)
- PRs with vague or minimizing descriptions
- Any PR touching code that handles secrets, credentials, or user data
- PRs with an unusually large number of files changed
- PRs where the description doesn't match the diff complexity

## Phase 1: PR Metadata Analysis (before reading code)

### 1.1 Commit Message / PR Description Audit
- [ ] **Does the description match the actual changes?** Read the description, form expectations, then compare against the diff
- [ ] **"No functional changes" claim**: Verify by diffing behavior — does any code path change? New imports? New function calls? New conditionals?
- [ ] **Minimizing language**: Watch for "just a refactor", "cleanup only", "minor fix", "cosmetic changes" on PRs that actually change behavior
- [ ] **Missing context**: Why was this change made? If the motivation is unclear, ask before reviewing
- [ ] **Urgency pressure**: "Need to merge before EOD", "critical fix, please approve ASAP" — urgency can suppress thorough review

### 1.2 Author Analysis
- [ ] **New contributor**: First PR? Extra scrutiny required
- [ ] **Changed behavior**: Does this author usually submit PRs of this type/scope?
- [ ] **Account age**: For open-source repos, check if GitHub account was recently created
- [ ] **Commit history**: Does the author have a track record of legitimate contributions?

### 1.3 File Scope Analysis
- [ ] **Security-sensitive files changed**: auth/, middleware/, crypto/, config/, .env*, secrets*, package.json, next.config.js
- [ ] **New files added**: Every new file in a "refactor" is suspicious — refactors reorganize, they shouldn't add
- [ ] **Files in unexpected locations**: .vscode/, .github/workflows/, scripts/, postinstall hooks
- [ ] **File count vs. described scope**: "Minor fix" with 15 files changed = mismatch

## Phase 2: Holistic Diff Analysis (before line-by-line review)

### 2.1 Cross-File Data Flow Map
For multi-file PRs, **before reading any file in detail**, map the data flow:
1. Which files import from which other files in this PR?
2. What data moves between the new/changed modules?
3. Does any data flow end at an execution function (`exec`, `eval`, `compile`, `new Function`, `subprocess`)?
4. Are there any circular or unusual dependency patterns?

**This is the step I missed.** Reviewing files individually allows scattered payload attacks to succeed.

### 2.2 Import Analysis
- [ ] List all new imports across all files in the PR
- [ ] Flag execution-adjacent imports: `types`, `importlib`, `marshal`, `subprocess`, `os`, `ctypes`, `child_process`, `vm`
- [ ] Check if each import is actually used in the file that imports it
- [ ] Check for homoglyphs in import statements (run every import name through ASCII check)

### 2.3 Behavioral Diff (not just textual diff)
Ask for each changed function:
- **Before**: What did this function do?
- **After**: What does this function do now?
- **Side effects**: Did any new side effects appear?
- **Return value**: Did the return type/value change?
- **Error handling**: Did error handling get looser (e.g., bare except added)?

## Phase 3: Line-by-Line Adversarial Review

### 3.1 Syntax Anomaly Check
- [ ] **`if __name__ == "__main__"`**: Verify the underscores are correct — `if name ==` is intentionally broken
- [ ] **Semicolons**: In Python, semicolons can hide statements on the same line
- [ ] **Long lines**: Lines > 200 chars may hide statements off-screen
- [ ] **Trailing whitespace**: Unusual trailing whitespace may be Unicode steganography
- [ ] **Comments containing code**: `# exec(payload)` in a comment might be un-commented later
- [ ] **String literals with unusual characters**: Run all string constants through Unicode check

### 3.2 Identifier Integrity Check
- [ ] **Run ASCII check on ALL identifiers**: `all(ord(c) < 128 for c in name)`
- [ ] **Look for visual collisions**: Two identifiers that look the same but differ (e.g., `sanitizer` and `sаnitizer`)
- [ ] **Class/function names vs. behavior**: Does `SecureSanitizer.sanitize()` actually sanitize? Or does it also extract and execute?

### 3.3 Environment Gate Detection
- [ ] Search for `os.getenv`, `os.environ`, `process.env` in all changed files
- [ ] For each: does the environment check gate code execution behavior?
- [ ] **Red flag**: Different code paths for `production` vs other environments that aren't configuration (e.g., log level) but execution (e.g., calling different functions)

### 3.4 Dead Code That Isn't Dead
- [ ] Functions labeled "legacy", "compat", "deprecated" — are they still called?
- [ ] Default parameter values that look inert but enable hidden paths
- [ ] `pass` or no-op function bodies — is there a second function with the real behavior?
- [ ] Test code that "doesn't trigger in CI" — why is it in the PR?

### 3.5 Side-Effect Purity Violations
Functions with these names should be PURE (no side effects):
- `sanitize()`, `validate()`, `clean()`, `filter()`, `normalize()`, `format()`
- `parse()`, `decode()`, `encode()`, `serialize()`, `deserialize()`
- Any function whose name implies transformation of input to output

If any of these functions:
- Make network calls → FLAG
- Write to filesystem → FLAG
- Execute code → BLOCKED
- Import modules dynamically → FLAG
- Access environment variables → FLAG

## Phase 4: Attack Pattern Matching

Cross-reference against known patterns from the `malicious-code-patterns` skill:

- [ ] Any of the 10 Python execution obfuscation families?
- [ ] Any of the JavaScript indirect eval patterns?
- [ ] Unicode steganography? (run scanner)
- [ ] Homoglyph identifiers? (run ASCII check)
- [ ] Payload encoding (base64/hex/rot13/marshal near execution)?
- [ ] Multi-file payload scattering?
- [ ] Environment-gated execution?
- [ ] Horizontal scrolling hidden statements?
- [ ] Decorator/metaclass abuse?

## Phase 5: PR Description Verdict

After completing the code review, verify:

- [ ] Does the PR description accurately describe ALL changes?
- [ ] Are there behavioral changes not mentioned in the description?
- [ ] If the description says "no functional changes" — is that actually true?
- [ ] **If the description is deceptive, that is itself a finding** (P0 for security PRs)

A deceptive PR description is evidence of intent. Legitimate developers may under-describe, but they don't actively misrepresent. "No functional changes" on a PR that introduces `exec()` is not an oversight — it's a lie.

## Phase 6: Corrected Implementation

Per Forge review protocol, every BLOCKED verdict must include:
1. **Complete corrected code** — copy-pasteable replacement for every affected file
2. **Changes Made section** — line-by-line changelog with reasons
3. **What was removed and why**

Never skip this step. The corrected code proves the fix exists and gives the developer a clear path forward.

## Review Tempo

**Do not rush multi-file PRs.** The scattered payload attack depends on the reviewer:
1. Reviewing files in isolation (miss cross-file data flow)
2. Skimming "boilerplate" sections (miss broken __main__ guards, homoglyphs)
3. Trusting the PR description (miss deceptive claims)
4. Stopping after finding the "main" issue (miss secondary payloads)

Budget at minimum:
- Single-file PR: 5 minutes adversarial review
- Multi-file PR (2-5 files): 15 minutes — map cross-file flow FIRST
- Large PR (5+ files): 30 minutes — may need multiple passes

## Integration with Forge Review Protocol

This skill adds **Phase 10** to the existing 9-phase review:

**Phase 10: Adversarial Analysis**
After standard review phases 1-9, put on the adversary hat:
1. Re-read every "cleanup" or "refactor" file assuming hostile intent
2. Map all cross-file data flows to execution sinks
3. Verify PR description honesty
4. Check for environment gates
5. Verify identifier integrity (homoglyphs)
6. Check for syntax anomalies
7. Confirm corrected implementation is provided if BLOCKED

## References

For specific code patterns to detect, see the `malicious-code-patterns` skill.
For Unicode-specific detection, see the `unicode-steganography-detection` skill.
