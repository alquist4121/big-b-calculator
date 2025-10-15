import 'card.dart';

/// Hidugi評価結果
class HidugiResult {
  // 最良のカード（代表例用）

  const HidugiResult(this.category, this.bestCards);
  final String category; // "quads", "trips", "two-pair", "one-pair", "high-card", "no-hidugi"
  final List<Card> bestCards;
}

/// Hidugi評価器
class HidugiEvaluator {
  /// 5枚のハンドからHidugi評価を行う
  static HidugiResult evaluate(List<Card> hand) {
    if (hand.length != 5) {
      throw ArgumentError('Hand must have exactly 5 cards');
    }

    // 4枚でスートが全て異なる組み合わせを探す
    final fourCardCombinations = _generateCombinations(hand, 4);
    List<Card>? bestHidugi;

    for (final combination in fourCardCombinations) {
      if (_hasAllDifferentSuits(combination)) {
        if (bestHidugi == null || _isBetterHidugi(combination, bestHidugi)) {
          bestHidugi = List.from(combination);
        }
      }
    }

    if (bestHidugi == null) {
      return const HidugiResult('no-hidugi', []);
    }

    final category = _getHandCategory(bestHidugi);
    return HidugiResult(category, bestHidugi);
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

  /// 4枚のカードが全て異なるスートかチェック
  static bool _hasAllDifferentSuits(List<Card> cards) {
    if (cards.length != 4) return false;

    final suits = <int>{};
    for (final card in cards) {
      if (suits.contains(card.suit)) {
        return false;
      }
      suits.add(card.suit);
    }
    return true;
  }

  /// 2つのHidugiの優劣を比較（より良いかどうか）
  static bool _isBetterHidugi(List<Card> a, List<Card> b) {
    final categoryA = _getHandCategory(a);
    final categoryB = _getHandCategory(b);

    // カテゴリの強さを比較
    final strengthA = _getCategoryStrength(categoryA);
    final strengthB = _getCategoryStrength(categoryB);

    if (strengthA != strengthB) {
      return strengthA > strengthB; // より強いカテゴリが良い
    }

    // 同じカテゴリの場合、詳細比較
    return _compareSameCategory(a, b, categoryA);
  }

  /// カテゴリの強さ（数値が大きいほど強い）
  static int _getCategoryStrength(String category) {
    return switch (category) {
      'quads' => 5,
      'trips' => 4,
      'two-pair' => 3,
      'one-pair' => 2,
      'high-card' => 1,
      _ => 0,
    };
  }

  /// 同じカテゴリ内での詳細比較
  static bool _compareSameCategory(List<Card> a, List<Card> b, String category) {
    final ranksA = a.map((card) => card.hidugiRank).toList()..sort((x, y) => y.compareTo(x));
    final ranksB = b.map((card) => card.hidugiRank).toList()..sort((x, y) => y.compareTo(x));

    return switch (category) {
      'quads' => _compareQuads(ranksA, ranksB),
      'trips' => _compareTrips(ranksA, ranksB),
      'two-pair' => _compareTwoPair(ranksA, ranksB),
      'one-pair' => _compareOnePair(ranksA, ranksB),
      'high-card' => _compareHighCard(ranksA, ranksB),
      _ => false,
    };
  }

  /// ハンドのカテゴリを判定
  static String _getHandCategory(List<Card> cards) {
    final ranks = cards.map((card) => card.hidugiRank).toList();
    final rankCounts = <int, int>{};

    for (final rank in ranks) {
      rankCounts[rank] = (rankCounts[rank] ?? 0) + 1;
    }

    final counts = rankCounts.values.toList()..sort((x, y) => y.compareTo(x));

    if (counts[0] == 4) return 'quads';
    if (counts[0] == 3) return 'trips';
    if (counts[0] == 2 && counts[1] == 2) return 'two-pair';
    if (counts[0] == 2) return 'one-pair';
    return 'high-card';
  }

  /// Quads比較
  static bool _compareQuads(List<int> ranksA, List<int> ranksB) {
    // 4枚のランクを比較
    final quadA = ranksA[0]; // 4枚のランク
    final quadB = ranksB[0];
    if (quadA != quadB) return quadA > quadB;

    // キッカー比較
    return ranksA[4] > ranksB[4];
  }

  /// Trips比較
  static bool _compareTrips(List<int> ranksA, List<int> ranksB) {
    // 3枚のランクを比較
    final tripsA = ranksA[0]; // 3枚のランク
    final tripsB = ranksB[0];
    if (tripsA != tripsB) return tripsA > tripsB;

    // キッカー比較
    return ranksA[3] > ranksB[3];
  }

  /// Two-pair比較
  static bool _compareTwoPair(List<int> ranksA, List<int> ranksB) {
    // 高いペア比較
    final highPairA = ranksA[0];
    final highPairB = ranksB[0];
    if (highPairA != highPairB) return highPairA > highPairB;

    // 低いペア比較
    final lowPairA = ranksA[2];
    final lowPairB = ranksB[2];
    if (lowPairA != lowPairB) return lowPairA > lowPairB;

    // キッカー比較
    return ranksA[4] > ranksB[4];
  }

  /// One-pair比較
  static bool _compareOnePair(List<int> ranksA, List<int> ranksB) {
    // ペアランク比較
    final pairA = ranksA[0];
    final pairB = ranksB[0];
    if (pairA != pairB) return pairA > pairB;

    // キッカー比較（降順）
    for (int i = 2; i < 4; i++) {
      if (ranksA[i] != ranksB[i]) {
        return ranksA[i] > ranksB[i];
      }
    }
    return false;
  }

  /// High-card比較
  static bool _compareHighCard(List<int> ranksA, List<int> ranksB) {
    // 降順で辞書順比較
    for (int i = 0; i < 4; i++) {
      if (ranksA[i] != ranksB[i]) {
        return ranksA[i] > ranksB[i];
      }
    }
    return false;
  }
}
