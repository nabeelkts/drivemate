Param(
    [string]$TaskName = 'MDS_Firestore_Supabase_DailyBackup',
    [string]$WorkingDir = 'd:\mds\mds\tools\backup',
    [string]$RunTime = '01:00'
)

try {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
} catch {
}

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -Command ""Set-Location '$WorkingDir'; node index.js"""
$trigger = New-ScheduledTaskTrigger -Daily -At (Get-Date $RunTime)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description 'Daily backup of Firestore to Supabase Storage'
