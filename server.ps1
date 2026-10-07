param(
    [int]$Port = 3000,
    [switch]$NoBrowser
)

$Folder = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   XS Prospeccao Clone - Servidor Local" -ForegroundColor Green
    Write-Host "   Acesse: $prefix" -ForegroundColor Yellow
    Write-Host "   Pressione Ctrl+C para encerrar." -ForegroundColor Gray
    Write-Host "==========================================" -ForegroundColor Cyan
    
    if (-not $NoBrowser) {
        Start-Process $prefix
    }

    $mimeMap = @{
        ".html" = "text/html; charset=utf-8"
        ".htm"  = "text/html; charset=utf-8"
        ".css"  = "text/css; charset=utf-8"
        ".js"   = "application/javascript; charset=utf-8"
        ".mjs"  = "application/javascript; charset=utf-8"
        ".json" = "application/json; charset=utf-8"
        ".png"  = "image/png"
        ".jpg"  = "image/jpeg"
        ".jpeg" = "image/jpeg"
        ".svg"  = "image/svg+xml"
        ".woff2" = "font/woff2"
        ".webmanifest" = "application/manifest+json"
    }

    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response

            $urlPath = $request.Url.LocalPath.TrimStart('/')
            if ([string]::IsNullOrWhiteSpace($urlPath)) {
                $urlPath = "index.html"
            }

            $localFile = [System.IO.Path]::Combine($Folder, $urlPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar))

            # SPA fallback: se nao for arquivo estatico existente, serve index.html
            if (-not (Test-Path -Path $localFile -PathType Leaf)) {
                if (-not ($urlPath.StartsWith("assets/") -or $urlPath.StartsWith("icons/"))) {
                    $localFile = [System.IO.Path]::Combine($Folder, "index.html")
                }
            }

            if (Test-Path -Path $localFile -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($localFile).ToLower()
                $contentType = if ($mimeMap.ContainsKey($ext)) { $mimeMap[$ext] } else { "application/octet-stream" }
                $response.ContentType = $contentType
                $response.Headers.Add("Access-Control-Allow-Origin", "*")

                $bytes = [System.IO.File]::ReadAllBytes($localFile)
                $response.ContentLength64 = $bytes.Length

                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                }
            } else {
                $response.StatusCode = 404
                $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
                $response.ContentLength64 = $notFound.Length
                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($notFound, 0, $notFound.Length)
                }
            }

            $response.OutputStream.Close()
        } catch {
            # Continue running on transient client disconnects
        }
    }
} finally {
    $listener.Stop()
}
