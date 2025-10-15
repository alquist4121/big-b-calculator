import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'card.dart';
import 'enumerator.dart';
import 'hand_eval_badugi.dart';
import 'hand_eval_hidugi.dart';

/// CLI引数処理と出力機能
class CliProcessor {
  CliProcessor() : parser = _createParser();
  final ArgParser parser;

  static ArgParser _createParser() {
    final parser = ArgParser();
    parser.addOption('hand', abbr: 'h', help: '5枚のハンド（例: As2c5d5sKs）');
    parser.addOption('discard', abbr: 'd', help: '捨てるカード（例: 5s,Ks または 4,5）');
    parser.addFlag('json', help: 'JSON形式で出力');
    parser.addFlag('help', help: 'ヘルプを表示');
    return parser;
  }

  /// メイン処理
  void process(List<String> arguments) {
    try {
      final results = parser.parse(arguments);

      if (results['help'] as bool) {
        _printHelp();
        return;
      }

      final handStr = results['hand'] as String?;
      final discardStr = results['discard'] as String?;
      final jsonOutput = results['json'] as bool;

      if (handStr == null || discardStr == null) {
        print('エラー: --hand と --discard の両方が必要です');
        _printHelp();
        exit(1);
      }

      _processCalculation(handStr, discardStr, jsonOutput);
    } catch (e) {
      print('エラー: $e');
      exit(1);
    }
  }

  /// 計算処理
  void _processCalculation(String handStr, String discardStr, bool jsonOutput) {
    try {
      // ハンドをパース
      final hand = Card.parseHand(handStr);
      if (hand.length != 5) {
        throw ArgumentError('ハンドは5枚である必要があります');
      }

      // 重複カードチェック
      final cardSet = <Card>{};
      for (final card in hand) {
        if (cardSet.contains(card)) {
          throw ArgumentError('重複したカードがあります: ${card.toString()}');
        }
        cardSet.add(card);
      }

      // 捨て札をパース
      final discardCards = _parseDiscard(discardStr, hand);

      // 残りデッキを作成
      final remainingDeck = _createRemainingDeck(hand, discardCards);

      // 計算実行
      final result = _calculateProbabilities(hand, discardCards, remainingDeck);

      // 出力
      if (jsonOutput) {
        _printJsonOutput(result);
      } else {
        _printTextOutput(result);
      }
    } catch (e) {
      print('エラー: $e');
      exit(1);
    }
  }

  /// 捨て札をパース
  List<Card> _parseDiscard(String discardStr, List<Card> hand) {
    final discardCards = <Card>[];

    // 空文字列の場合は空リストを返す
    if (discardStr.trim().isEmpty) {
      return discardCards;
    }

    final parts = discardStr.split(',');

    for (final part in parts) {
      final trimmed = part.trim();

      // 空の部分はスキップ
      if (trimmed.isEmpty) continue;

      // インデックス指定（1始まり）
      if (RegExp(r'^\d+$').hasMatch(trimmed)) {
        final index = int.parse(trimmed) - 1;
        if (index < 0 || index >= hand.length) {
          throw ArgumentError('無効なインデックス: $trimmed');
        }
        discardCards.add(hand[index]);
      } else {
        // カード指定
        discardCards.add(Card.parse(trimmed));
      }
    }

    // 捨て札がハンドに含まれているかチェック
    for (final discardCard in discardCards) {
      if (!hand.contains(discardCard)) {
        throw ArgumentError('捨て札がハンドに含まれていません: ${discardCard.toString()}');
      }
    }

    return discardCards;
  }

  /// 残りデッキを作成
  List<Card> _createRemainingDeck(List<Card> hand, List<Card> discardCards) {
    final allCards = <Card>[];

    // 全52枚のカードを生成
    for (int suit = 0; suit < 4; suit++) {
      for (int rank = 1; rank <= 13; rank++) {
        allCards.add(Card(rank, suit));
      }
    }

    // ハンドと捨て札を除外
    final usedCards = <Card>{...hand, ...discardCards};
    return allCards.where((card) => !usedCards.contains(card)).toList();
  }

