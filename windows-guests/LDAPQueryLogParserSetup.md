# LDAPQueryLogParser Setup

## Registry Setting

## Script deployment

- Script: `%PROGRAMFILES\AIT`
- Data: `%PROGRAMDATA%\AIT`
- Reg Key: `HKLM:\SOFTWARE\AIT\LDAPQueryLogParser\LastRun`
- `get-Date((get-itemproperty HKLM:\Software\ait\LDAPQueryLogParser\ -name LastRun).LastRun)`
- Edit ossec.conf according to ossec.conf from this repo

## Scheduled Task
```
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2024-09-02T20:34:35.4897897</Date>
    <Author>ENTERPRISE\Administrator</Author>
    <URI>\LDAPQueryLogParser</URI>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <Repetition>
        <Interval>PT15M</Interval>
        <Duration>P1D</Duration>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <StartBoundary>2024-09-02T12:00:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-nop -exec bypass -File "C:\Program Files\AIT\LDAPQueryLogParser.ps1"</Arguments>
      <WorkingDirectory>C:\ProgramData\AIT</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
```

## Setup Windows Log

https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.eventlog.createeventsource?view=net-8.0

```powershell
$source = "LDAPQueryLogParser"
if ([System.Diagnostics.EventLog]::SourceExists($source) -eq $false) {
    [System.Diagnostics.EventLog]::CreateEventSource($source, "Application")
}

function CreateParamEvent ($evtID, $param1, $param2, $param3)
  {
    $id = New-Object System.Diagnostics.EventInstance($evtID,1); #INFORMATION EVENT
    #$id = New-Object System.Diagnostics.EventInstance($evtID,1,2); #WARNING EVENT
    #$id = New-Object System.Diagnostics.EventInstance($evtID,1,1); #ERROR EVENT
    $evtObject = New-Object System.Diagnostics.EventLog;
    $evtObject.Log = $evtlog;
    $evtObject.Source = $source;
    $evtObject.WriteEvent($id, @($param1,$param2,$param3))
  }
```
