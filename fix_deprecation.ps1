Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $c = Get-Content $_.FullName -Raw
    $n = $c -replace '\.withOpacity\(([^)]+)\)', '.withValues(alpha: $1)'
    if ($c -ne $n) {
        Set-Content -Path $_.FullName -Value $n -NoNewline
        Write-Host "Fixed $($_.Name)"
    }
}
