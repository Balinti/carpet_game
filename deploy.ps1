# Carpet Game Deployment Script
# Run this in PowerShell from the carpet_game folder

Write-Host "=== Step 1: Clean and get dependencies ===" -ForegroundColor Cyan
flutter clean
flutter pub get

Write-Host "`n=== Step 2: Run Flutter analyze to find errors ===" -ForegroundColor Cyan
flutter analyze

Write-Host "`n=== Step 3: Build for web (verbose) ===" -ForegroundColor Cyan
flutter build web --base-href /carpet_game/ --release 2>&1 | Tee-Object -Variable buildOutput

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n!!! BUILD FAILED - See error above !!!" -ForegroundColor Red
    Write-Host "Fix the error and run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== Step 4: Deploy to GitHub Pages ===" -ForegroundColor Cyan

# Save current branch
$currentBranch = git rev-parse --abbrev-ref HEAD

# Create temp directory
$tempDir = "deploy_temp_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy build files
Copy-Item -Path "build/web/*" -Destination $tempDir -Recurse

# Switch to gh-pages
git checkout gh-pages 2>$null
if ($LASTEXITCODE -ne 0) {
    git checkout --orphan gh-pages
    git rm -rf .
}

# Clear old files except .git
Get-ChildItem -Exclude ".git",$tempDir | Remove-Item -Recurse -Force

# Move new files
Copy-Item -Path "$tempDir/*" -Destination "." -Recurse
Remove-Item -Path $tempDir -Recurse -Force

# Commit and push
git add -A
git commit -m "Deploy $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git push -u origin gh-pages --force

# Return to original branch
git checkout $currentBranch

Write-Host "`n=== DONE! ===" -ForegroundColor Green
Write-Host "Wait 1-2 minutes then visit: https://balinti.github.io/carpet_game/" -ForegroundColor Cyan
