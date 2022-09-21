:checkFolder

if not exist "C:\ProgramData\AutoPilotConfig\PDFMerge" (
    mkdir "C:\ProgramData\AutoPilotConfig\PDFMerge"
    set /a CheckFolderResult = 1
)

if %*CheckFolderResult*% EQU 0 goto checkFolder

xcopy "PSModules.ps1" "C:\ProgramData\AutoPilotConfig" /Y
xcopy "pswritepdf.0.0.19.nupkg" "C:\ProgramData\AutoPilotConfig" /Y
Powershell.exe -Executionpolicy bypass -File "C:\ProgramData\AutoPilotConfig\PSModules.ps1"