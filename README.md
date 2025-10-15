# Big-B Calculator

Big-B（5-card Badugi & 5-card Hidugi）の1回ドロー後の到達役確率を厳密計算するCLIツールです。

## 作るにあたっての履歴

本プロジェクトは、Vibe-Codingで作成されています

- [使用したプロンプト](./docs/)
- [ChatGPTとの対話（要アカウント）](https://chatgpt.com/share/e/68efcf2e-7050-8007-8a9e-3c07071fa6fc)

## 必要な環境

- Flutter SDK 3.35.3
- FVM (Flutter Version Management)

## セットアップ

1. FVMをインストール（未インストールの場合）:

```bash
dart pub global activate fvm
```

2. プロジェクトのFlutterバージョンを設定:

```bash
fvm install 3.35.3
fvm use 3.35.3
```

3. 依存関係をインストール:

```bash
fvm flutter pub get
```

4. ツールを実行:

```bash
fvm dart run lib/bigb_calc.dart --help
```

## 使用方法

### 基本的な使用方法

```bash
# ヘルプを表示
fvm dart run lib/bigb_calc.dart --help

# 基本的な計算例
fvm dart run lib/bigb_calc.dart --hand As2c5d5sKs --discard 5s,Ks

# インデックス指定での計算
fvm dart run lib/bigb_calc.dart --hand As2c5d5sKs --discard 4,5

# JSON形式で出力
fvm dart run lib/bigb_calc.dart --hand As2c5d5sKs --discard 5s,Ks --json
```

### オプション

- `--hand <ハンド>`: 5枚のハンドを指定（例: As2c5d5sKs）
- `--discard <捨て札>`: 捨てるカードを指定（例: 5s,Ks または 4,5）
- `--json`: JSON形式で出力
- `--help`: ヘルプを表示

## 開発

### テストの実行

```bash
# 簡単なテストランナーを実行
fvm dart run simple_test.dart

# 自動テストスクリプトを実行
./run_tests.sh

# 個別テストケースの実行例
fvm dart run lib/bigb_calc.dart --hand AcAdAhAsKd --discard ""
fvm dart run lib/bigb_calc.dart --hand Ac2d3h4s5c --discard 5c
```

### コードの静的解析

```bash
fvm dart analyze
```

## プロジェクト構造

```
├── .fvm/                        # FVMで管理されるFlutterバージョン
├── .fvmrc                       # FVM設定ファイル
├── lib/
│   ├── bigb_calc.dart           # メインエントリーポイント
│   ├── card.dart                # カードクラスとパース機能
│   ├── hand_eval_badugi.dart    # Badugi評価ロジック
│   ├── hand_eval_hidugi.dart    # Hidugi評価ロジック
│   ├── enumerator.dart          # 組合せ全列挙機能
│   └── cli.dart                 # CLI引数処理と出力機能
├── simple_test.dart             # テストランナー
├── run_tests.sh                 # 自動テストスクリプト
├── docs/                        # ドキュメント
│   ├── initial-prompt.md        # 初期実装プロンプト
│   └── unit-test-prompt.md      # テストケース生成プロンプト
├── pubspec.yaml                 # プロジェクト設定
├── analysis_options.yaml        # 静的解析設定
└── README.md                    # このファイル
```

## 機能

### Badugi（ローハンド部門）

- 5枚からスート全異かつランク全異の最も低い4枚を選ぶ
- カテゴリ: `Badugi`（4枚）、`tri`（3枚）、`no-badugi`（2枚以下）

### Hidugi（ハイハンド部門）

- 5枚からスートが全て異なる4枚を選び、通常ハイポーカー準拠で比較
- カテゴリ: `quads`、`trips`、`two-pair`、`one-pair`、`high-card`、`no-hidugi`

### 計算方法

- **全列挙による厳密計算**: 47枚からk枚の組み合わせを全て列挙
- **推測や近似なし**: 正確な確率を出力
- **組合せ数表示**: C(47, k)の総数を表示

## 出力例

### テキスト形式

```
Total outcomes: 1081 (draw 2 from 47)
Hidugi:
  trips       0.463% (example: As 5d Ac Ah)
  two-pair    0.463% (example: As 5d Ac 5h)
  one-pair    18.871% (example: As 5d Ac 2h)
  high-card   28.307% (example: As 5d 3c 4h)
  no-hidugi   51.896%

Badugi:
  Badugi      41.073% (example: As 2c 5d 3h)
  tri         58.927% (example: As 2c 5d)
```

### JSON形式

```json
{
  "total": 1081,
  "hidugi": {
    "trips": {"pct": 0.463, "example": ["As", "5d", "Ac", "Ah"]},
    "two-pair": {"pct": 0.463, "example": ["As", "5d", "Ac", "5h"]},
    "one-pair": {"pct": 18.871, "example": ["As", "5d", "Ac", "2h"]},
    "high-card": {"pct": 28.307, "example": ["As", "5d", "3c", "4h"]},
    "no-hidugi": {"pct": 51.896}
  },
  "badugi": {
    "Badugi": {"pct": 41.073, "example": ["As", "2c", "5d", "3h"]},
    "tri": {"pct": 58.927, "example": ["As", "2c", "5d"]}
  }
}
```

## テスト

### テストスイートの実行

```bash
# 簡単なテストランナー（推奨）
fvm dart run simple_test.dart

# 自動テストスクリプト
./run_tests.sh
```

### テスト結果例

```
Big-B Calculator 簡単テスト
========================================
A1_Hidugi_Quads_100pct: 4スートAでquads確定、4枚Badugiも成立で100%
--------------------------------------------------
✅ 実行成功
✅ 単一結果検証成功

A2_Hidugi_Trips_100pct: 3枚A+2枚Kでtrips確定、4枚Badugiも成立で100%
--------------------------------------------------
✅ 実行成功
✅ 単一結果検証成功

========================================
テスト結果: 7 成功, 1 失敗
成功率: 87.5%
```

## 技術仕様

### 実装詳細

- **Dart 3系対応**: NNBD（null safety）完全対応
- **外部依存最小**: `args`パッケージのみ使用
- **厳密計算**: 全列挙による正確な確率計算
- **エラーハンドリング**: 入力検証と適切なエラーメッセージ
- **柔軟な入力**: カード指定とインデックス指定の両方に対応

### パフォーマンス

- **小規模**: k=1-2の計算は瞬時（47-1081通り）
- **中規模**: k=3の計算は数秒（16215通り）
- **大規模**: k=4-5の計算は数分（178365-1533939通り）
