########### MMMデータセットの探索的データ分析用コード ###########
# 概要:
# 本ソースコードはRobynを含むMMMのモデリングを実施する前の探索的データ分析(EDA)のを行うためのサンプルコードです。
# 探索的データ分析については以下URLのデータレビューセクションを参照してください。
# https://github.com/yu-ya-tanaka/Robyn-Community-Japan-Resource/blob/main/robyn_webpage_japanese_version/analysts-guide-to-MMM_JP.md
#
# 用途:
# Robyn等でMMMのモデリングを行う前にデータの正確性や傾向をチェックするためにご利用ください。
# 例1. 0が極端に多い変数や空白が含まれる変数の特定
# 例2. 説明変数におけるペイドメディアの予算の内訳の確認
# 例3. ペイドメディアと目的変数の推移の可視化
#
# 利用方法:
# DLした本コードをR Studio等で開き、実行してください。
# 独自のデータを利用する場合、2.データの読み込みと3.パラメータの設定を変更してください

###### 1.事前準備) ライブラリの読み込み
# インストールされていなければインストール
libraries <- c("ggplot2", "dplyr", "plotly", "tidyr", "tidyverse", "scales", "Robyn")
for (lib in libraries) {
  if (!require(lib, character.only = TRUE)) {
    install.packages(lib)
    library(lib, character.only = TRUE)
  }
}

# 読み込み
library(ggplot2)
library(dplyr)
library(plotly)
library(tidyr)
library(tidyverse)
library(scales)
library(Robyn)

###### (任意)ディレクトリの設定
setwd('/Users/yuyatanaka/Desktop/')

###### 2.データの読み込み
data <- Robyn::dt_simulated_weekly

###### 3.パラメータの設定
date_col <- 'DATE' # 日付
kgi_col <- 'revenue' # KGI
cost_cols <- c('tv_S',
               'search_S',
               'ooh_S',
               'facebook_S',
               'print_S'
               ) # メディアコスト


###### 4.データの変換
# 日付列をDate型に変換
data <- data %>%
  mutate(DATE = ymd(DATE))

# メディア毎にコスト総額を計算
total_cost <- data %>%
  select(cost_cols) %>%
  summarise(across(everything(), sum, na.rm = TRUE)) %>%
  pivot_longer(cols = everything(), names_to = "channel", values_to = "total_cost") %>%
  mutate(percentage = total_cost / sum(total_cost) * 100)

###### 5. データチェック) 空白とゼロのレコードをカウント
count_summary <- data %>%
  summarize(across(
    .cols = everything(),
    .fns = list(
      zeros = ~sum(.x == 0, na.rm = TRUE),          # 0の個数
      blanks = ~sum(is.na(.x) | .x == "", na.rm = TRUE), # NAまたは空文字の個数
      others = ~sum(!(.x == 0 | is.na(.x) | .x == ""), na.rm = TRUE) # それ以外の個数
    ),
    .names = "{.col}___{.fn}"  # 新しいカラム名のフォーマット
  )) %>%
  pivot_longer(
    cols = everything(),
    names_to = c("column", "type"),
    names_sep = "___",
    values_to = "count"
  ) %>%
  pivot_wider(
    names_from = type,
    values_from = count
  ) %>%
  arrange(column)  # カラム名でソート

print(count_summary, n=100)

###### 6.可視化
##### 可視化1. メディア毎のコスト内訳を確認
# ggplot2でのプロット作成
p <- ggplot(total_cost, aes(y = reorder(channel, total_cost), x = total_cost)) +
  geom_col(fill = "lightblue") +  # 棒グラフを描画
  geom_text(aes(label = paste0(round(percentage, 2), "%")), hjust = -0.2, nudge_x = 50) +
  labs(title = "Cost per Channel", x = "Cost", y = "") +
  theme_minimal() +
  scale_x_continuous(labels = comma)

p
# ggplotly(p)

