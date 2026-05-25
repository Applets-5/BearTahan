# BT-04 — Sprint Plans
**Module:** BT-04 | **Version:** 1.1
**Team:** SM (Samy) · Dev 1 (Core UI) · Dev 2 (Backend) · Dev 3 (Content) · Dev 4 (Engagement)

---

## Sprint 1 — Core Learning Loop
**Duration:** Weeks 1–2
**Goal:** A child can open the app, complete a BM lesson, and earn stars. Parent can view basic progress in a read-only dashboard.
**End-of-sprint demo:** Live on a real Android device — parent logs in with Google, creates a child profile, picks a mascot outfit, taps BM Chapter 1, completes a 10-question MCQ session, sees completion screen with stars earned, parent switches to parent mode and views dashboard.
**End-of-sprint demo:** Live on a real Android device — parent logs in with Google, creates a child profile, picks a mascot outfit, taps BM Chapter 1, completes a 10-question MCQ session, sees completion screen with stars earned, parent switches to parent mode and views dashboard.

---

### Story assignments

| ID | Story summary | Priority | Owner | Notes |
|---|---|---|---|---|
| 1 | Google Sign-In via Firebase | Must | Dev 2 | First task — everything else depends on auth |
| 2 | Biometric / PIN parent mode switch | Must | Dev 2 | Spike flutter_local_auth on Day 1 on target device |
| 3 | Create child profile | Must | Dev 2 | Stored in Firestore under parent UID |
| 4 | Mascot outfit selection on first login | Must | Dev 4 | Starter outfit only; no unlock logic yet |
| 5 | Tutorial walkthrough | Should | SM (Samy) | 3–4 simple overlay screens; skippable; defer to Sprint 2 if Sprint 1 is tight |
| 6 | Kids home screen — subjects + progress bars | Must | Dev 1 | Depends on ID 3 (child profile must exist) |
| 7 | Star balance display on home screen | Must | Dev 1 | Show spendable balance; depends on ID 16 |
| 8 | Subject → chapter → level navigation | Must | Dev 1 | Linear locking logic |
| 9 | Locked level display | Should | Dev 1 | Greyed out with lock icon |
| 10 | MCQ tap question type | Must | Dev 1 | Core interaction — highest priority for Dev 1 |
| 11 | Answer feedback (visual + mascot) | Must | Dev 1 | Depends on ID 10 |
| 12 | Positive reinforcement — no star deduction | Must | Dev 1 | Logic rule, not a separate component |
| 13 | Counting-up timer | Should | Dev 4 | Simple stopwatch visible to child; store elapsed time per session in Firestore |
| 14 | Level completion screen | Must | Dev 1 | Score + stars + mascot celebration |
| 15 | BM Chapter 1 seed question bank | Must | Dev 3 | ~10 questions minimum; JSON uploaded to Firestore by Day 3 |
| 16 | Star earning logic (basic level thresholds) | Must | Dev 2 | 0/1/2/3 star tiers; one-time claim per tier; write to Firestore |
| 17 | Parent dashboard — read-only | Must | Dev 2 | Stars, lessons, streak, per-subject % |
| 18 | No internet — error screen | Must | SM (Samy) | Simple connectivity check on app launch |

### SM (Samy) — Sprint 1 non-dev responsibilities
- Set up Flutter project, Firebase project, and connect to Firestore + Firebase Auth
- Set up GitHub repository, branching strategy, and CI basics
- Conduct Sprint 1 planning, daily standups (x10), Sprint 1 review and retrospective
- Prepare initial product backlog submission for university deadline

---

### Dependencies

```
ID 1 (auth)          → ID 2, 3
ID 3 (child profile) → ID 6, 7, 16, 17
ID 10 (MCQ)          → ID 11, 12, 14
ID 14 (completion)   → ID 16
ID 15 (BM content)   → ID 10 (needs data to render questions)
ID 16 (star logic)   → ID 7 (balance display)
```

