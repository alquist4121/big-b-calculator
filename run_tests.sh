#!/bin/bash

# Big-B Calculator テスト実行スクリプト

echo "Big-B Calculator テストスイート実行"
echo "=================================="

# 依存関係の確認
if ! command -v fvm &> /dev/null; then
    echo "エラー: FVMがインストールされていません"
    exit 1
fi

# プロジェクトのセットアップ
echo "依存関係をインストール中..."
fvm flutter pub get

# 基本的な動作確認
echo ""
echo "基本的な動作確認:"
echo "----------------"

# ヘルプ表示テスト
echo "1. ヘルプ表示テスト"
fvm dart run lib/bigb_calc.dart --help

echo ""
echo "2. 基本的な計算テスト"
fvm dart run lib/bigb_calc.dart --hand AcAdAhQsQd --discard Qd

echo ""
echo "3. JSON出力テスト"
fvm dart run lib/bigb_calc.dart --hand AcAdAhQsQd --discard Qd --json

echo ""
echo "4. エラーハンドリングテスト"
echo "重複カードエラー:"
fvm dart run lib/bigb_calc.dart --hand AcAc2d3h4s --discard 4s || echo "期待通りエラーが発生"

echo ""
echo "5. テストケース実行"
echo "------------------"

# 簡単なテストランナーを実行
fvm dart run simple_test.dart

echo ""
echo "テスト完了"
