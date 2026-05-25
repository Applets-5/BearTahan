# BearTahan — Design Decisions & Meeting Agenda
**Module:** BT-02  
**Status:** Pending team discussion  
**Suggested meeting:** Weekday session before wireframe submission  
**Attendees:** Scrum Master, Product Owner, Development Team

---

## How to use this document

Each item below is an unresolved design decision that directly affects the product backlog and wireframe. Work through them in order — the earlier items tend to unblock the later ones. For each item, the team should agree on a decision and record it in the **Decision** field. Items marked 🔴 are blockers — they must be resolved before wireframing can begin on that area.

---

## Section A — Core Learning Loop (Resolve first)

---

### A1. Teaching phase or practice-only? 🔴

**The question:** Does each level begin with a short teaching/content phase (slides, audio tip, visual note like "Nota: vokal ialah AEIOU"), or does the child go straight into questions assuming school has already taught the material?

**Why it matters:** Option A (teaching phase) roughly doubles the content work — you need lesson slides in addition to questions. Option B (practice-only) is faster to build but the app assumes school teaching is sufficient. The answer may also differ by subject — Maths practice-only makes sense, Mandarin character recognition probably needs a reference slide first.

**Options to consider:**
- A: Teaching slide(s) → quiz for all subjects
- B: Practice-only for all subjects
- C: Hybrid — teaching phase for language subjects (BM, English, Mandarin), practice-only for Maths and Science

**Decision:** _______________________________________________

---

### A2. How many questions per level session? 🔴

**The question:** When a child opens a basic level, how many questions do they answer before the completion screen appears?

**Why it matters:** This determines session length, which directly affects the "bite-sized" promise and daily engagement time. Too few and there's no learning; too many and a 7-year-old disengages.

**Suggested range to discuss:** 5–10 questions per basic level, 10–15 for chapter summary stages.

**Decision:** _______________________________________________

---

### A3. Mid-level exit behaviour 🔴

**The question:** If a child closes the app or navigates away mid-level, what happens? Options: (a) session is lost, restart from question 1; (b) session is paused and resumes where they left off.

**Why it matters:** Resume logic is a meaningful engineering effort. If the team decides to implement it, it needs to be in the backlog from Sprint 1. If not, the UX needs a clear "you will lose your progress" warning on exit.

**Decision:** _______________________________________________

---

### A4. Shared device or separate devices? 🔴

**The question:** Is the assumed usage model one shared family phone where both parent and child use the same device, or do parent and child use separate devices?

**Why it matters:** If shared, the app needs a clear parent/child mode toggle with PIN protection on the parent side so a 7-year-old cannot access or modify rewards, goals, or dashboard data. If separate devices, the app can route directly to either view on launch based on the account type.

**Options:**
- A: Shared device — build parent PIN / mode switch into onboarding
- B: Separate devices assumed — no mode switch needed, simpler auth flow
- C: Support both — detect and ask during onboarding

**Decision:** _______________________________________________

---

## Section B — Star & Reward Economy

---

### B1. Full star threshold rule set 🔴

**The question:** What are the exact conditions for earning each star tier in basic stages and chapter summary stages?

**Current understanding (confirm or correct):**

| Stage type | 1★ | 2★ | 3★ |
|---|---|---|---|
| Basic stage | ≥ 50% | ≥ 80% | 100% |
| Chapter summary | ≥ 50% (first attempt) | escalates on repeat | escalates further |

**Open sub-questions to resolve:**
- Does the escalating threshold in chapter summary stages reset daily, or is it a permanent global counter per child per level?
- What is the daily cap on bonus stars from review stages — a fixed number of stars, or a fixed number of attempts?
- Can a child redo a basic stage to try for a higher star tier, or is each tier a one-time-only claim?

**Decision:** _______________________________________________

---

### B2. Reward redemption flow 🔴

**The question:** Who triggers redemption and what is the exact step-by-step flow?

**Proposed flow to validate:**
1. Child reaches the star threshold for a reward
2. Child taps "Claim" on the Rewards screen
3. Confirmation dialog: "This will cost X stars. Are you sure?"
4. Stars are placed in a "pending" state (not yet deducted from available balance)
5. Parent receives a push notification: "Your child wants to claim [Reward Name]!"
6. Parent delivers the reward in real life
7. Parent taps "Mark as Done" in their dashboard
8. Stars are now deducted from available balance
9. Child sees a celebration animation confirming the reward

**Challenges to resolve:**
- What happens if the parent never marks it done — does the claim expire after X days?
- Can the child cancel a pending claim?
- Can the parent reject a claim (e.g. if the reward is no longer appropriate)?
- Are stars deducted immediately on claim, or only after parent confirms?

**Decision:** _______________________________________________

---

### B3. Lifetime earned vs. available to spend display

**The question:** Should the app display two separate star counts — one that only ever goes up (lifetime earned, for motivation) and one that reflects the current spendable balance (decreases on redemption)?

