# BT-06 — Open Items & Post-MVP Roadmap
**Module:** BT-06 | **Version:** 1.0

---

## Section 1 — Remaining Open Questions

These are items that have not yet been fully decided and may need a brief team discussion before or during the sprint they affect.

---

### O1. Minimum Android OS version
**Affects:** Sprint 1 (auth, biometric)
**Question:** What is the minimum Android version the app must support?
**Why it matters:** The `flutter_local_auth` biometric plugin and Google Sign-In have minimum API level requirements. Most modern Android devices support API 23 (Android 6.0) and above, but confirming the target demographic's typical device generation will determine whether to set this higher (API 26+) or lower.
**Recommended default if undecided:** API 23 (Android 6.0) — broadest coverage.
**Owner to resolve:** Dev 2 before Sprint 1 Day 1.

---

### O2. State management library
**Affects:** Sprint 1 (architecture decision)
**Question:** Riverpod, Provider, Bloc, or GetX for Flutter state management?
**Why it matters:** This is an architectural decision that should be made before Sprint 1 begins. Switching later is painful. For a team of 3 developers with mixed Flutter experience, Riverpod or Provider are the most approachable.
**Recommended:** Riverpod 2.x — modern, testable, well-documented.
**Owner to resolve:** All devs, agree in Sprint 1 planning session.

---

### O3. TTS service selection
**Affects:** Sprint 2 (audio questions, ID 23)
**Question:** Which TTS service will be used for audio questions — `flutter_tts` (on-device), Google Cloud Text-to-Speech API (cloud), or another?
**Why it matters:** `flutter_tts` is free and works offline but voice quality is device-dependent and may sound unnatural for a 7-year-old's experience. Google Cloud TTS produces higher quality audio but costs money per character and requires API keys. The audio files could also be pre-generated and stored in Firebase Storage (recommended — no per-request cost, consistent quality).
**Recommended approach:** Pre-generate TTS audio files using Google Cloud TTS during content creation, store in Firebase Storage, link URLs to question documents. This is free at content-creation time and free at runtime.
**Owner to resolve:** Dev 3 before Sprint 2 begins.

---

### O4. Quest conditions — full list for V1
**Affects:** Sprint 3 (quests, ID 39–40)
**Question:** What is the exact quest condition for each of the 6 outfits?
**Why it matters:** The quest unlock logic (BT-05 Section 5) can only be implemented once the conditions are known. The admin CMS can store these, but the initial 6 must be defined before Sprint 3 begins.
**Suggested starting point (confirm or revise):**

| Outfit | Quest condition |
|---|---|
| Scholar Bear | Starter outfit — always unlocked |
| Chef Bear | Complete 5 BM lessons |
| Astro Bear | Score 100% on 3 Maths quizzes |
| Pirate Bear | Complete 10 English lessons |
| Super Bear | Earn 500 stars total |
| Explorer Bear | Complete all Science topics |

**Owner to resolve:** PO + SM, confirm before Sprint 3 planning.

---

### O5. Streak-at-risk notification — configurable time or fixed?
**Affects:** Sprint 2 (ID 31)
**Question:** Is the streak-at-risk notification sent at a fixed time (e.g. 8pm every day) or can the parent configure the time?
**Why it matters:** A fixed time is simpler to implement (Cloud Scheduler at 8pm). A configurable time requires storing the parent's preferred time and scheduling per-user. For V1, fixed is recommended.
**Recommended:** Fixed at 8pm for V1. Parent configurability moves to icebox.
**Owner to resolve:** SM + Dev 2 before Sprint 2.

---

### O6. Wrong-answer review — injection count per session
**Affects:** Sprint 3 (ID 37)
**Question:** How many review questions are silently injected per 10-question level session?
**Recommended:** 2 out of 10 (20%) — enough to surface review without disrupting the lesson flow. If the wrong-answer bank has fewer than 2 questions, inject what is available.
**Owner to resolve:** Dev 1 can default to 2 unless PO overrides.

---

### O7. Tutorial content
**Affects:** Sprint 1 (ID 5)
**Question:** What does the tutorial actually show? How many screens?
**Recommended:** 3–4 simple illustrated overlay screens covering: (1) how to answer a question, (2) what stars are for, (3) how to find the Quests tab. Keep it skippable.
**Owner to resolve:** PO provides copy; Dev 1 implements.

---

