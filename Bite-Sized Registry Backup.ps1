# Bite-Sized Registry Backup
# Copyright (C) 2025    maverickronin

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
####################################################################################################
#Configuration
####################################################################################################
#Temp directory for files and folders with trailing slash
$TempDir = $env:TEMP + "\Bite-Sized Registry Backup-$(([GUID]::NewGuid()).guid)\"
#Path to 7-Zip Executable
$7Path = "C:\Program Files\7-Zip\7z.exe"
#Path to store compressed registry backups with trailing slash
$BackupTarget = "B:\Registry\"
#Use daily and monthly retention limits below or make no monthlies and keep all dailys forever
$Retention = $true
#Number of daily backups to keep
$DailyLimit = 31
#Number of monthly backups to keep
$MonthlyLimit = 36
#Pause at end of script to keep window up for review
$Pause = $true
#Show progress bars.  Slows script a bit
$ShowProgress = $true
####################################################################################################
$Host.UI.RawUI.WindowTitle = "Bite-Sized Registry Backup"
$ErrorActionPreference = 'Stop'
####################################################################################################
#Registry keys to back up
####################################################################################################
#Parent registry keys to back up, making each subkey its own individual .reg file
[System.Collections.ArrayList]$ParentKeys = @(
"HKCU:\SOFTWARE"
"HKCU:\SOFTWARE\Classes"
"HKCU:\SOFTWARE\Classes\CLSID"
"HKCU:\SOFTWARE\Classes\Local Settings"
"HKCU:\SOFTWARE\Classes\WOW6432Node"
"HKCU:\SOFTWARE\Classes\WOW6432Node\CLSID"
"HKCU:\SOFTWARE\Clients"
"HKCU:\SOFTWARE\GNU"
"HKCU:\SOFTWARE\Microsoft"
"HKCU:\SOFTWARE\Microsoft\Windows"
"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion"
"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
"HKCU:\SOFTWARE\Microsoft\Windows NT"
"HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
"HKCU:\SOFTWARE\WOW6432Node"
"HKLM:\SOFTWARE"
"HKLM:\SOFTWARE\Classes"
"HKLM:\SOFTWARE\Classes\AppID"
"HKLM:\SOFTWARE\Classes\CLSID"
"HKLM:\SOFTWARE\Classes\Installer"
"HKLM:\SOFTWARE\Classes\Installer\Products"
"HKLM:\SOFTWARE\Classes\Interface"
"HKLM:\SOFTWARE\Classes\Record"
"HKLM:\SOFTWARE\Classes\Record\SystemFileAssociations"
"HKLM:\SOFTWARE\Classes\Record\TypeLib"
"HKLM:\SOFTWARE\Classes\WOW6432Node"
"HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID"
"HKLM:\SOFTWARE\Classes\WOW6432Node\Interface"
"HKLM:\SOFTWARE\Clients"
"HKLM:\SOFTWARE\GNU"
"HKLM:\SOFTWARE\Microsoft"
"HKLM:\SOFTWARE\Microsoft\Windows"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer"
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
"HKLM:\SOFTWARE\Microsoft\Windows NT"
"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
"HKLM:\SOFTWARE\WOW6432Node"
"HKLM:\SOFTWARE\WOW6432Node\Classes"
"HKLM:\SOFTWARE\WOW6432Node\Classes\CLSID"
"HKLM:\SOFTWARE\WOW6432Node\Classes\Interface"
"HKLM:\SOFTWARE\WOW6432Node\Clients"
"HKLM:\SOFTWARE\WOW6432Node\Microsoft"
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows"
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion"
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer"
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Setup"
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT"
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion"
"HKLM:\SYSTEM"
"HKLM:\SYSTEM\ControlSet001"
"HKLM:\SYSTEM\ControlSet001\Control"
"HKLM:\SYSTEM\ControlSet001\Control\Class"
"HKLM:\SYSTEM\ControlSet001\Control\DeviceClasses"
"HKLM:\SYSTEM\ControlSet001\Enum"
"HKLM:\SYSTEM\ControlSet001\Services"
"HKLM:\SYSTEM\CurrentControlSet"
"HKLM:\SYSTEM\CurrentControlSet\Control"
"HKLM:\SYSTEM\CurrentControlSet\Control\Class"
"HKLM:\SYSTEM\CurrentControlSet\Control\DeviceClasses"
"HKLM:\SYSTEM\CurrentControlSet\Enum"
"HKLM:\SYSTEM\CurrentControlSet\Services"
"HKLM:\SYSTEM\DriverDatabase"
"HKLM:\SYSTEM\DriverDatabase\DeviceIds"
"HKLM:\SYSTEM\DriverDatabase\DriverInfFiles"
"HKLM:\SYSTEM\DriverDatabase\DriverPackages"
)

