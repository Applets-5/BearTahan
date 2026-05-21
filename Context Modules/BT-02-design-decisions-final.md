# BT-02 — Design Decisions (Final)
**Module:** BT-02 | **Version:** Final — all decisions confirmed

All decisions below are final unless explicitly reopened by the team. Grouped by area.

---

## A. Core Learning Loop

**A1. Teaching phase or practice-only?**
Practice-only. The app does not include teaching slides or lesson content. Children learn from their KSSR textbooks at school; the app reinforces and tests that learning through practice questions only.

**A2. Questions per session**
- Basic level: 10 questions
- Chapter summary stage: 15 questions
- Wrong-answer review session: 10–20 questions (drawn from personal wrong-answer bank)

**A3. Mid-session exit behaviour**
If the child fully closes the app mid-level, the session is discarded and restarts from Question 1. A warning dialog is shown on exit. There is no session resume. This was chosen to avoid the engineering cost of session state persistence.

**A4. Device model**
Shared device. Both parent and child use the same physical Android phone. The app has two modes: child mode (default on launch) and parent mode (accessed via biometric or PIN). There is no automatic timeout from parent mode — the parent manually returns to child mode.

---

## B. Star & Reward Economy

**B1. Star threshold rules**

*Basic stages — one-time claim per tier:*

| Score | Stars |
|---|---|
| < 50% | 0 |
| ≥ 50% | 1★ |
| ≥ 80% | 2★ |
| 100% | 3★ |

Child can replay to claim unclaimed higher tiers. Once all three tiers are claimed, replaying earns nothing.

*Chapter summary stage — escalating permanent threshold:*

| Child's history | Required score to earn 1 star |
|---|---|
| Never scored ≥ 80% | 80% |
| Has achieved 80% once | 90% |
| Has achieved 90% once | 100% (permanent) |

- Threshold increases only when the child achieves the current threshold
- Threshold never resets — it is permanent and global per child per stage
- At 100% permanently: child earns 1 star per day for every 100% score (no further escalation)
- Daily cap: 1 star per day per chapter summary stage

*Wrong-answer review accumulation:*
Every 20 review questions answered (cross-subject) = 1 star. Counter resets after each star is awarded.

*Star display:*
Two separate counts shown: **Lifetime Earned** (never decreases) and **Available to Spend** (decreases on reward redemption). This preserves positive reinforcement even after spending.

**B2. Reward redemption flow**

1. Child taps Claim → confirmation dialog
2. Stars enter pending state (not yet deducted)
3. Push notification to parent
4. Parent approves → stars deducted, child sees celebration animation
5. Parent rejects → stars returned to available balance, child notified
6. No parent action in 7 days → claim expires, stars automatically returned
7. Child cannot cancel a pending claim — must ask parent to reject
8. Stars deducted only after parent approval, never on claim

---

## C. Review System

**C1. What "review" means in BearTahan**
Review = wrong-answer recovery only. It is not a time-based Ebbinghaus spaced repetition scheduler. The escalating threshold of the chapter summary stage serves as the app's equivalent of spaced repetition practice.

**C2. Review implementation — Hybrid (Option C)**
- **Dedicated section**: "Bear's Memory Challenge" tab/banner on child home screen. Appears when pending wrong-answer questions exist. Child taps in deliberately. Stars earned via 20-question accumulation counter.
- **Silent injection**: Wrong-answer questions are quietly mixed into regular level sessions without the child's knowledge. Normal level scoring applies.

---

## D. Authentication & Devices

**D1. Login method**
Google Sign-In via Firebase Auth. This covers registration, login, and session management. No separate email/password system. Apple Sign-In is a post-MVP nice-to-have; not required for V1.

**D2. Parent mode switch**
Biometric authentication (fingerprint) is the primary method. PIN is the fallback for devices without biometric support. PIN is set up during onboarding. The Switch to Parent Mode button is visible on the child's home screen — it does not need to be hidden.

**D3. Co-parent accounts**
Not in V1. Big-picture design: Netflix-style family account where Parent A sends an email invite to Parent B. Both have equal permissions. Both see reward claims in real time. Either can approve or reject; once one acts, the decision is final for both. This is documented as an icebox item (I-1) for post-MVP implementation.

---

## E. Content & Localisation

**E1. Chinese script**
Simplified Chinese. Confirmed against KSSR Mandarin textbooks used in SJKC schools.

**E2. Mandarin writing**
Stroke tracing is included in V1. The child traces characters on a canvas in correct stroke order. Scope is limited to simple Standard 1 characters only. This is a significant engineering effort and is assigned to Developer 1 as a dedicated Sprint 3 task.

**E3. App UI language**
English for V1. Full multilingual UI (BM, Mandarin, Tamil) is a post-MVP roadmap item. The subject content is naturally in the appropriate language (BM questions in Malay, Mandarin questions in Chinese, etc.) but the UI chrome — buttons, labels, navigation — is in English.

**E4. Audio content**
Text-to-speech (TTS) service for V1. Developer 3 manages the TTS pipeline alongside question bank creation. Native speaker recordings are a post-MVP quality improvement.

**E5. Content creation process**
AI-assisted drafting → Developer 3 human review → upload to Firestore via admin CMS. Developer 3 is the named content owner. Maths uses parametric generation (no manual bank). TTS is generated at the same time as questions are created.

---

## F. Non-Functional Decisions

**F1. Target platform**
Android. iOS is post-MVP. Minimum Android OS version: TBC (check Flutter/Firebase minimum support for target device demographics).

