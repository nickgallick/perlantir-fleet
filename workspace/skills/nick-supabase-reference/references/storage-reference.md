# Storage Reference

## Design questions
- public or private bucket?
- who can upload?
- who can read?
- who can delete?
- how are files tied to app rows or ownership?

## Rules
- avoid public buckets unless product needs public assets
- keep path conventions intentional
- align storage policy rules with app roles and ownership
- think through orphan cleanup and replacement behavior
