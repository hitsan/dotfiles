# Dataflow Design Patterns

## 基本パターン

### パターン1: 線形パイプライン

最もシンプルなデータフロー。データが一方向に流れ、各ステップで変換される。

**ASCII図:**
```
[Input] --> [Transform1] --> [Transform2] --> [Transform3] --> [Output]
```

**例: ユーザーデータの加工**
```
[User API]
    |
    v
+----------+
| fetchAPI |  → Promise<User[]>
+----------+
    |
    v
+-------------+
| validateData|  → User[]
+-------------+
    |
    v
+-----------+
| sortByAge |  → User[]
+-----------+
    |
    v
+-------------+
| formatNames |  → FormattedUser[]
+-------------+
    |
    v
[Result]
```

**関数型表現:**
```typescript
const result = pipe(
  fetchAPI,
  validateData,
  sortByAge,
  formatNames
)(input);
```

---

### パターン2: Map-Filter-Reduce

関数型プログラミングの基本パターン。

**ASCII図:**
```
[Array<T>]
    |
    v
+---------+
|  filter |  → Array<T>
+---------+
    |
    v
+---------+
|   map   |  → Array<U>
+---------+
    |
    v
+---------+
| reduce  |  → U
+---------+
    |
    v
[Result]
```

**例: 売上データの集計**
```
[Sales Data]
    |
    v
+------------------+
| filter(s =>      |
|  s.date >= start)|  → Sale[]
+------------------+
    |
    v
+------------------+
| map(s =>         |
|  s.amount)       |  → number[]
+------------------+
    |
    v
+------------------+
| reduce((sum, a) =>
|  sum + a, 0)     |  → number
+------------------+
    |
    v
[Total Amount]
```

---

### パターン3: 分岐・合流（Fan-out/Fan-in）

データを複数のパスで並列処理し、結果を統合する。

**ASCII図:**
```
            [Input]
               |
               v
          +---------+
          | split   |
          +---------+
               |
      +--------+--------+
      |                 |
      v                 v
 +---------+       +---------+
 | Path A  |       | Path B  |
 +---------+       +---------+
      |                 |
      +--------+--------+
               |
               v
          +---------+
          | merge   |
          +---------+
               |
               v
            [Output]
```

**例: ユーザー統計の並列計算**
```
[User[]]
    |
    v
+--------+
| split  |
+--------+
    |
    +----------+----------+----------+
    |          |          |          |
    v          v          v          v
+------+  +------+  +------+  +------+
|count |  |avgAge|  |names |  |emails|
+------+  +------+  +------+  +------+
    |          |          |          |
    +----------+----------+----------+
                  |
                  v
            +-----------+
            | mergeStats|
            +-----------+
                  |
                  v
           [UserStats]
```

**実装例:**
```typescript
const stats = {
  count: users.length,
  avgAge: average(users.map(u => u.age)),
  names: users.map(u => u.name),
  emails: users.map(u => u.email)
};
```

---

### パターン4: 条件分岐

データの内容に応じて処理を分岐する。

**ASCII図:**
```
    [Input]
       |
       v
  +---------+
  | switch  |
  +---------+
       |
   +---+---+
   |       |
[case A][case B]
   |       |
   v       v
+-----+ +-----+
|procA| |procB|
+-----+ +-----+
   |       |
   +---+---+
       |
       v
   [Output]
```

**例: HTTPステータスによる分岐**
```
[Response]
    |
    v
+---------------+
| checkStatus   |
+---------------+
    |
    +--------+--------+--------+
    |        |        |        |
  [2xx]    [4xx]    [5xx]   [other]
    |        |        |        |
    v        v        v        v
 +----+  +-----+  +-----+  +------+
 |data|  |warn |  |retry|  |error |
 +----+  +-----+  +-----+  +------+
    |        |        |        |
    +--------+--------+--------+
              |
              v
          [Result]
```

---

### パターン5: エラーハンドリング付きフロー

各ステップでエラーが発生する可能性を考慮した設計。

**ASCII図:**
```
[Input]
   |
   v
+------+
|step1 |--[error]--+
+------+           |
   |               |
   v               |
+------+           |
|step2 |--[error]--+
+------+           |
   |               |
   v               |
+------+           |
|step3 |--[error]--+
+------+           |
   |               |
   v               v
[Success]     [ErrorHandler]
```

