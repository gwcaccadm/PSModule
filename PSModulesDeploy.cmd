xcopy "PSModules.ps1" "C:\ProgramData\AutoPilotConfig" /Y
xcopy "pswritepdf.0.0.19.nupkg" "C:\ProgramData\AutoPilotConfig" /Y
Powershell.exe -Executionpolicy bypass -File "C:\ProgramData\AutoPilotConfig\PSModules.ps1"