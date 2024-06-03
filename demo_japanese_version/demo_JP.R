# Copyright (c) Meta Platforms, Inc. and its affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

# 本ソースコードは下記URLのMMeta MMM Open Source Robynのデモコードの日本語版です。
# https://github.com/facebookexperimental/Robyn/blob/main/demo/demo.R

#############################################################################################
####################         Meta MMM Open Source: Robyn 3.10.5       #######################
####################  　              クイックデモガイド                  ######################
#############################################################################################

# MetaオープンソースRobynを使用した高度なマーケティングミックスモデリング（Blueprintトレーニング）
# https://www.facebookblueprint.com/student/path/253121-marketing-mix-models?utm_source=demo

################################################################
#### ステップ 0: 環境設定

## 以下の2つのソースのいずれかを使用して、Robynの最新バージョンをインストール、ロード、チェックする:
## A) CRANから最新の安定版をインストールする:
# install.packages("Robyn")
## B) GitHubから最新の開発版をインストールする:
# install.packages("remotes") # remotesがインストールされていない場合、最初にインストールする
remotes::install_github("facebookexperimental/Robyn/R")
library(Robyn)

# このデモを実行する前に、最新バージョンをインストールしているかどうか確認してください。そうでない場合はアップデートしてください。
# https://github.com/facebookexperimental/Robyn/blob/main/R/DESCRIPTION#L4
packageVersion("Robyn")
# また、最新の開発版よりも古いバージョンを使用している場合は、古いdemo.Rを次のようにしてチェックしてください。
# https://github.com/facebookexperimental/Robyn/blob/vX.X.X/demo/demo.R

## RStudioの実行時にマルチコアを強制的に使用する
Sys.setenv(R_FUTURE_FORK_ENABLE = "true")
options(future.fork.enable = TRUE)

# ローカルにファイルを作成しないようにするにはFALSEに設定する
create_files <- TRUE

## 重要：Robynを使用する前に、pythonライブラリ "Nevergrad"をインストールし、セットアップする必要があります。
## ガイド: https://github.com/facebookexperimental/Robyn/blob/main/demo/install_nevergrad.R

################################################################
#### ステップ 1: データの読み込み

## シミュレーションデータセットをチェックするか、独自のデータセットをロードする
data("dt_simulated_weekly")
head(dt_simulated_weekly)

## Prophetに登録されている祝日の情報をチェックする
# 59カ国が含まれています。もしあなたの国が含まれていなければ、手動で追加してください。
# Tip: 学校の休みやイベントなどのイベントをこのテーブルに追加することができます。
data("dt_prophet_holidays")
head(dt_prophet_holidays)

## 日本の祝日を使いたい場合:
# 下記URLから日本の祝日データのCSVファイルをダウンロード
# https://github.com/yu-ya-tanaka/Robyn-Community-Japan-Resource/blob/main/jp_holiday.csv
# ダウンロードしたCSVファイルを任意のフォルダに配置し読み込む。以下は例
jp_holiday = read.csv('~/Desktop/Robyn Work/jp_holiday.csv')
head(jp_holiday)


# 結果をエクスポートするディレクトリを設定（新しいフォルダが作成されます。）
robyn_directory <- "~/Desktop"

################################################################
#### ステップ 2a: 初めてRobynを利用する方向け: 4ステップでモデルを指定する

#### 2a-1: 1.入力変数を指定する

## 全ての符号は自動的に制御されます: メディア変数とオーガニック変数は正の値、それ以外はデフォルト
## 必要であれば、カスタマイズも可能です。
## 次のコードを実行することで、ドキュメントにアクセスできます: ?robyn_inputs
InputCollect <- robyn_inputs(
  dt_input = dt_simulated_weekly,
  # dt_holidays = dt_prophet_holidays,
  dt_holidays = jp_holiday, # 日本の祝日を使い場合。上記で読み込んだ祝日データを指定
  date_var = "DATE", # 日付の書式は "2020-01-01"
  dep_var = "revenue", # 目的変数は1つのみ
  dep_var_type = "revenue", # "revenue" (ROI)、もしくは"conversion" (CPA)を指定可能
  prophet_vars = c("trend", "season", "holiday"), # "trend"、"season"、"weekday"、"holiday"を指定可能。複数可
  # prophet_country = "DE", # 国名コードを入力。詳細は dt_prophet_holidays をチェックしてください。
  prophet_country = "JP", # 国コードを"JP"に指定
  context_vars = c("competitor_sales_B", "events"), # 例: 競合、割引率、失業率など
  paid_media_spends = c("tv_S", "ooh_S", "print_S", "facebook_S", "search_S"), # 必須項目
  paid_media_vars = c("tv_S", "ooh_S", "print_S", "facebook_I", "search_clicks_P"), # 必須項目
  # paid_media_varsはpaid_media_spendsと同じ順序でなければなりません。
  # インプレッション、GRPなどのメディア露出指標を使用してください。該当しない場合は、代わりにspendを使用してください。
  organic_vars = "newsletter", # コストを伴わないマーケティング活動
  # factor_vars = c("events"), # context_varsまたはorganic_varsの変数を強制的にカテゴリー変数にする
  window_start = "2016-01-01",
  window_end = "2018-12-31",
  adstock = "geometric" # geometric、weibull_cdf、weibull_pdf
)
print(InputCollect)

