# Multi-Role Planning

When an app has multiple roles, design explicitly for:
- guest
- signed-in user
- manager/operator
- admin/owner

## For each role define
- what they can view
- what they can create
- what they can update
- what they can delete
- which entities are scoped to them

## Warning signs
- buyer flow exists but seller/operator flow does not
- admin role implied but no admin tables or controls exist
- membership table missing for team apps
- policies assume roles that are not represented in schema
