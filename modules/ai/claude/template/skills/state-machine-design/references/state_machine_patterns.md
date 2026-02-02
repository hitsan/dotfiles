# State Machine Design Patterns

## 一般的な状態遷移パターン

### パターン1: 認証フロー

```
+--------------+  login  +---------------+  auth_success  +-------------+
| Logged Out   |-------->| Authenticating|--------------->| Logged In   |
+--------------+         +---------------+                +-------------+
      ^                        |                                |
      |                        | auth_failure                   |
      |                        | [attempts < 3]                 |
      |                        v                                |
      |                  +--------------+                       |
      +------------------| Login Failed |                       |
                         +--------------+                       |
                               |                                |
                               | auth_failure                   |
                               | [attempts >= 3]                |
                               v                                |
                         +------------+                         |
                         | Locked Out |                         |
                         +------------+                         |
                               |                                |
                               | unlock                         |
                               v                                |
                         +--------------+                       |
                         | Logged Out   |<----------------------+
                         +--------------+        logout
```

**特徴:**
- ガード条件による分岐（失敗回数）
- ループバック（再ログイン）
- ロックアウト機構

---

### パターン2: 注文ワークフロー

```
[*] --> Draft
Draft --> Submitted: submit | [valid]
Draft --> Draft: edit
Submitted --> Processing: approve
Submitted --> Draft: reject
Processing --> Shipped: ship
Processing --> Cancelled: cancel
Shipped --> Completed: confirm_delivery
Completed --> [*]
```

**特徴:**
- 一方向フロー（戻り可能）
- 承認プロセス
- 複数の終了状態（Completed, Cancelled）

---

### パターン3: メディアプレーヤー

```
         +---------+
         | Stopped |<----+
         +---------+     |
              |          |
          play|          |stop
              v          |
         +---------+     |
    +--->| Playing |-----+
    |    +---------+     |
    |         |          |
    |     pause|         |
    |         v          |
    |    +---------+     |
    +----| Paused  |-----+
         +---------+
```

**特徴:**
- 循環構造（play/pause の繰り返し）
- 共通の終了条件（stop）

---

## 実装パターン

### パターンA: Enum + Switch

```typescript
enum State {
  Idle,
  Loading,
  Success,
  Error
}

enum Event {
  Fetch,
  FetchSuccess,
  FetchError,
  Retry
}

function transition(state: State, event: Event): State {
  switch (state) {
    case State.Idle:
      return event === Event.Fetch ? State.Loading : state;
    case State.Loading:
      if (event === Event.FetchSuccess) return State.Success;
      if (event === Event.FetchError) return State.Error;
      return state;
    case State.Error:
      return event === Event.Retry ? State.Loading : state;
    default:
      return state;
  }
}
```

---

### パターンB: State Pattern（オブジェクト指向）

```typescript
interface State {
  handle(event: Event): State;
}

class IdleState implements State {
  handle(event: Event): State {
    if (event === Event.Fetch) return new LoadingState();
    return this;
  }
}

class LoadingState implements State {
  handle(event: Event): State {
    if (event === Event.FetchSuccess) return new SuccessState();
    if (event === Event.FetchError) return new ErrorState();
    return this;
  }
}
```

---

### パターンC: 状態機械ライブラリ（XState など）

```typescript
import { createMachine } from 'xstate';

const machine = createMachine({
  id: 'fetch',
  initial: 'idle',
  states: {
    idle: {
      on: { FETCH: 'loading' }
    },
    loading: {
      on: {
        FETCH_SUCCESS: 'success',
        FETCH_ERROR: 'error'
      }
    },
    success: {},
    error: {
      on: { RETRY: 'loading' }
    }
  }
});
```

---

## アンチパターンと注意点

### ❌ ブーリアンフラグの乱立

```typescript
// 悪い例
let isLoading = false;
let isError = false;
let isSuccess = false;
```

**問題:**
- 不正な状態組み合わせが可能（isLoading && isSuccess など）
- 状態遷移が暗黙的

**改善:**
```typescript
// 良い例
type State = 'loading' | 'error' | 'success';
let state: State = 'loading';
```

---

### ❌ 到達不能な状態

```
[*] --> A
A --> B
C --> D  // C に到達する方法がない
```

**対策:**
- 状態遷移図を描いて全状態の到達可能性を確認
- デッドコードとして削除

---

### ❌ デッドロック状態

```
A --> B
B --> A
// 終了状態への遷移がない
```

**対策:**
- 各状態から終了状態への遷移経路を確保
- タイムアウトやキャンセル機能を追加

---

## テスト戦略

### 遷移パステスト

全ての遷移パスを網羅的にテスト:

```typescript
test('Idle -> Loading -> Success', () => {
  let state = State.Idle;
  state = transition(state, Event.Fetch);
  expect(state).toBe(State.Loading);
  state = transition(state, Event.FetchSuccess);
  expect(state).toBe(State.Success);
});
```

### 不正遷移の拒否テスト

```typescript
test('Success state ignores Fetch event', () => {
  let state = State.Success;
  state = transition(state, Event.Fetch);
  expect(state).toBe(State.Success); // 状態が変わらない
});
```

### エッジケーステスト

- 初期状態での全イベント
- 終了状態での全イベント
- ガード条件の境界値