### Risks
- **ID 2 (biometric):** `flutter_local_auth` behaves differently across Android versions. Dev 2 must spike this on Day 1 on the target test device before building any other auth flows around it.
- **ID 15 (content):** Dev 3 must have BM Chapter 1 questions in Firestore by Day 3 or the question engine has no real data to test against.
- **ID 5 (tutorial):** Should priority — defer to Sprint 2 if Sprint 1 runs tight. Flag during Day 7 standup.
- **SM project setup:** Samy must have the Flutter + Firebase project skeleton ready on Day 1 so all four developers can begin work in parallel without waiting on each other.

### Definition of done — Sprint 1
- [ ] Parent signs in with Google on a real Android device
- [ ] Parent creates a child profile
- [ ] Child selects a mascot outfit
- [ ] Child navigates to BM Chapter 1 and completes a 10-question MCQ session
- [ ] Correct/incorrect feedback shown after each answer with mascot reaction
- [ ] Completion screen shows score and correct star count
- [ ] Star balance visible on home screen and updates after level completion
- [ ] Parent switches to parent mode via biometric or PIN and sees read-only dashboard

---

## Sprint 2 — Full Content & Parent Tools
**Duration:** Weeks 3–4
**Goal:** All 5 subjects playable. Chapter summary stage working. Parents can set daily goals, create rewards, and receive push notifications.
**End-of-sprint demo:** Child plays a Maths parametric session and an English session. Parent creates a "Trip to the Park = 300 stars" reward and sets a daily goal of 3 lessons. Streak counter visible on child home screen.
**End-of-sprint demo:** Child plays a Maths parametric session and an English session. Parent creates a "Trip to the Park = 300 stars" reward and sets a daily goal of 3 lessons. Streak counter visible on child home screen.

---

### Story assignments

| ID | Story summary | Priority | Owner | Notes |
|---|---|---|---|---|
| 19 | Password reset (email) | Should | Dev 2 | Firebase handles natively; low effort |
| 20 | All 5 subjects — full question banks | Must | Dev 3 | Largest content effort; must begin Day 1 of Sprint 2 |
| 21 | Maths parametric generation | Must | Dev 2 (logic) + Dev 3 (rules) | Dev 2 builds generator; Dev 3 defines number ranges per chapter in admin config |
| 22 | Drag-and-drop question type | Should | Dev 4 | Use Flutter Draggable / DragTarget widgets |
| 23 | TTS audio playback on questions | Should | Dev 3 | Dev 3 pre-generates audio files; stored in Firebase Storage; Dev 1 integrates audio player widget |
| 24 | Chapter summary stage | Must | Dev 1 (UI) + Dev 3 (content) | Dev 1 builds stage UI and escalating threshold UI; Dev 3 seeds questions for summary pools |
| 25 | Parent creates custom rewards | Must | Dev 2 | Stored in Firestore per child |
| 26 | Parent edits/deletes rewards | Should | Dev 2 | CRUD on reward documents |
| 27 | Parent sets daily goal | Should | Dev 2 | Goal stored per child; child sees progress on home |
| 28 | Push notification — goal completed | Should | Dev 2 | FCM; trigger when session count or minutes reach goal |
| 29 | Push notification — reward claimed | Should | Dev 2 | FCM; trigger on claim creation (full claim flow Sprint 3; notification here) |
| 30 | Daily streak counter | Should | Dev 4 | Calendar-day logic (12am–12am); visible on child home screen |
| 31 | Streak-at-risk notification | Could | Dev 2 | FCM; Cloud Function scheduled at 8pm if no session that day |

### SM (Samy) — Sprint 2 non-dev responsibilities
- Sprint 2 planning, daily standups, Sprint 2 review and retrospective
- Wireframe review session with full team (university deadline)
- Unblock any dev dependencies surfaced in standups
- Begin drafting sprint 3 plan based on Sprint 2 velocity

---

### Dependencies

```
ID 20 (all subject banks)   → ID 22, 23, 24 (need content to test interactions)
ID 21 (Maths parametric)    → Dev 3 must provide number range config before Dev 2 codes the generator
ID 24 (summary stage)       → Dev 2 must design Firestore structure for escalating threshold before Dev 1 builds UI
ID 25 (create rewards)      → ID 26 (edit/delete)
ID 27 (daily goal)          → ID 28 (goal notification)
ID 30 (streak)              → requires session timestamp tracking from Sprint 1
```

