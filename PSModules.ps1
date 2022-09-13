
###--->


# receive result of last command
function CheckLastCommand {
    
    # force params to be mandatory
    Param(
        # must be a boolean
        [parameter(Mandatory=$true)] [bool] $commandResult,
        # must be a string
        [parameter(Mandatory=$true)] [string] $issueName
    )

    # if the last command was not run sucessfully, run this block
    # for debug, remove the exclaimation mark ("!$commandResult") from the below line
    if (!$commandResult) {
        # play a notification sound
        Write-Host "`a"
        # wait to give notification sound time to play
        Start-Sleep -Seconds 1
        Write-Host "There may an issue with $issueName" -ForegroundColor Yellow -BackgroundColor Red -NoNewline
        Write-Host "`n"
        Write-Host "Please contact IT Support" -ForegroundColor Yellow -BackgroundColor Red -NoNewline
        Write-Host "`n"
        Write-Host "Press any key to exit" -ForegroundColor Yellow -BackgroundColor Red -NoNewline
        Write-Host "`n"
        # accept any key, including modifiers, as they are pressed ("NoEcho,IncludeKeyDown") without displaying it
        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        exit
    }
}


###--->


# checks to ensure that onedrive is running
$oneDriveProcesses = Get-CimInstance Win32_Process -Filter "name = 'onedrive.exe'"
CheckLastCommand -commandResult $? -issueName "OneDrive process(es)"

# debug line
#$oneDriveProcesses

# loop through all runnning onedrive processes
foreach ($oneDriveProcess in $oneDriveProcesses) {

    # declare hashtable for single user's onedrive process details
    $currOneDriveSession = @{}
    
    # grab username and titlecase it
    $userName = (Invoke-CimMethod -InputObject $oneDriveProcess -MethodName GetOwner | Where-Object -Property User -eq $env:USERNAME).User -Replace '\.(.)',' $1'
    $userDisplayName = (Get-Culture).TextInfo.ToTitleCase($userName)
    
    # generate matrix
    $currOneDriveSession["UserDisplayName"] = $userDisplayName
    CheckLastCommand -commandResult $? -issueName "OneDrive process(es)"
    $currOneDriveSession["OneDrivePID"] = $oneDriveProcess.ProcessId
    CheckLastCommand -commandResult $? -issueName "OneDrive process(es)"
    $currOneDriveSession["Responding"] = (Get-Process -Id $oneDriveProcess.ProcessId).Responding
    CheckLastCommand -commandResult $? -issueName "OneDrive process(es)"
    
    # future functionality for multiple users on InTune/AVD
    #$currOneDriveSession[$userDisplayName] = @{}
    #$currOneDriveSession["UserName"]["OneDrivePID"] = $currOneDriveSession["OneDrivePID"] = $oneDriveProcess.ProcessId
    #$currOneDriveSession["UserName"]["Responding"] = $currOneDriveSession["Responding"] = (Get-Process -Id $oneDriveProcess.ProcessId).Responding
}


###--->


# checks to ensure that the user has a powershell modules path on onedrive
$userPSModulesPath = (($env:PSModulePath).Split(";") | Where-Object{$_.StartsWith($HOME) -and $_.Contains("OneDrive") -and $_.EndsWith("\Modules")})
# check result '$?' of last command and print error if false
CheckLastCommand -commandResult $? -issueName "geting the OneDrive modules paths"

# generate list of downloaded module files (*.nupkg)
$moduleFiles = @((Get-ChildItem -Path $PSScriptRoot -Filter *.nupkg).BaseName)
CheckLastCommand -commandResult $? -issueName "NUPKG module files"


