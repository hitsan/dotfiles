---
name: design
description: アーキテクチャ設計（arch）から詳細モデリング（modeling）まで一貫して実行。新規プロジェクトやフィーチャーの包括的な設計に使用。archとmodelingを順に実行し、コンテキストを引き継ぐ。
---

# Design

## Overview

アーキテクチャレベルから詳細モデリングまで、段階的に設計を進める統合スキル。

### 実行フロー

1. **Architecture Design (arch)**: アーキテクチャパターン選択
2. **Context Bridge**: 情報の整理と橋渡し
3. **Detailed Modeling (modeling)**: データフロー/ステートマシン設計
4. **Integration**: 成果物の統合

### 単独スキルとの使い分け

- **`/design`**: アーキテクチャ + 詳細モデリングの両方が必要な場合
- **`/arch`**: アーキテクチャ設計のみが必要な場合
- **`/modeling`**: 詳細モデリングのみが必要な場合

## Workflow

### Step 1: Architecture Design

**Skillツールでarchスキルを起動:**

```
Skill tool:
- skill: "arch"
```

archスキルの完全なワークフローを実行：
1. 要件のヒアリング（Round 1 & 2）
2. アーキテクチャパターンの選択
3. アーキテクチャ設計（ディレクトリ構造、コンポーネント定義）

**archから取得する情報:**
- アプリケーション種別（Web app, TUI, CLI, etc.）
- 主要機能リスト
- データ処理方法（CRUD-focused / Pipeline-style / Complex business rules / Real-time）
- 状態管理の複雑度（Simple / Moderate / Complex）
- 選択されたアーキテクチャパターン（Clean / Vertical Slice / Flux）

### Step 2: Context Bridge

archで得た情報を整理し、modelingスキルへのコンテキストを準備：

1. **情報の要約:**
   - archの成果物（アーキテクチャ図、ディレクトリ構造）を確認
   - 主要な設計判断を抽出

2. **設計対象機能の選択:**
   AskUserQuestionで確認：
   - 「archで特定した主要機能のうち、どの機能の詳細モデリングを進めますか？」
   - archで得た機能リストから選択肢を提示
   - 複数選択可能

3. **コンテキスト情報の構築:**
   以下の情報をmodelingスキルに渡す準備：
   ```
   Context = {
     app_type: [アプリケーション種別],
     target_features: [選択された機能],
     data_processing: [データ処理方法],
     state_complexity: [状態管理複雑度],
     arch_pattern: [選択されたパターン]
   }
   ```

### Step 3: Detailed Modeling

**Skillツールでmodelingスキルをコンテキストモードで起動:**

modelingスキルの実行時に、Step 2で構築したコンテキスト情報を提示：

1. **コンテキスト情報の提示:**
   - archから引き継いだ情報を要約して表示
   - 「以下の情報を基に詳細モデリングを進めます」

2. **modelingスキルの実行:**
   - Step 0 (Context Handling) でコンテキストありと判断
   - Step 2 (設計手法の判断) から開始
   - データ処理方法と状態管理複雑度から適切な手法を推奨
   - Step 3, 4 で設計を完了

3. **選択した各機能について繰り返し:**
   - 機能が複数ある場合、1つずつモデリング
   - または、ユーザーの希望に応じて並行/一括処理

### Step 4: Integration

arch と modeling の成果物を統合して提示：

**統合成果物の構成:**

1. **Architecture Overview (archから)**
   - 選択されたアーキテクチャパターン
   - アーキテクチャ図（ASCII/Mermaid）
   - ディレクトリ構造
   - レイヤー/スライス/ストアの定義

2. **Detailed Models (modelingから)**
   - 各機能のモデリング成果物：
     - データフロー設計: データ構造定義、フロー図、変換ステップ
     - ステートマシン設計: 状態リスト、遷移図、遷移表
     - 複合設計: 両方 + 統合ガイド

3. **Mapping & Integration**
   - アーキテクチャコンポーネントと詳細モデルの対応関係
   - 例: "UserRegistration機能 → Application/UseCases/RegisterUser + Domain/User"
   - データフローがどのレイヤー/スライスに配置されるか
   - 状態管理がどのコンポーネントで行われるか

4. **Implementation Roadmap**
   - 実装の推奨順序
   - 依存関係の考慮
   - 各機能の実装ガイドライン

**提示形式:**

```
# Design Output

## 1. Architecture Design
[archの成果物]

## 2. Detailed Models
### Feature: [機能名]
[modelingの成果物]

### Feature: [機能名]
[modelingの成果物]

## 3. Architecture-Model Mapping
[対応関係の表/図]

## 4. Implementation Roadmap
[実装ガイド]
```

### Step 5: 設計ファイルの出力

arch と modeling の成果物を別々のファイルに保存する。

**出力ファイル:**
1. `docs/design/機能名-architecture.md` - archスキルの成果物
2. `docs/design/機能名-modeling.md` - modelingスキルの成果物（機能ごと）

各スキルの出力フォーマットに従って保存（詳細は各スキルのSKILL.mdを参照）。

**対話での出力（500字以内）:**
```
✓ 設計完了: [プロジェクト名]

出力:
- アーキテクチャ: docs/design/[プロジェクト名]-architecture.md
- モデリング: docs/design/[機能名]-modeling.md (N件)

[2-3文でのプロジェクト概要、選択したパターン、設計手法の簡潔な説明]
```

## Important Notes

- **段階的な実行**: archとmodelingを明確に分離して実行し、各段階の成果を確認
- **コンテキストの明示**: modelingスキルに渡すコンテキスト情報を常に明示的に提示
- **柔軟な中断/再開**: 各ステップ後にユーザーに確認し、必要に応じて調整可能
- **重複の排除**: archで聞いた内容をmodelingで再度尋ねない
- **統合の重視**: 単に2つのスキルを実行するだけでなく、成果物の統合に注力
- **実装コードは書かない**: あくまで設計/モデリングのみで完了

## Error Handling

### archスキルが失敗した場合
- エラー内容を確認
- 不足情報を補足してarchを再実行
- または、ユーザーに手動でアーキテクチャ情報を提供してもらう

### modelingスキルが失敗した場合
- コンテキスト情報の不足を確認
- 必要に応じて追加ヒアリング
- または、スタンドアロンモードでmodelingを実行

### コンテキスト橋渡しの問題
- archとmodelingの間で情報の不整合が発生した場合
- ユーザーに確認して優先する情報を決定
- 必要に応じてarchに戻って再設計

## Related Skills

- **arch**: アーキテクチャ設計のみ実行
- **modeling**: 詳細モデリングのみ実行（スタンドアロンまたはコンテキストモード）

このスキルは両者を統合し、一貫した設計フローを提供する。
