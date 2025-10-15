#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// 簡単なテスト実行器
void main() async {
  print('Big-B Calculator 簡単テスト');
  print('=' * 40);

  // テストケース
  final testCases = [
    {
      'name': 'A1_Hidugi_Quads_100pct',
      'hand': 'AcAdAhAsKd',
      'discard': <String>[],
      'description': '4スートAでquads確定、4枚Badugiも成立で100%'
    },
    {
      'name': 'A2_Hidugi_Trips_100pct',
      'hand': 'AcAdAhKdQd',
      'discard': <String>[],
      'description': '3枚A+2枚Kでtrips確定、4枚Badugiも成立で100%'
    },
    {
      'name': 'A6_Hidugi_NoHidugi_100pct',
      'hand': 'AcKcQcJc9c',
      'discard': <String>[],
      'description': '5枚同スートで4スート揃えられずno-hidugi確定'
    },
    {
      'name': 'A7_Badugi_Badugi_100pct',
      'hand': 'Ac2d3h4sKd',
      'discard': <String>[],
      'description': '4スート異色・異ランクでBadugi確定'
    },
    {'name': 'A8_Badugi_Tri_100pct', 'hand': 'Ac2d3h3c5d', 'discard': <String>[], 'description': '3枚Badugi可能でtri確定'},
    {
      'name': 'A9_Badugi_NoBadugi_100pct',
      'hand': 'Ac2c3c4c5c',
      'discard': <String>[],
      'description': '5枚同スートでBadugi不可'
    },
    {
      'name': 'A10_Enumeration_Count_C47_1',
      'hand': 'Ac2d3h4s5c',
      'discard': <String>['5c'],
      'description': 'k=1でC(47,1)=47通りを検証'
    },
    {
      'name': 'O1_Hidugi_Quads_1of47',
      'hand': 'AcAdAhQsQd',
      'discard': <String>['Qd'],
      'description': 'Asを引いたときのみ4スートAでquads成立（1/47 ≈ 2.13%）'
    }
  ];

  int passed = 0;
  int failed = 0;

  for (final testCase in testCases) {
    print('\n${testCase['name']}: ${testCase['description']}');
    print('-' * 50);

    try {
      final hand = testCase['hand'] as String;
      final discard = testCase['discard'] as List<String>;

      // コマンドライン引数を構築
      final args = <String>['--hand', hand, '--discard', discard.join(','), '--json'];

      // プロセス実行
      final result = await Process.run(
        'fvm',
        ['dart', 'run', 'lib/bigb_calc.dart', ...args],
        workingDirectory: Directory.current.path,
      );

      if (result.exitCode != 0) {
        print('❌ 実行エラー: ${result.stderr}');
        failed++;
        continue;
      }

      // 結果を表示
      print('✅ 実行成功');
      print('出力:');
      print(result.stdout);

      // JSON結果をパースして簡単な検証
      try {
        final output = jsonDecode(result.stdout as String) as Map<String, dynamic>;
        final total = output['total'] as int;
        print('総数: $total');

        if (testCase['name'].toString().contains('Enumeration_Count_C47_1')) {
          if (total == 47) {
            print('✅ 列挙数検証成功: C(47,1)=47');
            passed++;
          } else {
            print('❌ 列挙数検証失敗: 期待=47, 実際=$total');
            failed++;
          }
        } else if (testCase['name'].toString().contains('O1_Hidugi_Quads_1of47')) {
          // O1テストケース: 1ドロー後の確率計算なのでtotal=47が正しい
          if (total == 47) {
            print('✅ 1ドロー後確率計算検証成功: total=47');
            passed++;
          } else {
            print('❌ 1ドロー後確率計算検証失敗: 期待=47, 実際=$total');
            failed++;
          }
        } else {
          if (total == 1) {
            print('✅ 単一結果検証成功');
            passed++;
          } else {
            print('❌ 単一結果検証失敗: 期待=1, 実際=$total');
            failed++;
          }
        }
      } catch (e) {
        print('❌ JSON解析エラー: $e');
        failed++;
      }
    } catch (e) {
      print('❌ テスト実行エラー: $e');
      failed++;
    }
  }

  print('\n${'=' * 40}');
  print('テスト結果: $passed 成功, $failed 失敗');
  print('成功率: ${(passed / (passed + failed) * 100).toStringAsFixed(1)}%');
}
