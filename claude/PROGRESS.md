# 試作機1 — 実装済み機能まとめ

## マップ

- 150×150タイルのグリッドマップ（灰色塗りつぶし）
- 黄色の外枠ライン（8px）
- 資源スポット（緑の円）を1200個ランダム配置（シード固定）

## コマンダー

- 青い正方形（P1）を左上エリアにスポーン
- クリックで選択・白枠で選択状態を表示
- 右クリックで移動（`move_to`）
- 複数選択時は円形にオフセット分散

## 選択システム

- ドラッグで矩形選択（SelectionBox）
- ドラッグ閾値8px（誤作動防止）
- 地面クリックで選択解除

## カメラ

- WASD移動・マウス中ボタンドラッグ
- ホイールズーム

## CommanderHUD（底部UI）

- コマンダー選択時に画面下部に表示
- 建物ボタン8種（PAスタイル）
- アンロック済み：Metal Extractor、Power Generator
- ロック済み：Factory、Turret、Shield Gen、Radar、Wall、Adv Factory
- ホバー・アクティブ状態のスタイル切り替え

## Metal Extractor 配置

- HUDのボタンを押すと配置モードに入る
- マウスに最寄りの資源スポットに吸い込み（Snap、半径 TILE_SIZE×0.6）
- 赤いスナップリング = 既存Extractorに近すぎて置けない（100px以内）
- 左クリックで1個ずつ配置
- **ドラッグで範囲選択→一括キュー追加**（最近傍ルートで順番最適化）
- Shiftを押しながら配置すると配置モードを継続
- コマンダーが射程外の資源はクリックすると自動移動→到着後に建設開始（Move-and-Claim）
- 建設中は青いラインとキュー表示、3秒で完成
- 完成資源には青いリング表示
- 右クリックでキャンセル

## 衝突

- コマンダーが資源スポットに重ならないようプッシュ処理あり（半径36px）

## ネットワーク

- WebSocket（`ws://127.0.0.1:8080`）で自動接続・3秒ごとに再接続試行
- コマンダー位置を50msごとにサーバーに送信
- 他プレイヤーのコマンダーを赤い正方形でリアルタイム表示
- プレイヤーの入退室を検知してスポーン／削除

## コードリファクタ（2026-05-15）

- `scripts/main.gd` を大幅整理、マネージャー3つに分離
- `scripts/managers/factory_manager.gd` — Factory配置・建設・ユニット生産キュー
- `scripts/managers/resource_manager.gd` — 資源スポット管理・Extractor配置
- `scripts/managers/selection_controller.gd` — ドラッグ選択・ユニット移動
- `scripts/factory_hud.gd` — Factory選択時のHUD
- `scripts/units/unit.gd` — ユニット基底クラス（旧`scripts/unit.gd`）
- `scripts/units/commander.gd` / `infantry.gd` / `tank.gd` — ユニット種別スクリプト
- `scenes/units/commander.tscn` / `infantry.tscn` / `tank.tscn` — ユニットシーン
- `claude/units.md` — ユニット仕様書追加

---

## 未実装（試作機2以降）

- コマンダーのHP・攻撃
- ファクトリーからのユニット生産（infantry/tankスポーンロジック）
- 資源の流入・消費（メタル / エネルギー）
- ドラフトシステム
- タイタンユニット
- ローカル2人対戦・リマッチ
