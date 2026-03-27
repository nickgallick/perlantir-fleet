# Query Patterns

## General rules
- keep privileged operations on the server
- keep client queries scoped to what the user can actually access
- design queries around the real UI needs
- think about sort/filter/pagination up front

## Common guidance
- fetch only needed columns when practical
- make empty/error/loading states explicit in UI design
- when joins/related data get complex, think through query shape and UI data dependencies together
- test against realistic seeded data

## Things to watch
- assuming policy failures are query bugs
- over-fetching related data
- not handling null/empty states
- server/client environment mismatch