**F2. Offline mode**
None. The app requires an active internet connection at all times. If no connection is detected, the app shows a "Please connect to the internet" screen and does not allow access to lesson content. Chosen to avoid local caching, sync logic, and data consistency complexity.

**F3. Device form factor**
Phone-first layout. Tablet-compatible layout is an icebox item — the app should not break on a tablet but is not optimised for it in V1.

**F4. Revision stage unlock condition**
Unlocked after a child completes all chapters in any one subject. Uses the same escalating threshold and daily cap mechanics as the chapter summary stage. Questions are drawn from the full subject question bank (cross-chapter mix).

**F5. Streak counting**
Calendar day (12:00am to 12:00am). A child who plays at 11:50pm and again at 12:10am is counted as playing on two different days. Streak is broken if no session is completed within a calendar day.

**F6. Password / account recovery**
Google Sign-In handles account recovery natively. No custom password reset flow needed.

---

## G. Additional Decisions (Post-Agenda)

**G1. Counting-up timer**
A counting-up timer is visible to the child during every level session. It does not affect scoring or stars. Time data is stored per session and displayed on the parent dashboard as both per-level time and daily total learning time.

**G2. Mascot and outfit system**
One bear character with interchangeable outfits (skins). Not separate bear characters. The starter outfit is always available. Additional outfits are unlocked via quest completion. Locked outfits are shown as silhouettes in the Quests tab to hook curiosity without revealing the design.

**G3. Quest system**
A dedicated Quests tab shows all missions with progress bars. Each mission corresponds to unlocking one outfit. Quest conditions are defined in the admin CMS (e.g. "Score 100% on 3 Maths quizzes"). Quest progress is tracked per child. Locked outfits are displayed as silhouettes — the child knows something is there but cannot see what it looks like.

**G4. Revision stage mechanics**
The revision stage is unlocked per subject (not per the entire app). When a child completes all chapters in Maths, a Maths revision stage unlocks. It draws from all Maths questions across all chapters in a single randomised session. Escalating threshold and daily star cap apply identically to the chapter summary stage.

## H. BearAI — AI Parent Consultation

**H1. BearAI scope and approach**
BearAI is an AI-powered chat consultation feature in the parent dashboard. It is not a general-purpose chatbot — it is scoped specifically to helping parents understand their child's in-app learning activity and make better decisions about rewards, goals, and subject focus.

The feature has two components:
- An AI insight card that auto-generates a 2–3 sentence summary of the child's recent activity after each session
- A chat interface where parents ask free-form questions or tap suggestion chips

BearAI uses the Claude API (Anthropic) with the child's Firestore data passed as context in the system prompt. The model is not fine-tuned — prompt engineering is used to constrain it to the child learning consultation role. Responses are grounded in real data (subject progress, session history, streak, star balance, wrong-answer patterns by subject).

Conversation history is not persisted across sessions in V1. This simplifies implementation and avoids storing sensitive conversational data under PDPA.

**H2. BearAI addresses the AI Integration judging criterion**
BearAI is the primary AI integration in BearTahan. It is user-facing, interactive, and grounded in real child data — not a backend pipeline. This directly satisfies the "AI Integration" sub-criterion in the Functionality & Technical Implementation judging area.

---

## I. Bear's Den — AI Adaptive Cross-Chapter Challenge

**I1. What Bear's Den is**
Bear's Den is a secret cross-chapter mixed-question session that lives inside a subject's chapter map, unlocking after the child completes a defined chapter range. It is not a test paper and it is not on the home screen. It is a game-style secret level that rewards daily revisits with stars while quietly targeting the child's weaker chapters through AI-weighted question selection.

**I2. Placement decision — inside subject, not home screen**
Bear's Den is accessed by tapping into a subject and scrolling to the special tile at the bottom of the chapter range. Before unlocking it appears as a mysterious locked tile ("???") with a golden glow — distinct from regular locked levels. After unlocking it reveals itself with the Bear's Den name and icon. This placement keeps it discoverable but not intrusive — children find it as a natural part of exploring their subject.

**I3. Analytics are parent-facing only**
The chapter strength breakdown (Strong / Average / Needs Work) is shown exclusively on the parent dashboard under "Chapter Insights." Children never see their weakness labels — they just experience Bear's Den as a fun cross-chapter challenge. The AI weighting is invisible to the child.

**I4. Unlock condition**
V1 MVP: BM only, one tier. Unlocks after the child completes all basic levels in Chapters 1–3 of Bahasa Melayu. Chapter ranges and unlock conditions are stored in Firestore config — not hardcoded — so the team can add a second tier (e.g. Chapters 4–6) or expand to other subjects without a code change.

**I5. Star logic**
- ≥ 70% score = 1 star; 100% = 2 stars
- Daily cap: max 2 stars per calendar day per Bear's Den unlock (12am–12am)
- Designed to motivate daily revisits — children come back each day to earn their 2 stars
- Stored via `bearsDenStarDate` field on the child document (same pattern as `lastSummaryStarDate`)

**I6. Bear's Den as the third AI feature**
Bear's Den joins stroke tracing (Mandarin) and BearAI (parent consultation) as the third AI feature in BearTahan. The AI layer is the question weighting algorithm that selects from completed chapters weighted toward weak areas. This is data-driven AI, not a language model — it operates on the child's existing `levelProgress` star data already in Firestore.

**G5. Mobile framework**
Flutter (Dart) + Firebase. This was decided outside the formal agenda. Flutter for the mobile app; Firebase for Auth (Google Sign-In), Firestore (database), and FCM (push notifications).