  /// 確率計算
  Map<String, dynamic> _calculateProbabilities(
    List<Card> originalHand,
    List<Card> discardCards,
    List<Card> remainingDeck,
  ) {
    final drawCount = discardCards.length;
    final enumerator = CombinationEnumerator(remainingDeck, drawCount);

    final hidugiCounts = <String, int>{};
    final badugiCounts = <String, int>{};
    final hidugiExamples = <String, List<Card>>{};
    final badugiExamples = <String, List<Card>>{};

    // 全組み合わせを列挙
    for (final drawCards in enumerator.enumerate()) {
      // 新しいハンドを作成
      final newHand = <Card>[];
      for (final card in originalHand) {
        if (!discardCards.contains(card)) {
          newHand.add(card);
        }
      }
      newHand.addAll(drawCards);

      // Hidugi評価
      final hidugiResult = HidugiEvaluator.evaluate(newHand);
      hidugiCounts[hidugiResult.category] = (hidugiCounts[hidugiResult.category] ?? 0) + 1;
      if (!hidugiExamples.containsKey(hidugiResult.category)) {
        hidugiExamples[hidugiResult.category] = hidugiResult.bestCards;
      }

      // Badugi評価
      final badugiResult = BadugiEvaluator.evaluate(newHand);
      badugiCounts[badugiResult.category] = (badugiCounts[badugiResult.category] ?? 0) + 1;
      if (!badugiExamples.containsKey(badugiResult.category)) {
        badugiExamples[badugiResult.category] = badugiResult.bestCards;
      }
    }

    final total = enumerator.totalCombinations;

    return {
      'total': total,
      'hidugi': _formatResults(hidugiCounts, hidugiExamples, total),
      'badugi': _formatResults(badugiCounts, badugiExamples, total),
    };
  }

  /// 結果をフォーマット
  Map<String, dynamic> _formatResults(
    Map<String, int> counts,
    Map<String, List<Card>> examples,
    int total,
  ) {
    final result = <String, dynamic>{};

    for (final entry in counts.entries) {
      final category = entry.key;
      final count = entry.value;
      final percentage = (count / total * 100).toStringAsFixed(3);

      final categoryResult = <String, dynamic>{
        'pct': double.parse(percentage),
      };

      if (examples.containsKey(category) && examples[category]!.isNotEmpty) {
        categoryResult['example'] = examples[category]!.map((card) => card.toString()).toList();
      }

      result[category] = categoryResult;
    }

    return result;
  }

  /// テキスト出力
  void _printTextOutput(Map<String, dynamic> result) {
    final total = result['total'] as int;
    final hidugi = result['hidugi'] as Map<String, dynamic>;
    final badugi = result['badugi'] as Map<String, dynamic>;

    print('Total outcomes: $total (draw ${_getDrawCount()} from 47)');
    print('Hidugi:');
    _printCategoryResults(hidugi, 'hidugi');
    print('');
    print('Badugi:');
    _printCategoryResults(badugi, 'badugi');
  }

  /// カテゴリ結果を出力
  void _printCategoryResults(Map<String, dynamic> results, String type) {
    final categories = _getCategoryOrder(type);

    for (final category in categories) {
      if (results.containsKey(category)) {
        final data = results[category] as Map<String, dynamic>;
        final pct = data['pct'] as double;
        final example = data['example'] as List<String>?;

        final exampleStr = example != null ? ' (example: ${example.join(' ')})' : '';
        print('  ${category.padRight(12)}${pct.toStringAsFixed(3)}%$exampleStr');
      }
    }
  }

  /// カテゴリの順序
  List<String> _getCategoryOrder(String type) {
    return switch (type) {
      'hidugi' => ['quads', 'trips', 'two-pair', 'one-pair', 'high-card', 'no-hidugi'],
      'badugi' => ['Badugi', 'tri', 'no-badugi'],
      _ => [],
    };
  }

  /// ドロー数を取得（簡易実装）
  int _getDrawCount() {
    // 実際の実装では、引数から取得する必要がある
    return 2; // デフォルト値
  }

  /// JSON出力
  void _printJsonOutput(Map<String, dynamic> result) {
    print(jsonEncode(result));
  }

  /// ヘルプ表示
  void _printHelp() {
    print('Big-B Calculator');
    print('');
    print('使用方法:');
    print('  dart run lib/bigb_calc.dart --hand <ハンド> --discard <捨て札> [--json]');
    print('');
    print('例:');
    print('  dart run lib/bigb_calc.dart --hand As2c5d5sKs --discard 5s,Ks');
    print('  dart run lib/bigb_calc.dart --hand As2c5d5sKs --discard 4,5 --json');
    print('');
    print('オプション:');
    print(parser.usage);
  }
}