foreach ($moduleFile in $moduleFiles) {
    
    # split module filename into module name and version
    ($moduleName,$moduleVesrion) = $moduleFile.Split(".",2)

    # generate zip filename for copy of module
    $zipFileName = Get-ChildItem -Path "$PSScriptRoot" -Include "$moduleFile.zip"

    # check to ensure zip file is present, if not, then copy
    if (!(Test-Path -Path "$PSScriptRoot\$moduleFile.zip")) {
        Copy-Item -Path "$PSScriptRoot\$moduleFile.nupkg" -Destination "$PSScriptRoot\$moduleFile.zip"
        CheckLastCommand -commandResult $? -issueName "copying nupkg file to zip file"
    }
    
    # check to ensure the temp module path is present, if not, then create
    if (!(Test-Path -Path "$PSScriptRoot\$moduleName\")) {
        New-Item -Path "$PSScriptRoot\$moduleName" -ItemType Directory | Out-Null
        CheckLastCommand -commandResult $? -issueName "creating module folder"
    }
    if (!(Test-Path -Path "$PSScriptRoot\$moduleName\$moduleVesrion\")) {
        New-Item -Path "$PSScriptRoot\$moduleName\$moduleVesrion" -ItemType Directory | Out-Null
        CheckLastCommand -commandResult $? -issueName "creating module version folder"
    }
    if (Test-Path -Path "$PSScriptRoot\$moduleName\$moduleVesrion\") {
        Expand-Archive -Path "$PSScriptRoot\$moduleFile.zip" -DestinationPath "$PSScriptRoot\$moduleName\$moduleVesrion" -Force | Out-Null
        CheckLastCommand -commandResult $? -issueName "extracting files from zip file"
    }

    # check to ensure the user's module path is present, if not, then create
    if (!(Test-Path -Path "$userPSModulesPath\$moduleName\")) {
        New-Item -Path "$userPSModulesPath\$moduleName" -ItemType Directory | Out-Null
        CheckLastCommand -commandResult $? -issueName "creating module folder"
    }
    if (!(Test-Path -Path "$userPSModulesPath\$moduleName\$moduleVesrion\")) {
        New-Item -Path "$userPSModulesPath\$moduleName\$moduleVesrion" -ItemType Directory | Out-Null
        CheckLastCommand -commandResult $? -issueName "creating module version folder"
    }
    
    <# declaire folders hash table

    data mtrix structure will by a hashtable of arrays:
    
    $extractedFolders[pathDepth](object1,object2,object3)
    
    #>

    $extractedFolders = @{}
    
    #$pathDepth = ("$PSScriptRoot\$moduleName\$moduleVesrion").Split('\\').Count
    #$pathDepth = ("$userPSModulesPath\$moduleName\$moduleVesrion").Split('\\').Count

    # get a list of all files extracted to the temp module path
    $extractedFiles = Get-ChildItem -Path "$PSScriptRoot\$moduleName\$moduleVesrion" -Recurse
    foreach ($extractedFileObj in $extractedFiles) {

        # generate base filename from object
        $extractedFile = $extractedFileObj.FullName
        $destinationFile = ($extractedFile).Replace($PSScriptRoot,$userPSModulesPath)

        # check user's module path for extracted files
        if (!(Test-Path -Path $destinationFile)) {

            # copy extracted file from temp module path to user's module path
            Copy-Item -Path $extractedFile -Destination $destinationFile
            CheckLastCommand -commandResult $? -issueName "copying extracted file"
        }

        # confirm extracted files are in user's module path before deleting from temp module path
        if (Test-Path -Path $destinationFile) {

            # test for file (leaf)
            If (Test-Path -Path $extractedFile -PathType Leaf) {

                # delete extracted file (not folder) from temp module path to user's module path
                Remove-Item -Path $extractedFile -Force
                CheckLastCommand -commandResult $? -issueName "deleting extracted file"

            # test for folder (container)
            } elseif (Test-Path -Path $extractedFile -PathType Container) {

                # generate the depth of each path by counting slashes
                $pathDepth = $extractedFile.Split('\\').Count
                CheckLastCommand -commandResult $? -issueName "generating path depth"

                # confirm if matrix has pathdepth key
                if (!($extractedFolders.ContainsKey($pathDepth))) {
                    $extractedFolders[$pathDepth] = @()
                    CheckLastCommand -commandResult $? -issueName "gerating extracted folder matrix key"
                }

                # add folder to matrix
                $extractedFolders[$pathDepth] += $extractedFile
                CheckLastCommand -commandResult $? -issueName "adding folder to matrix"
            }
        }
    }

    # grab and sort by the of the extractedfolders matrix in reverse order
    foreach ($pathDepth in ($extractedFolders.Keys | Sort-Object -Descending)) {

        # each hashtable item is an array of folder names
        foreach ($folders in $extractedFolders[$pathDepth]) {

            # grab each folder
            foreach($folder in $folders){
                
                # need to user get-item so that each folder is an object and run the delete method
                # onedrive wont allow you to delete using remove-item on folders
                $folderObj = Get-Item -Path $folder

                # require a boolean to be passed into it when method is used in a script
                $folderObj.Delete($true)
            }
        }
    }

    # delete the module name and module version temp folders
    $folderObj = Get-Item -Path "$PSScriptRoot\$moduleName\$moduleVesrion\"
    $folderObj.Delete($true)
    $folderObj = Get-Item -Path "$PSScriptRoot\$moduleName\"
    $folderObj.Delete($true)

    # delete the copied zip file
    Remove-Item -Path "$PSScriptRoot\$moduleFile.zip" -Force

    # import the module for use
    Import-Module $moduleName
    CheckLastCommand -commandResult $? -issueName "importing module(s)"
    
}