#### 2a-2: 2. ハイパーパラメータの定義と追加

## モデリング用のデフォルトのメディア変数がpaid_media_varsからpaid_media_spendsに変更されました。
## また、calibration_inputで入力するメディア名はpaid_media_spendsと同じ名前でなければなりません。
## ハイパーパラメータ名もpaid_media_spendsの入力に基づきます。ハイパーパラメータ名を参照する:
hyper_names(adstock = InputCollect$adstock, all_media = InputCollect$all_media)

## ハイパーパラメータを理解し設定するためのガイド

## Robynのハイパーパラメータには4つの要素があります:
## - アドストックのパラメータ (theta or shape/scale)
## - 飽和曲線のパラメータ (alpha/gamma)
## - 正則化パラメータ(lambda)、手動設定は不要
## - 時系列検証のパラメータ (train_size)

## 1. 重要: plot = TRUEにすることで、アドストックと飽和曲線のハイパーパラメータの影響を可視化したプロットを作成します。
plot_adstock(plot = FALSE)
plot_saturation(plot = FALSE)

## 2. 正しいハイパーパラメータ名を取得する:
# paid_media_spendsとorganic_varsの変数はすべてハイパーパラメーターを必要とし、アドストックと飽和曲線によって変換されます。
# hyper_names(adstock = InputCollect$adstock, all_media = InputCollect$all_media)
# を実行することで正しいメディアハイパーパラメータ名を取得できます。ハイパーパラメータの名前はすべて、
# hyper_names()で取得できる名前と同じでなければならず、大文字と小文字は区別されます。?hyper_names で関数の引数をチェックできます。

## 3. ハイパーパラメータの解釈と推奨:
## Geometricアドストック: thetaが唯一のパラメータで、固定減衰率を意味する。1日目に就航したTVCMが100円で、
# シータが0.7だとすると、2日目は1日目から100*0.7=70円分の効果が持ち越され、3日目は2日目から70*0.7=49円分の
# 効果が持ち越されます。メディアジャンルごとの一般的な値: TV: c(0.3, 0.8)、OOH/印刷/ラジオ: c(0.1, 0.4)、
# デジタル: c(0, 0.3)。また、週次を日次に変換するには、パラメータを(1/7)のべき乗に変換すればよく、
# 日次30%を週次に変換するには、0.3^(1/7)=0.84となります。

## Weibull CDFアドストック: 累積分布関数（CDF）のWeibull分布にはshapeとscaleの二つのパラメータがあり、
# 固定された減衰率を持つ幾何減衰と比較して柔軟な減衰率を持ちます。
# shapeパラメータは減衰曲線の形状を制御します。推奨される範囲はc(0, 2)です。
# shapeが大きいほど、S字型になります。shapeが小さいほど、L字型になります。
# scaleは減衰曲線の変曲点を制御します。scaleが広告効果の半減期を大幅に増加させるため、
# c(0, 0.1)という非常に保守的な範囲を推奨します。
# shapeまたはscaleが0の場合、広告効果は0になります。

