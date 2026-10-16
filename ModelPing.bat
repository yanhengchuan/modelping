@echo off
setlocal EnableExtensions EnableDelayedExpansion
title ModelPing - API Key tester

rem ============================================================
rem   ModelPing.bat  (by 周伯通 - 2026-10-16)
rem   Usage:  ModelPing  arg1  arg2  arg3
rem     arg1 = vendor / platform name (smart index table below; when
rem            not found, probes the base_url via Zhipu glm-flash free model)
rem     arg2 = the API key under test (must be typed exactly each time)
rem     arg3 = the model name under test (must be typed exactly each time)
rem
rem   Zhipu probe key (used only for the free-model base_url probe):
rem     Stored in a sidecar file "ModelPing.zkey" (one ASCII line).
rem     Location: the script's own folder when writable (portable use);
rem     otherwise the per-user %LOCALAPPDATA%\ModelPing\ (e.g. after a
rem     Chocolatey install, where the package folder is read-only for
rem     normal users).  See the path-resolution block below.
rem     First run asks whether to configure it, verifies it against
rem     glm-4-flash, and writes it to the sidecar file.
rem     Every run re-verifies it; a dead key forces a fresh entry.
rem   IMPORTANT: this .bat never rewrites itself.  cmd reads a .bat file
rem     on the fly while running it, so in-place rewriting corrupts the
rem     rest of the execution.  Key must live in the sidecar file.
rem ============================================================

set "MP_ZKEY_CONFIG="

rem ---- resolve where the sidecar key file lives ----
rem   Prefer the script folder (portable / direct download).  If that folder
rem   is read-only (e.g. installed under C:\ProgramData\chocolatey\lib, where
rem   BUILTIN\Users only has RX), fall back to the per-user %LOCALAPPDATA%.
set "MP_ZKEY_DIR=%~dp0"
set "MP_WTEST=%~dp0.mp_wtest"
> "%MP_WTEST%" echo. 2>nul
if not exist "%MP_WTEST%" set "MP_ZKEY_DIR=%LOCALAPPDATA%\ModelPing\"
del "%MP_WTEST%" >nul 2>&1
if not exist "%MP_ZKEY_DIR%" mkdir "%MP_ZKEY_DIR%" >nul 2>&1
set "MP_ZKEY_FILE=%MP_ZKEY_DIR%ModelPing.zkey"

set "MP_VENDOR=%~1"
set "MP_KEY=%~2"
set "MP_MODEL=%~3"

if /i "%MP_VENDOR%"=="/?"   goto :help
if "%MP_VENDOR%"==""         goto :help
if "%MP_KEY%"==""            goto :needkey
if "%MP_MODEL%"==""          goto :needmodel

echo.
echo [ModelPing] vendor=%MP_VENDOR%  model=%MP_MODEL%
echo.

rem ---- check the Zhipu probe key on every run ----
call :CHECKZKEY

set "MP_URL="

rem ---- vendor -> base_url index table (Chinese aliases kept in GBK) ----
if /i "%MP_VENDOR%"=="智谱"        set "MP_URL=https://open.bigmodel.cn/api/paas/v4"
if /i "%MP_VENDOR%"=="智普"        set "MP_URL=https://open.bigmodel.cn/api/paas/v4"
if /i "%MP_VENDOR%"=="zhipu"       set "MP_URL=https://open.bigmodel.cn/api/paas/v4"
if /i "%MP_VENDOR%"=="bigmodel"    set "MP_URL=https://open.bigmodel.cn/api/paas/v4"
if /i "%MP_VENDOR%"=="glm"         set "MP_URL=https://open.bigmodel.cn/api/paas/v4"

if /i "%MP_VENDOR%"=="deepseek"    set "MP_URL=https://api.deepseek.com/v1"
if /i "%MP_VENDOR%"=="深度求索"     set "MP_URL=https://api.deepseek.com/v1"

