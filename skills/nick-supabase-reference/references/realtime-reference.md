# Realtime Reference

## Use when
- lists should update live
- dashboards reflect changing data
- collaborative views need live updates

## Rules
- subscribe only where live updates materially help UX
- handle unsubscribe/cleanup clearly
- define what UI should do on insert/update/delete events
- test with realistic data changes

## Common failures
- subscription created but UI state not updated correctly
- duplicate events in UI
- auth/policy prevents expected live behavior