### O8. BearAI — Claude API key management approach
**Affects:** Sprint 3 (ID 55)
**Question:** Should the Claude API be called directly from the Flutter app, or proxied through a Firebase Cloud Function?
**Why it matters:** Calling the API directly from Flutter requires the API key to be stored on the device, which is a security risk. A Cloud Function wrapper keeps the key server-side. The Cloud Function approach adds a small latency overhead but is the correct production approach.
**Recommended:** Firebase Cloud Function wrapper for V1. The function receives the assembled context payload from the app, calls the Claude API, and returns the response. This means the API key is never in the Flutter binary.
**Owner to resolve:** Dev 2 before Sprint 3 Day 1.

---

### O9. BearAI — context payload scope and child data fields
**Affects:** Sprint 3 (ID 54, 55)
**Question:** Exactly which Firestore fields are included in the BearAI context payload, and how much session history is sent?
**Why it matters:** Sending too little data makes BearAI responses generic and unhelpful. Sending too much risks exceeding token limits or sending data that is irrelevant. The payload must be designed before the chat UI is built so Dev 2 knows what data to assemble.
**Recommended scope:** Subject progress %, last 14 days of session attempts (date, subject, score, time), current streak, star balances, daily goal status, wrong-answer count by subject. See BT-05 Section 13 for the full payload structure.
**Owner to resolve:** Dev 2 must finalise payload design on Sprint 3 Day 1 before starting ID 54 or 55.

---

### O10. Bear's Den — unlock condition configuration
**Affects:** Sprint 4 (IDs 56, 57)
**Question:** Should the chapter range required to unlock Bear's Den be hardcoded or stored in Firestore config?
**Why it matters:** If hardcoded, adding a second tier (e.g. Chapters 4–6) requires a code change and app update. If stored in Firestore, Dev 2 can configure new tiers without touching the app.
**Recommended:** Store unlock conditions in a Firestore config document (e.g. `/config/bearsDen`) with an array of unlock tiers, each specifying the required chapter IDs and the question pool range. The app reads this at runtime.
**Owner to resolve:** Dev 2 before starting ID 56.

---

These items are intentionally excluded from Sprints 1–4. They are fully documented so any developer with spare capacity can pick one up and understand what is needed without a separate briefing. V1 is complete and functional without any of these.

---

### I-1. Co-parent / Family Account
**Story:** As a parent, I want to invite a co-parent via email so both parents can monitor the same child, so that both parents have real-time equal access without sharing login credentials.

**Design decision (confirmed):**
- Netflix-style email invite — Parent A sends invite to Parent B's email
- Both parents have identical permissions (view dashboard, manage rewards, approve/reject claims)
- Both see pending claims in real time; the first to act finalises the decision
- Neither parent can remove the other without going through a support process (simplification for V1.x)

**What it needs to implement:**
- Email invite system (Firebase Dynamic Links or custom invite token stored in Firestore)
- Co-parent UID stored in child document
- Firestore security rules updated to allow both parent UIDs read/write access to the child's data
- Real-time listener on reward claims for both parents

**Estimated effort:** 1 sprint, primarily Dev 2.

---

### I-2. Apple Sign-In
**Story:** As a parent, I want to sign in with Apple ID in addition to Google, so that I can use my preferred account on iOS devices.

**Why deferred:** Android-first for V1. iOS development not in scope.
**What it needs:** Firebase Auth Apple Sign-In provider; iOS build configuration; App Store account.

---

### I-3. Tablet-Optimised Layout
**Story:** As a student, I want to use the app on a tablet with a layout optimised for the larger screen, so that the experience feels native rather than a stretched phone layout.

**Why deferred:** Phone-first for V1. App should not crash on a tablet but is not optimised.
**What it needs:** Flutter responsive layout breakpoints; separate widget trees or adaptive layouts for large screens.

---

### I-4. Multilingual App UI
**Story:** As a parent, I want to switch the app UI language between BM, English, Mandarin, and Tamil, so that parents and children who prefer a different language can use the app comfortably.

**Why deferred:** Full i18n triples copywriting and testing effort. English UI is sufficient for V1.
**What it needs:** Flutter `intl` package; `.arb` localisation files for all 4 languages; Tamil font support; language selector in settings.
**Estimated effort:** 2 weeks minimum per language pair.

---

### I-5. Standard 2 Content
**Story:** As a student, I want to access Standard 2 content once I complete all of Standard 1, so that I can continue learning and building on what I know.

