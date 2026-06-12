# BT-01 — Functional Requirements
**Module:** BT-01 | **Version:** 2.0 (post design decisions)

---

## 1. Authentication & Account Management

- Parent registers and logs in using Google Sign-In via Firebase Auth
- No email/password login — Google Sign-In is the sole auth method for V1
- Sessions persist across app restarts; parent does not re-authenticate on every launch
- The app uses a **shared device model** — one physical device is used by both parent and child
- On launch, the app opens in **child mode** by default
- A visible "Switch to Parent Mode" button is available on the child home screen
- Switching to parent mode requires biometric authentication (fingerprint). If the device does not support biometrics, a PIN set during onboarding is used as fallback
- There is no automatic timeout back to child mode — the parent manually switches back
- Account recovery uses Firebase's standard Google Sign-In recovery (no separate password reset)

---

## 2. Onboarding & First-Time Setup

- On first launch after registration, the parent creates a child profile (name, age)
- After the child profile is created, the child selects a bear mascot outfit from the available starter outfits — this creates personal ownership over their profile
- A brief tutorial walkthrough is shown to the child before their first lesson
- Parent consent for data collection (PDPA) is obtained explicitly during registration before any child data is stored
- Biometric/PIN for parent mode switch is configured during onboarding

---

## 3. Subject & Chapter Navigation

- Five subjects are available: Bahasa Melayu, English, Mandarin (华语), Mathematics, Science
- Within each subject, content is organised by chapter, mirroring the KSSR Standard 1 textbook chapter structure
- Within each chapter, content is organised into individual levels
- Chapter and level progression is strictly linear — a level must be completed before the next unlocks
- Locked levels are visible to the child (greyed out with a lock icon) but cannot be tapped
- The child navigates freely between subjects from the home screen
- Each subject displays a progress bar showing overall completion percentage

---

## 4. Level & Lesson Structure

The app is **practice-only**. There is no teaching phase. The child is expected to have learned material from their KSSR textbook at school. The app reinforces and tests that learning.

### Two stage types per chapter:

**Basic stages**
- Fixed question bank per level
- 10 questions per session
- One-time star claim per tier (see Section 6 for thresholds)
- Child can replay the level but cannot re-earn a star tier already claimed

**Chapter summary stage** (one per chapter, at the end)
- 15 questions per session drawn randomly from the chapter's full question bank
- Repeatable daily
- Escalating score threshold for star earning (see Section 6)
- One star earnable per session (daily cap)

### Session flow:
Question 1 → feedback → Question 2 → … → Question N → Completion screen (score + stars awarded + mascot celebration)

After each answer, feedback is shown for approximately **1.5 seconds** before the Next button becomes active. This prevents accidental rapid tapping.

### Stroke tracing attempts:
The child gets up to **3 attempts** per character before the correct stroke order is shown automatically. Each failed attempt still flags the question in the wrong-answer bank.

### Mid-session exit:
If the child exits the app mid-level (fully closes it), the session is lost and the child restarts from Question 1. A warning dialog is shown on exit: "Your progress will be lost. Are you sure?"

### Counting-up timer:
A counting-up timer is visible to the child during every level session. It does not affect scoring or stars. The elapsed time per session is stored and shown to the parent on the dashboard.

---

## 5. Question Engine & Interaction Types

### V1 question types:
- **MCQ tap** — child taps one of 4 answer options (primary type)
- **Drag-and-drop** — child drags an answer tile to a target zone
- **Audio-listen-and-select** — a TTS audio clip plays; child selects the matching answer
- **Mandarin stroke tracing** — child traces a Chinese character on a canvas in correct stroke order (Mandarin subject only; limited to simple Standard 1 characters)

### Feedback rules:
- After each answer: immediate visual feedback (correct = green highlight + mascot cheer animation; incorrect = red highlight + mascot consoling animation)
- Correct answer is always shown after an incorrect attempt
- **Stars are never deducted for wrong answers** — positive reinforcement only
- Wrong answers are flagged to the `wrongAnswerBank` **immediately on the feedback screen** — not at session end. This ensures partial sessions still produce review data.

### Mandarin content staging:
- Sprint 2 Mandarin questions are **recognition/MCQ only** — stroke tracing is a Sprint 3 feature
- Stroke order data for characters is added to question documents in Sprint 3 alongside the tracing implementation

