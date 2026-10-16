<!-- Static badges; ready to use as-is -->
![Platform](https://img.shields.io/badge/platform-Windows%2010%2B-0078D6?logo=windows&logoColor=white)
![Shell](https://img.shields.io/badge/shell-cmd%20batch-4D4D4D)
![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

# ModelPing

> A Windows batch script that quickly verifies whether an OpenAI-compatible API key is valid.

Type `ModelPing <vendor> <key> <model>` on the command line, and the script sends one small request to the corresponding platform and tells you whether the key actually works, based on the returned HTTP status code.

**English** | [中文](ModelPing-README.md)

```console
C:\>modelping zhipu 7f130286f301486d86e3a8e88495e3c7 glm-5.3-flash
[ModelPing] vendor=智谱  model=glm-5.3-flash
[i] verifying configured Zhipu probe key ...
[*] URL  : https://open.bigmodel.cn/api/paas/v4/chat/completions
[*] Model: glm-5.3-flash
========== HTTP 401 ==========
[RESULT] Key 无效 / 令牌过期或验证不正确 / 无权限 (401)
[*] done. returning to console.
```

> Note: conclusion messages are emitted in Chinese by design (see [Limitations](#limitations--notes)). The status code is always shown, so the result is unambiguous in any locale.

---

## Table of Contents

- [Problem It Solves](#problem-it-solves)
- [Features](#features)
- [Design Highlights](#design-highlights)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [HTTP Status Code Reference](#http-status-code-reference)
- [FAQ](#faq)
- [Repository Layout](#repository-layout)
- [Security Notice](#security-notice)
- [Limitations & Notes](#limitations--notes)
- [Disclaimer](#disclaimer)
- [License](#license)

---

## Problem It Solves

When working with various LLM platforms (Zhipu, DeepSeek, Qwen, Kimi, OpenAI, …), you often need to determine whether an API key is valid. Common pain points:

- **Inconsistent background knowledge**: OpenAI-compatible APIs are broadly similar to call, but every platform has a different `base_url` — hard to remember, easy to typo.
- **Too many keys, easy to mix up**: You may hold a pile of keys (different vendors, different purposes), and writing a full `curl` command each time is tedious and error-prone.
- **Unreadable errors**: What do HTTP `401 / 429 / 402` really mean? Many people are baffled by the garbled `error.message` inside the JSON.

ModelPing collapses all of this into a single command: **just the vendor name + key + model name** — the script handles the rest.

---

## Features

- **One command to test a key**: `ModelPing <vendor> <API key> <model>` finishes the verification; no URLs to memorize.
- **Built-in vendor lookup table**: Ships with `base_url` entries for many common LLM platforms. Just type the vendor name (Chinese/English aliases supported).
- **Works even for unknown vendors**: If the vendor is not in the table, the script probes the platform's `base_url` using Zhipu's free `glm-4-flash` model.
- **Human-readable conclusions**: Maps the returned HTTP status code (200 / 401 / 403 / 429 / 402, etc.) to a clear conclusion — **no mojibake, ever**.
- **Automatic "idle" key setup**: On first use it guides you to configure a Zhipu key (used only for the probe above), verifies it, and stores it in a sidecar file. Every subsequent run re-validates it and prompts for a new one if it has expired.
- **Ready to use**: The script hard-codes no user key and can be copied/shared directly — the recipient simply uses their own key.

---

## Design Highlights

| Highlight | Description |
|------|------|
| **Smart vendor indexing** | Arg 1 is the only "smart" parameter, backed by a built-in vendor table; args 2 and 3 (key, model) must be typed exactly each time |
| **Zero dependencies, works out of the box** | Uses only what Windows already ships (`curl`, PowerShell); no third-party libraries |
| **Key lives in a sidecar file; the script never rewrites itself** | The key is stored in `ModelPing.zkey`, and the `.bat` never modifies itself. This is a deliberate architectural choice — `cmd` reads a `.bat` file on the fly while running it, so in-place rewriting corrupts the rest of the execution. A sidecar file avoids this at the root |
| **Returns straight to the console** | Finishing the test returns you to the prompt immediately, so you can test many keys in a row without "press any key to continue" interruptions |
| **GBK/UTF-8 mojibake avoidance** | The script is GBK-encoded and keeps prompt text separate from ASCII/Chinese; combined with the code→Chinese conclusion table, mojibake is eliminated at the root |
| **Safe to hand over** | Ship only the `.bat`; deleting `.zkey` restores a fresh initial state, and the next user supplies their own key |

---

## Requirements

- **OS**: Windows 10 (1803+) / Windows 11
- **Bundled components** (nothing extra to install):
  - `curl.exe` (ships with Windows 10 1803+)
  - PowerShell 5.1+ (ships with Windows)
- **Prerequisite**: Public network access to the target platform's API (unavailable offline / on an intranet)

---

## Installation

Pick any one. The first two install with a **single command pulled from the repo** — no manual download.

### Option 1: PowerShell one-liner (recommended, zero friction)

Paste this into PowerShell and press Enter:

```powershell
irm https://raw.githubusercontent.com/yanhengchuan/modelping/main/install.ps1 | iex
```

This downloads `ModelPing.bat` to `%LOCALAPPDATA%\ModelPing\` and adds it to your user `PATH`.
**Open a new terminal** afterwards so the `PATH` change takes effect, then run `ModelPing ...`.

Uninstall:

```powershell
irm https://raw.githubusercontent.com/yanhengchuan/modelping/main/uninstall.ps1 | iex
```

### Option 2: Scoop (an `apt` / `npm`-style experience)

```powershell
scoop bucket add modelping https://github.com/yanhengchuan/modelping
scoop install modelping
```

Uninstall: `scoop uninstall modelping`

### Option 3: Direct download (portable)

1. Download `ModelPing.bat` from this repo into any folder (e.g. `D:\Scripts\`).
2. Optional: add that folder to your system `PATH` to call `ModelPing` from anywhere; otherwise just run it from its own folder.

### Option 4: git clone (developers)

```powershell
git clone https://github.com/yanhengchuan/modelping.git
cd modelping
.\ModelPing.bat /?
```

> None of the above require any extra dependency. Where the probe-key file lives: the script folder when writable; otherwise it automatically falls back to `%LOCALAPPDATA%\ModelPing\` (e.g. when a package manager installs into a read-only folder).

---

## Usage

```
ModelPing <vendor> <API key> <model>
```

### Arguments

| Argument | Smart? | Description |
|------|:---:|------|
| vendor | ✅ | Indexed via the built-in table; Chinese/English aliases supported. If absent from the table, the base_url is probed using Zhipu's free model |
| API key | ❌ | Must be typed exactly each time (the key you want to verify) |
| model | ❌ | Must be typed exactly each time, e.g. `deepseek-chat`, `glm-4-flash` |

### Built-in Vendor Table (aliases accepted for arg 1)

| Vendor aliases | base_url |
|------|------|
| `zhipu` / `glm` / `智谱` / `智普` | `https://open.bigmodel.cn/api/paas/v4` |
| `deepseek` / `深度求索` | `https://api.deepseek.com/v1` |
| `qwen` / `千问` / `通义` / `阿里` / `百炼` / `dashscope` | `https://dashscope.aliyuncs.com/compatible-mode/v1` |
| `ark` / `字节` / `火山` / `豆包` / `doubao` / `volcengine` | `https://ark.cn-beijing.volces.com/api/v3` |
| `kimi` / `moonshot` / `月之暗面` | `https://api.moonshot.cn/v1` |
| `minimax` / `海螺` | `https://api.minimaxi.com/v1` |
| `stepfun` / `阶跃` / `阶跃星辰` / `step` | `https://api.stepfun.com/v1` |
| `openai` / `chatgpt` / `gpt` | `https://api.openai.com/v1` |
| `anthropic` / `claude` (reference only, not OpenAI-compatible) | `https://api.anthropic.com/v1` |
| `gemini` / `google` | `https://generativelanguage.googleapis.com/v1beta/openai` |
| `grok` / `xai` | `https://api.x.ai/v1` |
| `硅基流动` / `siliconflow` | `https://api.siliconflow.cn/v1` |
| `百度` / `千帆` / `qianfan` | `https://qianfan.baidubce.com/v2` |
| `腾讯` / `混元` / `tencent` | `https://api.hunyuan.cloud.tencent.com/v1` |
| `零一` / `yi` | `https://api.lingyiwanwu.com/v1` |
| `百川` / `baichuan` | `https://api.baichuan-ai.com/v1` |
| `groq` / `together` / `mistral` | `https://api.groq.com/openai/v1`, etc. |

### Examples

```
ModelPing deepseek sk-xxxxxxxxx deepseek-chat
ModelPing zhipu   YOUR_KEY      glm-4-flash
ModelPing kimi    YOUR_KEY      moonshot-v1-8k
```

### First-Run Flow

1. Run any command (e.g. `ModelPing deepseek ...`).
2. The script asks whether to configure a Zhipu probe key: type `Y` / `yes`.
3. Paste your **complete** Zhipu key (the full `id.secret` string) and press Enter.
4. The script verifies it with `glm-4-flash`, saves it to the sidecar `ModelPing.zkey`, and automatically restarts to execute your command.
5. On every later run the script re-validates this probe key and prompts you to reconfigure it if it has expired.

### Command Help

```
ModelPing /?
```

---

## HTTP Status Code Reference

| Code | Meaning |
|:---:|------|
| 200 | API key valid, model available |
| 401 | Key invalid / token expired or verification failed / no permission |
| 402 | Insufficient balance; key valid but needs top-up |
| 403 | Key has no permission for this model |
| 404 | Endpoint/model not found; check base_url or model name |
| 429 | Too many requests / quota or balance exhausted; key valid but rate-limited |
| 500 / 503 | Server-side error; not a key problem |
| 000 | Connection failed / timeout (network or base_url unreachable) |

> For a status code not in the table, the script prints the raw response body for you to inspect.

---

## FAQ

**Q: Why does my key return 401?**
A: First check that you copied it **in full**. Keys on platforms like Zhipu follow the `id.secret` two-part form — missing one part causes a 401.

**Q: Can args 2 / 3 be smart too?**
A: No. That is intentional — the key and model must be provided exactly by you and cannot (and should not) be auto-guessed.

**Q: Does the script store my key?**
A: The Zhipu key used for probing is saved to the sidecar `ModelPing.zkey`; the key you pass on the command line **is not saved**. Delete `.zkey` before handing the tool to someone else for zero residue.

**Q: Do I need curl / PowerShell?**
A: Windows 10 1803+ ships both; no extra installation is required.

**Q: What if I see garbled characters?**
A: Mojibake is avoided by design (conclusions come from an HTTP-code lookup table, not from JSON parsing). Should you ever see it, run `chcp 936` in `cmd` and retry.

**Q: Can I test several keys in a row?**
A: Yes. The script returns to the console when done — just type the next command; no need to keep pressing a key.

---

## Repository Layout

```
.
├── ModelPing.bat          # main script (GBK + CRLF; the only file to distribute/install)
├── install.ps1            # one-line installer (download + PATH setup)
├── uninstall.ps1          # uninstaller
├── bucket/
│   └── modelping.json     # Scoop manifest (for `scoop bucket add`)
├── README.md              # Chinese docs
├── README.en.md           # English docs
├── LICENSE                # MIT
├── .gitignore             # ignores the runtime ModelPing.zkey, etc.
├── .gitattributes         # pins *.bat as binary (protects GBK/CRLF from Git)
└── ModelPing.zkey         # runtime key file (generated locally, never committed)
```

---

## Security Notice

> ⚠️ **`ModelPing.zkey` contains a real API key — never commit it to a repository.**

After the first run, a `ModelPing.zkey` file is generated in the script's directory. To prevent accidental commits, add the following to your repository's `.gitignore`:

```gitignore
# Local secret file generated at runtime by ModelPing
ModelPing.zkey
```

If you fork or clone this project, confirm the file is ignored. If it has already been committed by mistake, **revoke that key on the platform and generate a new one immediately** — merely removing it from `git` history does not stop the leak.

---

## Limitations & Notes

- **Windows only**: the script relies on `cmd`, `curl.exe`, and PowerShell.
- **Conclusion messages are in Chinese**: the built-in status-code table emits Chinese text. The numeric HTTP code is always printed alongside, so results remain unambiguous regardless of locale.
- **Vendor data can change**: built-in `base_url` entries and suggested model names may break when a platform changes its API; always defer to the official docs.
- **Network required**: the tool cannot validate keys offline.

---

## Disclaimer

This is a personal open-source convenience tool. It is **not affiliated with, endorsed by, or representing** any model vendor. The built-in `base_url` values and model names may become outdated as vendors change their APIs; refer to each platform's official documentation. You are responsible for ensuring you have the lawful right to use any key you test. Any consequences of using this tool are borne by the user.

---

## Contributing

Issues and pull requests are welcome. If a platform's `base_url` has changed, or you want to add a vendor, simply edit the vendor table near the top of the script (keep GBK encoding + CRLF line endings).

---

## License

Released under the [MIT License](LICENSE).
