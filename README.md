<!-- 静态徽章，开箱即用；如需同步仓库信息可替换为 shields.io 动态徽章 -->
![Platform](https://img.shields.io/badge/platform-Windows%2010%2B-0078D6?logo=windows&logoColor=white)
![Shell](https://img.shields.io/badge/shell-cmd%20batch-4D4D4D)
![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

# ModelPing

> 一个用于快速验证 OpenAI 兼容 API Key 是否有效的 Windows 批处理脚本。

[English](README.en.md) | **中文**

在命令行里输入 `ModelPing 厂商 密钥 模型名`，脚本就会替你向对应平台发送一次小请求，根据返回的 HTTP 状态码告诉你这把 Key 到底能不能用。

```console
C:\>modelping 智谱 7f130286f301486d86e3a8e88495e3c7 glm-5.3-flash
[ModelPing] vendor=智谱  model=glm-5.3-flash
[i] verifying configured Zhipu probe key ...
[*] URL  : https://open.bigmodel.cn/api/paas/v4/chat/completions
[*] Model: glm-5.3-flash
========== HTTP 401 ==========
[RESULT] Key 无效 / 令牌过期或验证不正确 / 无权限 (401)
[*] done. returning to console.
```

---

## 目录

- [要解决的问题](#要解决的问题)
- [主要功能](#主要功能)
- [亮点设计](#亮点设计)
- [运行环境](#运行环境)
- [安装方式](#安装方式)
- [使用方式](#使用方式)
- [HTTP 状态码结论速查](#http-状态码结论速查)
- [常见问题](#常见问题)
- [目录结构](#目录结构)
- [安全提示](#安全提示)
- [免责声明](#免责声明)
- [License](#license)

---

## 要解决的问题

在对接各类大模型平台（智谱、DeepSeek、千问、Kimi、OpenAI……）时，经常需要判断一个 API Key 是否有效。常见的痛点：

- **背景知识不统一**：OpenAI 兼容接口的调用方式大致相同，但每个平台的 `base_url` 不一样，记不住、容易拼错。
- **Key 很多、容易混淆**：手头可能同时有一堆 Key（不同厂商、不同用途），每次只能写一段完整的 `curl` 去试，繁琐易错。
- **报错看不懂**：HTTP 返回的 `401 / 429 / 402` 到底什么意思？很多人看到 JSON 里乱码般的 `error.message` 一头雾水。

ModelPing 把这些都收敛成一个命令：**只输入厂商名 + Key + 模型名**，其余交给脚本。

---

## 主要功能

- **一次命令测 Key**：`ModelPing <厂商> <API Key> <模型名>` 即可完成验证，无需记忆任何 URL。
- **内置厂商对照表**：内置大量常见大模型平台的 `base_url`，你只需输入厂商名（支持中/英文别名）即可索引。
- **厂商名找不到也能用**：当输入的厂商不在表内时，脚本会用智谱 `glm-4-flash` 免费模型自动探测该平台的 `base_url`。
- **智能中文结论**：根据返回的 HTTP 状态码（200 / 401 / 403 / 429 / 402 等）给出人类可读的中文结论，**绝不出现乱码**。
- **Key 自动"待机"配置**：首次使用会引导你配置一把智谱 Key（仅用于上述探测），验证成功后写入旁挂文件，后续每次运行自动校验，失效则提示重配。
- **即拿即用**：脚本本身不写死任何用户 Key，可直接拷贝共享给他人，对方用他自己的 Key 即可。

---

## 亮点设计

| 亮点 | 说明 |
|------|------|
| **厂商名智能索引** | 参数 1 是唯一"智能"参数，内置厂家对照表；参数 2、3（Key、模型名）每次都需准确输入 |
| **零依赖、开箱即用** | 仅需 Windows 自带环境（`curl`、PowerShell），无第三方库 |
| **Key 存旁挂文件，永不改写自身** | Key 存在 `ModelPing.zkey`，脚本 `.bat` 绝不自我改写。这是刻意的架构选择——`cmd` 执行 `.bat` 时会边跑边读文件，若运行中改写自身会破坏后续解析，旁挂文件从根源规避 |
| **直接返回控制台** | 测试完成直接回到命令行，方便连续测试多个 Key，不被"请按任意键继续"打断 |
| **GBK/UTF-8 自动规避** | 脚本用 GBK 编码、提示文案保持 ASCII/中文分离，配合 code→中文表，从根源杜绝乱码 |
| **可安全转让** | 交付时只给 `.bat`，删除 `.zkey` 即为全新初始状态，他人使用其自带 Key 即可 |

---

## 运行环境

- **操作系统**：Windows 10（1803+）/ Windows 11
- **已内置预装组件**（无需额外安装）：
  - `curl.exe`（Windows 10 1803+ 自带）
  - PowerShell 5.1+（Windows 自带）
- **使用前提**：能够访问目标模型平台的公网 API（离线/内网不可用）

---

## 安装方式

任选一种。前两种为**一条命令从仓库拉取安装**，无需手动下载。

### 方式一：PowerShell 一行安装（推荐，零门槛）

在 PowerShell 中粘贴以下命令并回车：

```powershell
irm https://raw.githubusercontent.com/yanhengchuan/modelping/main/install.ps1 | iex
```

> 若 `raw.githubusercontent.com` 被网络屏蔽，可改用 jsDelivr 镜像（`install.ps1` 内部也会自动尝试多个源，无需额外配置）：
>
> ```powershell
> irm https://cdn.jsdelivr.net/gh/yanhengchuan/modelping@main/install.ps1 | iex
> ```

脚本会把 `ModelPing.bat` 下载到 `%LOCALAPPDATA%\ModelPing\`，并自动加入用户 `PATH`。
**安装后请新开一个终端**，使 `PATH` 生效，然后直接运行 `ModelPing ...`。

卸载：

```powershell
irm https://raw.githubusercontent.com/yanhengchuan/modelping/main/uninstall.ps1 | iex
```

### 方式二：Scoop（类 `apt` / `npm` 体验）

```powershell
scoop bucket add modelping https://github.com/yanhengchuan/modelping
scoop install modelping
```

卸载：`scoop uninstall modelping`

### 方式三：直接下载（便携式）

1. 从本仓库下载 `ModelPing.bat` 到任意目录（例如 `D:\Scripts\`）。
2. 可选：把该目录加入系统 `PATH`，即可在任意路径直接调用 `ModelPing`；不加也行，就在脚本所在目录运行。

### 方式四：git clone（开发者）

```powershell
git clone https://github.com/yanhengchuan/modelping.git
cd modelping
.\ModelPing.bat /?
```

> 以上方式均**无需安装任何额外依赖**。探测 Key 文件的存放位置：脚本所在目录可写时放在同目录；若不可写（例如包管理器安装到只读目录），自动回退到 `%LOCALAPPDATA%\ModelPing\`。

---

## 使用方式

```
ModelPing <厂商名> <API Key> <模型名>
```

### 参数说明

| 参数 | 是否智能 | 说明 |
|------|:---:|------|
| 厂商名 | ✅ | 内置对照表索引，支持中/英文别名；表内无此项时自动用智谱免费模型探测 |
| API Key | ❌ | 每次必须准确输入（要验证的这把 Key） |
| 模型名 | ❌ | 每次必须准确输入，如 `deepseek-chat`、`glm-4-flash` |

### 内置厂商对照表（参数 1 支持的中/英文别名）

| 厂商别名 | base_url |
|------|------|
| `zhipu` / `glm` / `智谱` / `智普` | `https://open.bigmodel.cn/api/paas/v4` |
| `deepseek` / `深度求索` | `https://api.deepseek.com/v1` |
| `qwen` / `千问` / `通义` / `阿里` / `百炼` / `dashscope` | `https://dashscope.aliyuncs.com/compatible-mode/v1` |
| `ark` / `字节` / `火山` / `豆包` / `doubao` / `volcengine` | `https://ark.cn-beijing.volces.com/api/v3` |
| `kimi` / `moonshot` / `月之暗面` | `https://api.moonshot.cn/v1` |
| `minimax` / `海螺` | `https://api.minimaxi.com/v1` |
| `stepfun` / `阶跃` / `阶跃星辰` / `step` | `https://api.stepfun.com/v1` |
| `openai` / `chatgpt` / `gpt` | `https://api.openai.com/v1` |
| `anthropic` / `claude`（参考，非 OpenAI 兼容） | `https://api.anthropic.com/v1` |
| `gemini` / `google` | `https://generativelanguage.googleapis.com/v1beta/openai` |
| `grok` / `xai` | `https://api.x.ai/v1` |
| `硅基流动` / `siliconflow` | `https://api.siliconflow.cn/v1` |
| `百度` / `千帆` / `qianfan` | `https://qianfan.baidubce.com/v2` |
| `腾讯` / `混元` / `tencent` | `https://api.hunyuan.cloud.tencent.com/v1` |
| `零一` / `yi` | `https://api.lingyiwanwu.com/v1` |
| `百川` / `baichuan` | `https://api.baichuan-ai.com/v1` |
| `groq` / `together` / `mistral` | `https://api.groq.com/openai/v1` 等 |

### 使用示例

```
ModelPing deepseek sk-xxxxxxxxx deepseek-chat
ModelPing zhipu   YOUR_KEY      glm-4-flash
ModelPing kimi    YOUR_KEY      moonshot-v1-8k
```

### 首次使用流程

1. 运行任意一条命令（如 `ModelPing deepseek ...`）。
2. 脚本提示是否配置智谱探测 Key：输入 `Y` / `yes`。
3. 粘贴你**完整**的智谱 Key（形如 `id.secret` 两段式整串）并回车。
4. 脚本用 `glm-4-flash` 验证这把 Key，成功即写入旁挂的 `ModelPing.zkey` 并自动重启执行你的命令。
5. 之后每次运行脚本都会自动校验这把探测 Key，失效则提示重配。

### 查看命令帮助

```
ModelPing /?
```

---

## HTTP 状态码结论速查

| 状态码 | 含义 |
|:---:|------|
| 200 | API Key 有效，模型可用 |
| 401 | Key 无效 / 令牌过期或验证不正确 / 无权限 |
| 402 | 余额不足，Key 有效但需充值 |
| 403 | Key 无权限访问该模型 |
| 404 | 接口/模型不存在，检查 base_url 或模型名 |
| 429 | 请求过频 / 余额或配额耗尽，Key 有效但限流 |
| 500 / 503 | 服务端错误，非 Key 问题 |
| 000 | 连接失败 / 超时（网络或 base_url 不可达） |

> 表内未收录的状态码，脚本会原样打印返回体，便于自行排查。

---

## 常见问题

**Q：为什么我的 Key 提示 401？**
A：优先确认是否**完整复制**。智谱等平台的 Key 是 `id.secret` 两段式，缺一段就会 401。

**Q：参数 2 / 3 能智能化吗？**
A：不能。这是有意设计——Key 和模型名必须由你准确提供，无法也不应自动猜测。

**Q：脚本里会存我的 Key 吗？**
A：探测用的智谱 Key 会存到旁挂的 `ModelPing.zkey`；你命令行传入的要测试的 Key **不会被保存**。交付他人前删除 `.zkey` 即可保证零隐私残留。

**Q：我需要 curl / PowerShell 吗？**
A：Windows 10 1803+ 已内置，无需额外安装。

**Q：提示乱码怎么办？**
A：本脚本已从设计上规避乱码（结论由 HTTP code 查内置中文表得出，不解析 JSON）。若仍偶见乱码，请在 `cmd` 中执行 `chcp 936` 后重试。

**Q：能连续测多个 Key 吗？**
A：可以。脚本执行完直接返回控制台，连续敲命令即可，无需反复按任意键。

---

## 目录结构

```
.
├── ModelPing.bat          # 主脚本（GBK + CRLF，唯一需要分发/安装的文件）
├── install.ps1            # 一行安装脚本（下载 + 配置 PATH）
├── uninstall.ps1          # 卸载脚本
├── bucket/
│   └── modelping.json     # Scoop manifest（供 scoop bucket add 使用）
├── README.md              # 中文说明
├── README.en.md           # 英文说明
├── LICENSE                # MIT
├── .gitignore             # 忽略运行期生成的 ModelPing.zkey 等
├── .gitattributes         # 固定 *.bat 为二进制（保护 GBK/CRLF 不被 Git 转换）
└── ModelPing.zkey         # 运行时生成的本机密钥（不提交）
```

---

## 安全提示

> ⚠️ **`ModelPing.zkey` 内含真实 API Key，严禁提交到版本库。**

首次运行脚本后会在同目录生成 `ModelPing.zkey`。为避免误提交，请将以下内容加入仓库根目录的 `.gitignore`：

```gitignore
# ModelPing 运行期生成的本地密钥文件
ModelPing.zkey
```

若你 fork 或 clone 本项目，请确认该文件已被忽略。如果已经误提交，**立即到平台吊销该 Key 并重新生成**——仅从 `git` 历史里删除并不能阻止密钥泄漏。

---

## 免责声明

本项目为个人开源的便利工具，与任何模型厂商**均无关联**，亦不代表其官方立场。脚本内置的各平台 `base_url` 与模型名可能随厂商 API 调整而失效，请以各平台官方文档为准。使用者需自行确保对目标 Key 拥有合法使用权，因使用本工具产生的任何后果由使用者自行承担。

---

## 贡献

欢迎提交 Issue 与 Pull Request。若某个平台的 `base_url` 已变更或你想新增厂商，直接改脚本顶部的厂商对照表即可（保持 GBK 编码 + CRLF 行尾）。

---

## License

本项目基于 [MIT License](LICENSE) 开源。
