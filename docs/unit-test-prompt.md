# Big-B Calculator ユニットテストプロンプト

あなたはソフトウェアテストの専門家AIです。対象は「Big-B（5-card Badugi & 5-card Hidugi）」計算機 bigb_calc（Dart CLI）です。
このツールは、5枚手札から指定枚数を交換（全列挙）し、交換後に到達しうる役の分布をカテゴリ別に集計します。
このプロンプトでは、実装検証に使えるテストケース群を自動生成してください。
単なる例ではなく、すぐ自動テスト化できる具体的な「入力・期待値・検証ポイント」を含めてください。

【0) 前提（SUT: System Under Test）】
・実行例: bigb_calc –hand As2c5d5sKs –discard 5s,Ks [–json] [–toy-deck A234]
・交換枚数 k は –discard の数
・全列挙総数（期待値）= 組合せ数 C(残り枚数, k)（通常デッキでは 47 枚から引く）
・出力カテゴリ
	•	Hidugi（ハイ4枚役）: quads / trips / two-pair / one-pair / high-card / no-hidugi
	•	Badugi（ロー4枚役・枚数カテゴリ）: Badugi（4枚）/ tri（3枚）/ no-badugi（2/1/0枚を合算）
・評価ロジック要約
	•	Hidugi: 5枚から「4スート異色の4枚」を選び、ハイポーカー準拠（Aハイ）で役を判定。4スート揃わなければ no-hidugi
	•	Badugi: 5枚から「スート全異・ランク全異の最も低い4枚」。4枚作れれば Badugi、3枚なら tri、2枚以下は no-badugi。Aはロー

【出力フォーマット（厳守）】
すべてのテストを「JSON形式」と「人間可読テキスト」の両方で出力してください。

―― JSON形式（例）ここから ――
{
"tests": [
{
"name": "O1_Hidugi_Quads_1of47",
"hand": "AcAdAhQsQd",
"discard": ["Qd"],
"expect": {
"total": 47,
"hidugi": {"quads": 1},
"badugi": {}
},
"assertions": ["sum_equals_total", "categories_valid"]
},
{
"name": "A1_Badugi_Tri_100pct",
"hand": "Ac2d3h3c5d",
"discard": [],
"expect": {
"total": 1,
"badugi": {"tri": 1},
"hidugi": {}
},
"assertions": ["single_category_100pct"]
}
]
}
―― JSON形式（例）ここまで ――

―― テキスト形式（人間可読サマリ例）ここから ――
・O1_Hidugi_Quads_1of47: As を引いたときのみ4スートAで quads 成立（1/47 ≈ 2.13%）
・A1_Badugi_Tri_100pct: 4枚Badugi不可、3枚構成の tri 固定で100%
―― テキスト形式（例）ここまで ――

【1) 層別に検証する（小さく確実に）】
目的: まず役判定（評価器）の正しさ、次に列挙（全探索）の正しさを検証。

生成要件:
・A-1: 役判定のみで100%決まるケース（k=0）
	•	Hidugi: quads / trips / two-pair / one-pair / high-card / no-hidugi を各1件
	•	Badugi: Badugi / tri / no-badugi を各1件
・A-2: 列挙数検証（k=1〜5）で total = C(47,k) を確認できる代表例
・A-3: カテゴリ合計が total に一致（漏れ・重複なし）

【2) "狙い撃ち"のオラクル付きケースで確率まで検証】
目的: 数学的に正しい確率が明示できるケースで、実装の確率出力を照合。

必須ケース例（同等構造のケースを最低5件）:
・O-1: Hidugi quads = 1/47
hand=AcAdAhQsQd, discard=[Qd], k=1。As 1枚のみが有効 → quads=1, total=47
・O-2: Hidugi trips = 2/47
hand=KcKdQhJsAd, discard=[Ad]。K♥, K♠ の2枚有効 → trips=2, total=47
・O-3: Hidugi no-hidugi = 100%
hand=AcKcQcJc9c, k=0。4スート揃えられず、必ず no-hidugi
・O-4: Badugi = 10/47 型（不足スートを引けば成立）
hand=Ac2d3h9hKd, discard=[9h]。有効な♠が 13−3=10 枚 → Badugi=10, total=47
・O-5: Badugi tri = 100%
hand=Ac2d3h3c5d, k=0。4枚Badugi不可、3枚が最良で tri 確定

【3) メタモルフィック（変形）テストで網羅の穴を埋める】
目的: 変形（順序・スート置換など）後も結果が一定／単調に変化する性質を利用して検証。

生成要件:
・M-1: 順序不変（同一構成で並び替えても分布完全一致）
・M-2: スート置換不変（♣→♦→♥→♠→♣の置換でも分布一致）
・M-3: 非影響カード入替（最良役に関与しないカードを入替しても同分布）
・M-4: 境界（k=0 は単一カテゴリ100%、k=5 は total=C(47,5) かつ合計一致）
・M-5: Badugi単調性（ヒューリスティック）
tri 状態で、不足スート候補の枚数を増やすほど Badugi 確率が上がることを示す比較ペアを2組

【4) 縮小デッキで"人間でも全列挙できる世界"を作って照合】
目的: 玩具デッキ（例: A234×4スート=16枚）で、全探索の整合性を人力で確認しやすくする。

生成要件:
・T-1: toy-deck="A234" で複数の hand / discard（k=0〜3）を用意
	•	total = C(deckSize-5, k)
	•	各カテゴリ件数の合計 = total
	•	確率総和 ≈ 100%（丸め誤差±0.01）
・T-2: 同玩具デッキで順序不変・スート置換不変も成立

【7) すぐ使えるテスト入力テンプレ】
以下フォーマットに従い、合計30件以上（各セクション5件以上）を生成してください。

JSONひな形（そのまま埋めること）:
{
"tests": [
{
"name": "O1_Hidugi_Quads_1of47",
"hand": "AcAdAhQsQd",
"discard": ["Qd"],
"expect": {
"total": 47,
"hidugi": {"quads": 1},
"badugi": {}
},
"assertions": ["sum_equals_total", "categories_valid"]
},
{
"name": "A1_Badugi_Tri_100pct",
"hand": "Ac2d3h3c5d",
"discard": [],
"expect": {
"total": 1,
"badugi": {"tri": 1},
"hidugi": {}
},
"assertions": ["single_category_100pct"]
}
]
}

テキスト（人間可読）ひな形（各テスト1〜3行で意図を書く）:
・O1_Hidugi_Quads_1of47: As を引いたときのみ4スートAで quads 成立（1/47 ≈ 2.13%）
・A1_Badugi_Tri_100pct: 4枚Badugi不可、3枚構成の tri 固定で100%

【生成要件】
・各テストに「意図（なぜその結果になるか）」を1〜3行で記述
・件数指定のないカテゴリは 0 と見なす（省略可）
・期待値は件数（counts）ベースを基本とする（割合は丸め誤差が出やすい）
・テスト名はユニーク。A/M/O/T の頭字＋要点を含める
・assertions に検証タイプ（例: sum_equals_total, suit_invariance, monotonic_increase など）を列挙
・セクションごとに5件以上、全体で30件以上のテストケースを生成

【最終成果物】
	1.	すべてのテストを1つのJSON（tests配列）にまとめた出力
	2.	同内容の人間可読サマリ（各テストの意図説明付き）
	3.	両方をこのプロンプトへの単一応答として返すこと
