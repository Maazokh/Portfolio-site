param(
    [int]$Port = 8080,
    [string]$Directory = $PSScriptRoot
)

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".webp" = "image/webp"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
    ".ttf"  = "font/ttf"
}

$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    Write-Error "Failed to start listener on $prefix : $_"
    exit 1
}

Write-Host "HTTP server running at: $prefix"
Write-Host "Root directory: $Directory"
Write-Host "Press Ctrl+C to stop."

try {
    while ($listener.IsListening) {
        $context = $null
        try {
            $context = $listener.GetContext()
        } catch {
            break
        }

        try {
            $request = $context.Request
            $response = $context.Response

            $urlPath = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath)
            if ($urlPath -eq "/" -or [string]::IsNullOrWhiteSpace($urlPath)) {
                $urlPath = "/index.html"
            }

            # Normalize relative path and remove leading slash
            $relativePath = $urlPath.TrimStart('/') -replace '/', [System.IO.Path]::DirectorySeparatorChar
            $fullPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($Directory, $relativePath))

            # Security check: ensure path stays within root directory
            $normalizedRoot = [System.IO.Path]::GetFullPath($Directory)
            if (-not $fullPath.StartsWith($normalizedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                $response.StatusCode = 403
                $bytes = [System.Text.Encoding]::UTF8.GetBytes("403 Forbidden")
                $response.ContentType = "text/plain"
                $response.ContentLength64 = $bytes.Length
                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                }
                $response.OutputStream.Close()
                continue
            }

            if (Test-Path -Path $fullPath -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
                $contentType = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }

                $fileBytes = [System.IO.File]::ReadAllBytes($fullPath)
                $response.StatusCode = 200
                $response.ContentType = $contentType
                $response.ContentLength64 = $fileBytes.Length
                $response.AddHeader("Cache-Control", "no-cache, no-store, must-revalidate")
                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($fileBytes, 0, $fileBytes.Length)
                }
            } else {
                $response.StatusCode = 404
                $notFoundMsg = "404 Not Found: $urlPath"
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($notFoundMsg)
                $response.ContentType = "text/plain"
                $response.ContentLength64 = $bytes.Length
                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                }
            }

            $response.OutputStream.Close()
        } catch {
            try {
                if ($context -and $context.Response) {
                    $context.Response.StatusCode = 500
                    $context.Response.OutputStream.Close()
                }
            } catch {}
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
