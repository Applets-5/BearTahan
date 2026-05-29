# BT-03 — Product Backlog
**Module:** BT-03 | **Version:** 2.1 | **Total stories:** 53 active + 10 icebox

**Team:** SM (Samy) · Dev 1 (Core UI) · Dev 2 (Backend) · Dev 3 (Content) · Dev 4 (Engagement)
Priority scale: **Must** = essential for V1 · **Should** = important but not blocking · **Could** = nice-to-have if capacity allows

> **SM (Samy) dev note:** Samy carries a lighter story count due to sprint ceremony overhead. Assigned stories are setup tasks and simpler UI screens. If capacity allows in any sprint, Samy pulls the next unassigned Should/Could story from that sprint.

---

## Sprint 1 — Core Learning Loop
**Goal:** A child can open the app, complete a BM lesson, and earn stars. Parent can view basic progress.
**Stories:** 18

| ID | Epic | As a | I want to | So that | Priority | Owner |
|---|---|---|---|---|---|---|
| 1 | Auth & Onboarding | Parent | register and log in using my Google account via Firebase | I can securely access the app without creating a new password | Must | Dev 2 |
| 2 | Auth & Onboarding | Parent | switch from child mode to parent mode using biometrics or a PIN | my child cannot access or tamper with the parent dashboard | Must | Dev 2 |
| 3 | Auth & Onboarding | Parent | create a child profile with a name during onboarding | the app is personalised for my child from the start | Must | Dev 2 |
| 4 | Auth & Onboarding | Student | choose a bear mascot outfit during my first login | I feel ownership over my profile and get excited to start | Must | Dev 4 |
| 5 | Auth & Onboarding | Parent | see a brief tutorial walkthrough on first launch | I understand how the app works without needing external guidance | Should | SM (Samy) |
| 6 | Kids Home & Nav | Student | see all 5 subjects with progress bars on my home screen | I know which subjects I have been doing and what is left | Must | Dev 1 |
| 7 | Kids Home & Nav | Student | see my total star balance clearly on the home screen | I always know how many stars I have and feel motivated | Must | Dev 1 |
| 8 | Kids Home & Nav | Student | tap a subject and see its chapters and levels laid out | I can find what I want to learn and see what is locked ahead | Must | Dev 1 |
| 9 | Kids Home & Nav | Student | see locked levels as visible but inaccessible | I feel a sense of progress and have something to work toward | Should | Dev 1 |
| 10 | Learning Engine | Student | answer multiple-choice questions by tapping an answer | I can practise what I have learned in a simple touch-friendly way | Must | Dev 1 |
| 11 | Learning Engine | Student | see immediate visual and audio feedback after each answer | I know right away if I was correct and stay engaged | Must | Dev 1 |
| 12 | Learning Engine | Student | never have stars taken away for a wrong answer | I feel safe to try without fear of losing what I earned | Must | Dev 1 |
| 13 | Learning Engine | Student | see a counting-up timer during my level session | I can see how long I have been playing | Should | Dev 4 |
| 14 | Learning Engine | Student | see a completion screen with my score and stars earned after every level | I feel a sense of achievement at the end of each session | Must | Dev 1 |
| 15 | Content & Questions | Student | play BM Chapter 1 with real KSSR-aligned questions | the app is immediately useful and relevant to my schoolwork | Must | Dev 3 |
| 16 | Star Economy | Student | earn stars based on my score when I complete a basic level | I am rewarded for how well I do, not just for showing up | Must | Dev 2 |
| 17 | Parent Dashboard | Parent | view my child's total stars, lessons completed, streak, and per-subject progress | I have full visibility without having to ask my child | Must | Dev 2 |
| 18 | System | Parent | see a clear message when there is no internet connection | I am not confused by a blank or broken screen | Must | SM (Samy) |

---

## Sprint 2 — Full Content & Parent Tools
**Goal:** All 5 subjects live with question banks. Parents can set daily goals, create rewards, and receive push notifications.
**Stories:** 13

| ID | Epic | As a | I want to | So that | Priority | Owner |
|---|---|---|---|---|---|---|
| 19 | Auth & Onboarding | Parent | reset my password via a standard email reset flow | I can always recover access to my account | Should | Dev 2 |
| 20 | Content & Questions | Student | access all 5 subjects with KSSR-aligned questions across all chapters | I can practise every subject I study in school | Must | Dev 3 |
| 21 | Content & Questions | Student | answer randomised Maths questions generated from number ranges | I get different questions every session and build number fluency | Must | Dev 2 (logic) + Dev 3 (rules) |
| 22 | Learning Engine | Student | answer drag-and-drop questions where I match items | I have variety in how I practise and stay interested | Should | Dev 4 |
| 23 | Learning Engine | Student | hear an audio clip (TTS) play as part of a question | I can answer listening questions even if my reading is still developing | Should | Dev 3 (audio) |
| 24 | Content & Questions | Student | complete a chapter summary stage with randomised questions each session | I can repeat it daily and still get a fresh challenge | Must | Dev 1 (UI) + Dev 3 (content) |
| 25 | Star Economy | Parent | create custom real-world rewards with a name and star cost | my child has a tangible personalised goal to work toward | Must | Dev 2 |
| 26 | Star Economy | Parent | edit or delete rewards I have set at any time | I can keep the reward list relevant as my child grows | Should | Dev 2 |
| 27 | Parent Dashboard | Parent | set a daily learning goal for my child in lessons or minutes | my child builds a consistent learning habit with a clear target | Should | Dev 2 |
| 28 | Parent Dashboard | Parent | receive a push notification when my child completes their daily goal | I can praise them immediately and reinforce the habit | Should | Dev 2 |
| 29 | Parent Dashboard | Parent | receive a push notification when my child claims a reward | I am never surprised by a reward request I did not expect | Should | Dev 2 |
| 30 | Engagement | Student | see my daily streak counter on the home screen | I am motivated to open the app every day to keep my streak alive | Should | Dev 4 |
| 31 | Parent Dashboard | Parent | receive a streak-at-risk alert if my child has not practised by a set time | I can encourage them before the streak is broken | Could | Dev 2 |

