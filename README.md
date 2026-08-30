# dotfiles

## Windows

### 0. Paketler — **PowerShell'de, MSYS2 bash'te değil**

```powershell
winget install MSYS2.MSYS2 twpayne.chezmoi wez.wezterm Git.Git
```

> `winget` MSYS2 bash'ten çalışmaz. `%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe`
> gerçek binary değil, App Execution Alias — sıfır byte'lık reparse point.
> PATH'e eklesen bile MSYS2 exec katmanı çalıştıramaz.
> Mecbur kalırsan bash'ten:
> ```bash
> winget() { MSYS2_ARG_CONV_EXCL='*' cmd.exe /c winget "$@"; }
> ```
> (`MSYS2_ARG_CONV_EXCL` şart, yoksa MSYS `/c`'yi `C:/` diye path'e çevirir.)

MSYS2 ilk açılışta:
```bash
pacman -Syu    # kendini güncelleyip terminali kapatır
pacman -Syu    # tekrar aç, bir daha çalıştır
```

### 1. Home'u hizala

UCRT64 shell'de:
```bash
echo "db_home: windows" >> /etc/nsswitch.conf
```
Terminali kapat aç, **doğrula**:
```bash
echo $HOME     # /c/Users/<kullanıcı> dönmeli
```

chezmoi native Windows binary'si — cygwin/msys build'i yok. Home'u
`USERPROFILE`'dan okur. MSYS2 bash'in varsayılanı ise `/home/<kullanıcı>`.
Hizalamazsan dotfile'ların yarısı bir eve, yarısı öbürüne düşer.

### 2. chezmoi'yi PATH'e al — kalıcı olarak

```bash
echo 'export PATH="$PATH:/c/Users/$USERNAME/AppData/Local/Microsoft/WinGet/Links"' >> ~/.bashrc
source ~/.bashrc
chezmoi --version
```

`export`'u tek satır çalıştırmak yetmez, oturumla birlikte uçar.
(`WinGet/Links` winget'in kendisi değil, winget'in kurduğu şeylerin klasörü.)

### 3. init

```bash
chezmoi init --apply caneroglu
```

Repo private ise git credential'ı **önceden** hazırla

---

### Fallback — winget yoksa veya chezmoi gelmediyse

```bash
pacman -S --noconfirm unzip
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

`unzip` olmadan script `unzip: command not found` deyip hiçbir şey kurmadan çıkar.
İnen binary yine `windows/amd64` — adım 1'deki home hizalaması yine şart.


### Doğrulama

```bash
chezmoi managed | head
chezmoi source-path
```

Boş `chezmoi status` iki anlama gelir: her şey uygulandı **ya da** kaynak dizin boş.
Ayırt eden `managed` — boş dönüyorsa init repoyu çekmemiş.

### WezTerm config nerede aranıyor

Sırayla: `$XDG_CONFIG_HOME/wezterm/wezterm.lua` → `$HOME/.config/wezterm/wezterm.lua`
→ `$HOME/.wezterm.lua`. Windows'ta `$HOME` = `USERPROFILE`, yani adım 1 yapıldıysa
MSYS2 ile aynı yeri gösterir. Hangi dosyanın yüklendiğini görmek için WezTerm'de
debug overlay: `Ctrl+Shift+L`.

### Rust

https://rustup.rs

---

## Linux

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply caneroglu
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

---

## Günlük kullanım

```bash
chezmoi cd            # source repo'ya geç
chezmoi add ~/.foo    # yeni dosyayı yönetime al
chezmoi re-add        # lokal değişiklikleri repoya geri emdir
chezmoi diff          # apply öncesi ne değişecek
chezmoi update        # pull + apply
```

OS'a göre ayrım — `.tmpl` uzantılı dosyalarda:
```
{{ if eq .chezmoi.os "windows" }}...{{ else }}...{{ end }}
```