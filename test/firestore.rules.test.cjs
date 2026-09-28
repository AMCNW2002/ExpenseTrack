const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {after, before, beforeEach, test} = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {Timestamp, increment} = require('firebase/firestore');

const projectId = 'spendly-rules-tests';
let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8082,
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('users/alice').set({
      name: 'Alice Example',
      email: 'alice@example.com',
      phone: null,
      photoUrl: null,
      createdAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),
      updatedAt: null,
    });
    await db.doc('expenses/alice-expense').set(expense('alice'));
    await db.doc('budgets/alice_2026_09').set(budget('alice'));
    await db.doc('goals/alice-goal').set(goal('alice'));
  });
});

after(async () => {
  await environment.cleanup();
});

function expense(userId) {
  const now = Timestamp.fromDate(new Date('2026-09-01T00:00:00Z'));
  return {
    userId,
    title: 'Lunch',
    amount: 850,
    category: 'Food',
    date: now,
    note: null,
    receiptUrl: null,
    createdAt: now,
  };
}

function budget(userId) {
  return {
    userId,
    totalBudget: 50000,
    categoryBudgets: {Food: 10000},
    month: 9,
    year: 2026,
    createdAt: Timestamp.fromDate(new Date('2026-09-01T00:00:00Z')),
    updatedAt: Timestamp.fromDate(new Date('2026-09-01T00:00:00Z')),
  };
}

function goal(userId) {
  return {
    userId,
    title: 'Emergency fund',
    targetAmount: 10000,
    savedAmount: 2500,
    targetDate: null,
    note: null,
    createdAt: Timestamp.fromDate(new Date('2026-09-01T00:00:00Z')),
    updatedAt: null,
  };
}

test('signed-in users can read only their own documents', async () => {
  const alice = environment.authenticatedContext('alice', {
    email: 'alice@example.com',
  }).firestore();
  const bob = environment.authenticatedContext('bob', {
    email: 'bob@example.com',
  }).firestore();

  await assertSucceeds(alice.doc('users/alice').get());
  await assertFails(bob.doc('users/alice').get());
  await assertSucceeds(
    alice.collection('expenses').where('userId', '==', 'alice').get(),
  );
  await assertFails(alice.collection('expenses').get());
  await assertFails(bob.doc('expenses/alice-expense').get());
  await assertFails(bob.doc('budgets/alice_2026_09').get());
  await assertFails(bob.doc('goals/alice-goal').get());
});

test('unauthenticated access is denied', async () => {
  const db = environment.unauthenticatedContext().firestore();
  await assertFails(db.doc('users/alice').get());
  await assertFails(db.collection('expenses').get());
});

test('users can update their own profile but not another user profile', async () => {
  const db = environment.authenticatedContext('alice', {
    email: 'alice@example.com',
  }).firestore();

  await assertSucceeds(db.doc('users/alice').update({
    name: 'Alice Updated',
    phone: '5551234',
    updatedAt: Timestamp.now(),
  }));
  await assertFails(db.doc('users/bob').set({
    name: 'Bob',
    email: 'bob@example.com',
    createdAt: Timestamp.now(),
  }));
});

test('expense ownership cannot be spoofed or transferred', async () => {
  const alice = environment.authenticatedContext('alice', {
    email: 'alice@example.com',
  }).firestore();

  await assertSucceeds(alice.collection('expenses').add(expense('alice')));
  await assertFails(alice.collection('expenses').add(expense('bob')));
  await assertFails(alice.doc('expenses/alice-expense').update({userId: 'bob'}));
  await assertSucceeds(alice.doc('expenses/alice-expense').delete());
});

test('owners can create budget merge documents, update budgets, and delete them', async () => {
  const db = environment.authenticatedContext('alice', {
    email: 'alice@example.com',
  }).firestore();
  const budgetRef = db.doc('budgets/alice_2026_10');

  await assertSucceeds(budgetRef.set({
    userId: 'alice',
    totalBudget: 0,
    month: 10,
    year: 2026,
    updatedAt: Timestamp.now(),
  }, {merge: true}));
  await assertSucceeds(budgetRef.set({
    userId: 'alice',
    totalBudget: 40000,
    month: 10,
    year: 2026,
    updatedAt: Timestamp.now(),
  }, {merge: true}));
  await assertFails(db.doc('budgets/alice_2026_11').set({
    userId: 'bob',
    totalBudget: 30000,
    month: 11,
    year: 2026,
  }));
  await assertSucceeds(budgetRef.delete());
});

test('goal owners can atomically add progress but cannot transfer ownership', async () => {
  const db = environment.authenticatedContext('alice', {
    email: 'alice@example.com',
  }).firestore();
  const goalRef = db.doc('goals/alice-goal');

  await Promise.all([
    assertSucceeds(goalRef.update({
      savedAmount: increment(500),
      updatedAt: Timestamp.now(),
    })),
    assertSucceeds(goalRef.update({
      savedAmount: increment(1000),
      updatedAt: Timestamp.now(),
    })),
  ]);
  const updatedGoal = await goalRef.get();
  assert.equal(updatedGoal.data().savedAmount, 4000);
  await assertFails(goalRef.update({userId: 'bob'}));
  await assertSucceeds(db.collection('goals').add(goal('alice')));
});