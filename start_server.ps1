$port = 8080
$path = $PWD.Path
$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:$port/")
$http.Start()

Write-Host "Server running at http://localhost:$port/"
Write-Host "Press Ctrl+C to stop the server."

while ($http.IsListening) {
    try {
        $context = $http.GetContextAsync()
        if (-not $context.Wait(100)) { continue } # Non-blocking check
        $ctx = $context.Result
        
        $urlPath = $ctx.Request.Url.LocalPath.TrimStart('/')
        if ($urlPath -eq "") { $urlPath = "index.html" }
        
        $filePath = Join-Path $path $urlPath
        
        if (Test-Path $filePath -PathType Leaf) {
            $content = [System.IO.File]::ReadAllBytes($filePath)
            $ctx.Response.ContentLength64 = $content.Length
            $ctx.Response.ContentType = "text/html" # Simple mime handling
            if ($filePath.EndsWith(".css")) { $ctx.Response.ContentType = "text/css" }
            if ($filePath.EndsWith(".js")) { $ctx.Response.ContentType = "application/javascript" }
            if ($filePath.EndsWith(".jpg")) { $ctx.Response.ContentType = "image/jpeg" }
            if ($filePath.EndsWith(".png")) { $ctx.Response.ContentType = "image/png" }
            
            $ctx.Response.OutputStream.Write($content, 0, $content.Length)
            $ctx.Response.StatusCode = 200
        } else {
            $ctx.Response.StatusCode = 404
        }
        $ctx.Response.Close()
    } catch {
        Write-Error $_
    }
}