##### 可視化2. KGIとコスト全体の時系列推移を確認
# グラフ作成関数の定義
# 1.コストを積み上げで表現
create_time_series_plot <- function(data, date_col, kgi_col, cost_cols) {
  # 日付列をDate型に変換
  data <- data %>%
    mutate(!!sym(date_col) := ymd(!!sym(date_col)))

  # データを長い形式に変換
  data_long <- data %>%
    select(!!sym(date_col), !!sym(kgi_col), all_of(cost_cols)) %>%
    pivot_longer(cols = all_of(cost_cols), names_to = "channel", values_to = "cost")

  # グラフサイズの調整用: スケーリング係数を計算
  max_cost <- data %>% select(all_of(cost_cols)) %>% rowSums() %>% max(na.rm = TRUE)
  max_revenue <- max(data[[kgi_col]], na.rm = TRUE)
  scaling_factor <- max_cost / max_revenue

  # データを可視化
  plot <- ggplot() +
    # geom_area(data = data_long,
    #           aes_string(x = date_col, y = "cost", fill = "channel")) +
    geom_bar(data = data_long,
             aes_string(x = date_col, y = "cost", fill = "channel"), stat = "identity", position = "stack") +
    geom_line(data = data,
              aes_string(x = date_col, y = paste0(kgi_col, " * ", scaling_factor)), color = "black", size = .3) +  # スケーリングを調整
    theme_minimal() +
    labs(title = paste("Time Series of Media Costs and", kgi_col), x = "Date", y = kgi_col) +    scale_y_continuous(
      sec.axis = sec_axis(~./scaling_factor, name = kgi_col, labels = scales::comma),
      name = "Ad Cost",
      labels = scales::comma
    ) +
    labs(x = "Date")

  return(plot)
}
# 2.コストを全体を100%とした時の内訳で表現
create_time_series_plot_breakdown <- function(data, date_col, kgi_col, cost_cols) {
  # 日付列をDate型に変換
  data <- data %>%
    mutate(!!sym(date_col) := ymd(!!sym(date_col)))

  # データを長い形式に変換
  data_long <- data %>%
    select(!!sym(date_col), !!sym(kgi_col), all_of(cost_cols)) %>%
    pivot_longer(cols = all_of(cost_cols), names_to = "channel", values_to = "cost")

  # 日付ごとのコストの合計を計算
  total_cost_per_date <- data_long %>%
    group_by(!!sym(date_col)) %>%
    summarise(total_cost = sum(cost))

  # 各チャネルのコストの割合を計算
  data_long <- data_long %>%
    left_join(total_cost_per_date, by = date_col) %>%
    mutate(cost_ratio = cost / total_cost)

  # グラフサイズの調整用: スケーリング係数を計算
  max_revenue <- max(data[[kgi_col]], na.rm = TRUE)
  scaling_factor <- 1 / max_revenue

  # データを可視化
  plot <- ggplot() +
    # geom_area(data = data_long,
    #           aes_string(x = date_col, y = "cost_ratio", fill = "channel")) +
    geom_bar(data = data_long,
             aes_string(x = date_col, y = "cost_ratio", fill = "channel"), stat = "identity", position = "stack") +
    geom_line(data = data,
              aes_string(x = date_col, y = paste0(kgi_col, " * ", scaling_factor)), color = "black", size = .3) +  # スケーリングを調整
    theme_minimal() +
    labs(title = paste("Time Series of Media Costs and", kgi_col), x = "Date", y = kgi_col) +
    scale_y_continuous(
      sec.axis = sec_axis(~./scaling_factor, name = kgi_col, labels = scales::comma),
      name = "Ad Cost Ratio",
      labels = scales::percent
    ) +
    labs(x = "Date")

  return(plot)
}

# 週次/月次への変換を行わない場合
p <- create_time_series_plot(data, date_col, kgi_col, cost_cols)
p
# ggplotly(p)

p <- create_time_series_plot_breakdown(data, date_col, kgi_col, cost_cols)
p
# ggplotly(p)

