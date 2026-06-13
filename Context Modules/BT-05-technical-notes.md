# BT-05 — Technical Notes
**Module:** BT-05 | **Version:** 1.1
**Stack:** Flutter (Dart) · Firebase (Firestore, Auth, FCM)

---

## 1. Tech Stack Summary

| Layer | Technology | Purpose |
|---|---|---|
| Mobile app | Flutter (Dart) | Single codebase, Android-first |
| Database | Cloud Firestore | Real-time NoSQL; per-user/child documents |
| Authentication | Firebase Auth + Google Sign-In | Single auth method for V1 |
| Push notifications | Firebase Cloud Messaging (FCM) | Parent alerts |
| Biometric auth | flutter_local_auth plugin | Biometric / PIN for parent mode switch (in-app, separate from Firebase Auth) |
| Audio | TTS service (flutter_tts or google_cloud_tts) | Question audio; managed by Dev 3 |
| Stroke tracing | Custom Flutter canvas widget | Mandarin character tracing; Dev 1 task |
| State management | Riverpod 2.x | App-wide state — confirmed in use (childIdProvider, parentIdProvider) |

---

## 2. Firestore Data Model

### Top-level collections

```
/users/{parentUID}
/children/{childID}
/subjects/{subjectID}
/chapters/{chapterID}
/levels/{levelID}
/questions/{questionID}
```

> **⚠️ Implementation note (as of Sprint 2):** The current codebase uses `/parents/{uid}/children` and `/parents/{uid}/rewards` rather than the top-level `/users` and `/children` collections documented above. This divergence exists because of early teammate implementation choices. The documented schema above remains the intended target architecture. Until a formal migration decision is made: (a) all new Firestore writes should follow the existing `/parents/{uid}/...` path to stay consistent with the live code, and (b) do not reintroduce `/users` writes or top-level `/children` writes. Resolve the mismatch in a future sprint when it starts blocking feature work.

### `/users/{parentUID}`
```dart
{
  uid: String,                  // Firebase Auth UID
  email: String,
  displayName: String,
  createdAt: Timestamp,
  consentGiven: bool,           // PDPA consent flag
  consentTimestamp: Timestamp,
  notificationPreferences: {
    goalCompleted: bool,
    chapterCompleted: bool,
    rewardClaimed: bool,
    streakAtRisk: bool,
  },
  fcmToken: String,             // Updated on each login
}
```

### `/children/{childID}`
```dart
{
  childID: String,              // Auto-generated
  parentUID: String,            // Reference to /users
  name: String,
  age: int,
  activeOutfitID: String,       // Reference to outfit
  createdAt: Timestamp,

  // Star economy
  lifetimeStarsEarned: int,     // Never decreases
  availableStars: int,          // Decreases on reward redemption

  // Review accumulation
  reviewQuestionCounter: int,   // Resets every 20; global cross-subject

  // Streak
  currentStreak: int,
  lastSessionDate: String,      // "YYYY-MM-DD" calendar day
  longestStreak: int,

  // Daily goal
  dailyGoal: {
    type: String,               // "lessons" | "minutes"
    target: int,
    todayProgress: int,
    lastUpdatedDate: String,    // Reset when date changes
  },
}
```

### `/children/{childID}/subjectProgress/{subjectID}`
```dart
{
  subjectID: String,
  completionPercent: double,
  lessonsCompleted: int,
  starsEarned: int,
  allChaptersComplete: bool,    // Triggers revision stage unlock
}
```

### `/children/{childID}/levelProgress/{levelID}`
```dart
{
  levelID: String,
  subjectID: String,
  chapterID: String,
  starsClaimedTiers: [int],     // e.g. [1, 2] means 1★ and 2★ claimed, 3★ not yet
  bestScore: double,
  attemptCount: int,
  lastPlayedAt: Timestamp,
  totalTimeSeconds: int,        // Cumulative time

  // Chapter summary stage only
  isSummaryStage: bool,
  summaryThreshold: int,        // 80 | 90 | 100
  lastSummaryStarDate: String,  // For daily cap enforcement
}
```

### `/children/{childID}/attempts/{attemptID}`
```dart
{
  attemptID: String,
  levelID: String,
  subjectID: String,
  score: double,                // e.g. 0.7 for 70%
  starsEarned: int,
  timeSeconds: int,
  completedAt: Timestamp,
  wrongAnswerQuestionIDs: [String],  // IDs flagged for review
}
```

