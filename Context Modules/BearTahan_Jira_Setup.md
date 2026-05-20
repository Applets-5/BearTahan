# BearTahan — Jira Setup Guide
**Project key:** BEAR (or SCRUM as shown in your Jira)
**Methodology:** Scrum · 4 sprints · 2 weeks each

---

## How to use this document

1. Create all **Epics** first (Section 1) — they are the parent containers
2. Create all **Icebox stories** in the Backlog without a sprint (Section 3)
3. Create all **Sprint stories** (Section 2) and assign them to the correct sprint
4. Each story entry shows: Summary · User Story · Acceptance Criteria · Priority · Story Points · Assignee · Sprint · Epic link · Dependencies

**Story point scale used:** 1 = trivial · 2 = simple · 3 = small · 5 = medium · 8 = large · 13 = very large

---

# SECTION 1 — EPICS

Create these 8 epics first. In Jira: Backlog → Create → change type to Epic.

| Epic Name | Label | Description |
|---|---|---|
| Auth & Onboarding | AUTH | Google Sign-In, parent/child mode switch, child profile creation, mascot selection, tutorial |
| Kids Home & Navigation | NAV | Home screen, subject list, chapter map, level navigation, progress bars |
| Learning Engine | LEARN | MCQ, drag-drop, audio questions, feedback, completion screen, session timer |
| Content & Questions | CONTENT | KSSR question banks for all 5 subjects, Maths parametric generation, chapter summary stage, revision stage |
| Star Economy | STARS | Star earning, thresholds, lifetime/spendable balance, transaction history, reward creation, redemption flow |
| Parent Dashboard & Monitoring | PARENT | Progress dashboard, daily goals, push notifications, multi-child, timer data |
| BearAI | BEARAI | AI-powered parent consultation — insight card, chat interface, Claude API integration, context payload assembly |
| Bear's Den | BD | AI-driven cross-chapter secret challenge — unlock logic, chapter strength calculation, weighted question session, parent Chapter Insights |
| Engagement & Cosmetics | ENGAGE | Mascot outfits, quests, sound effects, mascot animations, streak counter |
| System, Settings & Compliance | SYSTEM | Error states, settings screen, PDPA consent, data deletion, internal admin CMS |

---

# SECTION 2 — SPRINT STORIES

---

## 🟢 SPRINT 1 — Core Learning Loop
**Sprint goal:** A child can open the app, complete a BM lesson, and earn stars. Parent can view basic progress.
**Duration:** Weeks 1–2
**Demo target:** Parent signs in → creates child profile → child picks mascot → completes BM Chapter 1 MCQ session → sees stars → parent views dashboard

---

### BEAR-9
**Epic:** Auth & Onboarding
**Summary:** Google Sign-In registration and login via Firebase
**Type:** Story
**Priority:** Must (High)
**Story Points:** 5
**Assignee:** Dev 2
**Sprint:** Sprint 1

**User Story:**
As a parent, I want to register and log in using my Google account via Firebase, so that I can securely access the app without creating a new password.

**Acceptance Criteria:**
- Google Sign-In button is displayed on the app launch screen
- Tapping it opens the Google account picker
- On successful sign-in, the parent is authenticated via Firebase Auth and navigated to onboarding
- On subsequent launches, the session persists — parent is not asked to sign in again
- If sign-in fails (no internet, cancelled), an appropriate error message is shown
- Parent UID is stored in Firestore `/users/{parentUID}` on first sign-in

**Dependencies:** None — implement first

---

### BEAR-10
**Epic:** Auth & Onboarding
**Summary:** Biometric and PIN parent mode switch
**Type:** Story
**Priority:** Must (High)
**Story Points:** 5
**Assignee:** Dev 2
**Sprint:** Sprint 1

**User Story:**
As a parent, I want to switch from child mode to parent mode using biometrics or a PIN, so that my child cannot access or tamper with the parent dashboard.

**Acceptance Criteria:**
- A "Switch to Parent Mode" button is visible on the child home screen
- Tapping it triggers the device biometric prompt (fingerprint)
- If biometrics are unavailable or fail, a PIN entry screen is shown as fallback
- PIN is set up during the onboarding flow (first launch only)
- On successful authentication, the parent dashboard is shown
- A "Back to Child Mode" button is visible in parent mode — tapping returns to child home with no re-authentication required
- There is no automatic timeout back to child mode

**Dependencies:** BEAR-9 must be complete

**⚠️ Risk:** Spike `flutter_local_auth` on the target test device on Day 1. Biometric behaviour varies across Android versions.

---

### BEAR-11
**Epic:** Auth & Onboarding
**Summary:** Create child profile during onboarding
**Type:** Story
**Priority:** Must (High)
**Story Points:** 3
**Assignee:** Dev 2
**Sprint:** Sprint 1

**User Story:**
As a parent, I want to create a child profile with a name during onboarding, so that the app is personalised for my child from the start.

**Acceptance Criteria:**
- After first sign-in, parent is prompted to create a child profile before any other screen
- Parent enters the child's name (required) and age (optional)
- Profile is saved to Firestore under `/children/{childID}` with `parentUID` field linking to parent
- After profile creation, the app transitions to mascot selection (BEAR-12)
- Parent can add additional child profiles later (Sprint 3 feature)

**Dependencies:** BEAR-9

---

### BEAR-12
**Epic:** Auth & Onboarding / Engagement & Cosmetics
**Summary:** Mascot outfit selection on first login
**Type:** Story
**Priority:** Must (High)
**Story Points:** 3
**Assignee:** Dev 4
**Sprint:** Sprint 1

**User Story:**
As a student, I want to choose a bear mascot outfit during my first login, so that I feel ownership over my profile and get excited to start.

**Acceptance Criteria:**
- After child profile creation, the child sees a mascot selection screen
- Only the starter outfit (Scholar Bear) is shown and selectable at this stage — other outfits appear locked with silhouettes
- Child taps to select the starter outfit and confirms
- Selected outfit is saved to the child's Firestore document as `activeOutfitID`
- The active outfit is displayed on the child home screen and completion screens

**Dependencies:** BEAR-11

---

### BEAR-13
**Epic:** Auth & Onboarding
**Summary:** First-launch tutorial walkthrough
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 2
**Assignee:** SM (Samy)
**Sprint:** Sprint 1

**User Story:**
As a parent, I want to see a brief tutorial walkthrough on first launch, so that I understand how the app works without needing external guidance.

**Acceptance Criteria:**
- After mascot selection, 3–4 simple overlay/card screens are shown explaining: how to answer questions, what stars are for, and how to find the Quests tab
- Each screen has a "Next" button; the last screen has a "Let's Go!" button
- A "Skip" option is available on every screen
- Tutorial is shown only once on first launch and never again
- Tutorial completion state is stored locally (SharedPreferences)

**Dependencies:** BEAR-12
**⚠️ Note:** If Sprint 1 runs tight, defer to Sprint 2. Flag at Day 7 standup.

---

### BEAR-14
**Epic:** Kids Home & Navigation
**Summary:** Kids home screen with subjects and progress bars
**Type:** Story
**Priority:** Must (High)
**Story Points:** 5
**Assignee:** Dev 1
**Sprint:** Sprint 1

**User Story:**
As a student, I want to see all 5 subjects with progress bars on my home screen, so that I know which subjects I have been doing and what is left.

**Acceptance Criteria:**
- Home screen displays 5 subject cards: Bahasa Melayu, English, Mandarin, Mathematics, Science
- Each card shows the subject name, an icon, and a progress bar (% of levels completed)
- Progress bar reads from child's Firestore `subjectProgress` subcollection
- Child's active mascot outfit is displayed on the home screen
- Star balance (spendable) is visible at the top of the home screen
- Screen renders correctly even when progress is 0% (first launch state)

**Dependencies:** BEAR-11 (child profile must exist)

---

