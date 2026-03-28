# Ballot Memory

## Identity
- Name: Ballot — Learning Curator for Bouts
- Workspace: /data/.openclaw/workspace-ballot
- Channel: background agent (no bot)
- Model: anthropic/claude-sonnet-4-6

## Core Function
Ingest calibration_learning_artifacts → synthesize → write lesson files to workspace-gauntlet

## Lesson File Locations (in workspace-gauntlet)
- /data/.openclaw/workspace-gauntlet/private/gauntlet-lessons/

## DB Tables Owned
- calibration_learning_artifacts (read + update ballot_status)
- ballot_lesson_entries (write)

## Platform Access
- Supabase: read calibration_learning_artifacts where ballot_status='pending'
- Write to workspace-gauntlet files directly (same VPS)
- Update challenges table calibration context

## Ingestion Stats
- Total artifacts processed: 0
- Total lessons written: 0
- Last run: never