### `/children/{childID}/wrongAnswerBank/{questionID}`
```dart
{
  questionID: String,
  subjectID: String,
  addedAt: Timestamp,
  reviewCount: int,             // How many times this has been reviewed
  lastReviewedAt: Timestamp,
}
```

### `/children/{childID}/starTransactions/{txID}`
```dart
{
  txID: String,
  type: String,                 // "earn" | "spend" | "pending" | "returned"
  amount: int,
  source: String,               // e.g. "level_complete" | "reward_redemption" | "review_milestone"
  sourceID: String,             // Level ID, reward ID, etc.
  timestamp: Timestamp,
}
```

### `/children/{childID}/rewardClaims/{claimID}`
```dart
{
  claimID: String,
  rewardID: String,
  rewardName: String,
  starCost: int,
  status: String,               // "pending" | "approved" | "rejected" | "expired"
  claimedAt: Timestamp,
  resolvedAt: Timestamp,
  expiresAt: Timestamp,         // claimedAt + 7 days
}
```

### `/children/{childID}/questProgress/{outfitID}`
```dart
{
  outfitID: String,
  questCondition: String,       // Human-readable description
  conditionType: String,        // e.g. "score_100_in_subject_n_times"
  conditionSubjectID: String,
  conditionTarget: int,         // e.g. 3
  currentProgress: int,         // e.g. 2
  isUnlocked: bool,
  unlockedAt: Timestamp,
}
```

### `/rewards/{rewardID}` (under parent)
```dart
// Stored as /users/{parentUID}/rewards/{rewardID}
{
  rewardID: String,
  childID: String,
  name: String,
  emoji: String,
  starCost: int,
  createdAt: Timestamp,
  isActive: bool,
}
```

### `/subjects/{subjectID}`
```dart
{
  subjectID: String,            // e.g. "bm", "english", "mandarin", "maths", "science"
  displayName: String,
  language: String,             // "ms" | "en" | "zh-Hans"
  colorHex: String,
  iconAsset: String,
  chapterIDs: [String],
}
```

### `/questions/{questionID}`
```dart
{
  questionID: String,
  subjectID: String,
  chapterID: String,
  levelID: String,              // null if summary-only question
  type: String,                 // "mcq" | "drag_drop" | "audio_select" | "stroke_trace"
  prompt: String,               // Question text
  promptAudioURL: String,       // TTS audio file URL
  imageURL: String,             // Optional
  options: [
    { optionID: String, text: String, audioURL: String, imageURL: String }
  ],
  correctOptionID: String,
  difficulty: int,              // 1 | 2 | 3
  // For stroke tracing only:
  characterUnicode: String,
  strokeOrderData: [            // Array of stroke paths
    { strokeIndex: int, points: [[x, y]] }
  ],
}
```

---

## 3. Star Economy Logic

### Basic level — star award on completion

```dart
int calculateStarsEarned(double score, List<int> alreadyClaimedTiers) {
  int maxEarnable = 0;
  if (score >= 1.0) maxEarnable = 3;
  else if (score >= 0.8) maxEarnable = 2;
  else if (score >= 0.5) maxEarnable = 1;

  // Stars = tiers newly crossed minus already claimed
  int highestNewTier = maxEarnable;
  int highestClaimed = alreadyClaimedTiers.isEmpty ? 0 : alreadyClaimedTiers.reduce(max);
  return max(0, highestNewTier - highestClaimed);
}
```

When stars are awarded:
- `lifetimeStarsEarned += starsEarned`
- `availableStars += starsEarned`
- `starsClaimedTiers` updated in levelProgress
- Star transaction written to `/starTransactions`

### Chapter summary stage — escalating threshold

```dart
bool canEarnStarToday(LevelProgress progress, String todayDate) {
  return progress.lastSummaryStarDate != todayDate;
}

bool meetsThreshold(double score, int threshold) {
  return (score * 100) >= threshold;
}

int getNextThreshold(int currentThreshold) {
  if (currentThreshold < 80) return 80;
  if (currentThreshold == 80) return 90;
  if (currentThreshold == 90) return 100;
  return 100; // already at ceiling
}

// On session completion:
// 1. Check canEarnStarToday
// 2. Check meetsThreshold(score, summaryThreshold)
// 3. If both true: award 1 star, update lastSummaryStarDate, escalate threshold
```

### Reward redemption — pending state flow