# 週次へ変換する場合
data_weekly <- data %>%
  mutate(!!sym(date_col) := floor_date(!!sym(date_col), "week")) %>%
  group_by(!!sym(date_col)) %>%
  summarise(across(c(kgi_col, all_of(cost_cols)), sum, na.rm = TRUE))

p <- create_time_series_plot(data_weekly, date_col, kgi_col, cost_cols)
p
# ggplotly(p)

p <- create_time_series_plot_breakdown(data_weekly, date_col, kgi_col, cost_cols)
p
# ggplotly(p)

# 月次へ変換する場合
data_monthly <- data %>%
  mutate(!!sym(date_col) := floor_date(!!sym(date_col), "month")) %>%
  group_by(!!sym(date_col)) %>%
  summarise(across(c(kgi_col, all_of(cost_cols)), sum, na.rm = TRUE))

p <- create_time_series_plot(data_monthly, date_col, kgi_col, cost_cols)
p
# ggplotly(p)

p <- create_time_series_plot_breakdown(data_monthly, date_col, kgi_col, cost_cols)
p
# ggplotly(p)

##### 可視化3. 相関行列
cor_matrix <- data %>%
  select(-date_col) %>%
  select_if(is.numeric) %>%
  cor()

p <- plot_ly(x = colnames(cor_matrix),
             y = rownames(cor_matrix),
             z = cor_matrix,
             type = "heatmap",
             colors = colorRamp(c("blue", "white", "red")))
p <- p %>% layout(title = 'correlation matrix')


p

##### 可視化4. KGI x 一つの説明変数の組み合わせで推移を確認
# 日付と数字のカラムに限定
data_date_and_numeric <- data %>%
  select_if(is.numeric) %>%
  mutate(DATE=data[[date_col]]) %>%
  select(DATE, everything())

# カラム数を取得
num_cols <- ncol(data_date_and_numeric) - 2

# 各メディアコストごとにグラフを作成
for (i in 1:num_cols) {
  # メディアコストのカラム名を取得
  cost_col <- names(data_date_and_numeric)[i + 2]  # Date と KGI をスキップ

  # scaling
  max_cost <- data_date_and_numeric[[cost_col]] %>% max(na.rm = TRUE)
  max_KGI <- data_date_and_numeric[[kgi_col]] %>% max(na.rm = TRUE)
  scaling_factor <-  max_KGI / max_cost

  # ggplotでグラフを描画
  p <- ggplot() +
    geom_line(data = data_date_and_numeric,
              aes_string(x = date_col, y = kgi_col), color = "red", alpha = 0.5) +
    geom_line(data = data_date_and_numeric,
              aes_string(x = date_col, y = paste0(cost_col, " * ", scaling_factor)), color = "blue", alpha = 0.5) +
    theme_minimal() +
    labs(title = paste("Time Series of", cost_col, "and", kgi_col), x = "Date", y = cost_col) +
    scale_y_continuous(sec.axis = sec_axis(~./scaling_factor, name = cost_col, labels = scales::comma),
                       name = kgi_col,
                       labels = scales::comma) +
    labs(x = date_col)

  # プロットを表示
  print(cost_col)
  print(p)
}

##### 可視化5. ヒストグラムで変数毎にばらつきを確認
# 日付と数字のカラムに限定
data_only_numeric <- data %>%
  select_if(is.numeric)

# 各数値カラムごとにヒストグラムを作成
for (i in 1:ncol(data_only_numeric)) {
  # 数値カラムのカラム名を取得
  col_name <- names(data_only_numeric)[i]

  # ヒストグラム用のデータの最大値を取得
  max_count <- max(table(data_only_numeric[[col_name]]))

  # ggplotでヒストグラムとカーネル密度推定を描画
  p <- ggplot(data_only_numeric, aes_string(x = col_name)) +
    geom_histogram(bins = 30, fill = "blue", color = "black", alpha = 0.7) +
    theme_minimal() +
    labs(title = paste("Histogram of", col_name), x = col_name, y = "Frequency") +
    scale_x_continuous(labels = scales::comma)

  # プロットを表示
  print(col_name)
  print(p)
}