### BEAR-15
**Epic:** Kids Home & Navigation
**Summary:** Star balance display on home screen
**Type:** Story
**Priority:** Must (High)
**Story Points:** 2
**Assignee:** Dev 1
**Sprint:** Sprint 1

**User Story:**
As a student, I want to see my total star balance clearly on the home screen, so that I always know how many stars I have and feel motivated.

**Acceptance Criteria:**
- Available (spendable) star count is displayed prominently on the home screen
- Balance updates in real time after any level completion or reward redemption
- Displays 0 on first launch with no error

**Dependencies:** BEAR-24 (star earning logic must write to Firestore before this can display real data)

---

### BEAR-16
**Epic:** Kids Home & Navigation
**Summary:** Subject → chapter → level navigation
**Type:** Story
**Priority:** Must (High)
**Story Points:** 5
**Assignee:** Dev 1
**Sprint:** Sprint 1

**User Story:**
As a student, I want to tap a subject and see its chapters and levels laid out, so that I can find what I want to learn and see what is locked ahead.

**Acceptance Criteria:**
- Tapping a subject card opens a chapter list screen
- Tapping a chapter shows its individual levels in order
- Levels are displayed as a visual map or list (to match wireframe)
- Completed levels are marked with a tick or star indicator
- Unlocked but unplayed levels are tappable
- Locked levels are visible but not tappable (see BEAR-17)
- Tapping an unlocked level starts the lesson session

**Dependencies:** BEAR-14

---

### BEAR-17
**Epic:** Kids Home & Navigation
**Summary:** Locked level display
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 2
**Assignee:** Dev 1
**Sprint:** Sprint 1

**User Story:**
As a student, I want to see locked levels as visible but inaccessible, so that I feel a sense of progress and have something to work toward.

**Acceptance Criteria:**
- Locked levels are shown with a padlock icon and greyed-out styling
- Tapping a locked level shows a brief message: "Complete the previous level to unlock this!"
- Levels unlock in strict linear order — completing level N unlocks level N+1
- First level of each subject's first chapter is unlocked by default

**Dependencies:** BEAR-16

---

### BEAR-18
**Epic:** Learning Engine
**Summary:** MCQ tap question type
**Type:** Story
**Priority:** Must (High)
**Story Points:** 8
**Assignee:** Dev 1
**Sprint:** Sprint 1

**User Story:**
As a student, I want to answer multiple-choice questions by tapping an answer, so that I can practise what I have learned in a simple touch-friendly way.

**Acceptance Criteria:**
- Each MCQ screen shows a question prompt (text and/or image) and exactly 4 answer options as tappable buttons
- Only one answer can be selected per question
- After tapping, the answer is locked — child cannot change it
- Immediate feedback is shown after tapping (see BEAR-19)
- A "Next" button appears after feedback to advance to the next question
- Questions are drawn from the level's question bank in Firestore
- 10 questions are shown per basic level session
- Questions are displayed in a randomised order each session

**Dependencies:** BEAR-23 (needs BM seed data to test with real questions)

---

### BEAR-19
**Epic:** Learning Engine
**Summary:** Answer feedback with mascot reaction
**Type:** Story
**Priority:** Must (High)
**Story Points:** 5
**Assignee:** Dev 1
**Sprint:** Sprint 1

**User Story:**
As a student, I want to see immediate visual and audio feedback after each answer, so that I know right away if I was correct and stay engaged.

**Acceptance Criteria:**
- Correct answer: selected option highlights green, mascot plays a cheer animation, a positive sound effect plays
- Incorrect answer: selected option highlights red, correct answer is highlighted green, mascot plays a consoling animation
- Wrong answer question ID is flagged and stored in the child's `wrongAnswerBank` in Firestore
- Feedback is shown for approximately 1.5 seconds before the Next button becomes active
- Stars are never deducted for a wrong answer (BEAR-20 enforces this at logic level)

**Dependencies:** BEAR-18

---

### BEAR-20
**Epic:** Learning Engine
**Summary:** Positive reinforcement — no star deduction for wrong answers
**Type:** Story
**Priority:** Must (High)
**Story Points:** 1
**Assignee:** Dev 1
**Sprint:** Sprint 1

**User Story:**
As a student, I want to never have stars taken away for a wrong answer, so that I feel safe to try without fear of losing what I earned.

**Acceptance Criteria:**
- No star deduction logic exists anywhere in the codebase for wrong answers
- Star balance only ever increases (from level completion or review milestones) or decreases (from reward redemption)
- Unit test confirms star balance is unchanged after a session with 0% correct answers

**Dependencies:** BEAR-18, BEAR-24

---

### BEAR-21
**Epic:** Learning Engine
**Summary:** Counting-up session timer visible to child
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 3
**Assignee:** Dev 4
**Sprint:** Sprint 1

**User Story:**
As a student, I want to see a counting-up timer during my level session, so that I can see how long I have been playing.

**Acceptance Criteria:**
- A counting-up timer (MM:SS format) is visible on the question screen during every session
- Timer starts at 00:00 when the first question is shown
- Timer continues while the child is on the feedback screen
- Timer stops when the completion screen is shown
- Elapsed time in seconds is stored in the attempt document in Firestore
- Timer does not affect score or star calculation in any way

**Dependencies:** BEAR-18

---

### BEAR-22
**Epic:** Learning Engine
**Summary:** Level completion screen
**Type:** Story
**Priority:** Must (High)
**Story Points:** 5
**Assignee:** Dev 1
**Sprint:** Sprint 1

**User Story:**
As a student, I want to see a completion screen with my score and stars earned after every level, so that I feel a sense of achievement at the end of each session.

**Acceptance Criteria:**
- Completion screen is shown after the final question's feedback
- Screen displays: score as a fraction (e.g. 7/10) and percentage, stars earned (0–3 with star animation), mascot celebration animation
- "Play Again" and "Back to Map" buttons are present
- If new stars were earned (tier not previously claimed), a star unlock animation plays
- If no new stars were earned (all tiers already claimed or score too low), a neutral message is shown ("Keep practising!")
- Star award is written to Firestore before the completion screen renders

**Dependencies:** BEAR-18, BEAR-24

---

### BEAR-23
**Epic:** Content & Questions
**Summary:** BM Chapter 1 seed question bank in Firestore
**Type:** Story
**Priority:** Must (High)
**Story Points:** 5
**Assignee:** Dev 3
**Sprint:** Sprint 1

**User Story:**
As a student, I want to play BM Chapter 1 with real KSSR-aligned questions, so that the app is immediately useful and relevant to my schoolwork.

**Acceptance Criteria:**
- Minimum 10 MCQ questions for BM Chapter 1 are created and uploaded to Firestore `/questions/` collection
- Questions are KSSR Standard 1 Bahasa Melayu aligned
- Each question has: prompt text, 4 answer options, correct answer ID, subject ID, chapter ID, level ID, difficulty (1–3)
- Questions are validated by a team member before upload (human review pass)
- Questions are queryable by level ID in Firestore
- At least 2 different difficulty levels represented in the bank

**Dependencies:** None — Dev 3 starts this independently on Day 1
**⚠️ Risk:** Must be in Firestore by Sprint 1 Day 3 so Dev 1 can test the question engine with real data.

---

### BEAR-24
**Epic:** Star Economy
**Summary:** Star earning logic for basic levels
**Type:** Story
**Priority:** Must (High)
**Story Points:** 8
**Assignee:** Dev 2
**Sprint:** Sprint 1

**User Story:**
As a student, I want to earn stars based on my score when I complete a basic level, so that I am rewarded for how well I do, not just for showing up.

**Acceptance Criteria:**
- Star calculation: < 50% = 0 stars, ≥ 50% = 1 star, ≥ 80% = 2 stars, 100% = 3 stars
- Each tier is a one-time claim — if child scored 60% (1 star) and replays scoring 85%, they earn the 2nd star only
- Stars already claimed for a level are read from `levelProgress.starsClaimedTiers` before awarding
- On completion: `lifetimeStarsEarned` and `availableStars` are both incremented in child's Firestore document
- A star transaction document is written to `/children/{childID}/starTransactions/`
- `levelProgress` document is updated with new `starsClaimedTiers`
- Unit tests cover all threshold boundaries and replay scenarios

