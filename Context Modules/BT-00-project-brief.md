# BT-00 — Project Brief
**Module:** BT-00 | **Version:** 1.0 | **Team:** APPLE-5

---

## App in one sentence

BearTahan is a gamified KSSR-aligned learning app for Malaysian Standard 1 students that makes screen time educational by turning lessons into a game and connecting children's achievements to real-world rewards set by their parents.

**Tagline:** Learn Like You Play.

---

## The problem

### For children
- Addicted to screens (Roblox, short-form video) with zero interest in books
- No structured daily learning plan
- Hard transition into Standard 1 — some children skip kindergarten entirely
- Scattered learning materials; no single place to practise all subjects

### For parents
- No time to sit and guide their child's studying
- Don't know how to teach Standard 1 content effectively
- Cannot tell where their child is struggling without sitting with them
- Existing parental control apps only restrict screen time — no educational value

---

## The solution

A Duolingo-style mobile app that:
- Covers all 5 KSSR Standard 1 subjects in one place
- Organises content chapter by chapter matching the actual textbook
- Makes learning feel like a game through stars, mascots, outfits, and quests
- Uses AI to detect each child's weak chapters and quietly weights Bear's Den sessions toward those gaps, strengthening knowledge through daily cross-chapter practice
- Gives parents real-time visibility and lets them set motivating real-world rewards
- Provides parents with BearAI — an AI-powered chat consultation that analyses their child's activity and gives personalised recommendations on rewards, daily goals, and subject-specific support
- Runs on the family's existing Android device with no extra hardware needed

---

## Subjects covered (KSSR Standard 1)

| Subject | Language | Notes |
|---|---|---|
| Bahasa Melayu | Malay | Pilot subject for Sprint 1 |
| English | English | Reading & Writing |
| Mandarin (华语) | Simplified Chinese | Includes stroke tracing for V1 |
| Mathematics | English/Chinese | Parametric generation — no manual bank needed |
| Science | English/Chinese | Explore & Discover |

---

## Competitive gap

| Competitor | What it lacks |
|---|---|
| Pandai app | Exam prep focus, no daily habit loop, partial gamification, no parent reward system |
| Exercise books | No engagement, no monitoring, children ignore them |
| Parental control apps | Only restrict usage, no learning, not gamified |

None of the above offer: daily habit formation + full gamification + parent monitoring + real-world reward redemption in one KSSR-aligned package.

---

## Unique selling points

1. Strictly aligned with KSSR Standard 1 — parents trust it maps to schoolwork
2. Gamified like Duolingo — children play without knowing they are studying
3. Real-time progress tracking for parents on the same device
4. Star economy bridging digital achievement and real-world parental rewards
5. Builds the learning habit at the most critical foundation year (Standard 1)
6. BearAI — an in-app AI consultation layer that gives parents personalised insights about their child's learning patterns, subject weaknesses, and actionable recommendations for rewards and goals
7. Bear's Den — a secret cross-chapter challenge that unlocks inside a subject after completing a chapter range; AI quietly weights questions toward the child's weaker chapters to strengthen gaps through daily motivated practice

---

## Team — APPLE-5

| Role | Person | Dev responsibilities |
|---|---|---|
| Scrum Master | Samy | Sprint ceremonies, backlog, project setup & config — lighter dev load; owns tutorial, error states, PDPA screens, settings |
| Product Owner | TBC | Backlog priority, stakeholder representation |
| Developer 1 | TBC | Core learning UI — home screen, subject/chapter navigation, question engine, level session flow, review UI |
| Developer 2 | TBC | Backend & Auth — Firebase Auth, Firestore, star economy logic, notifications (FCM), parent dashboard, admin CMS |
| Developer 3 | TBC | Content & Audio — question banks for all 5 subjects, TTS audio pipeline, Maths parametric rules |
| Developer 4 | TBC | Engagement & Animation — mascot/outfit system, quests, drag-drop, stroke tracing, streak UI, sound effects |

> **Note on Samy (SM):** Samy carries a lighter dev story count than the four developers due to sprint ceremony overhead (planning, review, retrospective, backlog grooming, standup facilitation). If sprint capacity allows, Samy pulls additional stories from the backlog.

---

## Technology stack

| Layer | Choice | Reason |
|---|---|---|
| Mobile framework | Flutter (Dart) | Cross-platform, single codebase, Android-first |
| Backend & Auth | Firebase | Firestore, Firebase Auth (Google Sign-In), FCM notifications |
| Audio | TTS service (TBC) | Faster than recording; replaced with native speaker audio post-MVP |
| Content strategy | AI-drafted → human-reviewed → uploaded to Firestore | Ensures KSSR accuracy while avoiding live AI generation risk |

---

## Project timeline

| Sprint | Duration | Goal |
|---|---|---|
| Sprint 1 | Weeks 1–2 | Core learning loop — child opens app, does BM lesson, earns stars |
| Sprint 2 | Weeks 3–4 | All 5 subjects live, parent tools (goals, rewards, notifications) |
| Sprint 3 | Weeks 5–6 | Full star economy, review system, quests, outfits, Mandarin tracing |
| Sprint 4 | Weeks 7–8 | Stability, QA, admin CMS, PDPA compliance, final demo |

**Key university deadlines:**
- Initial product backlog submission: end of Week 1
- Wireframe submission: end of Week 2
- Sprint 1 demo: end of Week 2
- Final demo: end of Week 8

---

## What a successful V1 looks like

A working Android app where:
- A child can register, pick a mascot, complete lessons in all 5 subjects, earn stars, and unlock outfits through quests
- Bear's Den unlocks inside Bahasa Melayu after the child completes Chapters 1–3, and delivers a cross-chapter AI-weighted session with stars earnable daily
- A parent can switch to parent mode (biometric/PIN), view their child's progress, use BearAI to get AI-powered insights and recommendations via chat, set daily goals, create real-world rewards, receive push notifications, and approve/reject reward claims
- The star economy works end-to-end: earn → save → claim → parent confirms → stars deducted
- The app is stable enough to demo to a real Standard 1 parent without crashing or showing placeholder content