### Audio:
- TTS service used for all audio in V1
- Audio plays automatically for audio-type questions; manual play button available on all questions
- Developer 3 manages the TTS pipeline alongside question bank creation

### Mathematics:
- Questions are parametrically generated (random number pairs within defined ranges per chapter)
- No manual question bank needed for Maths
- Generation rules (operation type, number ranges) are configured per chapter in the admin CMS

---

## 6. Scoring & Star Earning Logic

Stars are the app's primary currency. Two balances are tracked per child:
- **Lifetime earned** — cumulative total, never decreases, used as an achievement metric
- **Available to spend** — current spendable balance, decreases when rewards are redeemed

### Basic stage thresholds (one-time claim per tier):

| Score | Stars earned |
|---|---|
| < 50% | 0 stars |
| ≥ 50% | 1 star |
| ≥ 80% | 2 stars |
| 100% | 3 stars |

Each tier is a one-time claim. A child can replay to claim higher tiers. Once all 3 tiers are claimed, replaying earns no further stars.

### Chapter summary stage thresholds (escalating, permanent):

| Child's history on this stage | Threshold to earn 1 star |
|---|---|
| Has never scored ≥ 80% | 80% |
| Has achieved 80% at least once | 90% |
| Has achieved 90% at least once | 100% (permanent ceiling) |

- Threshold only increases when the child achieves the current threshold
- Threshold never resets — permanent global counter per child per stage
- Once at 100%, child earns 1 star per day for every 100% score (indefinitely)
- Daily cap: 1 star per day per chapter summary stage

### Wrong-answer review accumulation:
- Every review question answered (correctly or not) increments a global counter
- Every 20 review questions answered = 1 star; counter resets to 0
- Cross-subject: questions from any subject count toward the same counter

---

## 7. Wrong-Answer Review System

The review system surfaces questions the child has previously answered incorrectly. This is not a Ebbinghaus time-based scheduler — it is a wrong-answer recovery system.

### Hybrid implementation (Option C):

**Dedicated section — Bear's Memory Challenge:**
- Appears on the child's home screen when pending review questions exist
- Child taps in deliberately
- Sessions draw **10–20 questions** from the child's personal wrong-answer bank (cross-subject)
- After a question is answered in a review session (correctly or not), it is removed or deprioritised in the `wrongAnswerBank` — it will appear less frequently in future review sessions
- Star earning via the 20-question accumulation counter

**Silent injection:**
- Wrong-answer questions are quietly mixed into regular level sessions
- The child does not know these are review questions
- No separate star logic for injected questions — normal level scoring applies

---

## 8. Cosmetics, Outfits & Quest System

One bear character with interchangeable outfits. Outfits are unlocked by completing quest missions.

### Quest structure:
- Each outfit has one quest condition defined in the admin CMS
- Quest progress is tracked per child (e.g. "2/3 Maths 100% quizzes completed")
- Locked outfits shown as **silhouettes** to hook curiosity without revealing the design
- Completing a quest permanently unlocks the outfit

### Quests tab:
- All quests visible with progress bars — accessible from the **bottom navigation bar**
- Locked silhouettes with quest condition shown
- Unlocked outfits shown in full

### Outfit management:
- Child selects active outfit from Quests or Outfits tab
- Active outfit displayed across all in-app mascot surfaces

---

## 9. Reward Management & Redemption Flow

### Parent creates rewards:
- Name, optional emoji, star cost
- Suggested star cost ranges shown as a guide
- Editable and deletable at any time

### Redemption flow:
1. Child taps "Claim" on a reward they can afford
2. Confirmation dialog shown
3. Stars enter **pending state** (not yet deducted)
4. Parent receives push notification
5. Parent delivers reward in real life then taps "Approve" → stars deducted, child sees celebration
   OR parent taps "Reject" → stars return to available balance, child notified
6. Claim expires after **7 days** with no parent action → stars automatically returned

### Rules:
- Child cannot cancel a pending claim — only the parent can reject
- Stars deducted only after parent approval, not on claim
- Child cannot make a second claim on the same reward while a pending claim for that reward exists
- Deleting a reward that has a pending claim does not affect the pending claim — it runs to completion independently
- No hard limit on the number of rewards a parent can create in V1