**Dependencies:** BEAR-11 (child document must exist in Firestore)

---

### BEAR-25
**Epic:** Parent Dashboard & Monitoring
**Summary:** Read-only parent progress dashboard
**Type:** Story
**Priority:** Must (High)
**Story Points:** 5
**Assignee:** Dev 2
**Sprint:** Sprint 1

**User Story:**
As a parent, I want to view my child's total stars, lessons completed, streak, and per-subject progress, so that I have full visibility without having to ask my child.

**Acceptance Criteria:**
- Parent mode shows a dashboard screen with: total lifetime stars earned, available stars, total lessons completed, current streak (days), per-subject progress bars (% completion)
- Data is read from the child's Firestore document and `subjectProgress` subcollection
- Data refreshes in real time (Firestore stream listener)
- If no sessions have been played, all metrics show 0 with no error or crash
- Dashboard is only accessible from parent mode (behind biometric/PIN — BEAR-10)

**Dependencies:** BEAR-10 (parent mode must exist), BEAR-24 (stars must be writable)

---

### BEAR-26
**Epic:** System, Settings & Compliance
**Summary:** No internet connection error screen
**Type:** Story
**Priority:** Must (High)
**Story Points:** 2
**Assignee:** SM (Samy)
**Sprint:** Sprint 1

**User Story:**
As a parent, I want to see a clear message when there is no internet connection, so that I am not confused by a blank or broken screen.

**Acceptance Criteria:**
- App checks for internet connectivity on launch and on resuming from background
- If no connection is detected, a full-screen friendly error screen is shown: illustration + "Please connect to the internet to use BearTahan"
- A "Try Again" button re-checks connectivity
- No lesson content, Firestore reads, or navigation is permitted while offline
- The error screen does not crash and handles both Wi-Fi and mobile data states

**Dependencies:** None — independent of auth flow

---

## 🔵 SPRINT 2 — Full Content & Parent Tools
**Sprint goal:** All 5 subjects live. Chapter summary stage working. Parents can set goals, create rewards, and receive push notifications.
**Duration:** Weeks 3–4
**Demo target:** Child plays Maths + English sessions. Parent creates a reward, sets a daily goal. Streak visible.

---

### BEAR-29 (27)
**Epic:** Auth & Onboarding
**Summary:** Password / account recovery flow
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 1
**Assignee:** Dev 2
**Sprint:** Sprint 2

**User Story:**
As a parent, I want to reset my password via a standard email reset flow, so that I can always recover access to my account.

**Acceptance Criteria:**
- Since auth is Google Sign-In only, account recovery is handled natively by Google — no custom password reset flow is needed
- A "Having trouble signing in?" link on the login screen opens Google's account recovery page in the device browser
- This story is primarily documentation and a UI link — no backend work required

**Dependencies:** BEAR-9

---

### BEAR-30 (28)
**Epic:** Content & Questions
**Summary:** All 5 subjects — full KSSR-aligned question banks
**Type:** Story
**Priority:** Must (High)
**Story Points:** 13
**Assignee:** Dev 3
**Sprint:** Sprint 2

**User Story:**
As a student, I want to access all 5 subjects with KSSR-aligned questions across all chapters, so that I can practise every subject I study in school.

**Acceptance Criteria:**
- Questions exist in Firestore for all chapters of all 5 subjects: Bahasa Melayu, English, Mandarin, Mathematics (recognition questions — not parametric), Science
- Each subject has a minimum of 10 questions per chapter per level
- All questions are human-reviewed for KSSR Standard 1 accuracy before upload
- Mandarin questions in Sprint 2 are recognition/MCQ only — stroke tracing is Sprint 3
- Questions are tagged with correct subjectID, chapterID, levelID, and difficulty
- All audio URLs are populated (TTS pre-generated) for questions requiring audio

**Dependencies:** Dev 3 starts on Day 1 of Sprint 2 — this is the highest-risk item
**⚠️ Risk:** Must be substantially complete by mid-Sprint 2 or Sprint 2 demo is blocked.

---

### BEAR-31 (29)
**Epic:** Content & Questions
**Summary:** Maths parametric question generation
**Type:** Story
**Priority:** Must (High)
**Story Points:** 5
**Assignee:** Dev 2 (logic) + Dev 3 (rules config)
**Sprint:** Sprint 2

**User Story:**
As a student, I want to answer randomised Maths questions generated from number ranges, so that I get different questions every session and build number fluency.

**Acceptance Criteria:**
- Maths questions are generated at runtime — not stored individually in Firestore
- Generation rules (operation type, minA, maxA, minB, maxB) are stored in Firestore per chapter and configurable via admin CMS (Sprint 4)
- Generator produces: a question prompt string, the correct answer, and 3 numerically plausible wrong options (all distinct)
- Correct answer is always included in the options list
- All 4 options are distinct integers
- Generator is covered by unit tests (boundary cases, distinct options, correct answer in list)
- Dev 3 provides the number ranges and operation types per chapter to Dev 2 before coding begins

**Dependencies:** Dev 3 must hand range configuration to Dev 2 by Sprint 2 Day 1

---

### BEAR-33 (30)
**Epic:** Learning Engine
**Summary:** Drag-and-drop question type
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 8
**Assignee:** Dev 4
**Sprint:** Sprint 2

**User Story:**
As a student, I want to answer drag-and-drop questions where I match items, so that I have variety in how I practise and stay interested.

**Acceptance Criteria:**
- Drag-and-drop questions show a prompt and 2–4 draggable answer tiles
- Child drags a tile to a target drop zone
- Correct placement highlights green; incorrect highlights red with correct answer shown
- Works with touch input (not mouse) — use Flutter's `Draggable` and `DragTarget` widgets
- At least one drag-and-drop question exists in the question bank (Dev 3 provides) to test the interaction
- Wrong answers are flagged for the review bank (same as MCQ)
- Completion screen and star logic work identically to MCQ sessions

**Dependencies:** BEAR-18 (MCQ engine patterns), BEAR-28 (needs questions of this type)

---

### BEAR-34 (31)
**Epic:** Content & Questions
**Summary:** TTS audio playback on questions
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 5
**Assignee:** Dev 3 (audio generation) + Dev 1 (player widget)
**Sprint:** Sprint 2

**User Story:**
As a student, I want to hear an audio clip play as part of a question, so that I can answer listening questions even if my reading is still developing.

**Acceptance Criteria:**
- Audio questions display a speaker icon button the child can tap to play the audio
- For audio-type questions, audio plays automatically on question load (and can be replayed)
- Audio files are pre-generated TTS, stored in Firebase Storage, URLs stored in the question document's `promptAudioURL` field
- Audio player widget works for both auto-play and manual replay
- If audio file fails to load, the question still renders with a text fallback and an error icon on the speaker button
- Dev 3 pre-generates and uploads all required audio files; Dev 1 integrates the audio player widget

**Dependencies:** BEAR-28 (audio files linked to questions)

---

### BEAR-36 (32)
**Epic:** Content & Questions
**Summary:** Chapter summary stage with randomised questions and escalating threshold
**Type:** Story
**Priority:** Must (High)
**Story Points:** 8
**Assignee:** Dev 1 (UI) + Dev 3 (content pool)
**Sprint:** Sprint 2

**User Story:**
As a student, I want to complete a chapter summary stage with randomised questions each session, so that I can repeat it daily and still get a fresh challenge.