---

## Sprint 3 — Engagement & Reward Loop
**Goal:** Full star economy end-to-end. Review system live. Quests and outfits working. Mandarin stroke tracing complete.
**Stories:** 14

| ID | Epic | As a | I want to | So that | Priority | Owner |
|---|---|---|---|---|---|---|
| 32 | Star Economy | Student | claim a reward when I have enough stars and send a notification to my parent | my parent knows to deliver the reward in real life | Must | Dev 2 |
| 33 | Star Economy | Parent | approve or reject my child's reward claim in the app | the star deduction only happens after I physically deliver the reward | Must | Dev 2 |
| 34 | Star Economy | Student | see both my lifetime stars earned and my available stars to spend as two separate counts | I always feel like I am growing even after I redeem a reward | Should | SM (Samy) |
| 35 | Star Economy | Student | view a history of all the stars I have earned and spent | I can track my progress and understand where my stars went | Should | SM (Samy) |
| 36 | Review System | Student | see a dedicated Bear's Memory Challenge section when I have wrong-answer review questions | I can deliberately revisit and correct questions I got wrong | Should | Dev 1 (UI) + Dev 2 (logic) |
| 37 | Review System | Student | have wrong-answer questions silently mixed into my regular level sessions | I naturally re-encounter questions I got wrong without a separate step | Should | Dev 1 |
| 38 | Review System | Student | earn stars by accumulating review questions answered (every 20 = 1 star) | I am rewarded for putting in the effort to review my mistakes | Should | Dev 2 |
| 39 | Engagement | Student | unlock new bear outfits by completing specific quest missions | I have long-term goals that keep me coming back beyond just earning stars | Should | Dev 4 |
| 40 | Engagement | Student | see a Quests tab showing all missions with progress bars and locked bear silhouettes | I am curious about what I can unlock and motivated to complete challenges | Should | Dev 4 |
| 41 | Engagement | Student | choose which unlocked outfit my bear wears | I feel creative ownership over my in-app character | Should | Dev 4 |
| 42 | Engagement | Student | hear fun sound effects and see mascot animations throughout the app | the app feels alive and rewarding to use | Should | Dev 4 |
| 43 | Parent Dashboard | Parent | see how long my child took to complete each level and their daily total learning time | I understand their pace and can identify where they struggle | Should | Dev 2 |
| 44 | Content & Questions | Student | practise Mandarin by tracing Chinese characters in the correct stroke order | I learn how to write characters properly, not just recognise them | Must | Dev 4 (dedicated) |
| 45 | Parent Dashboard | Parent | add a second child profile and switch between them in the dashboard | I can monitor all my children from one account | Should | Dev 2 |
| 54 | Parent Dashboard (BearAI) | Parent | see an AI-generated insight card on my dashboard summarising my child's recent activity | I get an immediate overview of how my child is doing without reading all the stats manually | Should | Dev 2 |
| 55 | Parent Dashboard (BearAI) | Parent | chat with BearAI to ask questions about my child's progress and get personalised recommendations | I have a personal consultant that helps me make better decisions about rewards, goals, and subject support | Must | Dev 2 |

---

## Sprint 4 — Stability & Handoff
**Goal:** All edge cases handled. Admin CMS live. PDPA compliant. Stable for final demo.
**Stories:** 8