if /i "%MP_VENDOR%"=="千问"        set "MP_URL=https://dashscope.aliyuncs.com/compatible-mode/v1"
if /i "%MP_VENDOR%"=="通义"        set "MP_URL=https://dashscope.aliyuncs.com/compatible-mode/v1"
if /i "%MP_VENDOR%"=="qwen"        set "MP_URL=https://dashscope.aliyuncs.com/compatible-mode/v1"
if /i "%MP_VENDOR%"=="阿里"        set "MP_URL=https://dashscope.aliyuncs.com/compatible-mode/v1"
if /i "%MP_VENDOR%"=="dashscope"   set "MP_URL=https://dashscope.aliyuncs.com/compatible-mode/v1"
if /i "%MP_VENDOR%"=="百炼"        set "MP_URL=https://dashscope.aliyuncs.com/compatible-mode/v1"

if /i "%MP_VENDOR%"=="字节"        set "MP_URL=https://ark.cn-beijing.volces.com/api/v3"
if /i "%MP_VENDOR%"=="火山"        set "MP_URL=https://ark.cn-beijing.volces.com/api/v3"
if /i "%MP_VENDOR%"=="豆包"        set "MP_URL=https://ark.cn-beijing.volces.com/api/v3"
if /i "%MP_VENDOR%"=="ark"         set "MP_URL=https://ark.cn-beijing.volces.com/api/v3"
if /i "%MP_VENDOR%"=="volc"        set "MP_URL=https://ark.cn-beijing.volces.com/api/v3"
if /i "%MP_VENDOR%"=="volcengine"  set "MP_URL=https://ark.cn-beijing.volces.com/api/v3"
if /i "%MP_VENDOR%"=="doubao"      set "MP_URL=https://ark.cn-beijing.volces.com/api/v3"

if /i "%MP_VENDOR%"=="月之暗面"     set "MP_URL=https://api.moonshot.cn/v1"
if /i "%MP_VENDOR%"=="kimi"        set "MP_URL=https://api.moonshot.cn/v1"
if /i "%MP_VENDOR%"=="moonshot"    set "MP_URL=https://api.moonshot.cn/v1"

if /i "%MP_VENDOR%"=="minimax"     set "MP_URL=https://api.minimaxi.com/v1"
if /i "%MP_VENDOR%"=="海螺"        set "MP_URL=https://api.minimaxi.com/v1"

if /i "%MP_VENDOR%"=="阶跃"        set "MP_URL=https://api.stepfun.com/v1"
if /i "%MP_VENDOR%"=="阶跃星辰"     set "MP_URL=https://api.stepfun.com/v1"
if /i "%MP_VENDOR%"=="stepfun"     set "MP_URL=https://api.stepfun.com/v1"
if /i "%MP_VENDOR%"=="step"        set "MP_URL=https://api.stepfun.com/v1"

if /i "%MP_VENDOR%"=="openai"      set "MP_URL=https://api.openai.com/v1"
if /i "%MP_VENDOR%"=="chatgpt"     set "MP_URL=https://api.openai.com/v1"
if /i "%MP_VENDOR%"=="gpt"         set "MP_URL=https://api.openai.com/v1"

if /i "%MP_VENDOR%"=="anthropic"   set "MP_URL=https://api.anthropic.com/v1"
if /i "%MP_VENDOR%"=="claude"      set "MP_URL=https://api.anthropic.com/v1"

if /i "%MP_VENDOR%"=="gemini"      set "MP_URL=https://generativelanguage.googleapis.com/v1beta/openai"
if /i "%MP_VENDOR%"=="google"      set "MP_URL=https://generativelanguage.googleapis.com/v1beta/openai"

if /i "%MP_VENDOR%"=="grok"        set "MP_URL=https://api.x.ai/v1"
if /i "%MP_VENDOR%"=="xai"         set "MP_URL=https://api.x.ai/v1"

if /i "%MP_VENDOR%"=="硅基流动"     set "MP_URL=https://api.siliconflow.cn/v1"
if /i "%MP_VENDOR%"=="siliconflow" set "MP_URL=https://api.siliconflow.cn/v1"

if /i "%MP_VENDOR%"=="百度"        set "MP_URL=https://qianfan.baidubce.com/v2"
if /i "%MP_VENDOR%"=="千帆"        set "MP_URL=https://qianfan.baidubce.com/v2"
if /i "%MP_VENDOR%"=="qianfan"     set "MP_URL=https://qianfan.baidubce.com/v2"