**Acceptance Criteria:**
- Each chapter has one summary stage appearing at the end of its level list
- Summary stage draws 15 questions randomly from the entire chapter's question bank each session
- The same question may appear in different sessions
- Summary stage uses escalating threshold for star earning: first threshold is 80%; increases to 90% after achieving 80%; increases to 100% after achieving 90%; stays at 100% permanently
- Threshold only escalates when the child achieves the current threshold — failing does not escalate or reset
- Once at 100% permanently, child can earn 1 star per day for every 100% score
- Daily cap: 1 star per day per summary stage (enforced by `lastSummaryStarDate` in `levelProgress`)
- `summaryThreshold` and `lastSummaryStarDate` are persisted in Firestore `levelProgress` document per child
- Unit tests cover all escalation transitions and daily cap logic

**Dependencies:** BEAR-28 (needs question pool), BEAR-24 (star logic pattern)

---

### BEAR-37 (33)
**Epic:** Star Economy
**Summary:** Parent creates custom real-world rewards
**Type:** Story
**Priority:** Must (High)
**Story Points:** 5
**Assignee:** Dev 2
**Sprint:** Sprint 2

**User Story:**
As a parent, I want to create custom real-world rewards with a name and star cost, so that my child has a tangible personalised goal to work toward.

**Acceptance Criteria:**
- Parent mode has a Rewards management screen
- Parent can tap "Add Reward" to create a new reward: enter a name (required), optional emoji, and a star cost (required, positive integer)
- Suggested star cost ranges are shown as a guide (e.g. small treat = 50–100, big outing = 300–500)
- Reward is saved to Firestore `/users/{parentUID}/rewards/{rewardID}` linked to the child
- Created reward immediately appears in both the parent's Rewards screen and the child's Rewards screen
- Parent can create multiple rewards (no hard limit for V1)

**Dependencies:** BEAR-11 (child document must exist)

---

### BEAR-38 (34)
**Epic:** Star Economy
**Summary:** Parent edits or deletes rewards
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 2
**Assignee:** Dev 2
**Sprint:** Sprint 2

**User Story:**
As a parent, I want to edit or delete rewards I have set at any time, so that I can keep the reward list relevant as my child grows.

**Acceptance Criteria:**
- Each reward in the parent's Rewards screen has an edit (pencil) and delete (trash) icon
- Edit opens a form pre-filled with the existing reward data; parent can update name, emoji, or star cost and save
- Delete shows a confirmation dialog before removing the reward document from Firestore
- Deleting a reward that has a pending claim does not affect the pending claim — it runs to completion

**Dependencies:** BEAR-33

---

### BEAR-39 (35)
**Epic:** Parent Dashboard & Monitoring
**Summary:** Parent sets daily learning goal for child
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 3
**Assignee:** Dev 2
**Sprint:** Sprint 2

**User Story:**
As a parent, I want to set a daily learning goal for my child in lessons or minutes, so that my child builds a consistent learning habit with a clear target.

**Acceptance Criteria:**
- Parent mode has a Goal Setting section in the dashboard or settings
- Parent selects goal type (lessons or minutes) and enters a target number
- Goal is stored in the child's Firestore document: `dailyGoal.type`, `dailyGoal.target`
- Child home screen shows a daily goal progress indicator (e.g. "2 of 3 lessons done today")
- Goal progress resets at 12:00am each calendar day
- `dailyGoal.todayProgress` and `dailyGoal.lastUpdatedDate` are updated on each session completion
- If no goal is set, the goal indicator is not shown on the child home screen

**Dependencies:** BEAR-11, BEAR-25

---

### BEAR-40 (36)
**Epic:** Parent Dashboard & Monitoring
**Summary:** Push notification — daily goal completed
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 3
**Assignee:** Dev 2
**Sprint:** Sprint 2

**User Story:**
As a parent, I want to receive a push notification when my child completes their daily goal, so that I can praise them immediately and reinforce the habit.

**Acceptance Criteria:**
- When `dailyGoal.todayProgress` reaches or exceeds `dailyGoal.target`, a push notification is sent to the parent via FCM
- Notification payload: `{ type: "goal_complete", childName: String }`
- Notification is sent only once per calendar day per goal completion (not on every session if already completed)
- Notification is sent to the FCM token stored in `/users/{parentUID}/fcmToken`
- If parent has disabled goal notifications (Sprint 4), notification is not sent

**Dependencies:** BEAR-35, FCM token setup from BEAR-9

---

### BEAR-41 (37)
**Epic:** Parent Dashboard & Monitoring
**Summary:** Push notification — child claims reward
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 2
**Assignee:** Dev 2
**Sprint:** Sprint 2

**User Story:**
As a parent, I want to receive a push notification when my child claims a reward, so that I am never surprised by a reward request I did not expect.

**Acceptance Criteria:**
- When a reward claim document is created (Sprint 3 — BEAR-40), a push notification is sent to the parent
- Notification payload: `{ type: "reward_claimed", rewardName: String, starCost: int }`
- Notification links to the parent's Rewards screen showing the pending claim
- Notification setup and token management implemented here; full claim flow is BEAR-40 (Sprint 3)

**Dependencies:** BEAR-33, BEAR-9 (FCM token)

---

### BEAR-42 (38)
**Epic:** Engagement & Cosmetics
**Summary:** Daily streak counter on child home screen
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 3
**Assignee:** Dev 4
**Sprint:** Sprint 2

**User Story:**
As a student, I want to see my daily streak counter on the home screen, so that I am motivated to open the app every day to keep my streak alive.

**Acceptance Criteria:**
- A streak counter (e.g. "🔥 7 days") is displayed on the child home screen
- Streak increments when the child completes at least one session in a calendar day (12:00am–11:59pm)
- If the child plays today but `lastSessionDate` is not yesterday, streak resets to 1
- If the child has already played today, streak does not increment further
- Streak value is persisted in child's Firestore document: `currentStreak`, `lastSessionDate`
- Unit tests cover: first session, consecutive days, gap day (reset), same-day replay

**Dependencies:** BEAR-22 (session completion must update `lastSessionDate`)

---

### BEAR-43 (39)
**Epic:** Parent Dashboard & Monitoring
**Summary:** Streak-at-risk push notification
**Type:** Story
**Priority:** Could (Low)
**Story Points:** 3
**Assignee:** Dev 2
**Sprint:** Sprint 2

**User Story:**
As a parent, I want to receive a streak-at-risk alert if my child has not practised by a set time, so that I can encourage them before the streak is broken.

**Acceptance Criteria:**
- A Firebase Cloud Function runs on a daily schedule at 8:00pm
- The function checks all children whose `lastSessionDate` is not today and whose `currentStreak` > 0
- A push notification is sent to those parents: `{ type: "streak_risk", currentStreak: int }`
- Only sent if the child's streak would be broken by midnight with no session
- If parent has disabled streak notifications (Sprint 4), notification is not sent
- Fixed at 8pm for V1 — user-configurable time is an icebox item

**Dependencies:** BEAR-38, Firebase Cloud Functions setup

---

## 🟡 SPRINT 3 — Engagement & Reward Loop
**Sprint goal:** Full star economy end-to-end. Review system live. Quests and outfits. Mandarin stroke tracing.
**Duration:** Weeks 5–6
**Demo target:** Child claims reward → parent approves → celebration. Review section shown. Quest completed, outfit unlocked. Mandarin tracing demonstrated.

---

### BEAR-40 (starts 46)
**Epic:** Star Economy
**Summary:** Child claims reward — pending flow with parent notification
**Type:** Story
**Priority:** Must (High)
**Story Points:** 8
**Assignee:** Dev 2
**Sprint:** Sprint 3

**User Story:**
As a student, I want to claim a reward when I have enough stars and send a notification to my parent, so that my parent knows to deliver the reward in real life.

**Acceptance Criteria:**
- Child's Rewards screen shows all active rewards with progress bars (available stars / star cost)
- "Claim" button is active only when `availableStars >= reward.starCost`
- Tapping "Claim" shows a confirmation dialog: "This will use X stars. Are you sure?"
- On confirmation: a `rewardClaim` document is created in Firestore with `status: "pending"`, `expiresAt: now + 7 days`
- Stars are NOT deducted at this point — they remain in available balance but are logically reserved
- FCM push notification is sent to parent (BEAR-37 sets up the channel)
- Child's Rewards screen shows the reward as "Pending — waiting for parent approval"
- Child cannot claim the same reward again while it is pending