## Weibull PDFアドストック: Weibull分布の確率密度関数（PDF）も同様にshapeとscaleの二つのパラメータを持ち、
# Weibull CDFと同様に柔軟な減衰率を持ちます。CDFとの違いは、Weibull PDFが遅延効果を提供する点です。
# shapeが2以上の場合、曲線はx=0の後にピークを迎え、x=0での勾配がNULLになるため、
# 遅延効果と広告効果の急激な増減が可能になります。scaleパラメータはx軸上のピークの相対位置の限界を示します。
# shapeが1より大きく2未満の場合、曲線はx=0の後にピークを迎え、x=0での勾配が無限に正になります。
# これにより、遅延効果と広告効果の緩やかな増減が可能になり、scaleは上記と同じ効果を持ちます。
# shapeが1の場合、曲線はx=0でピークを迎え、指数減衰に収束し、scaleは変曲点を制御します。
# shapeが0より大きく1未満の場合、曲線はx=0でピークを迎え、増加する減衰を持ち、scaleは変曲点を制御します。
# すべての可能なshapeを想定する場合、shapeの範囲としてc(0.0001, 10)を推奨します。
# 強い遅延効果のみが関心の対象である場合shapeの範囲としてc(2.0001, 10)を推奨します。
# すべての場合において、scaleの範囲としてc(0, 0.1)という保守的な範囲を推奨します。
# Weibull PDFの非常に柔軟な特性により、Nevergradが探索するハイパーパラメータ空間の自由度が増し、
# 収束にはより多くのイテレーションが必要です。shapeまたはscaleが0の場合、広告効果は0になります。

## 飽和効果のためのHill関数: Hill関数は、Robynにおいてalphaとgammaの二つのパラメータを持つ関数です。
# alphaは曲線の形状を指数関数形状とS字形状の間で制御します。推奨範囲はc(0.5, 3)です。
# alphaが大きいほど、S字形状になります。alphaが小さいほど、C字形状になります。
# gammaは変曲点を制御します。推奨範囲はc(0.3, 1)です。gammaが大きいほど、反応曲線の変曲点が遅れます。

## リッジ回帰の正則化: lambdaは正則化回帰のためのペナルティ項です。
# lambdaはユーザーが手動で定義する必要はありません。デフォルトでハイパーパラメータ内の範囲がc(0, 1)に設定されており、
# lambda_maxおよびlambda_min_ratioによって適切な高さにスケーリングされます。

## 時系列検証: robyn_run()においてts_validation = TRUEの場合、train_sizeは学習、検証、およびサンプル外テストに使用される
# データの割合を定義します。例えば、train_size = 0.7の場合、val_sizeおよびtest_sizeはそれぞれ0.15になります。
# このハイパーパラメータはカスタマイズ可能で、デフォルト範囲はc(0.5, 0.8)であり、c(0.1, 1)の間でなければなりません。

## 4. 個々のハイパーパラメータの範囲を設定します。それらはc(0, 0.5)のように二つの値を含むか、
# あるいは一つの値のみを含み、その場合はそのハイパーパラメータを「固定」します。
# hyper_limits()を実行して範囲による最大上限と下限を確認してください。
hyper_limits()

# 例: Geometricアドストックの場合のハイパーパラメータの範囲設定
hyperparameters <- list(
  facebook_S_alphas = c(0.5, 3),
  facebook_S_gammas = c(0.3, 1),
  facebook_S_thetas = c(0, 0.3),
  print_S_alphas = c(0.5, 3),
  print_S_gammas = c(0.3, 1),
  print_S_thetas = c(0.1, 0.4),
  tv_S_alphas = c(0.5, 3),
  tv_S_gammas = c(0.3, 1),
  tv_S_thetas = c(0.3, 0.8),
  search_S_alphas = c(0.5, 3),
  search_S_gammas = c(0.3, 1),
  search_S_thetas = c(0, 0.3),
  ooh_S_alphas = c(0.5, 3),
  ooh_S_gammas = c(0.3, 1),
  ooh_S_thetas = c(0.1, 0.4),
  newsletter_alphas = c(0.5, 3),
  newsletter_gammas = c(0.3, 1),
  newsletter_thetas = c(0.1, 0.4),
  train_size = c(0.5, 0.8)
)

# 例: Weibull CDFアドストックの場合のハイパーパラメータの範囲設定
# facebook_S_alphas = c(0.5, 3)
# facebook_S_gammas = c(0.3, 1)
# facebook_S_shapes = c(0, 2)
# facebook_S_scales = c(0, 0.1)

# 例: Weibull PDFアドストックの場合のハイパーパラメータの範囲設定
# facebook_S_alphas = c(0.5, 3)
# facebook_S_gammas = c(0.3, 1)
# facebook_S_shapes = c(0, 10)
# facebook_S_scales = c(0, 0.1)

