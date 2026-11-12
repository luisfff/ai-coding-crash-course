$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$port = 8787

function Test-ProxyReady {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $result = $client.BeginConnect('127.0.0.1', $port, $null, $null)
        if (-not $result.AsyncWaitHandle.WaitOne(250)) {
            return $false
        }

        $client.EndConnect($result)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

if (-not (Test-ProxyReady)) {
    $escapedRoot = $repoRoot.Replace("'", "''")
    Start-Process powershell.exe -ArgumentList @(
        '-NoExit',
        '-Command',
        "Set-Location -LiteralPath '$escapedRoot'; npm run request-logger"
    ) -WorkingDirectory $repoRoot

    $deadline = (Get-Date).AddSeconds(30)
    while (-not (Test-ProxyReady) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 250
    }

    if (-not (Test-ProxyReady)) {
        throw "The request logger did not start listening on port $port within 30 seconds. Check its terminal for errors."
    }
}

$env:ANTHROPIC_BASE_URL = 'http://localhost:8787'
$env:ENABLE_TOOL_SEARCH = 'true'

claude @args
exit $LASTEXITCODE