**Dependencies:** BEAR-33 (rewards must exist), BEAR-37 (notification channel)

---

### BEAR-41
**Epic:** Star Economy
**Summary:** Parent approves or rejects reward claim
**Type:** Story
**Priority:** Must (High)
**Story Points:** 8
**Assignee:** Dev 2
**Sprint:** Sprint 3

**User Story:**
As a parent, I want to approve or reject my child's reward claim in the app, so that the star deduction only happens after I physically deliver the reward.

**Acceptance Criteria:**
- Parent Rewards screen shows a pending claim badge/notification
- Parent sees the pending claim with reward name, star cost, and claim timestamp
- "Approve" button: stars are deducted from `availableStars`, claim status updated to "approved", star transaction written, child's screen shows a celebration animation
- "Reject" button: claim status updated to "rejected", stars remain unchanged, child is notified with a message
- Claim expires after 7 days with no action: status becomes "expired", stars remain unchanged (they were never deducted), child's reward returns to claimable state
- Expiry is handled by a Firebase Cloud Function scheduled to run daily
- Both parent and child see the updated status in real time via Firestore stream listeners
- Star deduction writes a transaction: `{ type: "spend", source: "reward_redemption", amount: int }`

**Dependencies:** BEAR-40

---

### BEAR-42
**Epic:** Star Economy
**Summary:** Lifetime vs. spendable star balance display
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 3
**Assignee:** SM (Samy)
**Sprint:** Sprint 3

**User Story:**
As a student, I want to see both my lifetime stars earned and my available stars to spend as two separate counts, so that I always feel like I am growing even after I redeem a reward.

**Acceptance Criteria:**
- Child home screen and/or star history screen shows two distinct counts: "Total Earned" (lifetime, never decreases) and "Available" (spendable, decreases after redemption)
- Both values are read from child's Firestore document: `lifetimeStarsEarned` and `availableStars`
- "Total Earned" field is never decremented by any operation in the codebase
- Both values update in real time

**Dependencies:** Firestore fields `lifetimeStarsEarned` and `availableStars` already written by BEAR-24 and BEAR-41

---

### BEAR-43
**Epic:** Star Economy
**Summary:** Star history and transaction log screen
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 3
**Assignee:** SM (Samy)
**Sprint:** Sprint 3

**User Story:**
As a student, I want to view a history of all the stars I have earned and spent, so that I can track my progress and understand where my stars went.

**Acceptance Criteria:**
- A Star History screen is accessible from the child's profile or home screen
- Screen displays a chronological list of all star transactions
- Each entry shows: date, type (earned/spent), amount, and source (e.g. "Level 3 — BM", "Ice Cream Treat redeemed")
- Data is read from `/children/{childID}/starTransactions/` subcollection, ordered by timestamp descending
- Empty state shown with a friendly message if no transactions yet
- Parent can also see this screen from the dashboard

**Dependencies:** Star transaction documents written by BEAR-24, BEAR-41, BEAR-46

---

### BEAR-44
**Epic:** Learning Engine / Review System
**Summary:** Bear's Memory Challenge — dedicated wrong-answer review section
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 8
**Assignee:** Dev 1 (UI) + Dev 2 (logic)
**Sprint:** Sprint 3

**User Story:**
As a student, I want to see a dedicated Bear's Memory Challenge section when I have wrong-answer review questions, so that I can deliberately revisit and correct questions I got wrong.

**Acceptance Criteria:**
- A "Bear's Memory Challenge" banner or tab appears on the child home screen when pending review questions exist in their `wrongAnswerBank`
- Tapping it starts a review session: 10–20 questions drawn from the child's personal `wrongAnswerBank` (cross-subject)
- Review session UI is identical to a regular level session (same question engine)
- Every question answered in a review session increments the global `reviewQuestionCounter` in the child's Firestore document (regardless of correct/incorrect)
- When `reviewQuestionCounter` reaches 20: 1 star is awarded, counter resets to 0, star transaction is written
- A question answered in review is removed from or deprioritised in the `wrongAnswerBank`
- Banner does not appear if `wrongAnswerBank` is empty

**Dependencies:** `wrongAnswerBank` populated by BEAR-19 (wrong-answer flagging), BEAR-46 (accumulation counter logic)

---

### BEAR-45
**Epic:** Learning Engine / Review System
**Summary:** Silent injection of wrong-answer questions into level sessions
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 5
**Assignee:** Dev 1
**Sprint:** Sprint 3

**User Story:**
As a student, I want to have wrong-answer questions silently mixed into my regular level sessions, so that I naturally re-encounter questions I got wrong without a separate step.

**Acceptance Criteria:**
- When a level session is loaded, the app queries the child's `wrongAnswerBank` for up to 2 questions from any subject not recently reviewed
- These 2 questions replace 2 of the 10 normal level questions
- The final set of 10 questions is shuffled before display — the child cannot tell which are review questions
- If the `wrongAnswerBank` has fewer than 2 eligible questions, fewer are injected (no minimum)
- Injected review questions increment `reviewQuestionCounter` the same as dedicated review sessions
- Normal level score and star calculation is based on all 10 questions including injected ones

**Dependencies:** `wrongAnswerBank` populated by BEAR-19, BEAR-44 (counter logic)

---

### BEAR-46
**Epic:** Learning Engine / Review System
**Summary:** Review accumulation star earning (every 20 answered = 1 star)
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 3
**Assignee:** Dev 2
**Sprint:** Sprint 3

**User Story:**
As a student, I want to earn stars by accumulating review questions answered (every 20 = 1 star), so that I am rewarded for putting in the effort to review my mistakes.

**Acceptance Criteria:**
- `reviewQuestionCounter` is a field on the child's Firestore document, initialised to 0
- Every review question answered (in dedicated review or silent injection) increments the counter by 1
- When counter reaches 20: `availableStars += 1`, `lifetimeStarsEarned += 1`, counter resets to 0
- A star transaction is written: `{ type: "earn", source: "review_milestone" }`
- Counter is cross-subject — any review question from any subject counts toward the same counter
- Unit test covers: counter increment, milestone trigger at exactly 20, reset after milestone

**Dependencies:** BEAR-44, BEAR-45

---

### BEAR-47
**Epic:** Engagement & Cosmetics
**Summary:** Quest unlock logic — outfit unlocked by completing mission
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 8
**Assignee:** Dev 4
**Sprint:** Sprint 3

**User Story:**
As a student, I want to unlock new bear outfits by completing specific quest missions, so that I have long-term goals that keep me coming back beyond just earning stars.

**Acceptance Criteria:**
- Quest conditions for each outfit are stored in Firestore and readable by the app
- V1 quest conditions (confirm with PO before Sprint 3 start — see BT-06 O4): Scholar Bear = starter (always unlocked), Chef Bear = complete 5 BM lessons, Astro Bear = score 100% on 3 Maths quizzes, Pirate Bear = complete 10 English lessons, Super Bear = earn 500 total stars, Explorer Bear = complete all Science topics
- Quest progress is tracked per child in `/children/{childID}/questProgress/{outfitID}`
- After every session completion, all quest conditions are evaluated and progress documents updated
- When a quest condition is met: `isUnlocked = true` is written, an unlock animation is triggered
- Outfit unlock is permanent — replaying conditions does not re-lock an outfit

**Dependencies:** BEAR-49 (outfit selection must exist to equip the unlocked outfit)

---

### BEAR-48
**Epic:** Engagement & Cosmetics
**Summary:** Quests tab with progress bars and locked silhouettes
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 5
**Assignee:** Dev 4
**Sprint:** Sprint 3

