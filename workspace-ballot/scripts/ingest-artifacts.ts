/**
 * Ballot Artifact Ingestion Script
 * Run: npx ts-node scripts/ingest-artifacts.ts
 *
 * Fetches pending calibration_learning_artifacts from DB,
 * synthesizes lessons, writes to workspace-gauntlet lesson files,
 * updates ballot_lesson_entries.
 */

import { createClient } from '@supabase/supabase-js'
import * as fs from 'fs'
import * as path from 'path'
import * as crypto from 'crypto'

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!
const GAUNTLET_LESSONS_DIR = '/data/.openclaw/workspace-gauntlet/private/gauntlet-lessons'
const ALERTS_LOG = '/data/.openclaw/workspace-ballot/alerts.log'
const BALLOT_DIR = '/data/.openclaw/workspace-ballot'

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY')
  process.exit(1)
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

// ─── Types ────────────────────────────────────────────────────────────────────

interface LearningArtifact {
  id: string
  challenge_id: string
  bundle_id: string | null
  family: string
  format: string
  weight_class: string
  verdict: string
  cdi_score: number | null
  same_model_clustering_risk: string | null
  borderline_triggers: string[]
  separation_score: number | null
  tier_spread: number | null
  what_worked: string[]
  what_failed: string[]
  what_improved_discrimination: string[]
  what_caused_compression: string[]
  what_improved_same_model_spread: string[]
  what_reduced_same_model_spread: string[]
  what_triggered_audit: string[]
  mutation_lessons: Array<{ type: string; helped: boolean; reason: string }>
  contamination_patterns: string[]
  human_reviewer_fixes: string[]
  key_lesson: string | null
  key_anti_lesson: string | null
  recommended_future_action: string | null
  ballot_status: string
  created_at: string
}