```dart
// On child taps Claim:
// 1. Create rewardClaim document with status: "pending"
// 2. Do NOT deduct availableStars yet
// 3. Send FCM notification to parent

// On parent Approve:
// 1. availableStars -= starCost
// 2. Update claim status to "approved"
// 3. Write star transaction (type: "spend")
// 4. Trigger celebration animation on child side

// On parent Reject:
// 1. Update claim status to "rejected"
// 2. No star change needed (stars were never deducted)

// Expiry check (run on app launch or via Cloud Function):
// If claim.status == "pending" && now > claim.expiresAt:
//   Update status to "expired"
//   (stars were never deducted, so no return needed)
```

---

## 4. Review System Logic

### Wrong-answer flagging

After every session, write wrongAnswerQuestionIDs from the attempt to `/wrongAnswerBank`:
- If the question already exists in the bank, increment `reviewCount`
- If it does not exist, create a new document

### Review accumulation counter

```dart
// Every time a review question is answered (in either dedicated section or silent injection):
childData.reviewQuestionCounter += 1;

if (childData.reviewQuestionCounter >= 20) {
  childData.availableStars += 1;
  childData.lifetimeStarsEarned += 1;
  childData.reviewQuestionCounter = 0;
  // Write star transaction (type: "earn", source: "review_milestone")
}
```

### Silent injection

When loading questions for a basic level session:
1. Fetch the level's normal question set (10 questions)
2. Query `wrongAnswerBank` for up to 2 questions not recently reviewed
3. Replace 2 of the 10 normal questions with review questions
4. Shuffle the final set before displaying

---

## 5. Quest & Outfit Unlock Logic

Quest conditions are stored in Firestore per outfit. On every session completion, check all unlocked quests:

```dart
// Example: Quest condition = "score_100_in_subject_n_times"
// conditionSubjectID = "maths", conditionTarget = 3

void checkQuestProgress(String childID, String subjectID, double score) {
  // Fetch all quest progress documents for this child
  // For each quest matching subjectID and conditionType:
  if (score == 1.0 && quest.conditionSubjectID == subjectID) {
    quest.currentProgress += 1;
    if (quest.currentProgress >= quest.conditionTarget) {
      quest.isUnlocked = true;
      quest.unlockedAt = Timestamp.now();
      // Trigger unlock animation
    }
  }
  // Save updated quest progress to Firestore
}
```

---

## 6. Streak Logic

```dart
String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

void updateStreak(Child child) {
  String yesterday = DateFormat('yyyy-MM-dd')
    .format(DateTime.now().subtract(Duration(days: 1)));

  if (child.lastSessionDate == todayDate) {
    // Already played today — no change
    return;
  } else if (child.lastSessionDate == yesterday) {
    // Consecutive day — increment
    child.currentStreak += 1;
  } else {
    // Gap — reset streak
    child.currentStreak = 1;
  }

  child.lastSessionDate = todayDate;
  if (child.currentStreak > child.longestStreak) {
    child.longestStreak = child.currentStreak;
  }
  // Save to Firestore
}
```

---

## 7. Authentication Flow

### First launch
1. App opens in child mode (home screen with no profile)
2. "Sign in with Google" shown → Firebase Auth → store parent UID
3. PDPA consent screen → `consentGiven: true` stored in Firestore
4. Create child profile → stored under parent UID
5. Child picks mascot outfit → stored in child document
6. Tutorial shown → mark as seen

### Parent mode switch (every subsequent use)
1. Child taps "Switch to Parent Mode" button
2. `local_auth` plugin invokes biometric prompt
3. On biometric failure or unavailability → show PIN input
4. On success → navigate to parent mode screens
5. Parent taps "Back to Child Mode" → navigate back to child home

### FCM token management
- Retrieve and store FCM token on every app launch
- Update the `fcmToken` field in `/users/{parentUID}`
- All notifications sent to this token

---

## 8. Maths Parametric Generation

Maths questions are generated at runtime. No manual question bank in Firestore.

```dart
Map<String, dynamic> generateMathsQuestion(String chapterID) {
  final rules = mathsRules[chapterID]; // Loaded from Firestore/config
  // rules: { operation: "addition", minA: 1, maxA: 10, minB: 1, maxB: 10 }

  final random = Random();
  int a = rules.minA + random.nextInt(rules.maxA - rules.minA + 1);
  int b = rules.minB + random.nextInt(rules.maxB - rules.minB + 1);
  int correctAnswer = _calculate(a, b, rules.operation);

  // Generate 3 wrong options that are numerically plausible
  List<int> wrongOptions = _generateWrongOptions(correctAnswer, rules);

  return {
    'prompt': '$a ${_operationSymbol(rules.operation)} $b = ?',
    'correctAnswer': correctAnswer.toString(),
    'options': [...wrongOptions.map((o) => o.toString()), correctAnswer.toString()]..shuffle(),
  };
}
```