**User Story:**
As a student, I want to see a Quests tab showing all missions with progress bars and locked bear silhouettes, so that I am curious about what I can unlock and motivated to complete challenges.

**Acceptance Criteria:**
- A Quests tab is accessible from the child's bottom navigation bar
- Each outfit/quest is displayed as a card showing: bear silhouette (if locked) or full bear image (if unlocked), quest condition text, progress bar (e.g. "2 / 3 Maths 100% quizzes")
- Locked outfits show only the silhouette shape — the design is not revealed
- Unlocked outfits show the full outfit design and an "Equip" button
- Active outfit has an "Active" badge instead of an "Equip" button
- Progress data is read from `questProgress` subcollection in real time

**Dependencies:** BEAR-47

---

### BEAR-49
**Epic:** Engagement & Cosmetics
**Summary:** Outfit selection and active outfit persistence
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 3
**Assignee:** Dev 4
**Sprint:** Sprint 3

**User Story:**
As a student, I want to choose which unlocked outfit my bear wears, so that I feel creative ownership over my in-app character.

**Acceptance Criteria:**
- Child can tap "Equip" on any unlocked outfit in the Quests tab to make it active
- Active outfit is stored in child's Firestore document as `activeOutfitID`
- Active outfit is reflected across all mascot display surfaces in the app (home screen, question feedback, completion screen)
- Changing outfit takes effect immediately with no app restart required
- Equipping an outfit while another is active simply replaces the active outfit

**Dependencies:** BEAR-47 (quests must exist), BEAR-48 (UI to trigger equip)

---

### BEAR-50
**Epic:** Engagement & Cosmetics
**Summary:** Sound effects and mascot animations
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 5
**Assignee:** Dev 4
**Sprint:** Sprint 3

**User Story:**
As a student, I want to hear fun sound effects and see mascot animations throughout the app, so that the app feels alive and rewarding to use.

**Acceptance Criteria:**
- Sound effects play for: correct answer, wrong answer, level completion, star earned, outfit unlocked, streak milestone
- All sound assets are bundled within the Flutter app (not fetched from network)
- Mascot plays distinct animations for: idle (home screen), cheering (correct answer), consoling (wrong answer), celebrating (level complete), surprised/happy (outfit unlock)
- Sound can be toggled off via a settings control (BEAR-60 — settings screen)
- Animations are implemented using Flutter's animation system or a Lottie-compatible package
- App respects system silent mode — sound is muted if device is on silent

**Dependencies:** BEAR-19, BEAR-22, BEAR-47

---

### BEAR-51
**Epic:** Parent Dashboard & Monitoring
**Summary:** Level completion time data on parent dashboard
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 3
**Assignee:** Dev 2
**Sprint:** Sprint 3

**User Story:**
As a parent, I want to see how long my child took to complete each level and their daily total learning time, so that I understand their pace and can identify where they struggle.

**Acceptance Criteria:**
- Parent dashboard shows per-level elapsed time for recent sessions (e.g. "Level 3 — BM: 4m 32s")
- Dashboard also shows a daily total learning time (sum of all session times today)
- Data is read from the `attempts` subcollection and child's daily aggregated total
- If no sessions today, daily total shows 0m
- Timer data is stored in Firestore by BEAR-21 (the timer itself)

**Dependencies:** BEAR-21 (timer data in Firestore), BEAR-25 (parent dashboard base)

---

### BEAR-52
**Epic:** Content & Questions
**Summary:** Mandarin stroke tracing for Standard 1 characters
**Type:** Story
**Priority:** Must (High)
**Story Points:** 13
**Assignee:** Dev 4 (dedicated)
**Sprint:** Sprint 3

**User Story:**
As a student, I want to practise Mandarin by tracing Chinese characters in the correct stroke order, so that I learn how to write characters properly, not just recognise them.

**Acceptance Criteria:**
- Stroke tracing question type renders a canvas where the child draws a Chinese character with their finger
- Strokes must be drawn in the correct order — out-of-order strokes are rejected with feedback
- Validation uses fuzzy matching on stroke direction and start/end zones (not pixel-perfect)
- Target characters are limited to simple Standard 1 Simplified Chinese characters: 人, 大, 小, 山, 日, 月, 水, 火, 木, 土 (final list confirmed by Dev 3 against KSSR content)
- Stroke order data for each character is stored in the question document (`strokeOrderData` field) as an array of stroke paths
- The child gets up to 3 attempts per character before the correct stroke is shown
- Wrong attempts flag the question in the `wrongAnswerBank` as with other question types
- Completion screen and star logic identical to other question types

**⚠️ Risk:** Highest-risk item in the project. Dev 4 starts on Sprint 3 Day 1. Escalate by Day 7 if not functional. Fallback: Mandarin ships as recognition-only and stroke tracing moves to icebox.

**Dependencies:** BEAR-28 (Mandarin character data), stroke order data provided by Dev 3

---

### BEAR-53
**Epic:** Parent Dashboard & Monitoring
**Summary:** Multi-child support — add profile and switch in dashboard
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 5
**Assignee:** Dev 2
**Sprint:** Sprint 3

**User Story:**
As a parent, I want to add a second child profile and switch between them in the dashboard, so that I can monitor all my children from one account.

**Acceptance Criteria:**
- Parent mode has an "Add Child" option that starts the same child profile creation flow (BEAR-11)
- Each parent account can have multiple child documents in Firestore, all linked by `parentUID`
- Parent dashboard has a child profile switcher (e.g. tab bar or dropdown) showing all child names
- Switching children loads that child's progress data from Firestore
- Each child profile is fully independent: separate stars, progress, outfits, rewards, quests
- Deleting a child profile (not in V1 scope — document for future) does not need to be implemented

**Dependencies:** BEAR-11, BEAR-25

---

### BEAR-56
**Epic:** Parent Dashboard & Monitoring
**Summary:** BearAI insight card — AI-generated child activity summary
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 5
**Assignee:** Dev 2
**Sprint:** Sprint 3

**User Story:**
As a parent, I want to see an AI-generated insight card on my dashboard summarising my child's recent activity, so that I get an immediate overview of how my child is doing without reading all the stats manually.

**Acceptance Criteria:**
- BearAI tab is visible in the parent dashboard alongside existing tabs
- At the top of the BearAI tab, an insight card displays 2–3 sentences of AI-generated commentary
- Insight is generated by calling Claude API with child Firestore data as context (see BT-05 Section 13)
- Content covers: strongest subject, weakest subject, one behavioural observation (e.g. session time patterns, streak status)
- Card is generated once per parent session when the BearAI tab is first opened; response is cached in local state for the session (no repeated API calls)
- A loading indicator is shown while the API call is in progress
- If the API call fails, a fallback message is shown: "Unable to load insight right now. Please try again."
- API key is never stored in the Flutter binary — must be called via Firebase Cloud Function

**⚠️ Risk:** Claude API key must be provisioned and Cloud Function wrapper must be deployed before this story can be completed. Dev 2 resolves open item O8 on Sprint 3 Day 1.

**Dependencies:** BEAR-25 (parent dashboard base), child session data from Sprint 1/2 attempts

---

### BEAR-57
**Epic:** Parent Dashboard & Monitoring
**Summary:** BearAI chat interface — parent AI consultation
**Type:** Story
**Priority:** Must (High)
**Story Points:** 8
**Assignee:** Dev 2
**Sprint:** Sprint 3

**User Story:**
As a parent, I want to chat with BearAI to ask questions about my child's progress and get personalised recommendations, so that I have a personal consultant that helps me make better decisions about rewards, goals, and subject support.