#### 2a-3: 3. robyn_inputs() にハイパーパラメータを追加する

InputCollect <- robyn_inputs(InputCollect = InputCollect, hyperparameters = hyperparameters)
print(InputCollect)

#### 2a-4: 4. (オプショナル) モデルの補正/リフトテスト結果の追加

## モデルの補正（キャリブレーション）のガイド

# 1. キャリブレーションを行うチャネルはpaid_media_spendsまたはorganic_varsの名前である必要があります。
# 2. キャリブレーションする際には、自由度が高いWeibull PDFアドストックを使用することを強く推奨します。
# 3. リフトテストなどの実験的手法の結果を使用してMMMをキャリブレーションすることを強く推奨します。
#    通常の実験タイプは、人ベース（例: Facebookのコンバージョンリフト）または地域ベース（例: Facebook GeoLift）です。
#    実験におけるテスト群とコントロール群の性質上、結果は即時効果と見なされます。実験においてテスト以前の
#    キャリーオーバー効果を保持することはほぼ不可能です。したがって、即時および将来のキャリーオーバー効果のみを
#    キャリブレーションします。実験的手法の結果でキャリブレーションする場合、calibration_scope = "immediate"を使用します。
# 4. アトリビューション/MTAの貢献を使用してMMMをキャリブレーションすることは議論の余地があります。
#    アトリビューションはローワーファネルチャンネルに偏っており、シグナルの質に強く影響されると考えられています。
#    MTAでキャリブレーションする場合、calibration_scope = "immediate"を使用します。
# 5. MMMはそれぞれ異なるため、2つのMMMが比較可能かどうかは非常に文脈依存です。他のMMM結果を使用してRobynを
#    キャリブレーションする場合、calibration_scope = "total"を使用します。
# 6. 現在、Robynはキャリブレーションの入力として点推定のみを受け入れます。例えば、チャンネルAに対して10,000円の支出が
#    ホールドアウトでテストされた場合、以下の例のように純増リターンを点推定として入力します。
# 7. 点推定は常に変数内の支出と一致している必要があります。例えば、チャンネルAが通常100,000円/週の支出を持ち、
#    テストで設定したホールドアウト（非接触群）が70%である場合、70,000円ではなく30,000円のポイント推定を入力します。
# 8. もしテストが複数のメディア変数を含む場合、"channel_A+channel_B"と入力してチャンネルの組み合わせを示します。
#    大文字は小文字を区別します。

# calibration_input <- data.frame(
#   # チャネル名、paid_media_varsに存在する値である必要があります
#   channel = c("facebook_S",  "tv_S", "facebook_S+search_S", "newsletter"),
#   # liftStartDateは入力データ範囲内でなければなりません
#   liftStartDate = as.Date(c("2018-05-01", "2018-04-03", "2018-07-01", "2017-12-01")),
#   # liftEndDateは入力データ範囲内でなければなりません
#   liftEndDate = as.Date(c("2018-06-10", "2018-06-03", "2018-07-20", "2017-12-31")),
#   # 提供された値は、モデル内の同じキャンペーンレベルでテストされ、dep_var_typeと同じ指標でなければなりません
#   liftAbs = c(400000, 300000, 700000, 200),
#   # テストにおける支出: 各チャネルの日付範囲における支出がdt_inputと10%以内の誤差で一致している必要があります
#   spend = c(421000, 7100, 350000, 0),
#   # 信頼性: 頻度主義に基づくテスト結果の場合、1 - p値を使用できます
#   confidence = c(0.85, 0.8, 0.99, 0.95),
#   # 測定されたKPI: dep_varと一致している必要があります
#   metric = c("revenue", "revenue", "revenue", "revenue"),
#   # "immediate"または"total"のいずれか。Facebook Liftのような実験的入力には、"immediate"が推奨です
#   calibration_scope = c("immediate", "immediate", "immediate", "immediate")
# )
# InputCollect <- robyn_inputs(InputCollect = InputCollect, calibration_input = calibration_input)


################################################################
#### ステップ 2b: モデルの仕様が既知の場合、ワンステップでセットアップが可能

## 2a-2で指定したようにハイパーパラメータを指定し、オプショナルでステップ2a-4のキャリブレーションも指定して、robyn_inputs()へ直接渡します。