---

## 9. Mandarin Stroke Tracing

Dev 1 task — Sprint 3.

### Approach
- Use Flutter's `CustomPainter` and `GestureDetector` to capture touch paths on a canvas
- Each stroke is a list of `Offset` points captured as the user draws
- Stroke order data for each character is stored in the question document (`strokeOrderData` field)
- Validation: compare the direction and rough path of each drawn stroke against the expected stroke data (fuzzy matching — not pixel-perfect)

### Validation strategy (recommended)
- Divide each stroke into a start zone and end zone
- Check that the drawn stroke starts in the correct zone and ends in the correct zone
- Check that strokes are drawn in the correct order
- Do not require pixel-perfect accuracy — 7-year-olds will not draw perfectly

### Characters in scope for V1
Limited to simple Standard 1 Simplified Chinese characters (e.g. 人, 大, 小, 山, 日, 月, 水, 火, 木, 土). Character list to be confirmed by Dev 3 against KSSR Mandarin Chapter 1 content.

### Packages to evaluate
- `flutter_canvas` (custom implementation preferred for full control)
- Stroke order JSON data format: use the open-source Hanzi Writer stroke data format if available in Dart

---

## 10. Push Notifications — FCM

### Notification triggers and payloads

| Event | Trigger | Payload |
|---|---|---|
| Daily goal completed | Session completion causes dailyGoal.todayProgress >= target | `{ type: "goal_complete", childName: String }` |
| Chapter completed | Last level in a chapter is completed | `{ type: "chapter_complete", chapterName: String }` |
| Reward claimed | Child creates a rewardClaim document | `{ type: "reward_claimed", rewardName: String, starCost: int }` |
| Streak at risk | Cloud Function scheduled for 8pm if no session today | `{ type: "streak_risk", currentStreak: int }` |

### Implementation
- Use `firebase_messaging` Flutter package
- For streak-at-risk: use Firebase Cloud Functions with a scheduled function (Cloud Scheduler) to check `lastSessionDate` against today's date at 8pm daily
- Handle foreground and background notification receipt in `FirebaseMessaging.onMessage` and `onMessageOpenedApp`

---

## 11. Internal Admin CMS

Sprint 4 task — Dev 2.

A simple web app (Flutter Web or plain HTML/JS) that writes directly to Firestore with admin credentials. Not user-facing.

### Minimum functions:
- Create/edit/delete questions (all types)
- Upload image to Firebase Storage → store URL in question document
- Link TTS audio file to question
- Configure Maths parametric rules per chapter
- Set quest conditions per outfit

### Access control:
- Protected by a hardcoded admin email or Firebase custom claims
- No public access

---

## 12. Security Rules (Firestore)

```
// Users can only read/write their own data
match /users/{userID} {
  allow read, write: if request.auth.uid == userID;
}

// Parent can read/write their children's data
match /children/{childID} {
  allow read, write: if request.auth.uid == resource.data.parentUID;
}

// Subjects and questions — public read, admin write only
match /subjects/{subjectID} {
  allow read: if request.auth != null;
  allow write: if false; // Only via admin SDK
}

```

---

## 15. Implementation Constraints & Testing Notes

These are specific behavioral constraints and testing requirements extracted from story-level acceptance criteria. Developers should treat these as mandatory alongside the business logic in earlier sections.

### Question engine
- Feedback is shown for **approximately 1.5 seconds** before the Next button becomes active — prevents accidental tapping
- Wrong answers are written to `wrongAnswerBank` **on the feedback screen**, not at session end — partial sessions still produce review data
- Maths wrong option generation must produce **3 numerically plausible, distinct integers** — correct answer must also be in the options, all 4 options must be distinct
- **Unit tests required:** all star threshold boundaries and replay scenarios (BEAR-24); all summary stage escalation transitions and daily cap (BEAR-32); streak increment, consecutive days, gap day reset, same-day replay (BEAR-38); review counter increment, milestone trigger at exactly 20, reset after milestone (BEAR-46)

