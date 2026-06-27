# BearTahan

**Learn Like You Play.**

BearTahan is a completed Android MVP that turns Malaysian Standard 1 revision into a child-friendly game. It combines KSSR-aligned practice, visible learning progress, a bear mascot, quests, stars, and parent-managed rewards in one shared-device experience.

Developed by **APPLE-5** as an academic mobile application project, BearTahan completed its fourth and final sprint with the core child and parent journeys working end to end.

## Project Status

| Milestone | Status |
|---|---|
| Sprint 1: Core learning loop | Complete |
| Sprint 2: Multi-subject content and parent tools | Complete |
| Sprint 3: Rewards, quests, review, and Mandarin tracing | Complete |
| Sprint 4: AI features, adaptive practice, QA, and final polish | Complete |
| MVP | Achieved |

## Why BearTahan?

Young children are naturally drawn to games and mobile devices, while parents may not always have time to supervise every study session. BearTahan uses that familiar screen experience to encourage short, structured practice sessions instead of passive screen time.

The application is designed around two connected needs:

- **Children** need engaging practice, clear goals, and positive reinforcement.
- **Parents** need a simple way to understand progress, guide learning, and motivate their child.

BearTahan does not replace classroom teaching. It is a practice and reinforcement tool that supports the Standard 1 learning journey.

## The BearTahan Experience

### For Children

- Practise **Bahasa Melayu, English, Mandarin, Mathematics, and Science**.
- Progress through chapters and levels based on KSSR Standard 1 content.
- Answer multiple-choice, fill-in-the-blank, matching, rearrangement, numeric, listening, and drag-and-drop questions.
- Trace simple Mandarin characters using guided stroke order validation.
- Hear question prompts through preloaded text-to-speech audio.
- Receive immediate visual, mascot, and sound feedback.
- Earn stars based on performance and improve previous results through replay.
- Build daily streaks and complete parent-defined learning goals.
- Recover from mistakes through **Bear's Memory Challenge** and silently mixed review questions.
- Complete quests, reveal new bear outfits, and equip a preferred mascot.
- Spend earned stars on real-world rewards created by a parent.

### For Parents

- Create and manage child profiles on the same family device.
- Access a dedicated parent area protected by authentication controls.
- View subject progress, lesson history, learning time, stars, streaks, and daily-goal progress.
- Set daily lesson or study-time goals.
- Create meaningful real-world rewards with custom star costs.
- Approve or reject reward claims before stars are deducted.
- Receive and manage learning and reward notifications.
- Review chapter-level strengths through parent-facing insights.
- Ask BearAI for explanations and practical recommendations grounded in the child's activity.

## AI and Personalisation

BearTahan uses two complementary forms of intelligence.

### BearAI

BearAI is a parent-facing consultation assistant powered by **Google Gemini**. It receives relevant learning context from Firestore, such as recent sessions, subject progress, streaks, goals, stars, and weak areas. Parents can ask questions or use suggested prompts to receive concise, child-specific guidance.

BearAI is deliberately scoped to learning support. It is not presented as a general-purpose chatbot, and its conversation history is not permanently stored by the application.

### Bear's Den

Bear's Den is a hidden cross-chapter challenge that becomes available after the required Bahasa Melayu chapter range is completed. Its data-driven selection algorithm gives greater weight to weaker chapters while still including average and strong areas.

Children experience Bear's Den as a special challenge. Strength labels and learning analytics remain parent-facing so that children are encouraged without being labelled by weakness.

## Learning and Motivation Model

BearTahan connects digital achievement to real family motivation:

1. The child completes a level and earns stars.
2. Stars contribute to both lifetime achievement and the spendable balance.
3. The child claims a parent-created reward.
4. The parent approves or rejects the request.
5. Stars are deducted only after approval.

This creates a complete loop between practice, achievement, parental involvement, and meaningful rewards.

The application also supports:

- tiered star awards for standard levels;
- escalating mastery thresholds for chapter summaries;
- daily star limits for repeatable challenge stages;
- wrong-answer recovery and review milestones;
- quest-based outfit progression; and
- calendar-day learning streaks.

## Typical Demonstration Flow

1. Sign in and select a child profile.
2. Enter child mode and choose a subject, chapter, and level.
3. Complete a question session and view the score, stars, and mascot feedback.
4. Open the Quests area to inspect outfit progress or unlock an eligible outfit.
5. Claim a reward using earned stars.
6. Switch to parent mode to inspect progress and respond to the reward claim.
7. Open BearAI and ask for a recommendation based on the child's learning data.
8. View Chapter Insights and demonstrate the personalised Bear's Den experience.

## Technical Overview

| Area | Technology |
|---|---|
| Mobile application | Flutter and Dart |
| Target platform | Android, phone-first |
| State management | Riverpod |
| Navigation | GoRouter |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Notifications | Firebase Cloud Messaging |
| AI consultation | Google Gemini through Firebase Cloud Functions |
| Audio | Text-to-speech and local sound assets |
| Quality assurance | Flutter unit, widget, service, and integration-focused tests |

The application follows a shared-device model: child mode supports learning and rewards, while parent mode provides supervision, configuration, and insight. An active internet connection is required for authentication, cloud data, and AI services.

## Running the MVP

### Requirements

- Flutter `3.41.9` on the stable channel
- Android Studio or a configured Android device/emulator
- Access to the project's Firebase configuration

### Commands

```bash
flutter pub get
flutter run
```

To verify the project:

```bash
flutter analyze
flutter test
```

Firebase-backed features such as authentication, notifications, Firestore content, and BearAI require the configured BearTahan Firebase environment. Private credentials and service-account files are not included in the repository.

## MVP Boundaries

The finalized MVP is intentionally focused:

- Android is the primary supported platform.
- The interface is in English, while subject content uses its appropriate language.
- The application requires an internet connection.
- Bear's Den is implemented for its initial Bahasa Melayu chapter range.
- BearAI supports parent learning consultation rather than unrestricted conversation.
- iOS optimisation, full multilingual interface support, and broader adaptive-content expansion remain future opportunities.

## Project Outcome

BearTahan demonstrates an end-to-end educational ecosystem rather than a standalone quiz application. Its completed MVP connects structured practice, adaptive review, AI-supported parental insight, gamified progression, and real-world rewards while keeping the experience understandable for both a young child and their parent.

---

**Team APPLE-5**

Mobile Application Development Project

MVP completed after Sprint 4
