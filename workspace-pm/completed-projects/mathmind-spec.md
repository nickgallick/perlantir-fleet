# MathMind — Premium K-12 Math Practice App — FULL SPEC

Build a mobile iOS app called MathMind — a premium math practice app for ages 3-18 (full K-12). Users select their age/grade, and the app generates endless math problems calibrated to their exact skill level using an adaptive difficulty engine. Points, streaks, and mastery badges keep them engaged. The design is modern, luxury, sophisticated — NOT cartoon-heavy or childish. Think Monument Valley meets Duolingo meets Linear. This is a free app (portfolio/brand piece for Perlantir).

-----

## PLATFORM & TECH STACK

- Expo (React Native) with expo-router for navigation
- Supabase for auth (parent email), database, and progress sync
- Local-first architecture: ALL math problem generation happens on-device. No server needed for core gameplay. Supabase syncs progress when online.
- Rive for interactive character animations (correct/incorrect/idle states) — NOT Lottie (Rive gets ~60 FPS in React Native vs Lottie's ~17 FPS, files 15× smaller)
- expo-haptics for tactile feedback on correct/incorrect
- expo-av for sound effects
- Nativewind (Tailwind for React Native) for styling
- AsyncStorage or expo-secure-store for local progress until sync
- StoreKit 2 ready (even though free now — future-proof for premium tier)

-----

## COPPA COMPLIANCE (CRITICAL — NON-NEGOTIABLE)

This app targets children under 13. COPPA rules (updated June 2025, compliance deadline April 2026, penalties $53,088/violation):

- Parental consent required before creating any persistent account. Collect parent's email, send direct notice of data practices, verify consent before storing child data.
- No third-party analytics SDKs — no Firebase Analytics, no Mixpanel, no Amplitude. Apple's Kids Category rejects apps with these framework binaries. Use ONLY Apple's App Analytics (via App Store Connect) or self-hosted anonymous event counts to your own Supabase backend.
- No advertising SDKs. No IDFA. No App Tracking Transparency framework.
- All in-app purchases behind parental gate (a task adults can complete but children cannot — e.g., "Solve: 47 × 83" or "Type the words shown in this sentence").
- Written data retention policy — no indefinite retention. Delete inactive accounts after 12 months.
- Parental gate on all external links, permission requests, and purchase flows.
- Privacy policy accessible from app and App Store listing, written in plain language.

-----

## SCREENS NEEDED (13 screens)

### 1. Onboarding — Welcome

First launch. Animated logo reveal. "Welcome to MathMind" with subtle particle animation. Two paths: "I'm a Student" (large, primary) and "I'm a Parent" (smaller, secondary). No sign-up required to start playing — account creation is optional and comes later.

### 2. Grade/Age Selection

After tapping "I'm a Student": beautiful scrollable selector showing grade levels grouped into 4 tiers:

- Playroom (Pre-K, K) — warm pastel card with soft illustration
- Explorer (Grades 1-4) — confident blue card
- Academy (Grades 5-8) — deep purple card
- Studio (Grades 9-12) — minimal dark card

Each card shows the grade name and example topics (e.g., "Grade 3: Multiplication, Fractions, Area"). Tapping a grade runs a quick 6-question diagnostic to set initial difficulty.

### 3. Diagnostic Assessment

6 questions per core skill for the selected grade. Binary search: start at grade level, step up if correct, step down if wrong, narrowing by 40% each question. Shows progress dots (not a score). Encouraging language: "Let's see what you know!" Not "Test." At the end: "Great job! I know exactly where to start." Transitions to dashboard.

### 4. Dashboard (Home)

The main hub. Shows:

- Today's streak status (flame icon with day count, or "Start today's streak!" if not yet practiced)
- Daily goal progress ring (e.g., 7/10 problems today — circular progress)
- Current level/XP bar (level number + progress to next level)
- Topic cards — scrollable grid of available math topics for their grade, each showing: topic name, mastery percentage (ring), and a "Practice" button. Topics with mastery < 50% glow subtly to suggest focus.
- Quick Practice button — "Play" button that auto-selects the optimal topic mix (60% weakest unmastered, 25% review, 15% stretch)
- Streak calendar — mini GitHub-style contribution grid showing last 30 days (filled = practiced, empty = missed, today highlighted)

### 5. Practice Session (THE CORE SCREEN)

This is where 90% of time is spent. Full-screen, distraction-free.

Layout:

- Top bar: topic name, problem counter (e.g., "5 of 10"), streak multiplier if active, close (X) button
- Center: the math problem, large and clear. Proper math rendering — fractions stack vertically, exponents are superscript, square roots have proper radical symbols. Use a math rendering library (iosMath equivalent for React Native, or custom components).
- Bottom: answer input area (adapts by age — see input methods below)
- After answering: brief feedback animation (correct = green check + haptic + satisfying sound + XP popup, incorrect = gentle red X + haptic + show correct answer with brief explanation)

Answer input methods by age:

- Ages 3-5 (Pre-K, K): Tap-to-select from 2-3 large visual options (60-80pt touch targets, 64px spacing between buttons). No typing. All instructions via audio.
- Ages 5-7 (K-2): Oversized custom numpad (0-9, backspace, submit). Buttons 56pt minimum. Number display at top.
- Ages 7-10 (3-5): Standard numpad + fraction input template (tap fraction button → stacked numerator/denominator fields) + decimal point.
- Ages 10-13 (6-8): Full equation input with negative numbers, parentheses, exponent button, square root button. Keyboard-style layout.
- Ages 14-18 (9-12): Full expression builder with: fraction template, exponent template, square root template, absolute value bars, π symbol, variables (x, y), inequality symbols (<, >, ≤, ≥), plus standard numpad. For multiple choice on complex problems (proofs, trig identities), show 4 options.

Session flow:

- Default: 10 problems per session (configurable in settings: 5, 10, 15, 20)
- Mix: 60% current skill level, 25% spaced review of mastered material, 15% stretch problems
- After each problem: 1-2 second feedback, then auto-advance
- After session: summary screen with score, XP earned, streak update

### 6. Session Complete / Results

Shows:

- Score: X/10 correct (with celebratory animation if ≥ 8/10)
- XP earned (with level-up animation if applicable)
- Streak updated (flame animation)
- Accuracy by topic (mini breakdown)
- "Play Again" (primary CTA) and "Back to Dashboard" (secondary)
- If they got any wrong: "Review Mistakes" button showing each missed problem with the correct solution and a brief explanation

### 7. Topic Detail

When tapping a topic card from the dashboard:

- Topic name and description
- Mastery ring (percentage)
- Subtopics with individual mastery (e.g., "Multiplication" → "Times tables 1-5", "Times tables 6-10", "Multi-digit × 1-digit")
- "Practice This Topic" button (focused session on just this topic)
- Recent performance: last 10 attempts with correct/incorrect indicators

### 8. Achievements / Badges

Grid of earnable badges, organized by category:

- Streak badges: 3-day, 7-day, 14-day, 30-day, 60-day, 100-day, 365-day
- Mastery badges: per-topic mastery (e.g., "Fraction Master", "Equation Solver", "Geometry Pro")
- Volume badges: 100 problems, 500, 1000, 5000, 10000 solved
- Perfect badges: 10 in a row correct, 20 in a row, 50 in a row
- Grade completion: "Completed Grade 3", etc.

Earned badges are full color with date earned. Unearned are ghosted silhouettes showing requirements. Tapping shows full-screen badge with name, description, date.

### 9. Profile / Stats

- Current grade level (changeable)
- Total problems solved (lifetime)
- Total XP and current level
- Longest streak (all-time)
- Current streak
- Accuracy percentage (overall and per topic)
- Time spent practicing (total hours)
- Joined date
- Grade progress: visual showing mastery across all topics for current grade

### 10. Parent Dashboard (behind parental gate)

Access via parental gate (solve a complex math problem like "What is 47 × 83?"). Shows:

- Child's overall progress summary
- Topics they're struggling with (flagged in red/orange)
- Practice frequency (days per week chart)
- Session duration trends
- Accuracy trends over time
- Recommendations: "Focus on fractions — accuracy dropped to 62% this week"
- Manage account: change grade level, adjust daily goal, set session time limits (15/30/45/60 min)
- Data & privacy controls

### 11. Settings

- Daily goal (5/10/15/20 problems)
- Session length (5/10/15/20 problems per session)
- Sound effects on/off
- Haptic feedback on/off
- Session time limit (15/30/45/60 min, or unlimited) — enforced with gentle "Time for a break!" message
- Notifications (daily reminder at custom time)
- Theme preference (auto based on grade, or manual override)
- Account management (link parent email, sync progress)

### 12. Streak Freeze / Daily Challenge

Before practice each day, show a brief "Daily Challenge" card:

- One special problem slightly above their level
- Bonus XP if solved correctly
- Streak freeze available (earned by completing 5-day streaks, max bank of 2)

### 13. Review Mistakes

Accessible from session results or dashboard. Shows all recently missed problems with:

- The problem as presented
- What the student answered
- The correct answer
- A brief, age-appropriate explanation of HOW to solve it
- "Try Again" button (generates a similar problem to re-attempt)

-----

## DESIGN SYSTEM — 4-TIER AGE-ADAPTIVE THEME

The app MUST look different for a 4-year-old than a 16-year-old. Same app, same components, different skin. The theme auto-selects based on grade but can be manually overridden.

### Tier 1: "Playroom" (Pre-K, Kindergarten — Ages 3-5)

- Background: warm cream (#FFF8F0)
- Cards: white with soft shadows and rounded-2xl (16px) corners
- Primary accent: soft coral (#FF8C6B)
- Secondary accent: gentle gold (#FFD166)
- Tertiary accent: muted teal (#6BC5D2)
- Text: warm dark (#2D2926) — never pure black
- Font: Nunito (rounded, high x-height, single-story 'a' and 'g' — crucial for early readers)
- Body text: 20px minimum. Primary content: 24px+.
- Touch targets: 60-80pt minimum, 64px spacing between interactive elements
- Max interactive elements per screen: 3-4
- Illustrations: warm, rounded, friendly. Minimal — not cluttered. Think Pok Pok Playroom.
- Animations: expressive but brief (0.5-1.5s). Celebrations are joyful. Errors show empathy (character looks curious, not sad).
- Audio: ALL instructions spoken aloud. No text-reading dependency.

### Tier 2: "Explorer" (Grades 1-4 — Ages 6-9)

- Background: clean white-gray (#F8F9FA)
- Cards: white, rounded-xl (12px), subtle shadow
- Primary accent: confident blue (#5B8DEF)
- Secondary accent: warm amber (#FF9F43)
- Success: green (#26DE81)
- Text primary: (#1A1F36)
- Text secondary: (#697386)
- Font: Nunito transitioning to Inter at 18px body
- Touch targets: 48-56pt
- Illustrations: present but less dominant than Tier 1. Icon-forward.
- Animations: snappy, 0.3-1s. Less exuberant than Tier 1.

### Tier 3: "Academy" (Grades 5-8 — Ages 10-13)

- Background: light (#F4F5F7) or dark mode available (#1A1B2E)
- Cards: rounded-lg (8px), subtle border
- Primary accent: deep purple (#6C5CE7)
- Secondary accent: teal (#00CEC9)
- Text primary: (#1A1F36) light / (#E8ECF4) dark
- Font: Inter at 16px body
- Minimal illustration. More data visualization (progress charts, accuracy graphs).
- Dark mode toggle available (first tier to offer it).
- Achievement-focused — badges and stats are more prominent.

### Tier 4: "Studio" (Grades 9-12 — Ages 14-18)

- Background: pure white (#FFFFFF) or dark (#0D1117) — dark is default
- Cards: rounded-md (6px), very subtle border
- Primary accent: modern blue (#3B82F6)
- Secondary accent: emerald (#10B981)
- Text primary: (#1A1F36) light / (#E2E8F0) dark
- Font: Inter or system SF Pro at 15-16px body
- Zero illustrations. Zero characters. This looks like Linear or Notion — clean, analytical, grown-up.
- Dark mode default.
- Data-dense: show accuracy stats, problem-solving speed, topic mastery as clean data visualizations.
- NEVER let a 14-year-old see a cartoon character. They will delete the app instantly.

### Cross-Tier Design Principles

- Luxury = restraint. Premium means the ABSENCE of noise, not decoration. 11 colors max per tier.
- Content IS the interface. The math problem is the hero of every screen.
- Generous whitespace. Let everything breathe.
- Smooth transitions — 200-300ms ease for all state changes.
- Haptic feedback on every answer submission (success = light tap, error = double tap).
- Sound design: subtle, satisfying. Correct = crisp "ding". Wrong = soft "thud". Level up = musical flourish. NOT arcade/game sounds. Think Headspace, not Candy Crush.

-----

## ADAPTIVE DIFFICULTY ENGINE (Modified Elo System)

This is the brain of the app. Every student gets a separate Elo rating per skill domain. Every problem has a difficulty rating on the same scale.

### Data Model

Student.skills[skill_id] = {
  elo_rating: number, // starts at grade baseline - 100
  problems_attempted: number,
  problems_correct: number,
  last_10_results: boolean[], // rolling window
  mastery_level: 'unstarted' | 'learning' | 'practicing' | 'mastered',
  last_practiced: timestamp,
  next_review: timestamp // for spaced repetition
}

### Initial Rating by Grade

Pre-K = 200, K = 400, Grade 1 = 600, Grade 2 = 800, Grade 3 = 1000, Grade 4 = 1200, Grade 5 = 1400, Grade 6 = 1600, Grade 7 = 1800, Grade 8 = 2000, Grade 9 = 2200, Grade 10 = 2400, Grade 11 = 2600, Grade 12 = 2800. Each grade spans ~200 Elo points.

### Target: 85% Success Rate

Research shows the optimal learning error rate is ~15%, yielding 85% success. When rolling 10-problem accuracy > 90%, increase difficulty. When < 70%, step back.

### Problem Selection Algorithm

function selectNextProblem(student):
  skill = weightedSelect(
    60% weakest unmastered skill,
    25% skill due for spaced review,
    15% stretch skill (one level above current)
  )
  target_difficulty = student.skills[skill].elo_rating - 1.5
  return generateProblem(skill, target_difficulty)

### After Each Answer

function processAnswer(student, problem, correct, response_time_ms):
  θ = student.skills[problem.skill_id].elo_rating
  d = problem.difficulty_rating
  P_expected = 1.0 / (1.0 + exp(-(θ - d)))

  // Detect guessing: response faster than 1/3 expected solve time
  if response_time_ms < min_solve_time AND correct:
    outcome = 0.5 // discount as uncertain
  else:
    outcome = correct ? 1.0 : 0.0

  // Adaptive K-factor: higher when less data
  K = max(0.4, 2.0 / (1 + problems_attempted * 0.05))

  // Update rating
  student.skills[skill].elo_rating += K * (outcome - P_expected)

  // Check mastery
  if problems_attempted >= 10 AND last_10_accuracy >= 0.85:
    mastery_level = 'mastered'
    schedule next_review in 1 day (then 3, 7, 14, 30, 60, 120 days)

### Spaced Repetition for Mastered Skills

Review intervals: 1, 3, 7, 14, 30, 60, 120 days. If review accuracy < 80%, reset interval and flag for re-practice. The 25% "review" allocation in problem selection draws from skills due for review.

-----

## MATH PROBLEM GENERATION — FULL CURRICULUM

CRITICAL RULE: Generate every problem BACKWARD from the answer. Pick a clean answer first, then construct the problem. This eliminates ugly decimals, unsolvable problems, and edge cases.

### Pre-K (Ages 3-4) — Elo range 100-300

- Count objects (1-10): show N objects, tap the number
- Number recognition (1-10): match digit to quantity
- Shape identification: circle, square, triangle, rectangle
- Size comparison: bigger/smaller, taller/shorter
- Simple patterns: AB, AAB patterns with colors/shapes
- Sorting: group by color, shape, or size
- ALL visual, no text. Audio instructions. 2-3 answer choices max.

### Kindergarten (Ages 5-6) — Elo range 300-500

- Count sequence: "What comes after [N]?" where N ∈ [1, 90]
- Count objects: N ∈ [1, 20]
- Compare numbers: ∈ [1, 10], greater/less/equal
- Addition: a + b where a, b ∈ [0, 10], sum ≤ 10
- Subtraction: a − b where a ∈ [1, 10], b ∈ [0, a], result ≥ 0
- Decompose numbers: find pairs summing to N ∈ [2, 10]
- Compose teens: 10 + n where n ∈ [1, 9]
- 2D shapes: circle, square, triangle, rectangle, hexagon
- 3D shapes: cube, sphere, cylinder, cone

### Grade 1 (Ages 6-7) — Elo range 500-700

- Addition within 20: a + b, sum ≤ 20
- Subtraction within 20: a − b, result ≥ 0
- Missing addend: a + ? = c (generate c first, pick a < c)
- Add three numbers: a + b + c, each ∈ [1, 9], sum ≤ 20
- Two-digit + one-digit: a ∈ [10, 80], b ∈ [1, 9], no carrying initially
- Compare with symbols: >, <, = for numbers ≤ 100
- Place value: tens and ones in numbers 10-99
- Halves and quarters: partition shapes
- Telling time: hours and half-hours

### Grade 2 (Ages 7-8) — Elo range 700-900

- Addition within 100: include regrouping (ensure ones digits sum > 9)
- Subtraction within 100: include borrowing (ones digit of minuend < subtrahend)
- Add/subtract within 1000: multiples of 10 and 100
- Word problems (two-step): combine add/subtract
- Repeated addition (arrays): r rows × c columns, r,c ∈ [2, 5]
- Even/odd identification: N ∈ [1, 20]
- Place value (3-digit): hundreds, tens, ones in 100-999
- Money: add coins/bills, make change
- Time: analog/digital to nearest 5 minutes

### Grade 3 (Ages 8-9) — Elo range 900-1100

- Multiplication facts: a × b, a,b ∈ [1, 10]
- Division facts: a ÷ b (generate as b × quotient, quotient ∈ [1, 10])
- Missing factor: ? × b = c
- Fractions on number line: a/b where b ∈ {2, 3, 4, 6, 8}, a ∈ [1, b]
- Compare fractions: same numerator or denominator
- Equivalent fractions: a/b = ?/d
- Area of rectangle: l × w, l,w ∈ [1, 12]
- Perimeter of rectangle: side lengths ∈ [1, 20]
- Rounding: to nearest 10 or 100, numbers 1-1000

### Grade 4 (Ages 9-10) — Elo range 1100-1300

- Multi-digit × 1-digit: a ∈ [100, 9999], b ∈ [2, 9]
- Multi-digit × 2-digit: a,b ∈ [10, 99]
- Long division (1-digit divisor): generate as b × q + r, r ∈ [0, b-1]
- Equivalent fractions: base fraction × multiplier n ∈ [2, 6]
- Add/subtract fractions (like denominator): d ∈ {2,3,4,5,6,8,10,12}
- Mixed numbers ↔ improper fractions
- Multiply fraction × whole number
- Decimal notation: fractions with denom 10, 100 → decimals
- Compare decimals to hundredths
- Factors and multiples: find all factors of N ∈ [1, 100]
- Angle measurement: whole degrees, 0-360

### Grade 5 (Ages 10-11) — Elo range 1300-1500

- Add/subtract fractions (unlike denominator): LCD ≤ 60
- Multiply fractions: (a/b) × (c/d), a,c ∈ [1, 9], b,d ∈ [2, 10]
- Divide fractions by whole number
- Decimal add/subtract/multiply/divide (generate backward from clean answer)
- Order of operations (PEMDAS): 2-3 operations with parentheses
- Volume of rectangular prism: l × w × h
- Coordinate plane: first quadrant, integers 0-10
- Powers of 10: multiply/divide by 10, 100, 1000

### Grade 6 (Ages 11-12) — Elo range 1500-1700

- Divide fractions by fractions: (a/b) ÷ (c/d)
- Ratios and unit rates
- Percent of number: p% of N
- One-step equations: x + a = b, ax = b, etc. (generate answer first)
- One-step inequalities
- Evaluate expressions with substitution
- Absolute value
- Integer operations (including negatives)
- Area of triangles, parallelograms, trapezoids
- Surface area of rectangular prisms
- Mean, median, mode, range

### Grade 7 (Ages 12-13) — Elo range 1700-1900

- Two-step equations: px + q = r (generate x first, compute r)
- Two-step inequalities (flip sign when dividing by negative)
- Proportions: cross-multiply, solve for x
- Percent increase/decrease, tax, tip, markup
- Simple interest: I = Prt
- Rational number operations (fractions + decimals + negatives)
- Circle circumference (C = 2πr) and area (A = πr²)
- Complementary/supplementary/vertical angles
- Scale drawings
- Probability: P(event) = favorable/total

### Grade 8 (Ages 13-14) — Elo range 1900-2100

- Multi-step equations: ax + b = cx + d (generate x, pick a ≠ c)
- Systems of equations intro: generate solution point, build two equations through it
- Exponent rules: product, quotient, power, negative exponents
- Scientific notation: convert to/from, operations
- Square roots / cube roots of perfect squares/cubes
- Pythagorean theorem: ALWAYS use known triples (3-4-5, 5-12-13, 8-15-17, 7-24-25) or multiples
- Slope from two points
- Linear functions: y = mx + b, identify slope/intercept
- Function evaluation: f(x) = expression, find f(a)
- Transformations: translate, reflect, rotate, dilate
- Volume of cylinders, cones, spheres

### Grade 9 / Algebra I (Ages 14-15) — Elo range 2100-2300

- Solve linear equations/inequalities including distributive property
- Systems of equations: substitution and elimination (generate solution pair first)
- Factor quadratics: ALWAYS pick roots r₁, r₂ first, compute b = -(r₁+r₂), c = r₁·r₂
- Quadratic formula: ensure discriminant ≥ 0
- Vertex form: y = a(x − h)² + k
- Polynomial operations: add, subtract, multiply (degree ≤ 3)
- Radical expressions: simplify √N
- Arithmetic/geometric sequences: find nth term
- Absolute value equations: |ax + b| = c

### Grade 10 / Geometry (Ages 15-16) — Elo range 2300-2500

- Triangle congruence: identify SSS, SAS, ASA, AAS, HL
- Similar triangles: set up proportions
- Right triangle trig: sin, cos, tan (use special angles 30°, 45°, 60° for exact answers)
- Inverse trig: find angle given ratio
- Distance formula (use points forming Pythagorean triples for clean answers)
- Midpoint formula (use coordinates with even sums)
- Circle equations: (x−h)² + (y−k)² = r²
- Arc length and sector area
- Area of composite shapes
- Volume of prisms and pyramids
- Proof structure: fill-in-the-blank reasoning steps

### Grade 11 / Algebra II (Ages 16-17) — Elo range 2500-2700

- Factor higher polynomials: grouping, sum/difference of cubes
- Polynomial long/synthetic division
- Rational expressions: simplify, add, subtract, multiply, divide
- Logarithms: log_b(x) where x is a power of b (generate answer first)
- Log equations: solve for x
- Exponential equations: b^(f(x)) = c
- Exponential growth/decay word problems
- Complex number operations: (a + bi) arithmetic
- Sequences and series: arithmetic and geometric sums
- Conic sections: identify parabola, circle, ellipse, hyperbola
- Piecewise functions: evaluate

### Grade 12 / Pre-Calculus (Ages 17-18) — Elo range 2700-2900

- Unit circle trig values: sin, cos, tan at 16 standard angles
- Trig identities: verify/simplify
- Trig equations: solve in [0, 2π)
- Inverse trig functions
- Limits: including 0/0 indeterminate forms (construct expressions that factor cleanly)
- Limits at infinity: rational functions
- Vectors: addition, scalar multiplication, dot product, magnitude
- Matrix operations: add, multiply, determinants (2×2 and 3×3)
- Binomial probability: C(n,k) × p^k × (1−p)^(n−k)
- Normal distribution: z-scores
- Infinite series: geometric convergence

-----

## GAMIFICATION SYSTEM

### Points (XP)

- Correct answer: +10 XP (base)
- Streak multiplier: 2x after 5 in a row, 3x after 10 in a row
- Daily challenge bonus: +50 XP
- Speed bonus: +5 XP if answered in < 50% of expected time
- First try bonus: +5 XP (no hints used)

### Levels

- XP thresholds: Level 1 = 0 XP, Level 2 = 100 XP, Level 3 = 250 XP, Level 4 = 500 XP… increasing by ~50% each level
- Level-up animation: satisfying, brief (1.5s), age-appropriate per tier
- Level shown on profile and dashboard

### Streaks

- Track consecutive days practiced (minimum 1 complete session = 1 streak day)
- Celebrations at: 3, 7, 14, 30, 60, 100, 365 days
- Streak Freeze: earned by completing 5-day streaks, max bank of 2. Forgives 1 missed day.
- Daily reminder notification at user's chosen time
- Streak calendar on dashboard (30-day grid)

### Mastery Badges (per skill)

- "Learning" (attempted 5+ problems)
- "Practicing" (50%+ accuracy on last 10)
- "Mastered" (85%+ accuracy on last 10, 10+ attempts)
- Topic mastery badges: "Fraction Master", "Equation Solver", etc.
- Grade completion badge: "Completed Grade [N]" (all topics mastered)

### Session Design

- Session length: 10 problems default (configurable)
- Time limits by age: 15-20 min ages 3-7, 20-30 min ages 8-12, 30-45 min ages 13+
- Break reminder: gentle "Time for a break!" with celebration, not guilt
- NEVER use FOMO, guilt, or pressure language

-----

## DATABASE SCHEMA (Supabase)

users: id, parent_email, created_at, grade_level, theme_override, settings_json

student_profiles: id, user_id, display_name, avatar_id, grade_level, total_xp, current_level, current_streak, longest_streak, last_practice_date, streak_freezes_available

skills: id, grade_level, domain, name, description, difficulty_baseline

student_skills: id, student_id, skill_id, elo_rating, problems_attempted, problems_correct, mastery_level, last_practiced, next_review, last_10_results_json

sessions: id, student_id, started_at, completed_at, problems_count, correct_count, xp_earned, topic_focus

answers: id, session_id, student_id, skill_id, problem_json, student_answer, correct_answer, is_correct, response_time_ms, difficulty_rating, created_at

achievements: id, student_id, badge_type, badge_id, earned_at

daily_activity: id, student_id, date, problems_solved, correct_count, xp_earned, practice_minutes, streak_maintained

RLS: Each student only sees their own data. Parent sees their linked children.

-----

## WHAT MAKES THIS DIFFERENT FROM EVERY OTHER MATH APP

1. Design maturity — the app grows up with the student. A 5-year-old and a 16-year-old have completely different visual experiences. No cartoon bears for teens.
2. Growth-mindset scoring — mistakes are learning opportunities, not punishment. We NEVER subtract points for wrong answers (looking at you, IXL). Getting it wrong just means you get a similar problem next time.
3. Honest engagement — no ads, no deceptive upsells to children, no locked cosmetic items. The math IS the game.
4. Full K-12 in one app — no switching apps at grade 5. Seamless progression from counting apples to solving trig equations.
5. Generate backward from answers — every problem has a clean, satisfying answer. No ugly decimals or unsolvable edge cases.
6. 85% success target — most problems feel achievable, building confidence. Stretch problems create genuine satisfaction when solved.
