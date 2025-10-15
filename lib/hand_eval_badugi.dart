import 'card.dart';

/// Badugi評価結果
class BadugiResult {
  // 最良のカード（代表例用）

  const BadugiResult(this.category, this.bestCards);
  final String category; // "Badugi", "tri", "no-badugi"
  final List<Card> bestCards;
}

/// Badugi評価器
class BadugiEvaluator {
  /// 5枚のハンドからBadugi評価を行う
  static BadugiResult evaluate(List<Card> hand) {
    if (hand.length != 5) {
      throw ArgumentError('Hand must have exactly 5 cards');
    }

    // 4枚のBadugiを探す
    final fourCardResult = _findBestBadugi(hand, 4);
    if (fourCardResult != null) {
      return BadugiResult('Badugi', fourCardResult);
    }

    // 3枚のBadugiを探す
    final threeCardResult = _findBestBadugi(hand, 3);
    if (threeCardResult != null) {
      return BadugiResult('tri', threeCardResult);
    }

    // 2枚のBadugiを探す
    final twoCardResult = _findBestBadugi(hand, 2);
    if (twoCardResult != null) {
      return BadugiResult('no-badugi', twoCardResult);
    }

    // 1枚のBadugiを探す
    final oneCardResult = _findBestBadugi(hand, 1);
    if (oneCardResult != null) {
      return BadugiResult('no-badugi', oneCardResult);
    }

    // 0枚（Badugiなし）
    return const BadugiResult('no-badugi', []);
  }

  /// 指定枚数の最良Badugiを探す
  static List<Card>? _findBestBadugi(List<Card> hand, int targetCount) {
    final combinations = _generateCombinations(hand, targetCount);
    List<Card>? bestBadugi;

    for (final combination in combinations) {
      if (_isValidBadugi(combination)) {
        if (bestBadugi == null || _isBetterBadugi(combination, bestBadugi)) {
          bestBadugi = List.from(combination);
        }
      }
    }

    return bestBadugi;
  }

  /// 指定枚数の組み合わせを生成
  static Iterable<List<Card>> _generateCombinations(List<Card> hand, int count) {
    if (count > hand.length) return [];
    if (count == 0) return [[]];

    return _combinationsRecursive(hand, count, 0, []);
  }

  /// 組み合わせ生成の再帰ヘルパー
  static Iterable<List<Card>> _combinationsRecursive(List<Card> hand, int count, int start, List<Card> current) sync* {
    if (current.length == count) {
      yield List.from(current);
      return;
    }

    for (int i = start; i < hand.length; i++) {
      current.add(hand[i]);
      yield* _combinationsRecursive(hand, count, i + 1, current);
      current.removeLast();
    }
  }

  /// Badugiの有効性をチェック（スート・ランク重複なし）
  static bool _isValidBadugi(List<Card> cards) {
    final suits = <int>{};
    final ranks = <int>{};

    for (final card in cards) {
      if (suits.contains(card.suit) || ranks.contains(card.badugiRank)) {
        return false;
      }
      suits.add(card.suit);
      ranks.add(card.badugiRank);
    }

    return true;
  }

  /// 2つのBadugiの優劣を比較（より良いかどうか）
  static bool _isBetterBadugi(List<Card> a, List<Card> b) {
    // 枚数が違う場合は枚数が多い方が良い
    if (a.length != b.length) {
      return a.length > b.length;
    }

    // 同じ枚数の場合、より低いランクの方が良い
    final sortedA = List.from(a)..sort((x, y) => x.badugiRank.compareTo(y.badugiRank));
    final sortedB = List.from(b)..sort((x, y) => x.badugiRank.compareTo(y.badugiRank));

    for (int i = 0; i < sortedA.length; i++) {
      final rankA = sortedA[i].badugiRank;
      final rankB = sortedB[i].badugiRank;
      if (rankA != rankB) {
        return rankA < rankB; // より低いランクが良い
      }
    }

    return false; // 同じ
  }
}