**Why deferred:** Requires a full new question bank (KSSR Standard 2 for all 5 subjects). No content exists yet.
**What it needs:** Dev 3 to produce Standard 2 question banks; admin CMS already supports uploading new content; revision stage mechanic extends naturally.

---

### I-6. Leaderboard / Ranking
**Story:** As a student, I want to see a leaderboard showing how my star total compares to other students, so that I feel competitive and motivated to earn more stars.

**Why deferred:** Privacy concerns for children's data under PDPA. Sharing a child's name and score publicly requires explicit additional consent and careful data handling.
**What it needs:** Privacy review; opt-in consent for leaderboard participation; Firestore aggregation query or Cloud Function to rank users.

---

### I-7. WhatsApp Notifications
**Story:** As a parent, I want to receive notifications via WhatsApp instead of or in addition to push notifications, so that I stay updated through the channel I use most.

**Why deferred:** WhatsApp Business API requires business verification, a paid account, and approval from Meta. Not feasible within academic project timeline.
**What it needs:** WhatsApp Business API account; webhook integration; phone number collected during registration.

---

### I-8. XP / Experience Bar
**Story:** As a student, I want to earn XP points that fill an experience bar and unlock milestones, so that I have a secondary progression system alongside stars.

**Why deferred:** Nice-to-have secondary engagement loop. Stars and quests are sufficient for V1.
**What it needs:** XP field in child document; XP award rules per action; milestone thresholds; UI bar component.

---

### I-9. Advanced AI Learning Analytics (post-BearAI V1)
**Story:** As a parent, I want to see deeper AI-generated insights about my child's learning traits, cognitive patterns, and long-term strengths, so that I understand not just their scores but how they learn best over time.

**Why deferred:** BearAI V1 (Story 55) covers the core consultation loop — progress summaries, reward recommendations, daily goals, and subject-specific advice grounded in session data. This icebox item refers to a deeper analytics layer: longitudinal trend analysis, learning style classification, and predictive performance modelling. These require significantly more data accumulation and a more sophisticated AI integration than the V1 chat feature.

**What it needs:** Extended Firestore data pipeline; aggregation Cloud Functions; longer data history (months, not days); potentially a fine-tuned model or structured ML layer rather than prompt engineering alone.

---

### I-10. Monetisation
**Story:** As a parent, I want to purchase premium features such as extra outfit packs or detailed analytics, so that I can support the app and access enhanced tools.

**Why deferred:** Outside academic project scope. Revenue model not yet designed.
**What it needs:** In-app purchase integration (Google Play Billing); premium content gating; subscription or one-time purchase model decision.

---

### I-11. Bear's Den — second unlock tier (Chapters 4–6)
**Story:** As a student, I want to unlock a second Bear's Den tier covering Chapters 4–6 once I complete those chapters, so that I have a new cross-chapter challenge as I progress further.

**Why deferred:** MVP is one tier only (Chapters 1–3). The Firestore config structure is designed to support additional tiers without a code change — Dev 2 just adds a second entry to the config document. Expand once the first tier is stable and tested.

**What it needs:** Chapters 4–6 question bank complete (Dev 3); second entry in `/config/bearsDen` Firestore config; verify chapter range themes match.

---

### I-12. Bear's Den — multi-subject expansion
**Story:** As a student, I want to access Bear's Den for all 5 subjects, not just Bahasa Melayu, so that I can do cross-chapter practice in every subject I study.

**Why deferred:** MVP is BM only to keep Stories 56/57 shippable within Sprint 4. The weighting algorithm and session UI are fully reusable — adding a subject is configuring new unlock conditions and pointing to the correct question bank. Expand once BM version is proven stable.

**What it needs:** Verified question banks for all subjects (Dev 3 Sprint 2 work); levelProgress data confirmed populating for non-BM subjects; subject selector in the Bear's Den unlock config.

---

### I-13. Bear's Den — parent dashboard session history
**Story:** As a parent, I want to see my child's Bear's Den session history and results on the parent dashboard, so that I can track how their cross-chapter knowledge is developing over time.

**Why deferred:** Bear's Den attempts are stored as normal attempt documents with `source: "bears_den"` so the data exists from day one. Surfacing it in the parent dashboard is a query filter and a UI card addition — non-complex but not essential for V1 demo.

**What it needs:** Filter parent dashboard attempt history by `source: "bears_den"`; display a "Bear's Den Results" card showing date, score, and chapter breakdown per attempt.