### Stroke tracing
- Child gets **up to 3 attempts** per character before the correct stroke order is shown automatically
- Failed attempts still flag the question in `wrongAnswerBank`
- Sprint 2 Mandarin questions are MCQ/recognition only — stroke order data and tracing UI are added in Sprint 3

### Animations and sound
- Mascot animations implemented using **Flutter's animation system or a Lottie-compatible package**
- Sound toggle state stored in **SharedPreferences** (local only, not Firestore)
- App respects **system silent mode** — sound is muted if device is on silent
- Sound toggle is accessible from both child and parent mode

### Navigation and first-run state
- **First level of each subject's first chapter is unlocked by default** — no prerequisite
- Tutorial completion state stored in **SharedPreferences** — shown once on first launch only
- Quests tab is accessible from the **bottom navigation bar**
- Active outfit is reflected on the home screen, question feedback screens, and completion screen

### Account recovery
- No custom password reset flow needed — Google Sign-In handles recovery natively
- A "Having trouble signing in?" link on the login screen opens Google's account recovery page in the device browser

### Data deletion cascade
- Full account deletion must cascade through **all subcollections** under the child document:
  `attempts`, `starTransactions`, `wrongAnswerBank`, `levelProgress`, `questProgress`, `rewardClaims`
- Plus: all reward documents under `/users/{parentUID}/rewards/` and the parent user document itself
- Implement via a **Firebase Cloud Function or batched Firestore write** — do not attempt client-side cascade deletion

### Reward claim constraints
- Stars are **never deducted at claim time** — only after parent approval
- Child cannot make a second pending claim on the same reward while one is already pending
- Deleting a reward with a pending claim does **not** affect the pending claim — it runs to completion
- Claim expiry (7 days) is handled by a **Firebase Cloud Function** scheduled daily — not client-side

---

## 13. BearAI — AI Parent Consultation

Sprint 3 task — Dev 2.

BearAI is a Gemini API-powered chat feature in the parent dashboard. It gives parents a personal AI consultant that understands their child's in-app activity and answers questions about progress, rewards, goals, and subject-specific concerns.

### Architecture

- The Flutter app calls the Gemini API directly from the parent dashboard (authenticated parent mode only)
- The API key is stored securely — never hardcoded in the app; retrieved from a Firebase Remote Config or environment config at runtime
- Each BearAI request assembles a context payload from Firestore in real time before calling the API
- No conversation history is stored in Firestore — the chat is session-only in V1

### Context payload structure

Before every API call, Dev 2 assembles the following child data from Firestore and injects it into the system prompt:

```dart
String buildBearAISystemPrompt(Child child, List<SubjectProgress> subjects, List<Attempt> recentAttempts) {
  return """
You are BearAI, a personal learning consultant inside the BearTahan app. 
You help Malaysian parents understand their Standard 1 child's learning progress 
and make better decisions about rewards, daily goals, and subject support.

Always be warm, concise, and actionable. Respond in 3–5 sentences maximum 
unless the parent asks for more detail. Ground every response in the data below.
Never invent data that is not in the context.

CHILD PROFILE:
- Name: ${child.name}, Age: ${child.age}
- Current streak: ${child.currentStreak} days
- Lifetime stars earned: ${child.lifetimeStarsEarned}
- Available stars: ${child.availableStars}
- Daily goal: ${child.dailyGoal.type} — target ${child.dailyGoal.target}, today's progress ${child.dailyGoal.todayProgress}

SUBJECT PROGRESS:
${subjects.map((s) => '- ${s.subjectID}: ${s.completionPercent.toStringAsFixed(0)}% complete, ${s.lessonsCompleted} lessons done').join('\n')}

RECENT SESSION HISTORY (last 14 days):
${recentAttempts.map((a) => '- ${a.subjectID} | ${a.completedAt} | score ${(a.score * 100).toStringAsFixed(0)}% | ${a.timeSeconds}s').join('\n')}

WRONG ANSWER SUMMARY BY SUBJECT:
${subjects.map((s) => '- ${s.subjectID}: ${s.wrongAnswerCount} pending review questions').join('\n')}
""";
}
```

### API call

```dart
Future<String> askBearAi(String message, List<Map<String, String>> history) async {
  final result = await FirebaseFunctions.instanceFor(region: 'asia-southeast1')
      .httpsCallable('askBearAi')
      .call({
    'childId': currentChildId,
    'message': message,
    'history': history,
  });
  return result.data['text'];
}
```