| ID | Epic | As a | I want to | So that | Priority | Owner |
|---|---|---|---|---|---|---|
| 46 | Content & Questions | Student | access a Revision Stage that mixes all questions from completed chapters across a subject | I can do a comprehensive cross-chapter review of everything I have learned | Should | Dev 1 (UI) + Dev 3 (content) |
| 47 | Parent Dashboard | Parent | configure which push notifications I receive | I do not get overwhelmed by alerts and disable them entirely | Could | Dev 2 |
| 48 | System | Content Creator | use an internal admin tool to upload and manage questions without developer help | the team can update the question bank independently and quickly | Must | Dev 2 |
| 49 | System | Student | see friendly error messages for empty and broken states | I am not confused by a blank screen or a technical error | Should | SM (Samy) |
| 50 | System | Parent | give explicit consent for my child's data to be collected during registration | I trust the app handles my child's information responsibly (PDPA) | Must | SM (Samy) |
| 51 | System | Parent | request full deletion of my account and all my child's data | I have control over my family's data if I choose to stop using the app | Must | Dev 2 |
| 52 | System | Parent | update my account details in settings | I can keep my account information accurate | Should | SM (Samy) |
| 53 | System | All | experience a polished, bug-free app across all completed features | the app is stable enough to demo as a working product | Must | All |
| 56 | Bear's Den | Student | discover and unlock Bear's Den inside Bahasa Melayu after completing Chapters 1–3 | I have a special cross-chapter challenge to look forward to and revisit daily | Should | Dev 1 (UI) + Dev 2 (logic) |
| 57 | Bear's Den | Student | attempt a Bear's Den session with AI-weighted cross-chapter BM questions and earn up to 2 stars daily | I am challenged across everything I have learned and motivated to come back each day | Should | Dev 1 (UI) + Dev 2 (logic) |

---

## Story count by person

| Person | Sprint 1 | Sprint 2 | Sprint 3 | Sprint 4 | Total |
|---|---|---|---|---|---|
| SM (Samy) | 2 (IDs 5, 18) | 0 | 2 (IDs 34, 35) | 3 (IDs 49, 50, 52) + shared 53 | **7 + shared** |
| Dev 1 | 7 (IDs 6–12, 14) | 1 (ID 24 UI) | 3 (IDs 36, 37, 46 UI) | 2 (IDs 56 UI, 57 UI) | **14** |
| Dev 2 | 4 (IDs 1–3, 16, 17) | 8 (IDs 19, 21, 25–29, 31) | 7 (IDs 32, 33, 38, 43, 45, 54, 55) | 5 (IDs 47, 48, 51, 56 logic, 57 logic) + shared 53 | **25 + shared** |
| Dev 3 | 1 (ID 15) | 3 (IDs 20, 21 rules, 23, 24 content) | 0 | 1 (ID 46 content) | **6** |
| Dev 4 | 2 (IDs 4, 13) | 2 (IDs 22, 30) | 5 (IDs 39–42, 44) | 0 + shared 53 | **9 + shared** |

> Dev 2's count is high but Stories 56 and 57 share the same Firestore read logic already built in Sprint 1/2 (levelProgress). The chapter strength calculation is a query on existing data, not a new collection. Bear's Den is a Sprint 4 Should — if Sprint 4 runs tight on Must items, defer 56 and 57 to icebox immediately. Story 57 depends on 56 completing first.

---

## Icebox — Not Prioritised
V1 is fully functional without any of these. Drag into an active sprint if capacity allows.

| ID | Epic | As a | I want to | So that | Notes |
|---|---|---|---|---|---|
| I-1 | Auth | Parent | invite a co-parent via email so both parents can monitor the same child | both parents have equal real-time access without sharing login credentials | Netflix-style; email invite; equal permissions; first to approve/reject finalises |
| I-2 | Auth | Parent | sign in with Apple ID in addition to Google | I can use my preferred account on iOS devices | Android-first for V1 |
| I-3 | Learning Engine | Student | use the app on a tablet with a layout optimised for the larger screen | the experience feels native rather than a stretched phone layout | Responsive tablet layout |
| I-4 | System | Parent | switch the app UI language between BM, English, Mandarin, and Tamil | parents and children who prefer a different language can use the app comfortably | Full i18n — English UI for V1 |
| I-5 | Content | Student | access Standard 2 content once I complete all of Standard 1 | I can continue learning and building on what I know | Requires full Standard 2 question bank |
| I-6 | Engagement | Student | see a leaderboard showing how my star total compares to other students | I feel competitive and motivated to earn more stars | Privacy considerations for minors |
| I-7 | System | Parent | receive notifications via WhatsApp instead of or in addition to push notifications | I stay updated through the channel I use most | WhatsApp Business API |
| I-8 | Engagement | Student | earn XP points that fill an experience bar and unlock milestones | I have a secondary progression system alongside stars | XP bar system |
| I-9 | System | Parent | see AI-generated insights about my child's learning traits and strengths | I understand not just their scores but how they learn best | Requires significant data and AI integration |
| I-10 | System | Parent | purchase premium features such as extra outfit packs or detailed analytics | I can support the app and access enhanced tools | Monetisation module |
| I-11 | Bear's Den | Student | unlock a second Bear's Den tier covering Chapters 4–6 once I complete those chapters | I have a new challenge as I progress further through the subject | Requires Stories 56/57 stable and Chapters 4–6 question bank complete |
| I-12 | Bear's Den | Student | access Bear's Den for all 5 subjects, not just Bahasa Melayu | I can do cross-chapter practice in every subject I study | Requires verified question banks and levelProgress data for all subjects; BM only for MVP |
| I-13 | Bear's Den | Parent | see my child's Bear's Den session history and results on the parent dashboard | I can track how their cross-chapter knowledge is developing over time | Requires filtering attempt history by source: bears_den |
