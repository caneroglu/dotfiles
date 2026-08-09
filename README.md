# dotfiles

## Windows
```powershell
winget install MSYS2.MSYS2 twpayne.chezmoi wez.wezterm Git.Git
```
MSYS2 UCRT64 aç, `/etc/nsswitch.conf` içine `db_home: windows` ekle, terminali yeniden aç:
```bash
export PATH="$PATH:/c/Users/$USERNAME/AppData/Local/Microsoft/WinGet/Links"
chezmoi init --apply caneroglu
```
Rust: https://rustup.rs

## Linux
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply caneroglu
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
