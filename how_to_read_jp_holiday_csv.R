# Copyright (c) Meta Platforms, Inc. and its affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

#############################################################################################
####################         Meta MMM Open Source: Robyn 3.10.5       #######################
####################             Quick demo guide                     #######################
#############################################################################################

# Advanced marketing mix modeling using Meta Open Source project Robyn (Blueprint training)
# https://www.facebookblueprint.com/student/path/253121-marketing-mix-models?utm_source=demo

################################################################
#### Step 0: Setup environment

## Install, load, and check (latest) Robyn version, using one of these 2 sources:
## A) Install the latest stable version from CRAN:
# install.packages("Robyn")
## B) Install the latest dev version from GitHub:
# install.packages("remotes") # Install remotes first if you haven't already
# remotes::install_github("facebookexperimental/Robyn/R")
library(Robyn)

# Please, check if you have installed the latest version before running this demo. Update if not
# https://github.com/facebookexperimental/Robyn/blob/main/R/DESCRIPTION#L4
packageVersion("Robyn")
# Also, if you're using an older version than the latest dev version, please check older demo.R with
# https://github.com/facebookexperimental/Robyn/blob/vX.X.X/demo/demo.R

## Force multi-core use when running RStudio
Sys.setenv(R_FUTURE_FORK_ENABLE = "true")
options(future.fork.enable = TRUE)

# Set to FALSE to avoid the creation of files locally
create_files <- TRUE

## IMPORTANT: Must install and setup the python library "Nevergrad" once before using Robyn
## Guide: https://github.com/facebookexperimental/Robyn/blob/main/demo/install_nevergrad.R

################################################################
#### Step 1: Load data

## Check simulated dataset or load your own dataset
data("dt_simulated_weekly")
head(dt_simulated_weekly)

################################################################
#### ここまでDemo.Rと同じ
#### https://github.com/facebookexperimental/Robyn/blob/main/demo/demo.R
################################################################

# 日本の祝日データのCSVファイルをダウンロードし、読み込む
# CSVファイル: https://github.com/yu-ya-tanaka/Robyn-Community-Japan-Resource/blob/main/jp_holiday.csv
jp_holiday = read.csv('~/Desktop/Robyn Work/jp_holiday.csv')
head(jp_holiday)

# Directory where you want to export results to (will create new folders)
robyn_directory <- "~/Desktop"

################################################################
#### Step 2a: For first time user: Model specification in 4 steps

#### 2a-1: First, specify input variables

## All sign control are now automatically provided: "positive" for media & organic
## variables and "default" for all others. User can still customise signs if necessary.
## Documentation is available, access it anytime by running: ?robyn_inputs
InputCollect <- robyn_inputs(
  dt_input = dt_simulated_weekly,
  dt_holidays = jp_holiday, # 上記で読み込んだ祝日データを指定
  date_var = "DATE", # date format must be "2020-01-01"
  dep_var = "revenue", # there should be only one dependent variable
  dep_var_type = "revenue", # "revenue" (ROI) or "conversion" (CPA)
  prophet_vars = c("trend", "season", "holiday"), # "trend","season", "weekday" & "holiday"
  prophet_country = "JP", # 国コードを"JP"に指定
  context_vars = c("competitor_sales_B", "events"), # e.g. competitors, discount, unemployment etc
  paid_media_spends = c("tv_S", "ooh_S", "print_S", "facebook_S", "search_S"), # mandatory input
  paid_media_vars = c("tv_S", "ooh_S", "print_S", "facebook_I", "search_clicks_P"), # mandatory.
  # paid_media_vars must have same order as paid_media_spends. Use media exposure metrics like
  # impressions, GRP etc. If not applicable, use spend instead.
  organic_vars = "newsletter", # marketing activity without media spend
  # factor_vars = c("events"), # force variables in context_vars or organic_vars to be categorical
  window_start = "2016-01-01",
  window_end = "2018-12-31",
  adstock = "geometric" # geometric, weibull_cdf or weibull_pdf.
)
print(InputCollect)

################################################################
#### 以降Demo.Rと同じ
#### https://github.com/facebookexperimental/Robyn/blob/main/demo/demo.R
################################################################