**Acceptance Criteria:**
- Below the insight card (BEAR-56), a chat interface fills the remaining BearAI tab space
- Four quick-reply suggestion chips are shown when no messages exist: "How is [child name] doing this week?", "Suggest a reward amount", "What daily goal should I set?", "Which subject needs more focus?"
- Tapping a chip sends it as a parent message and triggers a BearAI response
- Parent can also type free-form questions in the text input bar and tap Send
- BearAI responses are grounded in the child's real Firestore data (assembled context payload per BT-05 Section 13)
- Multi-turn conversation works within a session — full message history is passed on each API call
- Conversation history is not persisted to Firestore — it is session-only and clears when parent mode is exited
- A disclaimer is shown below the input bar: "BearAI uses [child name]'s in-app activity data only."
- Loading indicator shown while awaiting BearAI response; input is disabled during this time
- If API call fails, show inline error: "BearAI couldn't respond. Please try again."
- Topics BearAI can address: weekly progress summaries, subject-specific performance, reward name and star cost recommendations, daily goal recommendations, streak observations, learning pattern insights

**Dependencies:** BEAR-56 (BearAI tab and insight card must exist), Claude API Cloud Function from O8

---
**Sprint goal:** All edge cases handled. Admin CMS live. PDPA compliant. Stable for final demo.
**Duration:** Weeks 7–8
**Demo target:** Full end-to-end walkthrough. Admin CMS demonstrated. Error states shown. Data deletion demonstrated.

---

### BEAR-54
**Epic:** Content & Questions
**Summary:** Subject revision stage — cross-chapter mixed questions
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 5
**Assignee:** Dev 1 (UI) + Dev 3 (content)
**Sprint:** Sprint 4

**User Story:**
As a student, I want to access a Revision Stage that mixes all questions from completed chapters across a subject, so that I can do a comprehensive cross-chapter review of everything I have learned.

**Acceptance Criteria:**
- Revision Stage unlocks for a subject when `allChaptersComplete = true` in that subject's `subjectProgress` document
- One Revision Stage exists per subject — it appears at the bottom of the subject's chapter list when unlocked
- Session draws 15 questions randomly from the entire subject's question bank (cross-chapter)
- Uses the same escalating threshold mechanics as chapter summary stage (80% → 90% → 100%)
- Same daily star cap (1 star per day per revision stage)
- `summaryThreshold` and `lastSummaryStarDate` are tracked per revision stage in `levelProgress` (using a dedicated levelID for each revision stage)

**Dependencies:** BEAR-32 (summary stage threshold logic reused), BEAR-28 (full question bank)

---

### BEAR-55
**Epic:** Parent Dashboard & Monitoring
**Summary:** Parent configures push notification preferences
**Type:** Story
**Priority:** Could (Low)
**Story Points:** 2
**Assignee:** Dev 2
**Sprint:** Sprint 4

**User Story:**
As a parent, I want to configure which push notifications I receive, so that I do not get overwhelmed by alerts and disable them entirely.

**Acceptance Criteria:**
- Parent settings screen has a Notifications section with toggles for each event type: Goal completed, Chapter completed, Reward claimed, Streak at risk
- Toggle states are stored in `/users/{parentUID}/notificationPreferences`
- All notification-sending functions (BEAR-36, 29, 31) check the relevant preference before sending
- Default state: all notifications enabled

**Dependencies:** BEAR-36, BEAR-37, BEAR-39

---

### BEAR-56
**Epic:** System, Settings & Compliance
**Summary:** Internal admin CMS for question bank management
**Type:** Story
**Priority:** Must (High)
**Story Points:** 13
**Assignee:** Dev 2
**Sprint:** Sprint 4

**User Story:**
As a content creator, I want to use an internal admin tool to upload and manage questions without developer help, so that the team can update the question bank independently and quickly.

**Acceptance Criteria:**
- A simple web-based admin tool (Flutter Web or plain HTML/JS) connects to Firestore with admin credentials
- Admin can: create a question (all types), edit an existing question, delete a question
- Question form fields: subject, chapter, level, type, prompt text, image upload (to Firebase Storage), audio URL link, up to 4 answer options, correct answer selection, difficulty rating
- Maths parametric rules are configurable per chapter (operation, number ranges)
- Quest conditions per outfit are configurable via the CMS
- The tool is protected by a hardcoded admin email check or Firebase custom claims — no public access
- Content changes in Firestore are immediately reflected in the app

**⚠️ Note:** Prioritise this above Should items at Sprint 4 start — Dev 3 needs it to update content for the final demo without developer intervention.

**Dependencies:** All Firestore collections established in Sprints 1–3

---

### BEAR-57
**Epic:** System, Settings & Compliance
**Summary:** Friendly error messages for empty and broken states
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 3
**Assignee:** SM (Samy)
**Sprint:** Sprint 4

**User Story:**
As a student, I want to see friendly error messages for empty and broken states, so that I am not confused by a blank screen or a technical error.

**Acceptance Criteria:**
- Empty states handled with illustrated messages for: no questions available for a level, empty `wrongAnswerBank` when Review section is tapped, first-time parent dashboard with no sessions yet, no rewards created yet (parent side)
- Error states handled for: Firestore read failure (show "Something went wrong, please try again"), image/audio load failure (fallback text shown)
- No raw exception messages or stack traces are ever shown to the user
- Loading states show a spinner or skeleton screen — not a blank screen

**Dependencies:** All UI screens from Sprints 1–3 (retrofit)

---

### BEAR-58
**Epic:** System, Settings & Compliance
**Summary:** PDPA consent during registration
**Type:** Story
**Priority:** Must (High)
**Story Points:** 3
**Assignee:** SM (Samy)
**Sprint:** Sprint 4

**User Story:**
As a parent, I want to give explicit consent for my child's data to be collected during registration, so that I trust the app handles my child's information responsibly.

**Acceptance Criteria:**
- During the onboarding flow (after Google Sign-In, before child profile creation), a PDPA consent screen is shown
- Screen displays a clear summary of what data is collected and why
- A link to the full privacy policy is provided (opens in browser)
- Parent must tick a checkbox confirming consent before proceeding — the "Continue" button is disabled until checked
- `consentGiven: true` and `consentTimestamp` are stored in the parent's Firestore document
- If consent is not given (checkbox unchecked and back is pressed), the parent is returned to the sign-in screen and no data is stored
- This screen is retrofitted into the Sprint 1 onboarding flow — regression test full auth flow after implementation

**Dependencies:** BEAR-9, BEAR-11 (retrofitting into existing onboarding screens)

---

### BEAR-59
**Epic:** System, Settings & Compliance
**Summary:** Full account and data deletion
**Type:** Story
**Priority:** Must (High)
**Story Points:** 5
**Assignee:** Dev 2
**Sprint:** Sprint 4

**User Story:**
As a parent, I want to request full deletion of my account and all my child's data, so that I have control over my family's data if I choose to stop using the app.

**Acceptance Criteria:**
- A "Delete Account" option is available in the parent settings screen
- Tapping it shows a confirmation dialog explaining what will be deleted and that it cannot be undone
- On confirmation: all child documents and subcollections are deleted from Firestore, all reward documents under the parent are deleted, the parent user document is deleted, the Firebase Auth account is revoked/deleted
- Deletion cascades through all subcollections (attempts, starTransactions, wrongAnswerBank, levelProgress, questProgress, rewardClaims)
- After deletion, the app returns to the sign-in screen
- A Cloud Function or batched Firestore write handles the cascade deletion

**Dependencies:** Knowledge of all Firestore collections created across Sprints 1–3

---

### BEAR-60
**Epic:** System, Settings & Compliance
**Summary:** Settings screen — account details and sound toggle
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 3
**Assignee:** SM (Samy)
**Sprint:** Sprint 4

**User Story:**
As a parent, I want to update my account details and toggle sound effects in settings, so that I can keep my account information accurate and control the app's audio.

**Acceptance Criteria:**
- A Settings screen is accessible from parent mode
- Displays: account name (display name from Google), email (read-only from Google), option to view privacy policy
- Sound effects on/off toggle — state persisted locally (SharedPreferences); respected by all sound-playing components (BEAR-50)
- A "Delete Account" button links to BEAR-59 flow
- Settings screen is also accessible from child mode for the sound toggle only