if /i "%MP_VENDOR%"=="腾讯"        set "MP_URL=https://api.hunyuan.cloud.tencent.com/v1"
if /i "%MP_VENDOR%"=="混元"        set "MP_URL=https://api.hunyuan.cloud.tencent.com/v1"
if /i "%MP_VENDOR%"=="tencent"     set "MP_URL=https://api.hunyuan.cloud.tencent.com/v1"

if /i "%MP_VENDOR%"=="零一"        set "MP_URL=https://api.lingyiwanwu.com/v1"
if /i "%MP_VENDOR%"=="yi"          set "MP_URL=https://api.lingyiwanwu.com/v1"

if /i "%MP_VENDOR%"=="百川"        set "MP_URL=https://api.baichuan-ai.com/v1"
if /i "%MP_VENDOR%"=="baichuan"    set "MP_URL=https://api.baichuan-ai.com/v1"

if /i "%MP_VENDOR%"=="groq"        set "MP_URL=https://api.groq.com/openai/v1"
if /i "%MP_VENDOR%"=="together"    set "MP_URL=https://api.together.xyz/v1"
if /i "%MP_VENDOR%"=="mistral"     set "MP_URL=https://api.mistral.ai/v1"

rem ============================================================
rem   vendor not in table -> probe with Zhipu glm-flash free model
rem ============================================================
if "%MP_URL%"=="" (
    echo [i] vendor not in table, probing with Zhipu glm-flash free model ...
    call :PROBE
)

if "%MP_URL%"=="" (
    echo.
    set /p "MP_URL=Please type an OpenAI-compatible base_url (e.g. https://api.xxx.com/v1): "
    if "!MP_URL!"=="" goto :fail
)
goto :test

rem ============================================================
rem   Zhipu probe key: load / verify / configure (every run)
rem ============================================================

:LOADZKEY
    set "MP_ZKEY_CONFIG="
    if not exist "%MP_ZKEY_FILE%" exit /b 1
    for /f "usebackq delims=" %%K in ("%MP_ZKEY_FILE%") do set "MP_ZKEY_CONFIG=%%K"
    exit /b 0

:CHECKZKEY
    call :LOADZKEY
    if "!MP_ZKEY_CONFIG!"=="" goto :ZKEY_EMPTY
    echo [i] verifying configured Zhipu probe key ...
    call :VERIFY_ZKEY
    if not errorlevel 1 exit /b 0
    echo [WARN] configured Zhipu probe key REJECTED by API.
    set "MP_ZKEY_CONFIG="
    :ZKEY_EMPTY
    echo.
    echo Configure now? type Y/yes to enter a valid Zhipu API Key, other to skip.
    set /p "MP_YN="
    if /i "!MP_YN!"=="y"   goto :CFG_KEY
    if /i "!MP_YN!"=="yes" goto :CFG_KEY
    echo    skipped (zhipu probe disabled; manual base_url still usable)
    exit /b 0

:VERIFY_ZKEY
    set "MP_ZKEY_HTTP=000"
    >"%TEMP%\mp_verify_body.json" echo {"model":"glm-4-flash","messages":[{"role":"user","content":"ping"}],"max_tokens":1}
    for /f %%C in ('curl.exe -s -m 15 -o "%TEMP%\mp_verify.json" -w "%%{http_code}" -X POST "https://open.bigmodel.cn/api/paas/v4/chat/completions" -H "Authorization: Bearer !MP_ZKEY_CONFIG!" -H "Content-Type: application/json" -d "@%TEMP%\mp_verify_body.json"') do set "MP_ZKEY_HTTP=%%C"
    if "!MP_ZKEY_HTTP!"=="200" exit /b 0
    exit /b 1