#Delete temp path if it already exists
if (test-path $TempDir){ Remove-Item $TempDir -Recurse -Force }

#Loop through registry keys and export reg files to a folder structure
$CloneKeys = $ParentKeys.Clone()
$i = 0
foreach ($ParentKey in $ParentKeys) {
    if ($ShowProgress) {
        Write-Progress -Activity "Parent Key" -Status "$ParentKey" -PercentComplete (($i/($ParentKeys.Count)) * 100) -id 0
    }
    $Root = gci $ParentKey -ErrorAction 'SilentlyContinue' #some subkeys may not exist
    $CloneKeys.Remove($ParentKey)
    $j = 0
    foreach ($key in $Root) {
        if ($ShowProgress) {
            if ($j -eq 0 -or $j % 100 -eq 0) {
                Write-Progress -Activity "Subkey" -Status "$key" -PercentComplete (($j/($Root.Count)) * 100) -ParentId 0 -id 1
            }
        }
        #Even if you query with HKCU:\ or HKLM:\ you get the long version back so replace it
        #with short and add colon
        $RegPath = ($key.Name).Replace("HKEY_LOCAL_MACHINE","HKLM:")
        $RegPath = ($RegPath).Replace("HKEY_CURRENT_USER","HKCU:")
        if ($RegPath  -notin $CloneKeys) {
            #Clean up into valid file and folder names, build subfolder directory/file path
            $RegPath = ($RegPath).Replace(":","")
            $Subfolder = $RegPath.Substring(0,4)
            $Subfolder = $Subfolder + ($ParentKey.Replace("HKLM:","")).Replace("HKCU:","") + "\"
            $FileName = $RegPath.Replace($Subfolder,"")
            if (-not (Test-Path ($TempDir + $Subfolder))) {mkdir ($TempDir + $Subfolder.Trim("\")) | Out-null}
            #Build argument string
            $a = "export " + "`"" + $RegPath + "`"" + " " + "`"" + $TempDir + $Subfolder + $FileName + ".reg`""
            #This will spawn many instances of reg.exe which will export different keys in parallel
            Start-Process reg -ArgumentList $a -WindowStyle Hidden
        }
        $j++
    }
    $i++
}

#Wait until all export processes have finished
while ((Get-Process).ProcessName -contains "reg") {
    Start-Sleep -s 5
}

#Compress with 7-Zip
$Date = Get-Date -Format "yyyy/MM/dd"
Pushd ($TempDir)
$a = "a " + $Date + ".7z " + " -t7z -mx9 -m0=LZMA -md3840m -mfb273 -mmt=off -sdel"
start-process $7Path -ArgumentList $a -Wait

#Create backup destination directories if needed
if (-not(Test-Path $BackupTarget)) {New-Item -Path $BackupTarget -ItemType Directory}
if (-not(Test-Path "$BackupTarget\Monthlies")) {New-Item -Path "$BackupTarget\Monthlies" -ItemType Directory}

#Move out of temp
Move-Item ($Date + ".7z") $BackupTarget -Force

if ($Retention) {
    #Make an extra copy at month end
    if (([DateTime]::DaysInMonth((Get-Date).Year, (get-date).Month)) -eq (get-date).Day) {
        copy ("$BackupTarget\$Date" + ".7z ") "$BackupTarget\Monthlies"
    }
    #"Catch up" if backup was missed on last day of month
    $MonthlyArchives = gci "$BackupTarget\Monthlies" -Filter "*.7z"
    if ($MonthlyArchives.Count -eq 0 -or ($MonthlyArchives[-1].LastWriteTime) -lt (Get-Date -hour 0 -minute 0 -second 0).AddMonths(-1)) {
        copy ("$BackupTarget\$Date" + ".7z ") "$BackupTarget\Monthlies"
    }
    #Delete daily backups older than limit
    $DailyArchives = gci $BackupTarget -Filter "*.7z"
    while ($DailyArchives.count -gt $DailyLimit) {
        Remove-Item $DailyArchives[0].FullName -Force
        $DailyArchives = $DailyArchives[1..$DailyArchives.count]
    }
    #Delete monthly backups older than limit
    while ($MonthlyArchives.count -gt $MonthlyLimit) {
        Remove-Item $MonthlyArchives[0].FullName -Force
        $MonthlyArchives = $MonthlyArchives[1..$MonthlyArchives.count]
    }
}
if ($pause -eq $true) {Pause}