---

## 10. Parent Progress Dashboard

- Accessible via biometric/PIN parent mode switch
- Per child: lifetime stars, available stars, lessons completed, streak (calendar day, 12am–12am), daily goal progress, per-subject progress %
- Level completion time: per-session elapsed time, also shown as daily learning total
- Real-time data updates

---

## 11. Daily Goals & Notifications

- Parent sets daily goal per child: number of lessons or minutes
- Child sees goal progress on home screen — **goal progress indicator is not shown if no goal has been set**
- FCM push notifications for: goal completed, chapter completed, reward claim pending, streak at risk
- Goal completion notification is sent **once per calendar day only** — not on every session if the goal was already completed earlier that day
- Streak-at-risk notification fires at a **fixed time of 8pm** daily via Cloud Scheduler (user-configurable time is an icebox item)
- Parent can configure notification preferences (Sprint 4)
- Online-only: no offline mode. No-internet screen shown when connection is unavailable

---

## 12. Multi-Child Management

- Multiple child profiles under one parent account (Sprint 3)
- Each profile independent
- Profile switcher in parent dashboard
- Co-parent (two accounts, one child) is post-MVP icebox

---

## 13. Revision Stage

- Unlocks after completing all chapters in any one subject
- Mixes all questions from that subject into one pool
- 15 questions per session, randomised — the **same question can appear across different sessions**
- Same escalating threshold as chapter summary (80% → 90% → 100%)
- Same daily star cap (1 star per day)
- One revision stage per subject — it appears at the **bottom of the subject's chapter list** when unlocked
- Each revision stage has a **dedicated `levelID`** in `levelProgress` to track its threshold and daily star date independently

---

## 14. Content Management — Internal Admin CMS

- Internal web tool for Developer 3 to manage question banks without code changes
- Create/edit questions: subject, chapter, level, type, image, audio, answer options, correct answer
- Maths parametric rules configured per chapter (not individual questions)
- Quest conditions per outfit configured here
- Content versioned to avoid breaking active sessions

---

## 15. Settings, Privacy & Compliance

- Sound on/off (accessible from **both child and parent mode** — child can toggle sound, parent can toggle it in settings)
- Sound toggle state is persisted **locally** (SharedPreferences) — not stored in Firestore
- Notification preferences (parent mode, Sprint 4)
- Account details update (parent mode)
- PDPA consent during registration; policy visible in settings
- Full account + data deletion available — cascade deletes all Firestore subcollections (attempts, starTransactions, wrongAnswerBank, levelProgress, questProgress, rewardClaims, rewards)
- App is online-only — no offline mode
- Account recovery uses Google's native recovery — no custom password reset flow; a "Having trouble signing in?" link on the login screen opens Google's account recovery page
- The **first level of each subject's first chapter is unlocked by default** — no prerequisite needed
- Tutorial shown once on first launch only; completion state stored **locally** (SharedPreferences)

---

## 16. BearAI — AI Parent Consultation

BearAI is an AI-powered consultation feature accessible from the parent dashboard. It is the primary AI integration in the app, giving parents a personal assistant that understands their child's in-app activity and provides actionable guidance.

### Access
- BearAI is available as a dedicated tab within the parent dashboard (parent mode only)
- Accessible immediately after switching to parent mode — no separate login

### AI Insight Card
- At the top of the BearAI tab, a dynamically generated insight card summarises the child's recent activity in 2–3 sentences
- Insight covers: strongest subject, weakest subject, session time patterns, streak status
- Updated after each session completion

### Chat Interface
- Parent can type free-form questions or tap quick-reply suggestion chips
- Suggested chips shown by default: "How is [child] doing this week?", "Suggest a reward amount", "What daily goal should I set?", "Which subject needs more focus?"
- BearAI responds with personalised answers grounded in the child's actual Firestore data (stars, session history, subject progress, streak, wrong-answer bank)
- Conversation history is stored per parent session; it does not persist across app restarts in V1