# InputCollect <- robyn_inputs(
#   dt_input = dt_simulated_weekly
#   ,dt_holidays = dt_prophet_holidays
#   ,date_var = "DATE"
#   ,dep_var = "revenue"
#   ,dep_var_type = "revenue"
#   ,prophet_vars = c("trend", "season", "holiday")
#   ,prophet_country = "DE"
#   ,context_vars = c("competitor_sales_B", "events")
#   ,paid_media_spends = c("tv_S", "ooh_S",	"print_S", "facebook_S", "search_S")
#   ,paid_media_vars = c("tv_S", "ooh_S", 	"print_S", "facebook_I", "search_clicks_P")
#   ,organic_vars = c("newsletter")
#   ,factor_vars = c("events")
#   ,window_start = "2016-11-23"
#   ,window_end = "2018-08-22"
#   ,adstock = "geometric"
#   ,hyperparameters = hyperparameters # 上記2a-2の通り
#   ,calibration_input = calibration_input # 上記2a-4の通り
# )

#### 出稿金額と露出量の適合性をチェックする（paid_media_varsで露出量がインプットされている場合）
if (length(InputCollect$exposure_vars) > 0) {
  lapply(InputCollect$modNLS$plots, plot)
}

##### InputCollectをJSONファイルとして手動で保存してインポートする
# robyn_write(InputCollect, dir = "~/Desktop")
# InputCollect <- robyn_inputs(
#   dt_input = dt_simulated_weekly,
#   dt_holidays = dt_prophet_holidays,
#   json_file = "~/Desktop/RobynModel-inputs.json")

################################################################
#### ステップ 3: 初期モデルを構築する

## すべてのトライアルとイテレーションを実行する。?robyn_run でパラメータ定義を確認可能
OutputModels <- robyn_run(
  InputCollect = InputCollect, # 全てのモデル仕様をフィードする
  cores = NULL, # デフォルトはNULLで利用可能な最大値 - 1が設定される
  iterations = 2000, # ダミーデータセットでキャリブレーションを行わない場合、2000が推奨
  trials = 5, # ダミーデータセットの場合、5が推奨
  ts_validation = TRUE, # NRMSEの検証のため、時系列に3分割を行う
  add_penalty_factor = FALSE # 実験的な機能なため、使用する際は注意
)
print(OutputModels)

## MOO（多目的最適化）収束プロットを確認する
# 収束ルールについての詳細はこちらを参照してください: ?robyn_converge
OutputModels$convergence$moo_distrb_plot
OutputModels$convergence$moo_cloud_plot

## 時系列検証プロットを確認する（ts_validation = TRUEの場合）
# 詳細を確認し、結果を再現するにはこちらを参照してください: ?ts_validation
if (OutputModels$ts_validation) OutputModels$ts_validation_plot

## パレートフロントの計算、クラスタリング、結果とプロットを出力します。詳細はこちらを参照してください: ?robyn_outputs
OutputCollect <- robyn_outputs(
  InputCollect, OutputModels,
  pareto_fronts = "auto", # min_candidates（100）を満たすために、パレートフロントの数を自動的に選択する
  # min_candidates = 100, # クラスタリングのためのトップパレートモデル、デフォルトは100
  # calibration_constraint = 0.1, # 範囲はc(0.01, 0.1)で、デフォルトは0.1
  csv_out = "pareto", # "pareto"、"all"、またはNULL（なしの場合）
  clusters = TRUE, # ROASによる類似モデルのクラスタリングを有効にする。詳細はこちらを参照してください: ?robyn_clusters
  export = create_files, # ローカルファイルを作成する
  plot_folder = robyn_directory, # プロットをエクスポートしファイルを作成するパス
  plot_pareto = create_files # モデルのone-pagersのプロットと保存を無効にするにはFALSEに設定します
)
print(OutputCollect)

## 今後の結果の活用に役立つ、4つのCSVファイルがフォルダにエクスポートされます。スキーマはこちらを参照してください:
## https://github.com/facebookexperimental/Robyn/blob/main/demo/schema.R
# pareto_hyperparameters.csv, パレート出力モデルごとのハイパーパラメータ
# pareto_aggregated.csv, すべてのパレート出力の独立変数ごとの集計分解
# pareto_media_transform_matrix.csv, すべてのメディア変換ベクトル
# pareto_alldecomp_matrix.csv, 説明変数のすべての分解ベクトル


################################################################
#### ステップ 4: 任意のモデルを選択して保存する

