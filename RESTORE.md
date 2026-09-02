# Restore — Fresh Arch Linux + Hyprland from `chlxyz/doftfiles`

This repo is a private plain-git dump of `~/.mydotfiles/com.ml4w.dotfiles.stable` + `~/.config/Kvantum` + `pkglist.txt`. Tested on Arch, Hyprland 0.56.2.

## 0. Pre-req (fresh install)
Boot Arch live USB, run `archinstall` (or manual). Ensure:
- user `chloe` created, sudo enabled
- network working (`ping archlinux.org`)

## 1. Install base tools + authenticate GitHub
```bash
sudo pacman -S --needed git github-cli jq rsync
gh auth login
# choose: GitHub.com -> HTTPS -> Yes -> Paste token (or Browser flow)
gh auth status  # should show ✓ Logged in as chlxyz
```

## 2. Clone backup
```bash
gh repo clone chlxyz/doftfiles /tmp/doftfiles
ls /tmp/doftfiles | head   # should show .config .bashrc pkglist.txt README.md
```

## 3. Install packages (restore apps)
Your explicit pkgs (116) from backup:
```bash
cat /tmp/doftfiles/pkglist.txt | head -n 20
sudo pacman -S --needed - < /tmp/doftfiles/pkglist.txt
# if AUR pkgs exist:
cat /tmp/doftfiles/pkglist-aur.txt
# install AUR helper first if needed: sudo pacman -S --needed base-devel && git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si
# yay -S --needed - < /tmp/doftfiles/pkglist-aur.txt
```

Essential Hypr packages if pkglist fails:
```bash
sudo pacman -S --needed hyprland hypridle hyprlock hyprpaper hyprpicker waybar rofi kitty
```

## 4. Restore dotfiles (lazy rsync — no ML4W installer needed)
```bash
mkdir -p ~/.mydotfiles
rsync -a /tmp/doftfiles/ ~/.mydotfiles/com.ml4w.dotfiles.stable/ --exclude .git/ --exclude README.md --exclude RESTORE.md --exclude pkglist.txt --exclude pkglist-aur.txt --exclude hypr-version.txt
# Kvantum (extra, not in ML4W stable)
mkdir -p ~/.config
rsync -a /tmp/doftfiles/.config/Kvantum/ ~/.config/Kvantum/

# .gitconfig if you want same identity:
cp /tmp/doftfiles/.gitconfig ~/.gitconfig 2>/dev/null || true

# Recreate ML4W symlinks (same as deploy_symlinks in ml4w-dotfiles-installer):
mkdir -p ~/.config
for src in ~/.mydotfiles/com.ml4w.dotfiles.stable/.config/*; do
  base=$(basename "$src")
  target="$HOME/.config/$base"
  # backup existing
  if [ -e "$target" ] && [ ! -L "$target" ]; then mv "$target" "$target.bak.$(date +%Y%m%d)"; fi
  ln -sfn "$src" "$target"
  echo "linked $target -> $src"
done
for src in ~/.mydotfiles/com.ml4w.dotfiles.stable/.??*; do
  base=$(basename "$src")
  [[ "$base" == ".config" || "$base" == ".git" || "$base" == "." || "$base" == ".." ]] && continue
  [[ -e "$src" ]] || continue
  target="$HOME/$base"
  if [ -e "$target" ] && [ ! -L "$target" ]; then mv "$target" "$target.bak.$(date +%Y%m%d)"; fi
  ln -sfn "$src" "$target"
  echo "linked $target -> $src"
done

# mark active profile (so ml4w settings apps work)
mkdir -p ~/.config/ml4w-dotfiles-installer
echo '{"active":"com.ml4w.dotfiles.stable"}' > ~/.config/ml4w-dotfiles-installer/active.json

# verify
ls -l ~/.config/hypr         # -> ../.mydotfiles/.../hypr
ls -l ~/.bashrc ~/.zshrc     # -> .mydotfiles/...
cat ~/.config/Kvantum/kvantum.kvconfig  # theme=KvGray
```

## 5. Reload / reboot
```bash
hyprctl reload
# or reboot fully:
reboot
# in SDDM select Hyprland
# SUPER + SHIFT + B to reload waybar after first login
```

## 6. Future updates (on main machine)
After tweaking hypr/waybar:
```bash
rsync -aL ~/.mydotfiles/com.ml4w.dotfiles.stable/ /tmp/doftfiles-staging/ && rsync -a ~/.config/Kvantum/ /tmp/doftfiles-staging/.config/Kvantum/ && cp ~/.gitconfig /tmp/doftfiles-staging/.gitconfig 2>/dev/null; pacman -Qqe > /tmp/doftfiles-staging/pkglist.txt; pacman -Qqm > /tmp/doftfiles-staging/pkglist-aur.txt; hyprctl version > /tmp/doftfiles-staging/hypr-version.txt; cd /tmp/doftfiles-staging && git add -A && git commit -m "update: $(date -I)" && git push
```
Or add alias to `~/.bashrc`:
```bash
alias doftfiles-push='rsync -aL ~/.mydotfiles/com.ml4w.dotfiles.stable/ /tmp/doftfiles-staging/ && rsync -a ~/.config/Kvantum/ /tmp/doftfiles-staging/.config/Kvantum/ && cp ~/.gitconfig /tmp/doftfiles-staging/.gitconfig 2>/dev/null; pacman -Qqe > /tmp/doftfiles-staging/pkglist.txt; hyprctl version > /tmp/doftfiles-staging/hypr-version.txt; cd /tmp/doftfiles-staging && git add -A && git commit -m "update: $(date -I)" && git push'
```

## Troubleshooting
- `gh: not found` -> `sudo pacman -S github-cli`
- `permission denied` on clone -> `gh auth status` and `gh auth login`, ensure token has `repo` scope
- Hyprland black screen -> `cat ~/.cache/hyprland/hyprland.log` or `journalctl --user -u hyprland`, check `~/.config/hypr/monitors.conf`
- Waybar not showing -> `~/.config/waybar/launch.sh` or `hyprctl reload`
- Kvantum theme not applied -> `kvantummanager` -> select KvGray
- Missing symlinks -> re-run step 4 loop, check `ls -la ~/.config/ | grep mydotfiles`

## What this RESTORE skips
- `.cache/`, `.local/share/flatpak`, browser profiles (intentional, large)
- Add when you need them: extend rsync to include those paths.
