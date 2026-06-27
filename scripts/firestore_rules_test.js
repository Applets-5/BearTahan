const fs = require("node:fs");
const path = require("node:path");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {doc, getDoc, setDoc, updateDoc} = require("firebase/firestore");

const projectId = "beartahan-rules-test";
const rules = fs.readFileSync(
  path.join(__dirname, "..", "firestore.rules"),
  "utf8",
);

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {rules},
  });

  try {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "parents/parent-a"), {name: "Parent A"});
      await setDoc(doc(db, "parents/parent-a/children/child-a"), {name: "Ali"});
      await setDoc(doc(db, "subjects/bm"), {name: "Bahasa Melayu"});
      await setDoc(doc(db, "subjects/bm/chapters/c1"), {name: "Chapter 1"});
      await setDoc(doc(db, "questions/bm_c1_l1_q01"), {text: "Question"});
      await setDoc(doc(db, "outfitQuests/scholar"), {name: "Scholar"});
      await setDoc(doc(db, "privateConfig/internal"), {enabled: true});
    });

    const unauthenticated = testEnv.unauthenticatedContext().firestore();
    const parentA = testEnv.authenticatedContext("parent-a").firestore();
    const parentB = testEnv.authenticatedContext("parent-b").firestore();

    await assertFails(getDoc(doc(unauthenticated, "parents/parent-a")));
    await assertSucceeds(getDoc(doc(parentA, "parents/parent-a")));
    await assertSucceeds(
      updateDoc(doc(parentA, "parents/parent-a/children/child-a"), {age: 7}),
    );
    await assertFails(getDoc(doc(parentB, "parents/parent-a")));
    await assertFails(
      updateDoc(doc(parentB, "parents/parent-a/children/child-a"), {age: 8}),
    );

    await assertSucceeds(getDoc(doc(parentA, "subjects/bm")));
    await assertSucceeds(getDoc(doc(parentA, "subjects/bm/chapters/c1")));
    await assertSucceeds(getDoc(doc(parentA, "questions/bm_c1_l1_q01")));
    await assertSucceeds(getDoc(doc(parentA, "outfitQuests/scholar")));
    await assertFails(
      setDoc(doc(parentA, "questions/new-question"), {text: "No"}),
    );
    await assertFails(
      updateDoc(doc(parentA, "subjects/bm"), {name: "Changed"}),
    );
    await assertFails(getDoc(doc(parentA, "privateConfig/internal")));

    console.log("Firestore rules tests passed.");
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
