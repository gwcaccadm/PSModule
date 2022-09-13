# PSModule

PowerShell Script deployed as WIN32 app via InTune that installs bundled PowerShell Modules to Users' OneDriveCommercial PSModule folder without elevated priv's.

PSModuleDeploy.cmd copies files to a local public folder before running the script:

  C:\ProgramData\AutoPilotConfig

Bundled PSModules are extracted into the following folder whilst maintaining the structure:

  C:\Users\User.Name\OneDrive - TenantName\WindowsPowerShell\Modules\ModuleName\ModuleVersion

The folders created are based on the bundled module filename:

  thisModule.1.3.2.5.nupkg creates folder structure ..\thisModule\1.3.2.5\..
