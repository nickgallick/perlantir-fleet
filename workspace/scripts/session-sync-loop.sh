#!/bin/bash
while true; do
  node /data/.openclaw/workspace/scripts/sync-sessions.js >> /tmp/session-sync.log 2>&1
  sleep 300
done
