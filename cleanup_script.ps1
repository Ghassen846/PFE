# Delete all unnecessary backup and temporary files
$filesToDelete = @(
    "c:\Users\PC\developement\flutter-apps\first_app_new\lib\services\auth_service.dart.bak",
    "c:\Users\PC\developement\flutter-apps\first_app_new\lib\services\api_service.dart.bak",
    "c:\Users\PC\developement\flutter-apps\first_app_new\lib\l10n\intl_en.arb.bak",
    "c:\Users\PC\developement\flutter-apps\first_app_new\lib\services\auth_service.dart.backup",
    "c:\Users\PC\developement\flutter-apps\first_app_new\lib\services\api_service.dart.backup",
    "c:\Users\PC\developement\flutter-apps\fix_guide.md",
    "c:\Users\PC\developement\flutter-apps\dashboard_fixes_summary.md",
    "c:\Users\PC\developement\flutter-apps\connection_troubleshooting_guide.md"
)

foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        Write-Host "Deleting $file"
        Remove-Item -Path $file -Force
    } else {
        Write-Host "$file not found"
    }
}

Write-Host "Cleanup completed!"