## すべてのモデルのone-pagersを比較し、現実のビジネスを最もよく反映されるものを選択します
print(OutputCollect)
select_model <- "1_12_6" # OutputCollectから選択したモデルの1つを選択して続行します

#### バージョン >=3.7.1: JSONのエクスポートとインポート（RDSファイルよりも高速で軽量）
ExportedModel <- robyn_write(InputCollect, OutputCollect, select_model, export = create_files)
print(ExportedModel)

# 任意のモデルのone-pagersをプロットする場合:
myOnePager <- robyn_onepagers(InputCollect, OutputCollect, select_model, export = FALSE)

# それぞれのone-pagerのプロットをチェックする場合:
# myOnePager[[select_model]]$patches$plots[[1]]
# myOnePager[[select_model]]$patches$plots[[2]]
# myOnePager[[select_model]]$patches$plots[[3]] # ...

################################################################
#### ステップ 5: 上記で選択したモデルに基づいて予算配分を取得する

## 予算配分の結果はさらに検証が必要です。ここで得られる推奨結果は慎重に使用してください。
## 選択したモデルがビジネス上の期待に合わない場合、予算配分の結果をそのまま解釈しないでください。

# 選択したモデルのメディアサマリーを確認します
print(ExportedModel)

# パラメータの定義を確認するには ?robyn_allocator を実行してください

# 注意: 制約の順序は以下に従う必要があります:
InputCollect$paid_media_spends

# シナリオ "max_response": "過去の支出額の実績において最大のリターンを得るには？"
# 例 1: max_response のデフォルト設定: 最新月のリターンを最大化
AllocatorCollect1 <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  # date_range = "all", # デフォルトは"all"
  # total_budget = NULL, # NULLの場合、デフォルトは内のdate_rangeの期間のトータル支出額
  channel_constr_low = 0.7,
  channel_constr_up = c(1.2, 1.5, 1.5, 1.5, 1.5),
  # channel_constr_multiplier = 3,
  scenario = "max_response",
  export = create_files
)
# アロケーターの出力をプリント＆プロットする
print(AllocatorCollect1)
plot(AllocatorCollect1)

# 例 2: 指定された支出額で最新の10期間のリターンを最大化する
AllocatorCollect2 <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  date_range = "last_10", # 直近10期間、c("2018-10-22", "2018-12-31")と同じ
  total_budget = 5000000, # date_range期間のシミュレーションのための総予算
  channel_constr_low = c(0.8, 0.7, 0.7, 0.7, 0.7),
  channel_constr_up = c(1.2, 1.5, 1.5, 1.5, 1.5),
  channel_constr_multiplier = 5, # より広範なインサイトを得るために制約範囲をカスタマイズ
  scenario = "max_response",
  export = create_files
)
print(AllocatorCollect2)
plot(AllocatorCollect2)

# シナリオ "target_efficiency": "ROASまたはCPAの目標を達成するためにどれだけ支出すべきか?"
# 例 3: デフォルトのROASターゲット（目的変数がrevenueの場合）またはCPAターゲット（目的変数がconversionの場合）を使用します
# InputCollect$dep_var_typeでrevenueまたはconversionのタイプを確認します
# 2つのデフォルトのROASターゲット: 初期ROASの0.8倍およびROAS=1
# 2つのデフォルトのCPAターゲット: 初期CPAの1.2倍および2.4倍
AllocatorCollect3 <- robyn_allocator(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  # date_range = NULL, # デフォルトで最新月を初期期間として設定
  scenario = "target_efficiency",
  # target_value = 2, # カスタマイズしたターゲットROASまたはCPA
  export = create_files
)
print(AllocatorCollect3)
plot(AllocatorCollect3)

# 例 4: ROASまたはCPAのターゲット値をカスタマイズする（json_fileを使用）
json_file = "~/Desktop/Robyn_202406031014_init/RobynModel-1_12_6.json"
AllocatorCollect4 <- robyn_allocator(
  json_file = json_file, # 予算配分のためにrobyn_write()で作成したjsonファイルを使用する
  dt_input = dt_simulated_weekly,
  dt_holidays = dt_prophet_holidays,
  date_range = NULL, # デフォルトで最新月を初期期間として設定
  scenario = "target_efficiency",
  target_value = 2, # カスタマイズしたターゲットROASまたはCPA
  plot_folder = "~/Desktop/my_dir",
  plot_folder_sub = "my_subdir",
  export = create_files
)

