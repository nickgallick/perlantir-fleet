# Execution Workflow

## Standard deep QA run
1. Run `scripts/init_qa_run.sh <name>` to create a structured temp workspace
2. Create `/tmp/qa-screenshots/` if not already present
3. Read source code when available and write the product map first
4. Use `scripts/generate_playwright_task.js` to generate a starting Playwright task
5. Refine the generated task for the app's actual flows
6. Execute it with `playwright-skill-safe`
7. Fill in the markdown report and JSON summary

## Fast post-deploy run
1. Initialize run workspace
2. Generate `smoke` or `responsive` task
3. Execute immediately
4. Record trust issues, console issues, and obvious product gaps

## Notes
- These scripts create structure and starting templates, not a full autonomous test system
- Always customize the generated Playwright task to the product being tested
- Always separate product gaps from implementation bugs