**Why it matters:** A child who redeems a reward and sees their star count drop may feel punished, which contradicts the positive reinforcement principle. Showing both gives the child a sense of growth while still making the economy work.

**Decision:** _______________________________________________

---

## Section C — Spaced Repetition

---

### C1. Dedicated review section or silent injection? 🔴

**The question:** How does spaced repetition surface past questions to the child?

**Option A — Dedicated section:**
A "Bear's Memory Challenge" tab or banner appears on the home screen when review questions are due. The child navigates to it deliberately. Transparent and gives the child agency. Needs to be framed as something fun or a 7-year-old will ignore it.

**Option B — Silent injection:**
Review questions are quietly mixed into regular level sessions. The child just plays their normal lesson and occasionally gets a question from a previous topic. Seamless but the child never knows it's happening.

**Option C — Hybrid:**
A few injected questions per session plus a dedicated "bonus review" section for parents who want to push harder review.

**Decision:** _______________________________________________

---

## Section D — Authentication & Devices

---

### D1. Login method for V1

**The question:** What authentication method does the parent use to register and log in?

**Options:**
- A: Email + password only (simplest to build, V1 recommended)
- B: Google SSO / Apple Sign-In (better UX, more engineering effort)
- C: Email + password for V1, SSO added in a future sprint

**Decision:** _______________________________________________

---

### D2. Two parents, one child

**The question:** Can two parents (e.g. mother and father) both monitor the same child's progress?

**Why it matters:** If yes, this requires either a shared account login or an invite/link-by-code feature. If no, you will receive complaints from families with two involved parents.

**Options:**
- A: Not supported in V1 — single account per child, documented as a future feature
- B: Both parents share the same login credentials (workaround, no engineering cost)
- C: Build an invite/co-parent feature (significant engineering effort, post-MVP)

**Decision:** _______________________________________________

---

## Section E — Content & Localisation

---

### E1. Chinese subject — Simplified or Traditional?

**The question:** The Mandarin subject in SJKC Standard 1 uses which Chinese script?

**Note:** This affects font assets, question bank content, and TTS audio. Must be confirmed with reference to the actual KSSR Mandarin textbook used in the target schools.

**Decision:** _______________________________________________

---

### E2. Chinese character writing — stroke tracing or recognition only?

**The question:** Does the Mandarin subject in V1 include interactive stroke-order tracing (child draws the character with their finger), or only recognition/matching (child identifies the correct character from options)?

**Why it matters:** Stroke tracing requires a custom drawing input component, handwriting recognition or stroke validation logic, and significantly more engineering time. Recognition-only is achievable with the same MCQ/drag-drop engine used for other subjects.

**Options:**
- A: Recognition and matching only for V1, tracing as a future feature
- B: Stroke tracing included in V1

**Decision:** _______________________________________________

---

### E3. App UI language

**The question:** Does the app UI itself (buttons, labels, instructions, navigation) need to be available in three languages (BM, English, Mandarin), or does the UI stay in one language while only the subject content varies by subject?

**Recommendation:** UI in one language for V1 (BM or English), full language switching as a post-MVP roadmap item. Full i18n triples copy and testing effort.

**Decision:** _______________________________________________

---

### E4. Audio content — recording approach

**The question:** How will pronunciation audio and question audio be produced?

**Options:**
- A: Record a native speaker (highest quality, requires a recording session and file management pipeline)
- B: Text-to-speech via a service (faster, lower quality, must verify naturalness for 7-year-olds)
- C: Hybrid — TTS for V1 placeholder, replace with recorded audio in a later sprint

**Also confirm:** Who on the team is responsible for content creation and audio management?

**Decision:** _______________________________________________

---

## Section F — Edge Cases & Non-Functional Requirements

These are not immediate blockers but should be briefly discussed to avoid surprises during development.

| # | Question | Why it matters |
|---|---|---|
| F1 | What is the minimum supported OS version (Android/iOS)? | Affects which device APIs are available and how large the user base is |
| F2 | Does the app work offline, or is an internet connection required? | Offline mode requires local caching of questions and syncing logic — significant effort |
| F3 | Is the app phone-only, or does it need to support tablets? | Tablet layout is a separate responsive design effort |
| F4 | What happens when a child completes all available content? | Empty state UX — "You've finished everything! New lessons coming soon" |
| F5 | How long is a streak counted — calendar day or 24-hour rolling window? | A child who plays at 11pm and 1am on consecutive days should not lose their streak |
| F6 | What is the account recovery flow if a parent forgets their password? | Standard email reset — confirm this is in scope for V1 |

---

## Decision Log

*Fill this in during the meeting.*

| ID | Decision made | Owner | Date |
|---|---|---|---|
| A1 | | | |
| A2 | | | |
| A3 | | | |
| A4 | | | |
| B1 | | | |
| B2 | | | |
| B3 | | | |
| C1 | | | |
| D1 | | | |
| D2 | | | |
| E1 | | | |
| E2 | | | |
| E3 | | | |
| E4 | | | |

---

*Previous document: BT-01 — Functional Requirements*