## 今後の結果の活用に役立つ、CSVファイルがフォルダにエクスポートされます。スキーマはこちらを参照してください:
## https://github.com/facebookexperimental/Robyn/blob/main/demo/schema.R

## QA optimal response
# 任意のメディア変数を選択: InputCollect$all_media
select_media <- "search_S"
# paid_media_spendsの場合、metric_valueを最適な支出として設定します
metric_value <- AllocatorCollect1$dt_optimOut$optmSpendUnit[
  AllocatorCollect1$dt_optimOut$channels == select_media
]; metric_value
# # paid_media_varsおよびorganic_varsの場合、手動で値を選択します
# metric_value <- 10000

## アドストック効果を考慮した飽和曲線の例
robyn_response(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  metric_name = select_media,
  metric_value = metric_value,
  date_range = "last_5"
)

################################################################
#### ステップ 6: 選択したモデルと保存された結果に基づいてモデルをリフレッシュする

## リフレッシュの前に、最初に任意のモデルをエクスポートするためにrobyn_write()を実行する必要があります（手動または自動で）。
## robyn_refresh()関数は「合理的な期間内」の更新に適しています。
## モデルを再構築する方が良いと考えられる2つの状況があります:
## 1. ほとんどのデータが新しい場合。初期モデルが100週間分のデータを持ち、更新時に80週間の新しいデータが追加される場合、
##    モデルを再構築する方が良いかもしれません。経験則では、データの50%以下が新しい場合はリフレッシュが望ましいです。
## 2. 新しい変数が追加された場合。

# InputCollectおよびExportedModelの仕様を含むJSONファイルを渡します。
# 初期モデルでもリフレッシュ後のモデルでもかまいません。
json_file = "~/Desktop/Robyn_202406031014_init/RobynModel-1_12_6.json"
RobynRefresh <- robyn_refresh(
  json_file = json_file,
  dt_input = dt_simulated_weekly,
  dt_holidays = dt_prophet_holidays,
  refresh_steps = 13,
  refresh_iters = 1000, # 1k is an estimation
  refresh_trials = 1
)

# 同じアプローチに従って、更新されたモデルを再度更新します
json_file_rf1 <- "~/Desktop/Robyn_202406031014_init/Robyn_202406031019_rf1/RobynModel-1_109_9.json"
RobynRefresh <- robyn_refresh(
  json_file = json_file_rf1,
  dt_input = dt_simulated_weekly,
  dt_holidays = dt_prophet_holidays,
  refresh_steps = 7,
  refresh_iters = 1000, # 1,000は推定値
  refresh_trials = 1
)

# 更新された新しいInputCollect、OutputCollect、select_modelの値を使用して続行します
InputCollectX <- RobynRefresh$listRefresh1$InputCollect
OutputCollectX <- RobynRefresh$listRefresh1$OutputCollect
select_modelX <- RobynRefresh$listRefresh1$OutputCollect$selectID

## プロットに加えてフォルダには今後の結果の活用に役立つ、4つのCSVファイルが出力されています。
# report_hyperparameters.csv, レポーティングのためのすべての選択されたモデルのハイパーパラメータ
# report_aggregated.csv, 説明変数ごとの集計分解
# report_media_transform_matrix.csv, すべてのメディア変換ベクトル
# report_alldecomp_matrix.csv, すべての説明変数の分解ベクトル

################################################################
#### ステップ 7: 限界リターンを取得する

## 検索チャネルにおいて、80,000円の支出レベルから次の1,000円の限界ROIを取得する例

# パラメータの定義を確認するには ?robyn_response を実行します

## robyn_response()関数は、支出と露出（インプレッション、GRP、ニュースレターの送信など）に対する応答を出力し、
## 個々の飽和曲線をプロットできます。これに対応して新しい引数名"metric_name"および"metric_value"が使用されます。
## また、返される出力はリストになり、プロットも含まれます。

## オリジナルの飽和曲線を再作成する
Response <- robyn_response(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  metric_name = "facebook_S"
)
Response$plot

## またはJSONファイルを直接呼び出すこともできます（少し時間がかかります）
# Response <- robyn_response(
#   json_file = "your_json_path.json",
#   dt_input = dt_simulated_weekly,
#   dt_holidays = dt_prophet_holidays,
#   metric_name = "facebook_S"
# )

