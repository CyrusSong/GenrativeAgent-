# Generative Agents 一键启动脚本
# 用法：双击同目录下的 start-simulation.bat
# 顺序：前端(Django:8000) → 嵌入服务(8765) → 后端(reverie.py，本窗口)

$ErrorActionPreference = 'Stop'

$gaRepo      = 'E:\游戏Agent学习\Generative_Agent\generative_agents-main'
$gaPython    = Join-Path $gaRepo '.venv\Scripts\python.exe'
$embedPython = Join-Path $gaRepo '.venv-embed\Scripts\python.exe'
$maxCalls    = '2000'   # 每个后端进程的 DeepSeek 付费调用上限，按需调整
# 本机系统 PATH 缺失 System32，显式补全并使用 PowerShell 绝对路径
$env:PATH    = "C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0;$env:PATH"
$psExe       = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'

function Test-Listening([int]$port) {
    return [bool](Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
}

function Wait-Port([int]$port, [int]$seconds, [string]$name) {
    for ($i = 0; $i -lt $seconds; $i++) {
        if (Test-Listening $port) { return }
        Start-Sleep -Seconds 1
    }
    throw "$name 在 $seconds 秒内没有启动成功（端口 $port 无监听），请查看对应窗口的报错。"
}

function Wait-EmbedReady([int]$seconds) {
    for ($i = 0; $i -lt $seconds; $i++) {
        try {
            $r = Invoke-RestMethod -Uri 'http://127.0.0.1:8765/health' -TimeoutSec 2
            if ($r.status -eq 'ready') { return }
        } catch { }
        Start-Sleep -Seconds 2
    }
    throw "嵌入服务在 $($seconds * 2) 秒内没有就绪，请查看嵌入服务窗口的报错。"
}

Write-Host '===== Generative Agents 启动器 =====' -ForegroundColor Cyan

# ---------- 1/3 前端 ----------
if (Test-Listening 8000) {
    Write-Host '[1/3] 前端已在 8000 端口运行，跳过。' -ForegroundColor Yellow
} else {
    Write-Host '[1/3] 正在新窗口启动前端（Django，127.0.0.1:8000）...' -ForegroundColor Green
    $feCmd = "`$host.ui.RawUI.WindowTitle='GA 前端 Django'; Set-Location -LiteralPath '$gaRepo\environment\frontend_server'; & '$gaPython' manage.py runserver 127.0.0.1:8000"
    Start-Process $psExe -ArgumentList '-NoExit','-Command',$feCmd
    Wait-Port 8000 30 '前端'
    Write-Host '      前端已就绪。' -ForegroundColor Green
}

# ---------- 2/3 嵌入服务 ----------
if (Test-Listening 8765) {
    Write-Host '[2/3] 嵌入服务已在 8765 端口运行，跳过。' -ForegroundColor Yellow
} else {
    Write-Host '[2/3] 正在新窗口启动嵌入服务（127.0.0.1:8765）...' -ForegroundColor Green
    $emCmd = "`$host.ui.RawUI.WindowTitle='GA 嵌入服务'; Set-Location -LiteralPath '$gaRepo'; & '$embedPython' '.\reverie\backend_server\embedding_server.py'"
    Start-Process $psExe -ArgumentList '-NoExit','-Command',$emCmd
    Wait-Port 8765 120 '嵌入服务'
}
Write-Host '      等待嵌入服务就绪...'
Wait-EmbedReady 60
Write-Host '      嵌入服务已就绪。' -ForegroundColor Green

# ---------- 3/3 后端（本窗口，需要交互输入模拟名称） ----------
Write-Host '[3/3] 在本窗口启动后端 reverie.py' -ForegroundColor Green
$env:GA_LLM_PROVIDER      = 'deepseek'
$env:GA_DEEPSEEK_MODEL    = 'deepseek-flash'
$env:GA_MAX_DEEPSEEK_CALLS = $maxCalls
$env:PYTHONUTF8           = '1'
Write-Host "      调用上限 GA_MAX_DEEPSEEK_CALLS = $maxCalls"

$secure = Read-Host '请输入 DeepSeek API key（输入不显示）' -AsSecureString
$env:DEEPSEEK_API_KEY = [System.Net.NetworkCredential]::new('', $secure).Password

Set-Location -LiteralPath (Join-Path $gaRepo 'reverie\backend_server')

Write-Host ''
Write-Host '后端即将启动。提示：' -ForegroundColor Cyan
Write-Host '  1) 分叉名称填已有存档（如 base_the_ville_isabella_maria_klaus 或你上次的存档名）'
Write-Host '  2) 新名称必须是一个不存在的新名字'
Write-Host '  3) 出现 Enter option: 后，浏览器打开 http://127.0.0.1:8000/simulator_home 并保持页面开着'
Write-Host '  4) 先输入 run 1 验证，再逐步加大步数；save 保存进度'
Write-Host '  5) 用 fin 保存并结束（千万别用 exit，exit 会删除本次模拟目录）'
Write-Host ''

& $gaPython reverie.py

Write-Host ''
Write-Host '后端已退出。前端和嵌入服务窗口仍在运行，不用时可手动关闭。' -ForegroundColor Cyan
