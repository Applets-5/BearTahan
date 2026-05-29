# BearTahan — Functional Requirements
**Module:** BT-01  
**Status:** Rough draft — subject to team review  
**Last updated:** April 2026

---

## Overview

BearTahan is a gamified mobile learning app for Malaysian Standard 1 (Year 1) students, aligned with the KSSR syllabus. It serves two user groups simultaneously: children who experience it as a game, and parents who use it as a monitoring and motivation tool. The core loop is: child learns → earns stars → parent sets real-world rewards → child redeems.

---

## 1. Authentication & Account Management

- Parent creates a master account using email and password
- Parent can log in and out across sessions
- One parent account can hold multiple child profiles
- Child profiles are accessed from within the parent account — children do not have their own login credentials
- Parent-side features (dashboard, reward management, settings) must be protected from child access (PIN or equivalent)
- Session persistence: parent stays logged in across app restarts unless they explicitly log out

---

## 2. Onboarding & First-Time Setup

- On first launch, parent completes registration before any child-facing content is accessible
- After registration, parent creates at least one child profile (name, age/class, school type)
- Child selects a mascot/avatar during first login to their profile — this creates ownership
- A brief tutorial walkthrough introduces the app to the child before their first lesson
- Consent for data collection is obtained from the parent during registration (PDPA compliance)

---

## 3. Subject & Chapter Navigation

- Five subjects available: Bahasa Melayu, English, Mandarin (华语), Mathematics, Science
- Content is organised by subject → chapter → level, mirroring the KSSR Standard 1 textbook structure
- Chapter and level progression is linear — a level must be completed before the next unlocks
- Locked levels are visible but not accessible, giving the child a sense of the road ahead
- Child can freely navigate between subjects from the home screen
- Progress bars per subject are visible on the home screen

---

## 4. Level & Lesson Structure

- Each level contains a fixed set of questions drawn from its chapter's question bank
- A level session consists of: question sequence → completion screen → star award
- The completion screen shows the child's score, stars earned, and a mascot celebration
- If a child exits mid-level, progress for that session is not saved — they restart from question 1
- Two stage types exist within each chapter:
  - **Basic stages** — fixed question bank, one-time star claim per star tier
  - **Chapter summary/review stage** — randomised question pool, repeatable daily with escalating thresholds

---

## 5. Question Engine & Interaction Types

- **MCQ tap** — child taps one of 4 answer options (primary interaction type for V1)
- **Drag-and-drop** — child drags an answer to the correct position (V1 scope)
- **Audio-listen-and-select** — audio clip plays, child selects the matching answer
- Questions may include images, audio, or text — or a combination
- After each answer, immediate feedback is shown: mascot reacts, correct answer highlighted
- Positive reinforcement only — no lives lost, no negative score deduction
- Mathematics questions use parametric generation (random number pairs within defined ranges) to produce effectively unlimited questions without a manual bank
- Question count per level session to be confirmed during team discussion

---

## 6. Scoring & Star Earning Logic

- Stars are the primary currency and reward unit of the app
- **Basic stage rules:**
  - Score ≥ 50% → 1 star (claimable once only per star tier, regardless of replays)
  - Higher tiers (2★, 3★) require higher score thresholds — exact values TBC
- **Chapter summary/review stage rules:**
  - Randomised questions each session; can be repeated daily
  - Star thresholds escalate across attempts (exact escalation logic TBC)
  - Daily cap on bonus star earning from review stages
- Stars are never deducted as punishment — only spent voluntarily on reward redemption
- Two balances are tracked: **lifetime earned** (never decreases) and **available to spend** (decreases on redemption)
- Star history is viewable by both child and parent

---

## 7. Spaced Repetition Engine

- The app surfaces previously completed questions on a schedule based on the Ebbinghaus Forgetting Curve
- Questions from lessons completed several days ago are re-queued for review
- Implementation approach (dedicated Review section vs. silent injection into sessions) TBC
- Review sessions earn stars to incentivise engagement

---

## 8. Cosmetics, Outfits & Mascot System

- Child selects a base mascot during onboarding
- Additional outfits are unlocked by completing specific in-app achievements (e.g. complete 5 BM lessons, score 100% in 3 Math quizzes)
- One outfit is active at a time; child can change their active outfit from the Outfits screen
- The active outfit is reflected on the child's home screen and throughout the app
- Locked outfits are visible with their unlock condition displayed
- V1 includes 6 outfits as shown in the mockup (Scholar, Chef, Astro, Pirate, Super, Explorer)

---

## 9. Reward Management & Redemption

- Parent creates custom real-world rewards with a name, emoji/icon, and star cost (e.g. "Ice Cream Treat = 200 stars")
- Parent can edit or delete existing rewards at any time
- Child views their reward list and progress toward each on the Rewards screen
- Redemption flow: child taps Claim → confirmation dialog → parent notified → parent confirms delivery → stars deducted from available balance
- Exact redemption trigger and approval loop TBC during team discussion
- Suggested star costs are shown to the parent as a guide during reward creation

---

## 10. Parent Progress Dashboard

- Parent sees an overview of each child's: total stars, lessons completed, current streak, and per-subject progress percentage
- Subject progress breakdown shows lessons done, stars earned, and approximate mastery level
- Parent can switch between child profiles from the dashboard if multiple children are registered
- Data refreshes in real time as the child completes sessions

---

## 11. Daily Goals & Notifications

- Parent sets a daily learning goal per child (number of lessons or minutes of learning)
- Child sees their daily goal progress on the home screen
- Push notifications are sent to the parent for: daily goal met, chapter completed, reward claimed by child, streak at-risk (child has not practised by a configurable time)
- Parent can configure which notifications they receive
- Notification channel: push notification (V1); WhatsApp integration is a post-MVP consideration

---

## 12. Multi-Child Management

- Parent can add more than one child profile under the same account
- Switching between children in the parent dashboard shows that child's data only
- Each child profile is fully independent (separate progress, stars, outfits, and rewards)

---

## 13. Content Management (Internal Admin)

- An internal admin tool allows the team's content creator to manage the question bank without developer involvement
- Admin can: create a question, assign it to a subject/chapter/level, set question type, upload image or audio, enter answer options and mark the correct one
- Content is versioned so updates do not break active sessions
- Math parametric questions are configured via rules (number ranges, operation type) rather than individual entries

---

## 14. Media Asset Pipeline

- Audio files (pronunciation, question audio) are pre-recorded by a native speaker or generated via approved TTS and stored per question
- Images are uploaded and linked to individual questions via the admin tool
- Mascot animations and sound effects are bundled with the app build
- Assets are delivered via CDN for performance

---

## 15. Settings, Privacy & Compliance

- Sound effects on/off toggle (child-accessible)
- Notification preferences (parent-accessible)
- Account details and password change (parent-accessible)
- Data deletion: parent can request deletion of their account and all associated child data
- PDPA compliance: explicit consent obtained during registration, data handling policy visible in settings
- No data collected on children beyond what is necessary for app function

---

## Out of Scope for V1

The following are documented as post-MVP roadmap items and should not be included in Sprint 1–4 planning:

- Leaderboard and ranking system
- Monetisation (premium insights, paid outfits, exam modules)
- AI-generated trait and personality analytics
- Full UI language switching (BM / English / Mandarin)
- Chinese character stroke-order tracing
- WhatsApp notification channel
- Standard 2+ content
- Experience/XP bar system

---

*Next document: BT-02 — Design Decisions & Meeting Agenda*
