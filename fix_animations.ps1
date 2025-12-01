# PowerShell script to remove animation_wrappers imports and usages
$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # Remove animation_wrappers imports
    $content = $content -replace "import 'package:animation_wrappers/[^']+';`r?`n", ""
    $content = $content -replace "// import 'package:animation_wrappers/[^']+';`r?`n", ""
    
    # Remove FadedSlideAnimation wrapper (keep child)
    $content = $content -replace "FadedSlideAnimation\([^{]*\{[^}]*\},?\s*child:\s*", ""
    
    # Remove FadedScaleAnimation wrapper (keep child)
    $content = $content -replace "FadedScaleAnimation\([^{]*\{[^}]*\},?\s*child:\s*", ""
    
    # Remove simple FadedSlideAnimation/FadedScaleAnimation calls
    $content = $content -replace "FadedSlideAnimation\(\s*child:\s*", ""
    $content = $content -replace "FadedScaleAnimation\(\s*child:\s*", ""
    
    Set-Content $file.FullName $content
}

Write-Host "Animation wrappers removed from all Dart files"