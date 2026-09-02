# doftfiles — Arch Hyprland ML4W backup

Private backup of Hyprland + ML4W dotfiles (standard + Kvantum + Waybar overrides).  
Source: `~/.mydotfiles/com.ml4w.dotfiles.stable` (495 files, 45M) + `~/.config/Kvantum` + `pkglist.txt`.

- **Created:** 2026-09-02 | Arch Linux | Hyprland 0.56.2
- **Machine:** chloe | ML4W Stable
- **Repo visibility:** PRIVATE (`chlxyz/doftfiles`)

## What's inside
- `.config/hypr/` (hyprland.lua, hypridle.conf, hyprlock.conf, colors.conf, conf/*, scripts/*)
- `.config/waybar/`, `.config/rofi/`, `.config/kitty/`, `.config/ml4w/`, `.config/btop/` etc (symlink sources)
- `.config/Kvantum/` (KvGray + KvArc, extra not in ML4W)
- `.bashrc`, `.zshrc`, `.Xresources`, `.gtkrc-2.0`, `.gitconfig`
- `pkglist.txt` (116 explicit pacman pkgs), `pkglist-aur.txt` (0), `hypr-version.txt`
- `RESTORE.md` — fresh Arch restore steps

## Quick restore (fresh Arch)
See `RESTORE.md` for full steps. TL;DR:

```bash
gh repo clone chlxyz/doftfiles /tmp/doftfiles
rsync -a /tmp/doftfiles/ ~/.mydotfiles/com.ml4w.dotfiles.stable/ --exclude .git/
rsync -a /tmp/doftfiles/.config/Kvantum/ ~/.config/Kvantum/
mkdir -p ~/.config && for f in ~/.mydotfiles/com.ml4w.dotfiles.stable/.config/*; do ln -sfn "$f" ~/.config/"$(basename "$f")"; done
for f in ~/.mydotfiles/com.ml4w.dotfiles.stable/.??*; do [[ "$f" == *".config" ]] && continue; [[ -e "$f" ]] && ln -sfn "$f" ~/"$(basename "$f")"; done
hyprctl reload
```

## Updating backup (manual — recommended)
```bash
# run when you tweak hypr/waybar:
rsync -aL ~/.mydotfiles/com.ml4w.dotfiles.stable/ /tmp/doftfiles-staging/ && rsync -a ~/.config/Kvantum/ /tmp/doftfiles-staging/.config/Kvantum/ && cp ~/.gitconfig /tmp/doftfiles-staging/.gitconfig 2>/dev/null; pacman -Qqe > /tmp/doftfiles-staging/pkglist.txt; hyprctl version > /tmp/doftfiles-staging/hypr-version.txt; cd /tmp/doftfiles-staging && git add -A && git commit -m "update: $(date -I)" && git push
```
Alias: add to `~/.bashrc`/`~/.zshrc`:
```
alias doftfiles-push='rsync -aL ~/.mydotfiles/com.ml4w.dotfiles.stable/ /tmp/doftfiles-staging/ && rsync -a ~/.config/Kvantum/ /tmp/doftfiles-staging/.config/Kvantum/ && cp ~/.gitconfig /tmp/doftfiles-staging/.gitconfig 2>/dev/null; pacman -Qqe > /tmp/doftfiles-staging/pkglist.txt; hyprctl version > /tmp/doftfiles-staging/hypr-version.txt; cd /tmp/doftfiles-staging && git add -A && git commit -m "update: $(date -I)" && git push'
```

Skipped: auto-watcher/cron (add when you forget 3x).

## Verify
```bash
gh repo view chlxyz/doftfiles --json url,visibility
du -sh /tmp/doftfiles && git log --oneline -1
```
