# Flux2 Image Generation on Apple Silicon Mac

Apple Silicon Mac (M1/M2/M3/M4, 16GB+) で Flux2 画像生成AIを動かす環境です。

## 技術スタック

- **環境管理**: Nix Flakes
- **Python パッケージ**: uv (高速な pip 代替)
- **タスクランナー**: just
- **Python**: 3.12
- **推論バックエンド**: MPS (Metal Performance Shaders)

## 前提条件

- macOS (Apple Silicon)
- [Nix](https://nixos.org/download.html) インストール済み
- [direnv](https://direnv.net/) (推奨)

### Nix のインストール

```bash
# Determinate Systems installer (推奨)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# または公式インストーラー
sh <(curl -L https://nixos.org/nix/install)
```

### Flakes の有効化

`~/.config/nix/nix.conf` に追加:
```
experimental-features = nix-command flakes
```

## クイックスタート

```bash
# 1. リポジトリに移動
cd img-gen-sandbox

# 2. Nix 環境に入る
nix develop

# 3. Python 環境セットアップ
just setup

# 4. Hugging Face にログイン
just login

# 5. 画像生成
just generate "a cat sitting on a red chair"
```

## direnv を使う場合（推奨）

```bash
# direnv を許可（初回のみ）
direnv allow

# 以降は自動で環境がロードされる
just setup
just login
just generate "your prompt"
```

## コマンド一覧

```bash
just              # コマンド一覧を表示
just setup        # 環境セットアップ
just login        # Hugging Face ログイン
just generate "prompt"           # 画像生成
just generate-fast "prompt"      # 高速生成 (schnell)
just generate-quality "prompt"   # 高品質生成 (dev)
just generate-hires "prompt"     # 高解像度生成 (768x768)
just check-mps    # MPS 利用可否を確認
just info         # 環境情報を表示
just clean        # クリーンアップ
```

## 利用可能なモデル

| モデル | 用途 | ステップ数 | メモリ |
|--------|------|-----------|--------|
| FLUX.1-schnell | 高速生成 | 4 | ~16GB |
| FLUX.1-dev | 高品質生成 | 20 | ~16GB |

## 使用例

### 基本的な生成

```bash
just generate "a beautiful sunset over mountains"
```

### オプション指定

```bash
# 出力先を指定
just generate "a robot" output.png

# モデルを指定
just generate "a portrait" output.png "black-forest-labs/FLUX.1-dev"
```

### 直接 Python を実行

```bash
python generate.py "your prompt" \
    -o output.png \
    -m black-forest-labs/FLUX.1-schnell \
    --width 512 \
    --height 512 \
    --steps 4 \
    --seed 42
```

## トラブルシューティング

### MPS が利用できない

```bash
just check-mps
```

`False` の場合:
- macOS 12.3+ が必要
- PyTorch 2.0+ が必要

### メモリ不足

1. 画像サイズを小さくする (512x512)
2. 他のアプリを終了する
3. schnell モデルを使用する

### 認証エラー

```bash
# 認証状態を確認
just auth-status

# 再ログイン
just login
```

モデルライセンスへの同意も必要:
- https://huggingface.co/black-forest-labs/FLUX.1-schnell
- https://huggingface.co/black-forest-labs/FLUX.1-dev

### モデルキャッシュの確認

```bash
# キャッシュサイズを確認
just disk-usage

# キャッシュを削除（再ダウンロードが必要になる）
just clean-all
```

## ファイル構成

```
.
├── flake.nix          # Nix Flake 定義
├── flake.lock         # 依存関係ロックファイル
├── pyproject.toml     # Python プロジェクト定義
├── justfile           # タスクランナー定義
├── .envrc             # direnv 設定
├── .gitignore         # Git 除外設定
├── generate.py        # 画像生成スクリプト
└── README.md          # このファイル
```

## 開発

```bash
# 開発用依存関係をインストール
just setup-dev

# リンター実行
just lint

# フォーマット
just fmt
```

## 参考リンク

- [FLUX.1 公式](https://github.com/black-forest-labs/flux)
- [Diffusers ドキュメント](https://huggingface.co/docs/diffusers)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [uv ドキュメント](https://docs.astral.sh/uv/)
- [just マニュアル](https://just.systems/man/en/)
