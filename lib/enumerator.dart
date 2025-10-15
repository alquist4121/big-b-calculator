import 'card.dart';

/// 組合せ全列挙器
class CombinationEnumerator {
  CombinationEnumerator(this.deck, this.drawCount);
  final List<Card> deck;
  final int drawCount;

  /// 全ての組み合わせを反復生成
  Iterable<List<Card>> enumerate() sync* {
    if (drawCount > deck.length) return;
    if (drawCount == 0) {
      yield [];
      return;
    }

    yield* _combinationsRecursive(deck, drawCount, 0, []);
  }

  /// 組み合わせ生成の再帰ヘルパー
  static Iterable<List<Card>> _combinationsRecursive(
    List<Card> deck,
    int count,
    int start,
    List<Card> current,
  ) sync* {
    if (current.length == count) {
      yield List.from(current);
      return;
    }

    for (int i = start; i < deck.length; i++) {
      current.add(deck[i]);
      yield* _combinationsRecursive(deck, count, i + 1, current);
      current.removeLast();
    }
  }

  /// 組み合わせの総数を計算（C(n, k)）
  int get totalCombinations {
    if (drawCount > deck.length) return 0;
    if (drawCount == 0) return 1;

    int result = 1;
    for (int i = 0; i < drawCount; i++) {
      result = result * (deck.length - i) ~/ (i + 1);
    }
    return result;
  }
}