### Risks
- **ID 20 (all 5 question banks):** Highest risk item. Dev 3 must produce banks for all 5 subjects by mid-Sprint 2. Start on Day 1 — no other work first.
- **ID 24 (summary stage threshold):** Escalating threshold requires a per-child per-stage persistent counter. Dev 2 must design the Firestore structure before Dev 1 builds the UI. Align on Day 1 of Sprint 2.
- **ID 23 (TTS audio):** If TTS service is not selected by Sprint 2 start, audio questions ship as text-only for the demo. See BT-06 O3.

### Definition of done — Sprint 2
- [ ] All 5 subjects navigable with real KSSR questions
- [ ] Maths generates random questions correctly within configured ranges
- [ ] Drag-and-drop questions render and validate correctly
- [ ] Chapter summary stage is repeatable with random questions and tracks escalating threshold
- [ ] Parent can create, edit, and delete custom rewards
- [ ] Parent can set a daily goal; child sees progress on home screen
- [ ] Push notification fires when child completes daily goal
- [ ] Streak counter visible on child home screen and increments correctly

---

## Sprint 3 — Engagement & Reward Loop
**Duration:** Weeks 5–6
**Goal:** Full star economy end-to-end. Review system live. Quests and outfits working. Mandarin stroke tracing complete.
**End-of-sprint demo:** Child claims a reward → parent approves → stars deducted and celebration shown. Child sees Bear's Memory Challenge. Child completes a quest and unlocks a new outfit. Mandarin stroke tracing demonstrated. BearAI tab visible with insight card and chat working.
**End-of-sprint demo:** Child claims a reward → parent approves → stars deducted and celebration shown. Child sees Bear's Memory Challenge. Child completes a quest and unlocks a new outfit. Mandarin stroke tracing demonstrated.

---

### Story assignments

| ID | Story summary | Priority | Owner | Notes |
|---|---|---|---|---|
| 32 | Child claims reward — pending flow | Must | Dev 2 | Stars go to pending state; push notification sent to parent |
| 33 | Parent approves/rejects claim | Must | Dev 2 | Approve deducts stars; reject returns them; 7-day expiry |
| 34 | Lifetime vs. spendable star display | Should | SM (Samy) | Two separate counters in Firestore (Dev 2 in Sprint 1); Samy builds the UI display |
| 35 | Star history / transaction log UI | Should | SM (Samy) | Log already written by Dev 2 in earlier sprints; Samy builds the display screen |
| 36 | Bear's Memory Challenge dedicated section | Should | Dev 1 (UI) + Dev 2 (logic) | Dev 2 builds wrong-answer query and accumulation counter; Dev 1 builds the UI section |
| 37 | Silent injection of review questions | Should | Dev 1 | Inject 2 from wrong-answer bank into each 10-question session; shuffle final set |
| 38 | Review accumulation star earning (20 = 1★) | Should | Dev 2 | Global counter per child; resets on star award |
| 39 | Quest unlock logic — outfit per mission | Should | Dev 4 | Quest conditions read from Firestore; check on session complete |
| 40 | Quests tab — progress bars + silhouettes | Should | Dev 4 | Silhouette for locked outfits; full image for unlocked |
| 41 | Outfit selection and active outfit persistence | Should | Dev 4 | Active outfit stored per child; reflected across all mascot surfaces in app |
| 42 | Sound effects and mascot animations | Should | Dev 4 | Bundle assets in Flutter; trigger on correct answer, level complete, quest unlock events |
| 43 | Timer data on parent dashboard | Should | Dev 2 | Per-level elapsed time and daily total; query from attempt documents |
| 44 | Mandarin stroke tracing | Must | Dev 4 (dedicated) | Canvas drawing + stroke order validation; limited to simple Std 1 characters; see BT-05 §9 |
| 45 | Multi-child — add profile + switch | Should | Dev 2 | Second child profile creation; profile switcher in parent mode dashboard |
| 54 | BearAI insight card | Should | Dev 2 | Auto-generated 2–3 sentence summary of child's recent activity; displayed at top of BearAI tab in parent dashboard; generated via Claude API call with child Firestore data as context |
| 55 | BearAI chat interface | Must | Dev 2 | Full chat UI in parent dashboard BearAI tab; suggestion chips; free-form questions; Claude API with child data context payload; conversation not persisted across sessions |