**Dependencies:** BEAR-50 (sound effects must exist), BEAR-59 (delete account link)

---

### BEAR-61
**Epic:** System, Settings & Compliance
**Summary:** Final QA, bug fixes, performance, and demo polish
**Type:** Story
**Priority:** Must (High)
**Story Points:** 8
**Assignee:** All
**Sprint:** Sprint 4

**User Story:**
As the team, we want to experience a polished, bug-free app across all completed features, so that the app is stable enough to demo as a working product.

**Acceptance Criteria:**
- All Must stories from Sprints 1–4 pass manual regression testing on a real Android device
- No unhandled exceptions during a full end-to-end demo walkthrough
- No loading spinner exceeds 2 seconds on a standard Android device with a normal connection
- All navigation routes lead to valid screens — no dead ends
- Final demo walkthrough script is prepared and rehearsed at least once
- All GitHub CI checks pass on the main branch (dart format, flutter analyze, unit tests)

**⚠️ Note:** Block the last 3 days of Sprint 4 exclusively for this. No new features after Sprint 4 Day 11.

---

---

### BEAR-72
**Epic:** Bear's Den
**Summary:** Bear's Den — unlock logic, secret tile UI, parent Chapter Insights (BM)
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 5
**Assignee:** Dev 2 (logic) + Dev 1 (UI)
**Sprint:** Sprint 4

**User Story:**
As a student, I want to discover and unlock Bear's Den inside Bahasa Melayu after completing Chapters 1–3, so that I have a special cross-chapter challenge to look forward to.

**Acceptance Criteria:**
- A mysterious locked tile ("???") appears inside the BM chapter map after Chapter 3's summary stage tile — visually distinct from regular locked levels (amber/gold colour, bear paw or cave icon)
- Hint text below the locked tile: "Complete Chapters 1–3 to unlock"
- No tap action in locked state
- Dev 2 implements `checkBearsDenUnlock()` on every session completion: reads `levelProgress` for BM Chapters 1–3; if all basic levels in each chapter have at least 1 star claimed, sets `bearsDenUnlocked = true` on the child document
- On first unlock: tile animates into revealed state showing "Bear's Den" label, cave/bear icon, "Chapter Mix" badge, and "NEW" ribbon
- `bearsDenStarDate` field added to child document (String, "YYYY-MM-DD", used for daily cap enforcement in BEAR-73)
- Unlock conditions are read from Firestore config (`/config/bearsDen`), not hardcoded
- **Parent dashboard — Chapter Insights section** (Dev 2 builds alongside unlock logic, same data):
  - A "Chapter Insights — Bahasa Melayu" card appears on the parent dashboard below subject progress bars
  - Shows each BM chapter with star rating and strength badge: Strong (green, ≥ 80%), Average (yellow, 50–79%), Needs Work (red, < 50%)
  - Strength computed from `levelProgress` stars earned vs max possible (3 × number of basic levels per chapter, excluding summary stage)
  - Note below: "Bear's Den questions are personalised to strengthen weaker chapters"
  - **Parent-facing only** — never rendered in child mode
- Empty state if child has no BM level data: tile shows locked state with hint only; Chapter Insights card shows "Complete some BM lessons to see chapter insights"

**⚠️ Risk:** Dev 2 and Dev 1 must align on the `bearsDenUnlocked` and `bearsDenStarDate` Firestore fields on Sprint 4 Day 1 before either starts building. Dev 2 must not start this story until Must stories (BEAR-57, BEAR-59, BEAR-61) are on track.

**Dependencies:** BEAR-22 (levelProgress data), BEAR-08 (child document structure), Sprint 1/2 level completion flow

---

### BEAR-73
**Epic:** Bear's Den
**Summary:** Bear's Den — cross-chapter AI-weighted session (BM)
**Type:** Story
**Priority:** Should (Medium)
**Story Points:** 5
**Assignee:** Dev 1 (UI) + Dev 2 (logic)
**Sprint:** Sprint 4

**User Story:**
As a student, I want to attempt a Bear's Den session with cross-chapter questions that challenge everything I have learned, so that I strengthen my weaker chapters while earning stars for coming back daily.

**Acceptance Criteria:**
- Tapping the unlocked Bear's Den tile (BEAR-72) generates and starts a 10-question session
- Dev 2 implements `generateBearsDenSession()`: Needs Work chapters → 50% of questions; Average → 30%; Strong → 20%; questions drawn from BM Chapters 1–3 question bank only; shuffled before display (see BT-05 Section 14 for full algorithm)
- Each question shows a small chapter tag in grey below the question text (e.g. "Chapter 2 — Keluarga") — subtle, 11px
- **No "AI Generated" badge** — the AI weighting is invisible to the child
- Session header: "Bear's Den" with cave/bear icon; standard progress bar and timer
- MCQ interaction, mascot feedback, and completion screen are identical to regular level sessions
- Star scoring: ≥ 70% = 1 star; 100% = 2 stars
- Daily cap enforced via `bearsDenStarDate` (set in BEAR-72): if `bearsDenStarDate == today`, session plays normally but no stars awarded
- Completion screen message when stars earned: "Bear's Den complete! Come back tomorrow for more stars ⭐"
- Completion screen message when daily cap hit (no stars): "You already earned your stars today. Come back tomorrow! ⭐"
- Wrong answers flagged to `wrongAnswerBank` as with all other question types
- Session stored as attempt document with `source: "bears_den"` for traceability
- Empty/fallback: if fewer than 3 chapters have data, draw equally from available chapters with no weighting

**⚠️ Sprint 4 priority note:** If Must stories are not complete by Sprint 4 Day 9, BEAR-72 and BEAR-73 move to icebox immediately. Do not delay QA.

**Dependencies:** BEAR-72 (unlock tile and `bearsDenStarDate` field must exist), BEAR-28 (BM question bank complete), BEAR-57 (child Firestore document structure)

---

# SECTION 3 — ICEBOX (Backlog — no sprint assigned)

Create these in the Jira Backlog without assigning them to any sprint. Any developer with spare capacity can drag one into the active sprint.

| Jira ID | Summary | Epic | Story Points | Notes |
|---|---|---|---|---|
| BEAR-62 | Co-parent email invite — Netflix-style family account | Auth & Onboarding | 13 | Email invite; equal permissions; first to approve/reject claim finalises |
| BEAR-63 | Apple Sign-In via Firebase | Auth & Onboarding | 3 | iOS only; Android-first for V1 |
| BEAR-64 | Tablet-optimised responsive layout | Learning Engine | 8 | Flutter responsive breakpoints; phone-first for V1 |
| BEAR-65 | Multilingual app UI — BM, English, Mandarin, Tamil | System | 13 | Flutter intl package; full i18n; English UI for V1 |
| BEAR-66 | Standard 2 KSSR content | Content & Questions | 13 | New question bank; same app structure |
| BEAR-67 | Student leaderboard by star total | Engagement | 8 | Privacy review required for minors |
| BEAR-68 | WhatsApp Business notification channel | System | 8 | Meta Business API; not feasible in academic timeline |
| BEAR-69 | XP experience bar and milestone system | Engagement | 5 | Secondary progression alongside stars |
| BEAR-70 | Advanced AI learning analytics (post-BearAI V1) | BearAI | 13 | Post-BearAI V1; longitudinal trends, learning style classification; requires months of data and ML layer |
| BEAR-71 | In-app purchases and monetisation | System | 13 | Google Play Billing; out of academic project scope |
| BEAR-74 | Bear's Den — second unlock tier (Chapters 4–6) | Bear's Den | 5 | Requires BEAR-72/73 stable and Chapters 4–6 question bank; no code change if Firestore config used |
| BEAR-75 | Bear's Den — multi-subject expansion | Bear's Den | 8 | Expand beyond BM; requires all 5 subject question banks verified |
| BEAR-76 | Bear's Den — parent dashboard session history | Bear's Den | 3 | Filter attempt history by source: bears_den; surface in parent dashboard |