### Prompt Strategy (Gemini 1.5 Flash)

1. **System Instruction**: Set role as "BearAI", provide child context (stars, streak, progress).
2. **Context Injection**: Assemble Firestore data into a structured string.
3. **Chat History**: Pass latest 10 messages for continuity.

### Rate Limiting

- **Cooldown**: 6 seconds between messages per parent.
- **Daily Cap**: 50 messages per parent per day.
- **Enforcement**: Managed via Firestore transactions in Cloud Functions.

For multi-turn conversation within the same session, maintain the message history in local state and pass the full history array on each call:

```dart
// In the chat widget state:
List<Map<String, String>> _messages = [];

Future<void> sendMessage(String userText) async {
  _messages.add({'role': 'user', 'content': userText});

  final response = await http.post(
    // ...same headers...
    body: jsonEncode({
      'model': 'gemini-1.5-flash',
      'max_tokens': 400,
      'system': systemPrompt,
      'messages': _messages, // full history
    }),
  );

  final assistantText = jsonDecode(response.body)['content'][0]['text'];
  _messages.add({'role': 'assistant', 'content': assistantText});
  // Update UI
}
```

### AI Insight Card

The insight card at the top of the BearAI tab is generated once per session when the parent opens the BearAI tab. It calls the API with a fixed prompt:

```dart
const insightPrompt = "In exactly 2–3 sentences, summarise this child's learning activity. "
  "Mention their strongest subject, one area that needs attention, and one specific observation "
  "about their behaviour patterns (e.g. session time, streak, review question accumulation). "
  "Do not use bullet points. Write naturally as a consultant speaking to the parent.";
```

Cache the response in local state for the session so reopening the tab does not re-call the API.

### Suggestion chips

The four suggestion chips map to these fixed prompts sent as user messages:
- "How is [child name] doing this week?" → triggers a weekly summary response
- "Suggest a reward amount" → BearAI recommends a star cost based on current balance and earning pace
- "What daily goal should I set?" → BearAI recommends lessons or minutes based on historical session frequency
- "Which subject needs more focus?" → BearAI identifies the weakest subject by score average and wrong-answer count

### Security note

The Gemini API key must never be bundled in the Flutter app binary. Options:
1. Call the API via a Firebase Cloud Function (recommended) — the function holds the key server-side and the app calls the function
2. Use Firebase Remote Config with server-side key management

For V1 demo purposes, a Cloud Function wrapper is the cleanest approach.

---

## 14. Bear's Den — AI Adaptive Cross-Chapter Challenge

Sprint 4 task — Dev 2 (logic) + Dev 1 (UI). MVP scope: Bahasa Melayu, Chapters 1–3 unlock tier only.

### Overview

Bear's Den reads the child's existing `levelProgress` data to compute chapter strength, then generates a weighted 10-question session drawing from completed chapters. No new data collection is required — all inputs already exist in Firestore. The AI weighting is invisible to the child; they experience it as a mixed cross-chapter challenge.

### Firestore additions to child document

Add two new fields to `/children/{childID}`:
```dart
// Bear's Den state
bearsDenUnlocked: bool,        // true when Chapters 1–3 all completed
bearsDenStarDate: String,      // "YYYY-MM-DD" — last date stars were earned (daily cap)
```

### Unlock condition check

```dart
bool checkBearsDenUnlock(List<LevelProgress> levelProgressList, List<String> requiredChapterIDs) {
  // requiredChapterIDs loaded from Firestore config — e.g. ["bm_ch1", "bm_ch2", "bm_ch3"]
  for (final chapterID in requiredChapterIDs) {
    final chapterLevels = levelProgressList
        .where((lp) => lp.chapterID == chapterID && !lp.isSummaryStage)
        .toList();

    // Chapter is "complete" if all its basic levels have at least 1 star claimed
    final allComplete = chapterLevels.every((lp) => lp.starsClaimedTiers.isNotEmpty);
    if (!allComplete || chapterLevels.isEmpty) return false;
  }
  return true;
}
// Call this on every session completion. If true and bearsDenUnlocked == false:
// set bearsDenUnlocked = true and trigger unlock animation in UI
```

### Chapter strength calculation