### SM (Samy) — Sprint 3 non-dev responsibilities
- Sprint 3 planning, daily standups, Sprint 3 review and retrospective
- ID 34 and 35 are Samy's dev stories — UI work building on top of Firestore data Dev 2 already wrote
- Monitor stroke tracing (ID 44) progress closely — escalate by Day 7 if not functional

---

### Dependencies

```
ID 32 (claim)             → ID 25 (rewards must exist from Sprint 2)
ID 33 (approve/reject)    → ID 32
ID 34, 35 (star UI)       → Firestore star transaction structure from Dev 2 Sprint 1/2
ID 36, 37, 38 (review)    → Wrong-answer flag data must exist from Sprint 1/2 sessions
ID 39 (quest unlock)      → ID 41 (outfit selection must exist first)
ID 40 (quests tab)        → ID 39
ID 44 (stroke tracing)    → Dev 3 must supply character stroke order data for target Std 1 characters
ID 54 (BearAI insight)    → Firestore child data must be populated from Sprint 1/2 sessions; Claude API key must be configured
ID 55 (BearAI chat)       → ID 54 (insight card and BearAI tab must exist first); Claude API key configured; child Firestore context payload designed by Dev 2 before UI work begins
```

### Risks
- **ID 44 (stroke tracing):** Highest-risk item in the entire project. Dev 4 must start this on Day 1 of Sprint 3. If not functional by mid-sprint, escalate to full team immediately. Fallback plan: Mandarin ships as recognition-only for V1 and stroke tracing moves to icebox.
- **ID 36–38 (review system):** Requires wrong-answer data from Sprint 1 and 2 sessions. If no real test sessions have been played, seed test data before the Sprint 3 demo.
- **ID 55 (BearAI chat):** Requires Claude API key to be provisioned and the child data context payload to be designed before Dev 2 starts building the chat UI. Dev 2 must spike the API call and context structure on Day 1 of Sprint 3. If API integration proves too complex within sprint, fallback plan is hardcoded mock responses for the demo — flag by Day 7.

### Definition of done — Sprint 3
- [ ] Child can claim a reward; stars show as pending; parent receives notification
- [ ] Parent can approve or reject; star balances update correctly on both sides
- [ ] Bear's Memory Challenge appears when wrong-answer questions exist
- [ ] Review accumulation counter awards a star at every 20 questions answered
- [ ] At least 2 quests visible with progress bars; completing a quest unlocks an outfit
- [ ] Active outfit change reflects across the app
- [ ] Mandarin stroke tracing works for at least 5 Standard 1 characters
- [ ] Timer data visible on parent dashboard
- [ ] BearAI tab visible in parent dashboard with AI insight card populated from real child session data
- [ ] Parent can send a message in BearAI chat and receive a contextually relevant response grounded in child data

---

## Sprint 4 — Stability & Handoff
**Duration:** Weeks 7–8
**Goal:** All edge cases handled. Admin CMS live. PDPA compliance complete. App is stable for final demo.
**End-of-sprint demo:** Full end-to-end walkthrough from registration to reward redemption. Admin CMS demonstrated. Error states shown. Data deletion flow demonstrated. Bear's Den unlocked and session played if Sprint 4 capacity allows.
**End-of-sprint demo:** Full end-to-end walkthrough from registration to reward redemption. Admin CMS demonstrated. Error states shown. Data deletion flow demonstrated.

---

### Story assignments

