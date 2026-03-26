---
name: state-machine-patterns
description: State machines for Arena challenges, OUTBOUND leads, and payment flows — TypeScript discriminated unions, transition validation, XState for complex flows.
---

# State Machine Patterns

## State Machines in Our Products

### Arena Challenge
```
draft → open → active → judging → voting → complete → archived
```

### OUTBOUND Lead
```
scraped → enriched → verified → emailed → replied → meeting → won/lost
```

### Stripe Subscription
```
trial → active → past_due → canceled
                     ↓
                  unpaid → canceled
```

---

## TypeScript Implementation

```ts
// Each status carries ONLY its relevant data
type ChallengeState =
  | { status: 'draft'; createdBy: string; title: string }
  | { status: 'open'; title: string; startsAt: Date; maxEntries: number }
  | { status: 'active'; startedAt: Date; entries: string[]; endsAt: Date }
  | { status: 'judging'; submittedAt: Date; entriesCount: number }
  | { status: 'voting'; judgeScores: Score[]; votingEndsAt: Date }
  | { status: 'complete'; results: Result[]; completedAt: Date }
  | { status: 'archived'; archivedAt: Date }

// Exhaustive switch — compiler catches missing cases
function getStatusLabel(state: ChallengeState): string {
  switch (state.status) {
    case 'draft': return 'Draft'
    case 'open': return `Opens ${state.startsAt.toLocaleDateString()}`
    case 'active': return `${state.entries.length} entries — ends ${state.endsAt.toLocaleDateString()}`
    case 'judging': return 'Judging in progress'
    case 'voting': return `Voting ends ${state.votingEndsAt.toLocaleDateString()}`
    case 'complete': return `Winner: ${state.results[0]?.agentName}`
    case 'archived': return 'Archived'
    default: {
      const _exhaustive: never = state
      throw new Error(`Unhandled: ${_exhaustive}`)
    }
  }
}
```

## Transition Validation

```ts
const VALID_TRANSITIONS: Record<string, string[]> = {
  draft: ['open'],
  open: ['active', 'draft'],  // can go back to draft
  active: ['judging'],
  judging: ['voting'],
  voting: ['complete'],
  complete: ['archived'],
  archived: [],  // terminal
}

function validateTransition(current: string, next: string): boolean {
  return VALID_TRANSITIONS[current]?.includes(next) ?? false
}

// Database-level enforcement (concurrent-safe)
async function transitionChallenge(id: string, from: string, to: string) {
  if (!validateTransition(from, to)) {
    throw new Error(`Invalid transition: ${from} → ${to}`)
  }
  
  const { data, error } = await supabase
    .from('challenges')
    .update({ status: to, updated_at: new Date().toISOString() })
    .eq('id', id)
    .eq('status', from) // WHERE clause prevents concurrent invalid transitions
    .select()
    .single()
  
  if (!data) {
    throw new Error(`Transition failed — challenge may have changed state concurrently`)
  }
  return data
}
```

## XState for Complex Flows

```ts
import { createMachine, assign } from 'xstate'

const challengeMachine = createMachine({
  id: 'challenge',
  initial: 'draft',
  context: { entries: [], scores: [] },
  states: {
    draft: {
      on: { PUBLISH: { target: 'open', guard: 'hasTitle' } }
    },
    open: {
      on: {
        START: { target: 'active', guard: 'hasMinEntries' },
        CANCEL: 'draft',
      }
    },
    active: {
      on: { TIMEOUT: 'judging' },
      after: { CHALLENGE_DURATION: 'judging' }, // auto-transition on timer
    },
    judging: {
      invoke: { src: 'judgeAllEntries', onDone: 'voting', onError: 'judging' },
    },
    voting: {
      after: { VOTING_DURATION: 'complete' },
    },
    complete: { type: 'final' },
  },
})
```

**Use XState when:** >5 states, guards (conditions), async services (API calls on transition), parallel states, or visual diagram is valuable for team understanding.

**Use simple discriminated unions when:** <5 states, simple transitions, no async side effects on transitions.

## Sources
- statelyai/xstate documentation
- TypeScript handbook (discriminated unions)
- lichess game state machine

## Changelog
- 2026-03-21: Initial skill — state machine patterns
