$envPath = "backend\.env"
$content = Get-Content $envPath
$newContent = @()
foreach ($line in $content) {
    if ($line -match "^DATABASE_URL=") {
        $newContent += "DATABASE_URL=postgresql://postgres:MedicalAppPassword1234@db.hqkcuxwxdsybtxqgnydx.supabase.co:5432/postgres"
    } elseif ($line -match "^SUPABASE_URL=" -or $line -match "^SUPABASE_KEY=") {
        # Skip existing
    } else {
        $newContent += $line
    }
}
$newContent += "SUPABASE_URL=https://hqkcuxwxdsybtxqgnydx.supabase.co"
$newContent += "SUPABASE_KEY=sb_publishable_efbQ-0WZV8kPB-Jb8aOHpg_S61Al-Iw"
$newContent | Set-Content $envPath
Write-Host "Updated .env successfully"