:CFG_KEY
    set "MP_YN="
    set "MP_ZKEY_RAW="
    echo.
    echo Enter Zhipu Probe API Key (no echo; paste fully then press Enter):
    set /p "MP_ZKEY_RAW=> "
    if "!MP_ZKEY_RAW!"=="" (
        echo [WARN] empty input, abort.
        exit /b 1
    )
    set "MP_ZKEY_CONFIG=!MP_ZKEY_RAW!"
    echo [i] verifying the key you typed ...
    call :VERIFY_ZKEY
    if errorlevel 1 (
        echo [X] the key is REJECTED by API. please type a valid one.
        goto :CFG_KEY
    )
    rem ---- write key to sidecar (pure ASCII line, no self-rewrite) ----
    > "!MP_ZKEY_FILE!" echo !MP_ZKEY_RAW!
    if not exist "!MP_ZKEY_FILE!" (
        echo [WARN] failed to save key file.
        exit /b 1
    )
    echo [*] key OK and saved to  !MP_ZKEY_FILE!
    echo [*] restarting automatically with your arguments ...
    echo.
    call "%~f0" "%MP_VENDOR%" "%MP_KEY%" "%MP_MODEL%"
    exit /b 0

rem ============================================================
rem   probe base_url via Zhipu glm-flash free model
rem ============================================================
:PROBE
    set "MP_ZKEY=!MP_ZKEY_CONFIG!"
    if "!MP_ZKEY!"=="" (
        echo [WARN] no Zhipu probe key configured; cannot probe.
        set "MP_URL="
        exit /b 1
    )
    >"%TEMP%\mp_probe_body.json" echo {"model":"glm-4-flash","messages":[{"role":"user","content":"What is the OpenAI-compatible chat completions base_url for provider '%MP_VENDOR%'? Reply with ONLY one URL like https://api.example.com/v1 and nothing else."}],"max_tokens":60}
    curl.exe -s -m 20 -o "%TEMP%\mp_probe.json" -X POST "https://open.bigmodel.cn/api/paas/v4/chat/completions" -H "Authorization: Bearer !MP_ZKEY!" -H "Content-Type: application/json" -d "@%TEMP%\mp_probe_body.json"
    >"%TEMP%\mp_extract.ps1" echo $j = Get-Content -Raw -Encoding UTF8 "%TEMP%\mp_probe.json" ^| ConvertFrom-Json
    >>"%TEMP%\mp_extract.ps1" echo $j.choices[0].message.content
    set "MP_URL="
    for /f "delims=" %%U in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\mp_extract.ps1"') do set "MP_URL=%%U"
    echo [.] probed base_url = %MP_URL%
    if "%MP_URL%"=="" (
        echo [WARN] probe returned no URL.
        set "MP_URL="
        exit /b 1
    )
    exit /b 0

rem ============================================================
rem   final test: call the vendor with the args under test
rem ============================================================
:test
    echo.
    echo [*] URL  : !MP_URL!/chat/completions
    echo [*] Model: %MP_MODEL%
    echo.
    >"%TEMP%\mp_body.json" echo {"model":"%MP_MODEL%","messages":[{"role":"user","content":"reply OK"}],"max_tokens":10}
    set "MP_HTTP=000"
    for /f %%C in ('curl.exe -s -m 30 -o "%TEMP%\mp_resp.json" -w "%%{http_code}" -X POST "!MP_URL!/chat/completions" -H "Authorization: Bearer %MP_KEY%" -H "Content-Type: application/json" -d "@%TEMP%\mp_body.json"') do set "MP_HTTP=%%C"
    echo.
    echo ========== HTTP %MP_HTTP% ==========
    rem ---- friendly meaning via preset code table (no JSON decode, no mojibake) ----
    call :MAP_CODE "!MP_HTTP!"
    if "!MP_HTTP!"=="200" (
        set "HAS="
        findstr /i /c:"choices" "%TEMP%\mp_resp.json" >nul 2>&1 && set "HAS=1"
        if defined HAS echo [OK] response contains "choices" - model answered.
    ) else (
        rem show raw body only for codes not in table
        if not defined MP_MSG (
            set "MP_RAW="
            for /f "usebackq delims=" %%R in ("%TEMP%\mp_resp.json") do set "MP_RAW=%%R"
            echo [RAW] !MP_RAW!
        )
    )
    echo.
    echo [*] done. returning to console.
    exit /b 0