**Either/Result パターン:**
```typescript
type Result<T, E> = { ok: true, value: T } | { ok: false, error: E };

const process = (input: Input): Result<Output, Error> => {
  const step1 = validate(input);
  if (!step1.ok) return step1;

  const step2 = transform(step1.value);
  if (!step2.ok) return step2;

  return step2;
};
```

---

## 実装パターン

### A. 関数合成（Pipe/Compose）

```typescript
const pipe = <T>(...fns: Function[]) => (x: T) =>
  fns.reduce((v, f) => f(v), x);

const process = pipe(
  parseJSON,
  validateSchema,
  transformData,
  formatOutput
);

const result = process(rawInput);
```

---

### B. Promise チェーン（非同期パイプライン）

```typescript
fetchData(url)
  .then(parseJSON)
  .then(validateData)
  .then(transformData)
  .then(saveToDatabase)
  .catch(handleError);
```

---

### C. Observable/Stream（リアクティブ）

```typescript
import { from } from 'rxjs';
import { map, filter, reduce } from 'rxjs/operators';

from(users)
  .pipe(
    filter(u => u.age >= 18),
    map(u => u.name),
    reduce((acc, name) => [...acc, name], [])
  )
  .subscribe(result => console.log(result));
```

---

## アンチパターンと注意点

### ❌ 副作用の乱用

```typescript
// 悪い例: 入力を直接変更
function addAge(user) {
  user.age += 1;  // 副作用
  return user;
}
```

**改善:**
```typescript
// 良い例: 新しいオブジェクトを返す
function addAge(user) {
  return { ...user, age: user.age + 1 };
}
```

---

### ❌ 複雑すぎる単一関数

```typescript
// 悪い例: 一つの関数で全てを処理
function processUser(raw) {
  const parsed = JSON.parse(raw);
  const valid = validate(parsed);
  const transformed = transform(valid);
  return format(transformed);
}
```

**改善:**
```typescript
// 良い例: パイプラインに分解
const processUser = pipe(
  parseJSON,
  validate,
  transform,
  format
);
```

---

### ❌ エラーハンドリングの欠如

```typescript
// 悪い例: エラーを考慮していない
const result = pipe(
  step1,  // 失敗するかも
  step2,  // 失敗するかも
  step3
)(input);
```

**改善:**
```typescript
// 良い例: Either/Result パターン
const result = pipe(
  step1,
  andThen(step2),
  andThen(step3)
)(input);

if (result.ok) {
  console.log(result.value);
} else {
  console.error(result.error);
}
```

---

## テスト戦略

### 単体テスト（各ステップ）

```typescript
test('filter adults', () => {
  const users = [
    { name: 'Alice', age: 30 },
    { name: 'Bob', age: 17 }
  ];
  const result = filterAdults(users);
  expect(result).toEqual([{ name: 'Alice', age: 30 }]);
});
```

### 統合テスト（全体フロー）

```typescript
test('full pipeline', () => {
  const input = '[{"name":"Alice","age":30}]';
  const result = pipe(
    parseJSON,
    filterAdults,
    extractNames
  )(input);
  expect(result).toEqual(['Alice']);
});
```

### プロパティベーステスト

```typescript
test('pipeline preserves data count', () => {
  // フィルタリングしない場合、件数は変わらない
  fc.assert(
    fc.property(fc.array(fc.record({ name: fc.string() })), (users) => {
      const result = pipe(map(u => u.name))(users);
      return result.length === users.length;
    })
  );
});
```

---

## パフォーマンス最適化

### 遅延評価（Lazy Evaluation）

大量データの場合、全体を一度に処理せず、必要な分だけ処理する。

```typescript
// Eager（全データを処理）
const result = users
  .filter(u => u.age >= 18)
  .map(u => u.name)
  .slice(0, 10);  // 最終的に10件だけ必要

// Lazy（必要な分だけ処理）
const result = users
  .take(10)  // 先に制限
  .filter(u => u.age >= 18)
  .map(u => u.name);
```

### 並列処理

独立した処理は並列実行する。

```typescript
const [stats, names, emails] = await Promise.all([
  calculateStats(users),
  extractNames(users),
  extractEmails(users)
]);
```