### Topics BearAI can address
- Weekly and monthly progress summaries
- Subject-specific performance analysis and weak area identification
- Reward recommendations (name, star cost) calibrated to the child's current balance and earning pace
- Daily goal recommendations based on historical session frequency
- Streak status and at-risk warnings with suggested actions
- Learning pattern observations (e.g. child rushes Mandarin, spends longer on Maths)

### Implementation approach
- BearAI calls the Gemini API (Google) with a structured context payload containing the child's Firestore data
- The system prompt instructs the model to act as a child learning consultant for a Malaysian Standard 1 parent
- Child data sent as context: subject progress %, session history (last 14 days), star balance, streak, daily goal, wrong-answer bank summary by subject
- Responses are displayed in the chat UI
- A brief disclaimer is shown below the input: "BearAI uses [child name]'s in-app activity data only."

### Chapter Analytics — parent dashboard
- A "Chapter Insights" section appears on the parent dashboard below the subject progress bars
- V1 scope: Bahasa Melayu only
- Each BM chapter is shown with a star rating (filled/unfilled) and a strength badge:
  - **Strong** (≥ 80% of max stars earned): green badge
  - **Average** (50–79%): yellow badge
  - **Needs Work** (< 50%): red badge
- A note below the chapter list reads: "Bear's Den questions are personalised to strengthen weaker chapters"
- This analytics view is **parent-facing only** — children never see their chapter strength breakdown

---

## 17. Bear's Den — AI Adaptive Cross-Chapter Challenge

Bear's Den is a secret cross-chapter mixed-question session that unlocks inside a subject after the child completes a defined chapter range. The AI quietly weights questions toward the child's weaker chapters — the child experiences it as a fun challenge, not a remedial session.

### Placement and discovery
- Bear's Den does **not** appear on the home screen
- It lives **inside a subject's chapter/level map**, positioned after the chapter range it covers
- Before unlocking: shown as a mysterious locked tile with a hidden label ("???") and a subtle golden glow — visually distinct from regular locked levels, hinting something special is there
- After unlocking: reveals itself as "Bear's Den" with an amber bear-in-cave icon and a "Chapter Mix" badge
- The unlock moment is treated as a discovery — no advance announcement

### Unlock condition
- V1 MVP: BM only, one unlock tier
- Unlocks after the child completes all basic levels in Chapters 1–3 of Bahasa Melayu
- "Completing" a chapter = all basic levels in that chapter finished (at least 1 star claimed)
- Summary stage completion is not required for unlock
- The chapter range and unlock condition are configured in Firestore (not hardcoded) to allow expansion

### Session mechanics
- 10 questions drawn from the completed chapters (Chapters 1–3 for the first tier)
- AI weighting: Needs Work chapters → 50% of questions; Average → 30%; Strong → 20%
- If a tier has no chapters, redistribute weight proportionally to available tiers
- Questions are drawn randomly within the weight constraints and shuffled
- Same MCQ interaction and mascot feedback as regular levels
- A small chapter tag appears below each question (e.g. "Chapter 2 — Keluarga") — informational, subtle
- **No "AI Generated" badge, no analytics shown to the child** — the AI selection is invisible

### Stars
- ≥ 70% score = 1 star
- 100% score = 2 stars
- Daily cap: maximum 2 stars per calendar day per Bear's Den unlock (12am–12am, same logic as summary stage)
- A `bearsDenStarDate` field on the child document enforces the daily cap
- Wrong answers are flagged to the wrong-answer bank as normal
- Completion screen message: "Bear's Den complete! Come back tomorrow for more stars ⭐" — signals the daily revisit mechanic

### What the child sees vs what the parent sees
- Child: a fun secret level with mixed questions and a chapter tag per question. No analytics, no weakness labels
- Parent: Chapter Insights on the parent dashboard (Section 16) shows the chapter strength data that drives the weighting

### MVP scope and expansion
- V1: BM only, Chapters 1–3 unlock tier only
- Post-MVP icebox: second tier unlock (e.g. Chapters 4–6), multi-subject expansion, child chapter selection

---

## Out of Scope for V1

Co-parent accounts, Apple Sign-In, tablet layout, multilingual UI (Tamil/BM/Mandarin UI), Standard 2+, leaderboard, WhatsApp notifications, XP bar, AI analytics, monetisation, Bear's Den second tier unlock, Bear's Den multi-subject.
