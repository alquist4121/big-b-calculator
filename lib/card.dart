/// カードを表すクラス
class Card {
  // スート（0-3、c=0, d=1, h=2, s=3）

  const Card(this.rank, this.suit);
  final int rank; // ランク（1-13、A=1, K=13）
  final int suit;

  /// カード文字列をパース（例: "As" -> Card(1, 3)）
  static Card parse(String cardStr) {
    if (cardStr.length != 2) {
      throw ArgumentError('Invalid card format: $cardStr');
    }

    final rankChar = cardStr[0];
    final suitChar = cardStr[1];

    // ランクの解析
    int rank;
    switch (rankChar) {
      case 'A':
        rank = 1;
        break;
      case 'K':
        rank = 13;
        break;
      case 'Q':
        rank = 12;
        break;
      case 'J':
        rank = 11;
        break;
      case 'T':
        rank = 10;
        break;
      default:
        if (rankChar.codeUnitAt(0) >= '2'.codeUnitAt(0) && rankChar.codeUnitAt(0) <= '9'.codeUnitAt(0)) {
          rank = rankChar.codeUnitAt(0) - '0'.codeUnitAt(0);
        } else {
          throw ArgumentError('Invalid rank: $rankChar');
        }
    }

    // スートの解析
    int suit;
    switch (suitChar) {
      case 'c':
        suit = 0;
        break;
      case 'd':
        suit = 1;
        break;
      case 'h':
        suit = 2;
        break;
      case 's':
        suit = 3;
        break;
      default:
        throw ArgumentError('Invalid suit: $suitChar');
    }

    return Card(rank, suit);
  }

  /// ハンド文字列をパース（例: "As2c5d5sKs" -> [Card, Card, Card, Card, Card]）
  static List<Card> parseHand(String handStr) {
    if (handStr.length % 2 != 0) {
      throw ArgumentError('Invalid hand format: $handStr');
    }

    final cards = <Card>[];
    for (int i = 0; i < handStr.length; i += 2) {
      final cardStr = handStr.substring(i, i + 2);
      cards.add(parse(cardStr));
    }

    return cards;
  }

  /// カードを文字列に変換
  @override
  String toString() {
    final rankStr = switch (rank) {
      1 => 'A',
      10 => 'T',
      11 => 'J',
      12 => 'Q',
      13 => 'K',
      _ => rank.toString(),
    };

    final suitStr = switch (suit) {
      0 => 'c',
      1 => 'd',
      2 => 'h',
      3 => 's',
      _ => throw StateError('Invalid suit: $suit'),
    };

    return rankStr + suitStr;
  }

  /// ハンドを文字列に変換
  static String handToString(List<Card> hand) {
    return hand.map((card) => card.toString()).join(' ');
  }

  /// Hidugi用のランク（A=14）
  int get hidugiRank => rank == 1 ? 14 : rank;

  /// Badugi用のランク（A=1）
  int get badugiRank => rank;

  @override
  bool operator ==(Object other) {
    if (other is! Card) return false;
    return rank == other.rank && suit == other.suit;
  }

  @override
  int get hashCode => rank * 4 + suit;
}