| ID | Story summary | Priority | Owner | Notes |
|---|---|---|---|---|
| 46 | Revision Stage (post-subject completion) | Should | Dev 1 (UI) + Dev 3 (content pool) | Same mechanics as summary stage; Dev 3 confirms content pool; Dev 1 builds stage screen |
| 47 | Parent notification preferences | Could | Dev 2 | Per-event toggles in settings |
| 48 | Internal admin CMS | Must | Dev 2 | Web-based; CRUD questions, configure Maths rules, set quest conditions |
| 49 | Error and empty states | Should | SM (Samy) | No questions, no internet, first-time empty dashboard, loading states |
| 50 | PDPA consent during registration | Must | SM (Samy) | Checkbox + policy link retrofitted into Sprint 1 onboarding flow; consent stored in Firestore |
| 51 | Full account and data deletion | Must | Dev 2 | Delete all Firestore documents under parent UID; revoke Firebase Auth |
| 52 | Account details / settings screen | Should | SM (Samy) | Display and update account name/email display |
| 53 | QA, bug fixes, performance, polish | Must | All | Block last 3 days of Sprint 4 exclusively for this |
| 56 | Bear's Den — unlock logic, secret level UI, parent chapter analytics | Should | Dev 1 (UI) + Dev 2 (logic) | Dev 2: compute chapter strength from levelProgress, write bearsDenStarDate field, surface Chapter Insights on parent dashboard; Dev 1: build secret locked tile and unlocked tile inside BM chapter map; BM + Chapters 1–3 only |
| 57 | Bear's Den — cross-chapter session | Should | Dev 1 (UI) + Dev 2 (logic) | Dev 2: implement AI question weighting algorithm; Dev 1: build session UI with chapter tag per question, completion screen with daily star cap message; depends on ID 56 |

### SM (Samy) — Sprint 4 non-dev responsibilities
- Sprint 4 planning, daily standups, Sprint 4 final review and retrospective
- Coordinate final demo rehearsal — every demo path must be confirmed working
- IDs 49, 50, 52 are Samy's dev stories for this sprint

---

### Dependencies

```
ID 46 (revision stage)  → Requires a subject to be fully completed; may need test data seeded
ID 48 (admin CMS)       → Should be prioritised early in Sprint 4 so Dev 3 can update content for demo
ID 50 (PDPA)            → Retrofitted into Sprint 1 onboarding screens; regression test auth flow after
ID 51 (data deletion)   → Requires knowing all Firestore collections created across Sprints 1–3
ID 56 (Bear's Den unlock + parent analytics) → Requires levelProgress data from completed BM Chapters 1–3; seed test data if needed; Dev 2 and Dev 1 must align on Firestore field (bearsDenStarDate) before Dev 1 builds UI
ID 57 (Bear's Den session)               → Depends on ID 56 completing first; BM question bank (ID 48 admin CMS) must be ready
ID 53 (QA)              → Block last 3 days of Sprint 4 — no new features after Day 11
```

### Risks
- **Admin CMS (ID 48):** If not ready by Sprint 4 Day 5, Dev 3 cannot update content for the final demo without developer intervention. Prioritise above Should items at Sprint 4 start.
- **PDPA retrofit (ID 50):** Modifies existing Sprint 1 onboarding screens. Dev 2 must coordinate with SM (Samy) and regression-test the full auth flow after the change.
- **Bear's Den (IDs 56, 57):** Should priority — if Must items (48, 50, 51) are not on track by Sprint 4 Day 9, IDs 56 and 57 move to icebox immediately. Do not let them delay QA. Dev 2 must not start ID 56 until IDs 48, 50, and 51 are complete or clearly on track. Note: the parent Chapter Insights UI (part of ID 56) can be built independently of the child-facing unlock tile if Dev 1 and Dev 2 split the work early.
- **Sprint 4 buffer:** Last 3 days are QA only. Any Should/Could items not complete by Day 11 move to icebox.

### Definition of done — Sprint 4
- [ ] Admin CMS allows content creation without developer involvement
- [ ] PDPA consent is collected during registration and stored in Firestore
- [ ] Account and data deletion works completely (Firestore + Firebase Auth)
- [ ] All error and empty states show friendly messages — no blank screens or unhandled exceptions
- [ ] Revision stage unlocks after completing all chapters in any one subject
- [ ] Bear's Den secret tile appears locked inside BM chapter map before Chapters 1–3 are complete
- [ ] Bear's Den unlocks and becomes tappable after all basic levels in BM Chapters 1–3 are finished
- [ ] Bear's Den session delivers 10 AI-weighted cross-chapter questions with chapter tags visible
- [ ] Stars (1 or 2) are earnable once per calendar day per Bear's Den; daily cap enforced
- [ ] Parent dashboard shows Chapter Insights for BM with correct strength badges
- [ ] App does not crash during a full end-to-end walkthrough
- [ ] No loading spinner exceeds 2 seconds on a standard Android device
- [ ] Final demo walkthrough rehearsed and all demo paths confirmed working