```dart
double computeChapterStrength(String chapterID, List<LevelProgress> levelProgressList) {
  final chapterLevels = levelProgressList
      .where((lp) => lp.chapterID == chapterID && !lp.isSummaryStage)
      .toList();

  if (chapterLevels.isEmpty) return -1; // No data — skip chapter

  int maxPossibleStars = chapterLevels.length * 3;
  int starsEarned = chapterLevels.fold(0, (sum, lp) =>
      sum + (lp.starsClaimedTiers.isEmpty ? 0 : lp.starsClaimedTiers.reduce(max)));

  return starsEarned / maxPossibleStars; // 0.0 to 1.0
}

String getStrengthTier(double strengthRatio) {
  if (strengthRatio >= 0.8) return 'strong';
  if (strengthRatio >= 0.5) return 'average';
  return 'needs_work';
}
```

### Weighted question generation

```dart
List<Question> generateBearsDenSession(
    Map<String, String> chapterStrengthTiers, // chapterID → 'strong'|'average'|'needs_work'
    Map<String, List<Question>> questionsByChapter,
    {int totalQuestions = 10}) {

  int needsWorkTarget = (totalQuestions * 0.5).round(); // 50%
  int averageTarget   = (totalQuestions * 0.3).round(); // 30%
  int strongTarget    = totalQuestions - needsWorkTarget - averageTarget; // 20%

  List<Question> session = [];

  void drawFrom(String tier, int count) {
    final eligible = chapterStrengthTiers.entries
        .where((e) => e.value == tier)
        .expand((e) => questionsByChapter[e.key] ?? <Question>[])
        .toList()..shuffle();
    session.addAll(eligible.take(count));
  }

  drawFrom('needs_work', needsWorkTarget);
  drawFrom('average', averageTarget);
  drawFrom('strong', strongTarget);

  // Fill any shortfall (e.g. only one tier available)
  if (session.length < totalQuestions) {
    final all = questionsByChapter.values.expand((q) => q)
        .where((q) => !session.contains(q)).toList()..shuffle();
    session.addAll(all.take(totalQuestions - session.length));
  }

  session.shuffle();
  return session;
}
```

### Firestore queries

```dart
// Fetch levelProgress for BM chapters
final levelProgressSnapshot = await FirebaseFirestore.instance
    .collection('children').doc(childID)
    .collection('levelProgress')
    .where('subjectID', isEqualTo: 'bm')
    .get();

// Fetch questions for completed BM chapters only
final questionsSnapshot = await FirebaseFirestore.instance
    .collection('questions')
    .where('subjectID', isEqualTo: 'bm')
    .where('chapterID', whereIn: completedChapterIDs) // only chapters in the unlock range
    .get();
```

### Star logic

```dart
// Bear's Den stars: ≥70% = 1 star, 100% = 2 stars. Daily cap enforced.
int calculateBearsDenStars(double score) {
  if (score == 1.0) return 2;
  if (score >= 0.7) return 1;
  return 0;
}

bool canEarnBearsDenStarsToday(Child child, String todayDate) {
  return child.bearsDenStarDate != todayDate;
}

// On session completion:
// 1. Calculate stars from score
// 2. If starsEarned > 0 and canEarnBearsDenStarsToday:
//    - Add stars to lifetimeStarsEarned and availableStars
//    - Set bearsDenStarDate = today
//    - Write starTransaction (source: "bears_den")
// 3. Store attempt with source: "bears_den"
// 4. Flag wrong answers to wrongAnswerBank as normal
```

### Parent dashboard — Chapter Insights (Dev 2, part of Story 56)

Surfacing chapter analytics for parents is part of the same story as Bear's Den unlock logic, since it uses identical computed data.

```dart
// After computing chapter strengths for Bear's Den unlock:
// Also write a summary to a parent-readable field for the dashboard

// In parent dashboard, display a "Chapter Insights — Bahasa Melayu" card:
// For each chapter in the Bear's Den range, show:
//   - Chapter name
//   - Star rating (filled/unfilled, e.g. ⭐⭐☆)
//   - Strength badge: Strong (green) / Average (yellow) / Needs Work (red)
// Below the list: "Bear's Den questions are personalised to strengthen weaker chapters."
// This section is PARENT ONLY — never rendered in child mode
```

### UI notes for Dev 1

