$BackupPath = "C:\Backups"
$RegistryBackupPath = "$BackupPath\RegistryBackup.reg"
$SystemFilesBackupPath = "$BackupPath\SystemFiles.zip"
 
if (!(Test-Path -Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force
}
 
reg export HKLM\SYSTEM $RegistryBackupPath /y
 
$SystemFiles = @(
    "C:\Windows\System32\config\BCD",
    "C:\Windows\System32\config\SAM",
    "C:\Windows\System32\config\SYSTEM"
)
Compress-Archive -Path $SystemFiles -DestinationPath $SystemFilesBackupPath -Force
 
$LogFile = "$PSScriptRoot\BackupLog.txt"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $LogFile -Value "[$Timestamp] Backup executed successfully."
