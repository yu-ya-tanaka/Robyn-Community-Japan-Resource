# Copyright (c) Meta Platforms, Inc. and its affiliates.

# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

# 本ソースコードは下記URLのMMeta MMM Open Source RobynのためのNevergradインストールガイドの日本語版です。
# https://github.com/facebookexperimental/Robyn/blob/main/demo/install_nevergrad.R

#### Nevergradインストールガイド
## 注意: Pythonバージョン3.10以上はNevergradのエラーを引き起こす可能性があります
## reticulateを使用してPythonパッケージをインストールする方法についてはこちらを参照してください:
## https://rstudio.github.io/reticulate/articles/python_packages.html

# reticulateをまだインストールしていない場合、最初にインストールします
install.packages("reticulate")

#### オプション1: PIPを使用したnevergradのインストール
# 1. reticulateをロードします
library("reticulate")
# 2. 仮想環境を作成します
virtualenv_create("r-reticulate")
# 3. 作成した環境を使用します
use_virtualenv("r-reticulate", required = TRUE)
# 4. Pythonパスを仮想環境のpythonファイルにポイントします。以下はMacOS M1以上の例です。
#    "~"は私のホームディレクトリ "/Users/gufengzhou"です。
#    ファイルを自分で見つけたい場合は、隠しファイルを表示してください。
Sys.setenv(RETICULATE_PYTHON = "~/.virtualenvs/r-reticulate/bin/python")
# 5. Pythonパスを確認します
py_config() # 最初のパスが4のようでない場合、6を実行します
# 6. Rセッションを再起動し、最初に#4を実行し、次にlibrary("reticulate")をロードし、再度py_config()を確認します。
#    Pythonが#4のパスを持つべきです。
#    "NOTE: Python version was forced by RETICULATE_PYTHON_FALLBACK"が表示された場合
#    RStudioを使用している場合は、Global Options > Pythonに移動し、
#    "Automatically activate project-local Python environments"のチェックボックスを外します。
# 7. py_configがnumpyが利用できないと表示した場合、numpyをインストールします
py_install("numpy", pip = TRUE)
# 8. nevergradをインストールします
py_install("nevergrad", pip = TRUE)
# 9. 成功した場合、py_config()はインストールされたパスでnumpyとnevergradを表示します
# 10. Rセッションを再起動するたびに、Robynをロードする前に#4を実行してPythonパスを割り当てる必要があります
# 11. あるいは、ファイルRenvironにRETICULATE_PYTHON = "~/.virtualenvs/r-reticulate/bin/python"という行を追加して、
#    Rが常にデフォルトでこのパスを使用するように強制します。Renvironファイルを作成して編集する1つの方法は、
#    パッケージ"usethis"をインストールし、関数usethis::edit_r_environ()を実行することです。Unix/Macの場合、
#    "/Library/Frameworks/R.framework/Resources/etc/"パスにも別のRenvironファイルがあります。上記の行をこのファイルに追加します。
#    これにより、毎回#4を実行する必要がなくなります。編集後にRセッションを再起動します。

#### オプション2: condaを使用したnevergradのインストール
# 1. reticulateをロードします
library("reticulate")
# 2. condaが利用できない場合、インストールします
install_miniconda()
# 3. 仮想環境を作成します
conda_create("r-reticulate")
# 4. 作成した環境を使用します
use_condaenv("r-reticulate")
# 5. Pythonパスを仮想環境のpythonファイルにポイントします。以下はMacOS M1以上の例です。
#    "~"は私のホームディレクトリ"/Users/gufengzhou"です。
#    ファイルを自分で見つけたい場合は、隠しファイルを表示してください
Sys.setenv(RETICULATE_PYTHON = "~/Library/r-miniconda-arm64/envs/r-reticulate/bin/python")
# 6. Pythonパスを確認します
py_config() # 最初のパスが5のようでない場合、7を実行します
# 7. Rセッションを再起動し、最初に#5を実行し、次にlibrary("reticulate")をロードし、再度py_config()を確認します。
#    Pythonが#5のパスを持つべきです
# 8. py_configがnumpyが利用できないと表示した場合、numpyをインストールします
conda_install("r-reticulate", "numpy", pip=TRUE)
# 9. nevergradをインストールします
conda_install("r-reticulate", "nevergrad", pip=TRUE)
# 10. 成功した場合、py_config()はインストールされたパスでnumpyとnevergradを表示します
# 11. Rセッションを再起動するたびに、Robynをロードする前に#4を実行してPythonパスを割り当てる必要があります
# 12. あるいは、ファイルRenvironにRETICULATE_PYTHON = "~/Library/r-miniconda-arm64/envs/r-reticulate/bin/python"という行を追加して、
#    Rが常にデフォルトでこのパスを使用するように強制します。Renvironファイルを作成して編集する1つの方法は、
#    パッケージ"usethis"をインストールし、関数usethis::edit_r_environ()を実行することです。Unix/Macの場合、
#    "/Library/Frameworks/R.framework/Resources/etc/"パスにも別のRenvironファイルがあります。上記の行をこのファイルに追加します。
#    これにより、毎回#5を実行する必要がなくなります。編集後にRセッションを再起動します。

#### Nevergradのインストール時の既知の潜在的な問題と可能な修正方法
# SSLの問題を修正: reticulate:::rm_all_reticulate_state()
# pipの更新を試す: system("pip3 install --upgrade pip")
# reticulate/nevergradの問題をデバッグするためのアイデアについてはこちらを確認してください:
# https://github.com/facebookexperimental/Robyn/issues/189
