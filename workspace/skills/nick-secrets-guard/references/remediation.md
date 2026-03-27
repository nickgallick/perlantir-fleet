# Remediation

If secrets are found:
1. Stop the push
2. Identify whether the secret is still active
3. Rotate the credential
4. Remove it from current files
5. If committed, clean history if necessary
6. Update memory if the incident reveals a repeat-risk pattern

## Reporting rule
Never echo full secret values back to Nick. Show only redacted previews.
