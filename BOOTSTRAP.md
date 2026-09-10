# BOOTSTRAP — Yeni PC'ye full kurulum (AI'ye ver, tek tek uygular)

> Bu dosya fresh bir AI session'ına verilir. AI aşağıdaki adımları SORU SORMADAN sırayla uygular.
> Hedef: Windows, OpenCode + oh-my-openagent + tüm skill/MCP/config'ler çalışır halde.
> Kaynak: `opencode-kurulum-promptu.md` (skill+MCP detayları) + `~/.omo/omo.jsonc` (model eşlemesi).

```text
ROLE: Yeni PC bootstrap otomasyonu. Soru sormadan, sırayla, her adım bitmeden sonrakine geçme.

ADIM 0 — Ön koşullar (PowerShell, hepsi kurulu olmalı, eksikse DUR ve söyle):
git --version; node --version; npm --version; bun --version; uv --version; python --version
opencode --version  # >= 1.4.0 olmalı, yoksa https://opencode.ai/docs adresinden kur
# bun yoksa: powershell -c "irm bun.sh/install.ps1 | iex"

ADIM 1 — OMO installer:
bunx oh-my-openagent install --platform=opencode
# TUI açılır: opencode-go aboneliğini seç, soruları cevapla.
# Plugin kaydı şu dosyada olmalı: %USERPROFILE%\.config\opencode\opencode.jsonc
#   { "$schema": "https://opencode.ai/config.json", "plugin": ["oh-my-openagent@latest"], ... }

ADIM 2 — Dizinler:
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config\opencode\skills" | Out-Null
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config\opencode\mcp-servers" | Out-Null

ADIM 3 — Skill repolarını klonla (sırayla):
1) git clone --depth 1 https://github.com/leynos/rust-skill.git "$env:USERPROFILE\.config\opencode\skills\leynos-rust-skill"
2) git clone --filter=blob:none --sparse https://github.com/mattpocock/skills.git "$env:USERPROFILE\.config\opencode\skills\mattpocock-skills"
   git -C "$env:USERPROFILE\.config\opencode\skills\mattpocock-skills" sparse-checkout set skills/productivity/teach skills/productivity/grill-me skills/productivity/grilling
   # NOT: grill-me, grilling'e bağımlıdır (SKILL.md tek satır Call Skill grilling der). İkisi de şart.
3) git clone --filter=blob:none --sparse https://github.com/anthropics/skills.git "$env:USERPROFILE\.config\opencode\skills\anthropics-skills"
   git -C "$env:USERPROFILE\.config\opencode\skills\anthropics-skills" sparse-checkout set skills/skill-creator skills/frontend-design
4) git clone --filter=blob:none --sparse https://github.com/actionbook/rust-skills.git "$env:USERPROFILE\.config\opencode\skills\actionbook-rust-skills"
   git -C "$env:USERPROFILE\.config\opencode\skills\actionbook-rust-skills" sparse-checkout set skills/rust-router skills/domain-embedded skills/domain-cli skills/m01-ownership skills/m02-resource
5) git clone --depth 1 https://github.com/aklofas/kicad-happy.git "$env:USERPROFILE\.config\opencode\skills\kicad-happy"
6) git clone --depth 1 -b master https://github.com/SPREsxm/claude-pcb-designer.git "$env:USERPROFILE\.config\opencode\skills\claude-pcb-designer"
   Rename-Item -LiteralPath "$env:USERPROFILE\.config\opencode\skills\claude-pcb-designer" -NewName "pcb-designer"
   # SEBEP: SKILL.md frontmatter name: pcb-designer, klasör adı eşleşmeli yoksa opencode skill'i filtreler.
7) git clone --depth 1 -b master https://github.com/satoruhiga/claude-touchdesigner.git "$env:USERPROFILE\.config\opencode\skills\claude-touchdesigner"
   Rename-Item -LiteralPath "$env:USERPROFILE\.config\opencode\skills\claude-touchdesigner\touchdesigner\skills\td-guide" -NewName "touchdesigner"
   # SEBEP: SKILL.md name: touchdesigner, klasör td-guide idi. Eşleşmeli.
8) git clone --depth 1 https://github.com/rheadsh/audiovisual-production-skills.git "$env:USERPROFILE\.config\opencode\skills\audiovisual-production-skills"
9) git clone --depth 1 https://github.com/SpillwaveSolutions/design-doc-mermaid.git "$env:USERPROFILE\.config\opencode\skills\design-doc-mermaid"
10) KURMA: axtonliu/axton-obsidian-visual-skills (prototype/unmaintained).
11) K-Dense-AI/scientific-agent-skills KLONLAMA — sadece ADIM 5 references'e eklenir.

ADIM 4 — KiCAD-MCP-Server (build şart):
git clone https://github.com/mixelpixx/KiCAD-MCP-Server.git "$env:USERPROFILE\.config\opencode\mcp-servers\KiCAD-MCP-Server"
cd "$env:USERPROFILE\.config\opencode\mcp-servers\KiCAD-MCP-Server"; npm install; npm run build
# dist/index.js oluşmalı. Oluşmadıysa dur.
# KiCad sürümünü OTOMATİK tespit et: C:\Program Files\KiCad\<VER>\bin\python.exe
# & "<KICAD>\bin\python.exe" -m pip install -r requirements.txt
# & "<KICAD>\bin\python.exe" -c "import pcbnew; print(pcbnew.__file__)"  # yol yazdırmalı
# PYTHONPATH = pcbnew.py dizini, KICAD_PYTHON = python.exe yolu.

ADIM 5 — opencode.jsonc'yi yaz (mevcut $schema + plugin satırlarını KORU):
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["oh-my-openagent@latest"],
  "mcp": {
    "kicad": {
      "type": "local",
      "command": ["node", "<USERPROFILE>\\.config\\opencode\\mcp-servers\\KiCAD-MCP-Server\\dist\\index.js"],
      "enabled": true,
      "environment": {
        "NODE_ENV": "production", "LOG_LEVEL": "info",
        "KICAD_AUTO_LAUNCH": "false", "KICAD_MCP_DEV": "0", "KICAD_BACKEND": "auto",
        "PYTHONPATH": "<KICAD_PCBNEW_DIZINI>", "KICAD_PYTHON": "<KICAD_PYTHON_EXE>"
      }
    },
    "pcbparts": { "type": "remote", "url": "https://pcbparts.dev/mcp", "enabled": true },
    "touchdesigner": { "type": "local", "command": ["npx", "-y", "touchdesigner-mcp-server@latest", "--stdio"], "enabled": true, "environment": {} },
    "mermaid": { "type": "local", "command": ["cmd", "/c", "npx", "-y", "mcp-mermaid"], "enabled": true, "environment": {} }
  },
  "references": {
    "scientific-skills": {
      "repository": "K-Dense-AI/scientific-agent-skills", "branch": "main",
      "description": "Use for electronics, analog, physics, chemistry, statistics, information theory reference skills (163-skill mega-collection, on-demand via @scientific-skills)"
    }
  }
}
# KRİTİK: mcp.*.command dizi olmalı (string yasak), her server'da type şart.

ADIM 6 — omo.jsonc'yi yaz (%USERPROFILE%\.omo\omo.jsonc, aynen):
// OMO configuration
{
  "[opencode]": {
    "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/omo.schema.json",
    "agents": {
      "sisyphus": { "model": "opencode-go/kimi-k3" },
      "oracle": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "librarian": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "explore": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "multimodal-looker": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "prometheus": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "metis": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "momus": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "atlas": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "sisyphus-junior": { "model": "opencode-go/muse-spark-1.3-contributor" }
    },
    "categories": {
      "visual-engineering": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "ultrabrain": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "deep": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "artistry": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "quick": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "unspecified-low": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "unspecified-high": { "model": "opencode-go/muse-spark-1.3-contributor" },
      "writing": { "model": "opencode-go/muse-spark-1.3-contributor" }
    },
    "team_mode": { "enabled": true, "max_parallel_members": 4, "max_members": 8, "tmux_visualization": true }
  },
  "_migrations": ["2026-08-reasoning-unification"]
}
# ÖLÜMCÜL KURALLAR (çiğnenirse doctor "Invalid configuration" verir, tüm dosya çöp olur):
# - team_mode SADECE "[opencode]" bloğunun İÇİNDE. Top-level team_mode YASAK.
# - top-level telemetry YASAK (strict schema).
# - reasoning/variant/fallback_models anahtarı YOK (sade model).
# - %USERPROFILE%\.config\opencode\oh-my-openagent.jsonc DOSYASI OLMAMALI (legacy). Varsa sil.
# - Sadece sisyphus kimi-k3 (ultra zeka), diğer 17 slot muse-spark-1.3-contributor (token sınırsız).

ADIM 7 — Doğrula (hepsi yeşil olmalı):
- python -c "import json; json.load(open(r'%USERPROFILE%\.config\opencode\opencode.jsonc')); print('JSON OK')"
- skills altında **/SKILL.md sayısı >= 50
- pcb-designer/SKILL.md + touchdesigner/skills/touchdesigner/SKILL.md var
- dist/index.js var
- bunx oh-my-openagent doctor --verbose:
  "Invalid configuration" YOK, ● override'lar görünür, [team-mode] satırı okunduğunu kanıtlar
  ("capabilities: unknown" normaldir, muse-spark 02.09.2026 çıkışlı, fallback ile çalışır)
- Hata varsa düzeltmeden bitirme.

BİTİNCE: skill sayısı + 4 MCP durumu + doctor özeti + "opencode'u kapatıp yeniden başlat (team_* tool'ları için şart)" yaz.
```

---

## Bu dosyanın karşılığı (10 Eylül 2026, can@c)

- 52x SKILL.md global `skills\` altında
- 4x MCP (`opencode.jsonc`): kicad local-node, pcbparts remote, touchdesigner npx, mermaid cmd-wrapper
- KiCad 10.0: `C:\Program Files\KiCad\10.0\bin\python.exe`
- 2 rename (pcb-designer, touchdesigner), K-Dense referans, axtonliu yok
- OMO: `[opencode]` içinde team_mode + sadece sisyphus kimi-k3, diğer 17 slot muse-spark-1.3-contributor