interface LessonEntry {
  artifact_id: string
  category: string
  family: string | null
  subcategory: string | null
  lesson: string
  confidence: string
  observation_count: number
  first_seen_at: string
  last_seen_at: string
  lesson_hash: string
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function hashLesson(text: string): string {
  const normalized = text.trim().toLowerCase().replace(/\s+/g, ' ')
  return crypto.createHash('sha256').update(normalized).digest('hex')
}

function appendToLessonFile(filePath: string, content: string): void {
  fs.mkdirSync(path.dirname(filePath), { recursive: true })
  fs.appendFileSync(filePath, content + '\n')
}

function logAlert(message: string): void {
  const ts = new Date().toISOString()
  const line = `[${ts}] ALERT: ${message}\n`
  fs.appendFileSync(ALERTS_LOG, line)
  console.warn(line.trim())
}

function confidenceFromCount(count: number): string {
  if (count >= 5) return 'high'
  if (count >= 3) return 'medium'
  return 'low'
}

function familyFileSlug(family: string): string {
  return family.toLowerCase().replace(/[^a-z0-9]/g, '-').replace(/-+/g, '-')
}

// ─── Lesson synthesis ─────────────────────────────────────────────────────────

function synthesizeLessons(artifact: LearningArtifact): LessonEntry[] {
  const entries: LessonEntry[] = []
  const ts = new Date().toISOString()

  const addLesson = (
    lesson: string,
    category: string,
    subcategory: string | null = null,
    family: string | null = artifact.family
  ) => {
    if (!lesson || lesson.trim() === '') return
    const hash = hashLesson(lesson)
    entries.push({
      artifact_id: artifact.id,
      category,
      family,
      subcategory,
      lesson: lesson.trim(),
      confidence: 'low',
      observation_count: 1,
      first_seen_at: ts,
      last_seen_at: ts,
      lesson_hash: hash,
    })
  }

  // Positive lessons
  for (const item of artifact.what_worked ?? []) {
    addLesson(item, 'positive', 'discrimination')
  }
  for (const item of artifact.what_improved_discrimination ?? []) {
    addLesson(item, 'positive', 'discrimination')
  }
  for (const item of artifact.what_improved_same_model_spread ?? []) {
    addLesson(item, 'positive', 'same_model_spread')
  }
  if (artifact.key_lesson) {
    addLesson(artifact.key_lesson, 'positive', 'key_lesson')
  }

  // Negative lessons
  for (const item of artifact.what_failed ?? []) {
    addLesson(item, 'negative', 'discrimination')
  }
  for (const item of artifact.what_caused_compression ?? []) {
    addLesson(item, 'negative', 'compression')
  }
  for (const item of artifact.what_reduced_same_model_spread ?? []) {
    addLesson(item, 'negative', 'same_model_spread')
  }
  for (const item of artifact.contamination_patterns ?? []) {
    addLesson(item, 'negative', 'contamination')
  }
  if (artifact.key_anti_lesson) {
    addLesson(artifact.key_anti_lesson, 'negative', 'anti_lesson')
  }

  // Mutation lessons
  for (const ml of artifact.mutation_lessons ?? []) {
    if (ml.reason) {
      const text = `[${ml.type}] ${ml.helped ? 'HELPED' : 'DID NOT HELP'}: ${ml.reason}`
      addLesson(text, 'mutation', ml.type)
    }
  }

  // Audit triggers → calibration_system
  for (const item of artifact.what_triggered_audit ?? []) {
    addLesson(item, 'calibration_system', 'audit_trigger', null) // cross-family
  }

  // Human reviewer fixes → negative (if any)
  for (const fix of artifact.human_reviewer_fixes ?? []) {
    if (typeof fix === 'string') {
      addLesson(`Forge review required fix: ${fix}`, 'negative', 'reviewer_fix')
    }
  }

  return entries
}

// ─── Markdown write ───────────────────────────────────────────────────────────

function writeLessonToMarkdown(
  lesson: LessonEntry,
  artifact: LearningArtifact,
  existingCount: number
): void {
  const dateStr = new Date().toISOString().slice(0, 10)
  const count = existingCount + 1
  const confidence = confidenceFromCount(count)

  const block = [
    `## ${dateStr} · artifact:${artifact.id.slice(0, 8)} · confidence:${confidence}`,
    `**Lesson:** ${lesson.lesson}`,
    `**Source challenge:** ${artifact.challenge_id.slice(0, 8)} (${artifact.family}, ${artifact.format}, ${artifact.weight_class})`,
    `**Verdict:** ${artifact.verdict}`,
    `**Observed:** ${count} time${count !== 1 ? 's' : ''}`,
    `**Subcategory:** ${lesson.subcategory ?? 'general'}`,
    '',
  ].join('\n')

  let filePath: string

  switch (lesson.category) {
    case 'positive':
      filePath = path.join(GAUNTLET_LESSONS_DIR, 'positive-lessons.md')
      break
    case 'negative':
      filePath = path.join(GAUNTLET_LESSONS_DIR, 'negative-lessons.md')
      break
    case 'mutation':
      filePath = path.join(GAUNTLET_LESSONS_DIR, 'mutation-lessons.md')
      break
    case 'calibration_system':
      filePath = path.join(GAUNTLET_LESSONS_DIR, 'calibration-system-lessons.md')
      break
    case 'family_health':
      filePath = path.join(GAUNTLET_LESSONS_DIR, 'family-health.md')
      break
    default:
      filePath = path.join(GAUNTLET_LESSONS_DIR, 'calibration-system-lessons.md')
  }

  appendToLessonFile(filePath, block)

  // Also write to family-specific file
  if (lesson.family) {
    const slug = familyFileSlug(lesson.family)
    const familyFile = path.join(GAUNTLET_LESSONS_DIR, 'families', `${slug}.md`)
    appendToLessonFile(familyFile, block)
  }
}

// ─── Upsert ballot_lesson_entries ─────────────────────────────────────────────

async function upsertLessonEntry(entry: LessonEntry): Promise<number> {
  // Check if hash already exists
  const { data: existing } = await supabase
    .from('ballot_lesson_entries')
    .select('id, observation_count')
    .eq('lesson_hash', entry.lesson_hash)
    .single()

  if (existing) {
    const newCount = existing.observation_count + 1
    await supabase
      .from('ballot_lesson_entries')
      .update({
        observation_count: newCount,
        confidence: confidenceFromCount(newCount),
        last_seen_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', existing.id)
    return newCount
  } else {
    await supabase.from('ballot_lesson_entries').insert({
      ...entry,
      confidence: 'low',
      observation_count: 1,
    })
    return 1
  }
}

// ─── Alert checks ─────────────────────────────────────────────────────────────

async function checkAlerts(artifact: LearningArtifact): Promise<void> {
  // Contamination alert
  if ((artifact.contamination_patterns ?? []).length > 0) {
    logAlert(
      `CONTAMINATION DETECTED in artifact ${artifact.id} (challenge ${artifact.challenge_id}, family ${artifact.family}): ${artifact.contamination_patterns.join('; ')}`
    )
  }

  // Family collapse: 3 consecutive fails in same family
  const { data: recentFails } = await supabase
    .from('calibration_learning_artifacts')
    .select('id, verdict, created_at')
    .eq('family', artifact.family)
    .eq('verdict', 'fail')
    .eq('ballot_status', 'ingested')
    .order('created_at', { ascending: false })
    .limit(3)

  if (recentFails && recentFails.length >= 3) {
    logAlert(
      `FAMILY COLLAPSE WARNING: family "${artifact.family}" has 3+ consecutive calibration failures. Last artifact: ${artifact.id}`
    )
  }

  // CDI declining trend — last 3 artifacts in family, check cdi_score
  const { data: recentCDI } = await supabase
    .from('calibration_learning_artifacts')
    .select('cdi_score, created_at')
    .eq('family', artifact.family)
    .not('cdi_score', 'is', null)
    .order('created_at', { ascending: false })
    .limit(3)

  if (recentCDI && recentCDI.length === 3) {
    const scores = recentCDI.map(r => Number(r.cdi_score))
    if (scores[0] < scores[1] && scores[1] < scores[2]) {
      logAlert(
        `CDI DECLINING TREND in family "${artifact.family}": scores ${scores.join(' → ')} (newest first). Possible quality decay.`
      )
    }
  }
}

// ─── Index update ─────────────────────────────────────────────────────────────

async function updateIndexJson(processedCount: number, lessonCount: number): Promise<void> {
  const indexPath = path.join(GAUNTLET_LESSONS_DIR, 'index.json')

  let index: Record<string, unknown> = {}
  try {
    index = JSON.parse(fs.readFileSync(indexPath, 'utf-8'))
  } catch {
    // Fresh index
  }

  // Count lessons by category from DB
  const { data: categoryCounts } = await supabase
    .from('ballot_lesson_entries')
    .select('category')

  const byCategory: Record<string, number> = {
    positive: 0, negative: 0, mutation: 0, family_health: 0, calibration_system: 0,
  }
  for (const row of categoryCounts ?? []) {
    if (byCategory[row.category] !== undefined) byCategory[row.category]++
    else byCategory[row.category] = 1
  }

  // Family counts
  const { data: familyCounts } = await supabase
    .from('ballot_lesson_entries')
    .select('family')
    .not('family', 'is', null)

  const byFamily: Record<string, number> = {
    blacksite_debug: 0, fog_of_war: 0, false_summit: 0,
    recovery_spiral: 0, toolchain_betrayal: 0, abyss_protocol: 0,
  }
  for (const row of familyCounts ?? []) {
    if (row.family) {
      const slug = familyFileSlug(row.family).replace(/-/g, '_')
      byFamily[slug] = (byFamily[slug] ?? 0) + 1
    }
  }

  // High confidence lessons
  const { data: highConf } = await supabase
    .from('ballot_lesson_entries')
    .select('lesson, category, family, observation_count')
    .eq('confidence', 'high')
    .order('observation_count', { ascending: false })
    .limit(10)

  const updated = {
    ...index,
    last_updated: new Date().toISOString(),
    total_lessons: (categoryCounts ?? []).length,
    by_category: byCategory,
    by_family: byFamily,
    high_confidence_lessons: (highConf ?? []).map(h => ({
      lesson: h.lesson,
      category: h.category,
      family: h.family,
      observed: h.observation_count,
    })),
    active_alerts: fs.existsSync(ALERTS_LOG)
      ? fs.readFileSync(ALERTS_LOG, 'utf-8').trim().split('\n').slice(-5)
      : [],
  }

  fs.writeFileSync(indexPath, JSON.stringify(updated, null, 2))
}

// ─── Main ingestion loop ──────────────────────────────────────────────────────

async function ingestArtifacts(): Promise<void> {
  console.log('[Ballot] Starting artifact ingestion...')

  const { data: artifacts, error } = await supabase
    .from('calibration_learning_artifacts')
    .select('*')
    .eq('ballot_status', 'pending')
    .order('created_at', { ascending: true })

  if (error) {
    console.error('[Ballot] Failed to fetch artifacts:', error.message)
    process.exit(1)
  }

  if (!artifacts || artifacts.length === 0) {
    console.log('[Ballot] No pending artifacts. Nothing to do.')
    return
  }

  console.log(`[Ballot] Found ${artifacts.length} pending artifact(s).`)

  let processedCount = 0
  let totalLessons = 0

  for (const artifact of artifacts as LearningArtifact[]) {
    // Mark as processing
    await supabase
      .from('calibration_learning_artifacts')
      .update({ ballot_status: 'processing' })
      .eq('id', artifact.id)

    try {
      const lessons = synthesizeLessons(artifact)
      console.log(`[Ballot] Artifact ${artifact.id.slice(0, 8)}: synthesized ${lessons.length} lessons`)

      for (const lesson of lessons) {
        try {
          const count = await upsertLessonEntry(lesson)
          writeLessonToMarkdown(lesson, artifact, count - 1)
          totalLessons++
        } catch (lessonErr) {
          console.error(`[Ballot] Failed to write lesson: ${lessonErr}`)
        }
      }

      await checkAlerts(artifact)

      await supabase
        .from('calibration_learning_artifacts')
        .update({
          ballot_status: 'ingested',
          ballot_ingested_at: new Date().toISOString(),
          ballot_error: null,
        })
        .eq('id', artifact.id)

      processedCount++
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err)
      console.error(`[Ballot] Error processing artifact ${artifact.id}: ${msg}`)
      await supabase
        .from('calibration_learning_artifacts')
        .update({ ballot_status: 'error', ballot_error: msg })
        .eq('id', artifact.id)
    }
  }

  await updateIndexJson(processedCount, totalLessons)

  // Update MEMORY.md stats
  const memPath = path.join(BALLOT_DIR, 'MEMORY.md')
  if (fs.existsSync(memPath)) {
    let mem = fs.readFileSync(memPath, 'utf-8')
    mem = mem
      .replace(/Total artifacts processed: \d+/, `Total artifacts processed: (see DB)`)
      .replace(/Total lessons written: \d+/, `Total lessons written: (see DB)`)
      .replace(/Last run: .+/, `Last run: ${new Date().toISOString()}`)
    fs.writeFileSync(memPath, mem)
  }

  console.log(`[Ballot] Done. Processed: ${processedCount}, Lessons written: ${totalLessons}`)
}

ingestArtifacts().catch(err => {
  console.error('[Ballot] Fatal error:', err)
  process.exit(1)
})
