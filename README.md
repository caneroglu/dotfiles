# dotfiles


### 1. PowerShell — çekirdek dörtlü

```powershell
winget install Git.Git GitHub.cli MSYS2.MSYS2 twpayne.chezmoi
```

Bu dört paket bootstrap için yeterli. Gerisi adım 5'te repodan gelecek.

### 2. PowerShell — GitHub auth

```powershell
gh auth login
```

### 3. MSYS2 UCRT64 — home'u hizala

```bash
pacman -Syu          # kendini güncelleyip terminali kapatır
pacman -Syu          # tekrar aç, bir daha
echo "db_home: windows" >> /etc/nsswitch.conf
```

### 4. PATH

```bash
echo 'export PATH="$PATH:/c/Users/$USERNAME/AppData/Local/Microsoft/WinGet/Links"' >> ~/.bashrc
source ~/.bashrc
chezmoi --version
```

### 5. Tek komut

```bash
chezmoi init --apply --ssh caneroglu
```

Configler iner, `run_once_` script'i kalan paketleri kurar 

### 6. Rust

https://rustup.rs

---

## Paketler

Mevcut makinede paket listesini çıkar — **bunu makine ayaktayken yap**, sıfırlandıktan
sonra çıkaracak liste kalmaz:

```powershell
winget export -o packages.json --accept-source-agreements
```

`packages.json`'ı repoya at. Sonra `.chezmoiscripts/run_once_install-packages.ps1.tmpl`:

```
{{ if eq .chezmoi.os "windows" -}}
winget import -i "{{ .chezmoi.sourceDir }}/packages.json" --accept-package-agreements --accept-source-agreements --ignore-unavailable
{{ end -}}
```

Windows dışında dosya boş render olur, chezmoi boş script'i atlar.

`.chezmoi.toml.tmpl`'e interpreter tanımı şart — yoksa chezmoi `.ps1`'i çalıştıramaz:

```toml
[interpreters.ps1]
command = "powershell"
args = ["-NoLogo", "-NoProfile", "-NonInteractive"]
```

`run_once_` = script'in hash'i değişmedikçe bir daha çalışmaz. Paket listesini
güncelleyince hash değişir, tekrar çalışır. 


---

### Fallback — winget yoksa veya chezmoi gelmediyse

```bash
pacman -S --noconfirm unzip
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

`unzip` olmadan script `unzip: command not found` deyip hiçbir şey kurmadan çıkar.

### Doğrulama

```bash
chezmoi managed | head
chezmoi source-path
```

Boş `chezmoi status` iki anlama gelir: her şey uygulandı **ya da** kaynak dizin boş.
Ayırt eden `managed` — boş dönüyorsa init repoyu çekmemiş.


### Pacman Paketler

Mevcut listeyi çıkarmak için başlangıç noktası:

```bash
pacman -Qqe              # Arch — explicit kurulanlar
apt-mark showmanual      # Debian/Ubuntu
```

Çıktıyı **buda**, repoya `packages.txt` olarak elle bakımlı halde koy.

`.chezmoiscripts/run_once_install-packages.sh.tmpl`:

```
#!/bin/sh
{{ if eq .chezmoi.os "linux" -}}
{{   if eq .chezmoi.osRelease.id "arch" -}}
sudo pacman -S --needed --noconfirm - < "{{ .chezmoi.sourceDir }}/packages.txt"
{{   else if eq .chezmoi.osRelease.id "debian" "ubuntu" -}}
xargs -a "{{ .chezmoi.sourceDir }}/packages.txt" sudo apt-get install -y
{{   end -}}
{{ end -}}
```

Shebang yeterli, Windows'taki gibi `[interpreters]` tanımı gerekmez.

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