rem ============================================================
rem   HTTP code -> friendly meaning (Chinese table, no JSON decode)
rem   arg1 = HTTP code
rem   Sets MP_MSG to the preset text; null code stays raw.
rem ============================================================
:MAP_CODE
    set "MP_MSG="
    if "%~1"=="200"   set "MP_MSG=API Key 有效，模型可用（令牌有效、权限正常）"
    if "%~1"=="401"   set "MP_MSG=Key 无效 / 令牌过期或验证不正确 / 无权限 (401)"
    if "%~1"=="403"   set "MP_MSG=Key 无权限访问该模型 (403)"
    if "%~1"=="404"   set "MP_MSG=接口/模型不存在 (404)，请检查 base_url 或模型名"
    if "%~1"=="402"   set "MP_MSG=余额不足 (402)，key 有效但需充值"
    if "%~1"=="429"   set "MP_MSG=请求过频 / 余额或配额耗尽 (429)，key 有效但限流"
    if "%~1"=="500"   set "MP_MSG=服务端内部错误 (500)，非 key 问题"
    if "%~1"=="503"   set "MP_MSG=服务暂不可用 (503)，稍后重试"
    if "%~1"=="000"   set "MP_MSG=连接失败 / 超时（网络或 base_url 不可达）"
    if defined MP_MSG goto :MAP_HAVE
    echo [RESULT] HTTP %~1   (status not in table; see raw body above.)
    exit /b 0
    :MAP_HAVE
    echo [RESULT] !MP_MSG!
    exit /b 0

:needkey
    echo [x] Missing arg2 (API Key).
    goto :help

:needmodel
    echo [x] Missing arg3 (model name).
    goto :help

:fail
    echo.
    echo [x] No valid base_url, aborted.
    exit /b 1

:help
    echo.
    echo ModelPing - API Key tester  (by 周伯通)
    echo.
    echo Usage:  ModelPing  arg1  arg2  arg3
    echo   arg1  vendor name (smart index, see table below; if not found,
    echo         it probes base_url via the Zhipu glm-flash free model)
    echo   arg2  the API key to test
    echo   arg3  model name (e.g. deepseek-chat / glm-4-flash)
    echo.
    echo Zhipu probe key (checked on every run):
    echo   Stored in sidecar ModelPing.zkey (script folder if writable,
    echo   else %%LOCALAPPDATA%%\ModelPing).
    echo   First run asks whether to configure it; answer Y/yes to enter
    echo   the key, it is verified against glm-4-flash, saved, and the
    echo   script auto-restarts with your arguments.
    echo.
    echo Built-in vendors (arg1 supports Chinese/English aliases):
    echo   zhipu/glm/智谱              https://open.bigmodel.cn/api/paas/v4
    echo   deepseek/深度求索            https://api.deepseek.com/v1
    echo   qwen/千问/通义/阿里/百炼     https://dashscope.aliyuncs.com/compatible-mode/v1
    echo   ark/字节/火山/豆包/doubao    https://ark.cn-beijing.volces.com/api/v3
    echo   kimi/moonshot/月之暗面       https://api.moonshot.cn/v1
    echo   minimax/海螺               https://api.minimaxi.com/v1
    echo   stepfun/阶跃星辰/step       https://api.stepfun.com/v1
    echo   openai/chatgpt            https://api.openai.com/v1
    echo   anthropic/claude (ref)     https://api.anthropic.com/v1  (NOT OpenAI-compatible)
    echo   gemini/google             https://generativelanguage.googleapis.com/v1beta/openai
    echo   grok/xai                  https://api.x.ai/v1
    echo   siliconflow/硅基流动  baichuan/百川  qianfan/千帆  hunyuan/腾讯/混元
    echo   yi / groq / together / mistral
    echo.
    echo Example:
    echo   ModelPing deepseek sk-xxxxxxxx deepseek-chat
    echo   ModelPing zhipu   YOUR_KEY   glm-4-flash
    echo   ModelPing kimi    YOUR_KEY   moonshot-v1-8k
    echo.
    pause
    exit /b 0