**Inside BM chapter map (locked state):**
- Tile appears after the Chapter 3 summary stage tile
- Icon: shadowed circle with bear paw print or cave entrance — amber/gold colour (#FFB830)
- Label: "???" with hint text below: "Complete Chapters 1–3 to unlock"
- No tap action in locked state

**Inside BM chapter map (unlocked state):**
- Tile reveals: bear-in-cave icon, label "Bear's Den", small "Chapter Mix" badge
- "NEW" ribbon in top corner on first unlock
- Tappable — navigates to Bear's Den session

**Bear's Den session screen:**
- Header: "Bear's Den" with cave icon — no "AI Generated" badge
- Progress bar and timer: same as regular session
- Each question: small chapter tag in grey below the question text (e.g. "Chapter 2 — Keluarga") — 11px, subtle
- Completion screen: standard stars display + message "Bear's Den complete! Come back tomorrow for more stars ⭐"

**Empty/locked state:**
- If `bearsDenUnlocked == false` and child somehow reaches the tile: show "Complete Chapters 1, 2, and 3 to unlock Bear's Den"

---

## 16. Implementation Consistency Rules & Current State

This section documents constraints and deviations discovered during Sprint 2 stabilisation (commits 46fd21b → 87f77c4). Treat these as mandatory guardrails for all developers going forward.

### 16a. No hardcoded parent or child IDs

All Firestore writes scoped to a parent or child must resolve the parent UID from `parentIdProvider` (Riverpod) or `FirebaseAuth.currentUser`, never from a hardcoded string. Hardcoded demo UIDs (e.g. `demo_child_001`, any fixed UID string) are only acceptable inside mock/seed scripts that are explicitly excluded from production code paths. Violating this causes progress writes to land under the wrong account and is undetectable until a real multi-user test.

### 16b. Child ID resolution in screens

Child-specific screens (profile, rewards, level session, completion) must resolve `childId` using this priority order:
1. Route query parameter (URL/GoRouter query param) — preferred; survives web refresh and deep links
2. `childIdProvider` (Riverpod in-memory state) — fallback for navigation within an app session
3. If neither exists: render the shared `MissingChildProfile` widget (`lib/widgets/common/missing_child_profile.dart`) with a "Select Profile" button routing back to profile selection — never attempt a Firestore stream with an empty child ID

This pattern is required because some team members develop on Chrome, where a page refresh loses in-memory provider state.

### 16c. Firestore transaction scope

Firestore transactions must remain document-focused. A transaction should only `get` and `set`/`update` documents by their known path. Do not run collection queries (`.where(...)`, `.get()` on a collection) inside a transaction — collection queries in transactions are unreliable and cause hard-to-reproduce failures. The current `updateLevelProgress` transaction follows this pattern: it reads the child document and the level document, updates streak and star fields, then commits. Subject progress recalculation (which requires a collection count) runs after the transaction commits as a separate write.

### 16d. Auth — email paths in current implementation

Per design decision D1, the V1 product uses Google Sign-In only. However, the current codebase includes teammate-built email login, registration, and password reset flows used for development and testing convenience. These flows are intact and should not be removed without a team decision. `ParentAccountService` (`lib/services/parent_account_service.dart`) centralises parent document creation/update under `/parents/{uid}` and is used by both Google and email login paths. When in doubt, leave email paths intact; the final V1 demo decision on whether to disable them sits with the PO.

### 16e. Completion screen star resolution

`CompletionScreen` supports two calling conventions:
- Session flow (normal path): passes `stars` directly as a route/constructor parameter — used as-is
- Tests or direct callers: may pass only `score` and `total` — `CompletionScreen` derives stars via `StarUtils` as a fallback

Do not remove the `StarUtils` fallback; it keeps the test suite valid without requiring a full session flow.

### 16f. Android manifest — internet permission

The main `AndroidManifest.xml` (`android/app/src/main/AndroidManifest.xml`) includes `<uses-permission android:name="android.permission.INTERNET"/>`. This is required for all Firebase, network, and audio features. If you create a new product flavour or manifest variant, ensure this permission is present. Do not rely on debug/profile manifests only.

### 16g. Local verification and CI

**Local check (run before every push):**
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1
```
**Local check including APK build (before demo or native-feature work):**
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -BuildApk
```

The script runs: `flutter pub get` → format tracked Dart files → `flutter analyze --no-pub` → `flutter test --no-pub` → optionally `flutter build apk --debug --no-pub`.

**GitHub Actions CI** runs four separate checks on every push: Format · Analyze · Test · Android Debug Build. All four must be green before a PR is merged. If the Android Debug Build check fails on GitHub but tests pass locally, the likely cause is a missing manifest permission, a Gradle configuration issue, or a generated file not committed.

**Current baseline:** 27 tests passing, analyzer clean, APK builds successfully as of commit 87f77c4.
