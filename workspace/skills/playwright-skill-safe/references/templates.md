# Task Templates

## 1. Deploy QA mode
- open target URL
- wait for stable load
- capture title
- capture desktop screenshot
- check console/page/request failures
- optionally validate one main CTA and one heading
- run basic accessibility smoke

## 2. Responsive QA mode
- test desktop, tablet, mobile
- capture a screenshot for each
- note layout regressions or missing content

## 3. Form flow
- navigate to page
- fill by role/label/placeholder first
- submit
- wait for success state or validation state
- capture screenshot

## 4. Login flow
- navigate to login
- fill credentials
- submit
- verify redirect or auth-only UI
- capture screenshot

## 5. Visual regression helper
- capture baseline and current screenshot
- report changed artifact paths for manual review

## 6. Link/API smoke
- inspect request failures and HTTP 4xx/5xx responses
- surface broken resources clearly
