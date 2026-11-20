// Автотести правил доступу Firestore і Storage (лабораторна №6).
// Запуск (з кореня проєкту):
//   firebase emulators:exec --only firestore,storage --project demo-dimplan \
//     "npm --prefix rules_test test"
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  arrayRemove,
  arrayUnion,
  deleteField,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';

const HOME = 'home1';
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-dimplan',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
    storage: { rules: readFileSync('../storage.rules', 'utf8') },
  });
});

after(() => env.cleanup());

// Андрій (u1) — власник дому, Марія (u2) — учасниця, Олег (u3) — сторонній.
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'households', HOME), {
      name: 'Наша квартира',
      ownerId: 'u1',
      memberIds: ['u1', 'u2'],
      memberNames: { u1: 'Андрій', u2: 'Марія' },
      inviteCode: 'ДІМ-7K4M-92',
    });
    await setDoc(doc(db, 'invites', 'ДІМ-7K4M-92'), { householdId: HOME });
    await setDoc(doc(db, 'households', HOME, 'tasks', 't1'), {
      title: 'Помити підлогу',
      description: '',
      status: 'planned',
      assigneeId: 'u2',
      dueDate: null,
      createdBy: 'u1',
    });
  });
});

const db = (uid) =>
  (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const task = (over = {}) => ({
  title: 'Полити квіти',
  description: '',
  status: 'planned',
  assigneeId: null,
  dueDate: null,
  ...over,
});

describe('users', () => {
  test('власник читає й пише свій профіль', async () => {
    await assertSucceeds(setDoc(doc(db('u1'), 'users/u1'), { name: 'Андрій' }));
    await assertSucceeds(getDoc(doc(db('u1'), 'users/u1')));
  });
  test('чужий профіль недоступний', async () => {
    await assertFails(getDoc(doc(db('u2'), 'users/u1')));
    await assertFails(setDoc(doc(db('u2'), 'users/u1'), { name: 'Хакер' }));
  });
});

describe('households', () => {
  test('учасник бачить дім, сторонній і гість — ні', async () => {
    await assertSucceeds(getDoc(doc(db('u2'), 'households', HOME)));
    await assertFails(getDoc(doc(db('u3'), 'households', HOME)));
    await assertFails(getDoc(doc(db(null), 'households', HOME)));
  });

  test('створення дому разом із кодом одним пакетом', async () => {
    const d = db('u3');
    const batch = writeBatch(d);
    batch.set(doc(d, 'households', 'home2'), {
      name: 'Квартира Олега',
      ownerId: 'u3',
      memberIds: ['u3'],
      memberNames: { u3: 'Олег' },
      inviteCode: 'ДІМ-ABCD-12',
      createdAt: serverTimestamp(),
    });
    batch.set(doc(d, 'invites', 'ДІМ-ABCD-12'), { householdId: 'home2' });
    await assertSucceeds(batch.commit());
  });

  test('не можна створити дім від імені іншого користувача', async () => {
    await assertFails(
      setDoc(doc(db('u3'), 'households', 'home2'), {
        name: 'Чужий дім',
        ownerId: 'u1',
        memberIds: ['u1'],
        memberNames: { u1: 'Андрій' },
      }),
    );
  });

  test('не можна створити код для чужого дому', async () => {
    await assertFails(
      setDoc(doc(db('u3'), 'invites', 'ДІМ-XXXX-99'), { householdId: HOME }),
    );
  });

  test('приєднання: користувач додає лише себе', async () => {
    await assertSucceeds(
      updateDoc(doc(db('u3'), 'households', HOME), {
        memberIds: arrayUnion('u3'),
        'memberNames.u3': 'Олег',
      }),
    );
  });

  test('приєднання не дозволяє змінити назву чи додати іншого', async () => {
    await assertFails(
      updateDoc(doc(db('u3'), 'households', HOME), {
        memberIds: arrayUnion('u3'),
        'memberNames.u3': 'Олег',
        name: 'Мій дім',
      }),
    );
    await assertFails(
      updateDoc(doc(db('u3'), 'households', HOME), {
        memberIds: arrayUnion('u4'),
        'memberNames.u4': 'Хтось',
      }),
    );
  });

  test('назву змінює лише власник', async () => {
    await assertSucceeds(updateDoc(doc(db('u1'), 'households', HOME), { name: 'Хата' }));
    await assertFails(updateDoc(doc(db('u2'), 'households', HOME), { name: 'Дім Марії' }));
  });

  test('учасник змінює лише своє ім\'я у списку', async () => {
    await assertSucceeds(
      updateDoc(doc(db('u2'), 'households', HOME), { 'memberNames.u2': 'Марічка' }),
    );
    await assertFails(
      updateDoc(doc(db('u2'), 'households', HOME), { 'memberNames.u1': 'Андрійко' }),
    );
  });

  test('видаляти учасників може лише власник', async () => {
    await assertFails(
      updateDoc(doc(db('u2'), 'households', HOME), { memberIds: arrayRemove('u1') }),
    );
    await assertSucceeds(
      updateDoc(doc(db('u1'), 'households', HOME), {
        memberIds: arrayRemove('u2'),
        'memberNames.u2': deleteField(),
      }),
    );
    // Після видалення Марія більше не бачить дім.
    await assertFails(getDoc(doc(db('u2'), 'households', HOME)));
  });
});

describe('tasks', () => {
  const tasksOf = (uid) => `households/${HOME}/tasks`;

  test('учасник читає, створює й редагує завдання', async () => {
    await assertSucceeds(getDoc(doc(db('u2'), tasksOf(), 't1')));
    await assertSucceeds(
      setDoc(doc(db('u2'), tasksOf(), 't2'), task({ createdBy: 'u2' })),
    );
    await assertSucceeds(
      updateDoc(doc(db('u2'), tasksOf(), 't1'), { status: 'completed' }),
    );
  });

  test('сторонній не бачить і не змінює завдання', async () => {
    await assertFails(getDoc(doc(db('u3'), tasksOf(), 't1')));
    await assertFails(
      setDoc(doc(db('u3'), tasksOf(), 't2'), task({ createdBy: 'u3' })),
    );
  });

  test('автором можна вказати лише себе, автора не змінити', async () => {
    await assertFails(
      setDoc(doc(db('u2'), tasksOf(), 't2'), task({ createdBy: 'u1' })),
    );
    await assertFails(
      updateDoc(doc(db('u2'), tasksOf(), 't1'), { createdBy: 'u2' }),
    );
  });

  test('перевірка полів: назва обов\'язкова, статус із переліку', async () => {
    await assertFails(
      setDoc(doc(db('u2'), tasksOf(), 't2'), task({ createdBy: 'u2', title: '' })),
    );
    await assertFails(
      setDoc(doc(db('u2'), tasksOf(), 't2'), task({ createdBy: 'u2', status: 'done' })),
    );
  });
});

describe('storage', () => {
  const storage = (uid) => env.authenticatedContext(uid).storage();
  const png = new Uint8Array([137, 80, 78, 71]);

  test('користувач завантажує своє фото JPEG/PNG', async () => {
    await assertSucceeds(
      uploadBytes(ref(storage('u1'), 'users/u1/avatar/1.png'), png, {
        contentType: 'image/png',
      }),
    );
  });

  test('не можна писати в чужу папку, інші типи та файли понад 5 МБ', async () => {
    await assertFails(
      uploadBytes(ref(storage('u2'), 'users/u1/avatar/1.png'), png, {
        contentType: 'image/png',
      }),
    );
    await assertFails(
      uploadBytes(ref(storage('u1'), 'users/u1/avatar/1.gif'), png, {
        contentType: 'image/gif',
      }),
    );
    await assertFails(
      uploadBytes(
        ref(storage('u1'), 'users/u1/avatar/big.png'),
        new Uint8Array(5 * 1024 * 1024 + 1),
        { contentType: 'image/png' },
      ),
    );
  });
});