## Spend1に対する「次の100ドル」の限界応答を取得する
Spend1 <- 20000
Response1 <- robyn_response(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  metric_name = "facebook_S",
  metric_value = Spend1, # date_rangeの総予算
  date_range = "last_1" # 最後の1期間
)
Response1$plot

Spend2 <- Spend1 + 100
Response2 <- robyn_response(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  metric_name = "facebook_S",
  metric_value = Spend2,
  date_range = "last_1"
)
# Spend1のレベルからの+100円のROAS
(Response2$response_total - Response1$response_total) / (Spend2 - Spend1)

## 指定された予算とdate_rangeからのレスポンスを取得する
Spend3 <- 100000
Response3 <- robyn_response(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  metric_name = "facebook_S",
  metric_value = Spend3, # date_rangeの総予算
  date_range = "last_5" # 最後の5期間
)
Response3$plot

## ペイドメディアの露出応答曲線を取得する例
# imps <- 10000000
# response_imps <- robyn_response(
#   InputCollect = InputCollect,
#   OutputCollect = OutputCollect,
#   select_model = select_model,
#   metric_name = "facebook_I",
#   metric_value = imps
# )
# response_imps$response_total / imps * 1000
# response_imps$plot

## オーガニックメディアの露出応答曲線を取得する例
sendings <- 30000
response_sending <- robyn_response(
  InputCollect = InputCollect,
  OutputCollect = OutputCollect,
  select_model = select_model,
  metric_name = "newsletter",
  metric_value = sendings
)
# 1000通あたりのレスポンス
response_sending$response_total / sendings * 1000
response_sending$plot

################################################################
#### Optional: 以前のモデルを再作成し、結果を再現する

# エクスポートされたJSONファイル（モデルをエクスポートする際に自動的に作成されます）から、
# 以前にトレーニングされたモデルと出力を再作成できます。注意: メインデータセットと
# 休日データセットを提供する必要があります。これらはJSONファイルに保存されていません。
# これらのJSONファイルはほとんどの場合、自動的に作成されます。

############ 書き出し ############
# 入力データのみのJSONファイルを手動で作成する
robyn_write(InputCollect, dir = "~/Desktop")

# 入力と特定のモデル結果を含むJSONファイルを手動で作成する
robyn_write(InputCollect, OutputCollect, select_model)

############ 読み込み ############
# `InputCollect`および`OutputCollect`オブジェクトを再作成します
# エクスポートされたモデル（初期または更新済み）のいずれかを選択します
json_file <- "~/Desktop/Robyn_202406031014_init/RobynModel-1_12_6.json"

# オプショナル: ファイルに保存されたデータを手動で読み取り、確認します
json_data <- robyn_read(json_file)
print(json_data)

# InputCollectの再作成
InputCollectX <- robyn_inputs(
  dt_input = dt_simulated_weekly,
  dt_holidays = dt_prophet_holidays,
  json_file = json_file)

# OutputCollectの再作成
OutputCollectX <- robyn_run(
  InputCollect = InputCollectX,
  json_file = json_file,
  export = create_files)

# もしくはrobyn_recreate()を使うと両方を再作成できる。
RobynRecreated <- robyn_recreate(
  json_file = "~/Desktop/Robyn_202406031014_init/RobynModel-1_12_6.json",
  dt_input = dt_simulated_weekly,
  dt_holidays = dt_prophet_holidays,
  quiet = FALSE)
InputCollectX <- RobynRecreated$InputCollect
OutputCollectX <- RobynRecreated$OutputCollect

# モデルの再書き出しまたは再構築とサマリーのチェック
myModel <- robyn_write(InputCollectX, OutputCollectX, export = FALSE, dir = "~/Desktop")
print(myModel)

# one-pagerの再作成
myModelPlot <- robyn_onepagers(InputCollectX, OutputCollectX, export = FALSE)
# myModelPlot[[1]]$patches$plots[[7]]

# インポートしたモデルのリフレッシュ
RobynRefresh <- robyn_refresh(
  json_file = json_file,
  dt_input = InputCollectX$dt_input,
  dt_holidays = InputCollectX$dt_holidays,
  refresh_steps = 6,
  refresh_mode = "manual",
  refresh_iters = 1000,
  refresh_trials = 1
)

# レスポンスカーブの再作成
robyn_response(
  InputCollect = InputCollectX,
  OutputCollect = OutputCollectX,
  metric_name = "newsletter",
  metric_value = 50000
)
