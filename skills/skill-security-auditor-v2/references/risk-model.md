# Risk Model

## PASS

Use PASS when:
- no critical findings exist
- no meaningful high-risk executable behavior exists
- docs/examples are clearly separated from executable logic

## WARN

Use WARN when:
- behavior may be legitimate but deserves review
- cleanup/delete behavior exists but is scope-validated
- runtime/network behavior exists with a plausible safe reason
- dependencies are loose or repo hygiene is weak

## FAIL

Use FAIL when:
- command execution is unsafe
- prompt injection instructions are active, not documentary
- secrets or tokens are present
- exfiltration or credential harvesting appears intentional
- persistence or privilege escalation exists
- destructive filesystem behavior is not tightly bounded

## False-positive controls

Do not flag content merely because a dangerous string appears in:
- markdown tables
- fenced code blocks
- quoted examples
- detection-rule dictionaries
- explicit "Do not" guidance
- threat model documentation

## Preferred reviewer behavior

- Be conservative on installs
- Be practical on obvious documentation examples
- Explain judgment clearly
- Keep the final verdict readable for Nick
