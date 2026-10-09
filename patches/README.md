# tmux-resurrect per-pane history patch

`tmux-resurrect-per-pane-history.patch` は tmux-resurrect の
`scripts/restore.sh` に対する変更（pane ごと履歴 uuid の env 注入）です。

tpm 更新（`prefix + U`）でプラグインが `git pull` され、この変更が
上書きされた場合に再適用するためのものです。

- 対象リポジトリ: `~/.tmux/plugins/tmux-resurrect`
- 作成時の upstream ベース: `cff343c`（将来の upstream 変更次第で hunk がずれる可能性あり）

## 再適用

```sh
cd ~/.tmux/plugins/tmux-resurrect
git apply --check ~/.mcnk/patches/tmux-resurrect-per-pane-history.patch  # 事前確認
git apply         ~/.mcnk/patches/tmux-resurrect-per-pane-history.patch  # 適用
```

`--check` が失敗する（upstream が該当箇所を変更した）場合は 3-way マージを試す:

```sh
git apply --3way ~/.mcnk/patches/tmux-resurrect-per-pane-history.patch
```

## パッチの再生成（自分で restore.sh を編集し直した場合）

```sh
cd ~/.tmux/plugins/tmux-resurrect
git diff scripts/restore.sh > ~/.mcnk/patches/tmux-resurrect-per-pane-history.patch
```

## 関連ファイル（プラグイン外・更新の影響を受けない）

- `~/.mcnk/bashrc/functions/resurrect_pane_hist.sh` … pane ごと HISTFILE と同期
- `~/.mcnk/scripts/save_pane_hist_map.sh` … save hook（座標→uuid マップ）
- `~/.mcnk/scripts/backfill_pane_hist_id.sh` … 稼働中 pane の `@histfile_id` 一括修復（任意）
- `~/.mcnk/scripts/save_history_uniq.sh` … uniq アーカイブの dedup 圧縮
- `~/.byobu/.tmux.conf` … `@resurrect-hook-post-save-all` で上記 hook を呼ぶ

## 落とし穴（過去に踏んだもの）

`resurrect_pane_hist.sh` を編集するときは以下の 2 点に注意する。どちらも
エラーを出さずに壊れるため気付きにくい。

### 1. `history` は必ず `builtin history` と書く

`bashrc/bash_aliases` に `alias history="history | less -SFRX +G"` がある。
`resurrect_pane_hist.sh` は `bash_aliases` の**後**に source されるので、bare な
`history -c` は `history | less -SFRX +G -c` に展開されてしまう。

- `less -X` は終了時に画面を復元しないため、pane に `~` の埋め草行と履歴ファイルの
  中身が残る
- 本来の `history -r "$HISTFILE"` が実行されず、pane 別履歴が読み込まれない

### 2. `tmux set -p` / `show -pqv` には `-t "$TMUX_PANE"` を付ける

ターゲットを省略すると、呼び出し元の pane ではなく**セッションのカレント pane**が
対象になる。byobu 起動や resurrect restore のように pane が一斉生成される場面では、
全 shell の uuid が window 0 の pane に上書きされ、同一セッションの全 pane が
1 つの HISTFILE を共有してしまう。

なお `scripts/restore.sh` 側は元々 `-t` 付きで書かれているため、このパッチ自体に
変更は不要（上記はいずれもプラグイン外のファイルの問題）。
