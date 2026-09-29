# Generative Agents 一键关闭脚本
# 用法：双击同目录下的 stop-simulation.bat
# 会停止后端 reverie.py、嵌入服务(8765)、前端(8000)，并关闭启动脚本拉起的窗口

$ErrorActionPreference = 'Continue'

Write-Host '===== Generative Agents 关闭器 =====' -ForegroundColor Cyan
Write-Host '注意：请先在后端窗口用 fin 保存并结束模拟，否则未保存的进度会丢失。' -ForegroundColor Yellow
$ans = Read-Host '确认后端已经保存并结束？(输入 y 继续)'
if ($ans -ne 'y' -and $ans -ne 'Y') {
    Write-Host '已取消，没有关闭任何服务。'
    exit
}

function Stop-ByPort([int]$port, [string]$name) {
    $pids = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty OwningProcess -Unique
    if ($pids) {
        foreach ($p in $pids) { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue }
        Write-Host "$name（端口 $port）已停止。" -ForegroundColor Green
    } else {
        Write-Host "$name（端口 $port）没有在运行，跳过。" -ForegroundColor Yellow
    }
}

# 1. 后端 reverie.py（可能还挂在主窗口里运行）
$backend = Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
           Where-Object { $_.CommandLine -match 'reverie\.py' }
if ($backend) {
    $backend | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Write-Host '后端 reverie.py 已停止。' -ForegroundColor Green
} else {
    Write-Host '后端 reverie.py 没有在运行，跳过。' -ForegroundColor Yellow
}

# 2. 嵌入服务和前端
Stop-ByPort 8765 '嵌入服务'
Stop-ByPort 8000 '前端'

# 3. 关闭启动脚本拉起的窗口（窗口标题以 GA 开头的 PowerShell 窗口）
$wins = Get-Process powershell -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -like 'GA *' }
if ($wins) {
    $wins | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host '前端 / 嵌入服务窗口已关闭。' -ForegroundColor Green
}

Write-Host ''
Write-Host '全部处理完成。' -ForegroundColor Cyan
