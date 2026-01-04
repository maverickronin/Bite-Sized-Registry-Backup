# Bite-Sized Registry Backup

The Registry - The cause of, and solution to, all of your Windows problems.

## What it does

This script exports user accessible portions HKLM:\System, HKLM:\Software, and HKCU:\Software to a number of different .reg files stored in a directory structure copying the registry's nested key structure.  It is not fully recursive though and does not make individual .reg files for every single subkey.

I have set default breakpoints based on my own projected needs but the list of keys is easily modified to suit yours.  Switching from W10 to W11 absolutely destroyed the performance of this script so I changed the defaults to export the giant "classes" subkeys as single large files and added a rate limiter.

## How to use it

It's just a PowerShell script with a few variables at the top to change settings.  Run it on demand or make a scheduled task.

It can retain a fixed number of of daily and monthly backups

It may bog down slower computers or just take a while because it will spawn reg.exe instances in parallel without rate limiting.

## Settings

#### $ParentKeys
List of parent keys from which each subkey is exported as an individual .reg files.

Adding a child key to the list under a parent key will break out that child key into a subfolder with individual .reg files for each of it's subkeys.  This can be repeated with deeper and deeper subkeys as desired.

#### $TempDir
By default it's a randomly named directory in %temp%, but you can change it if you want.

#### $7Path
Path to 7zip's 7z.exe for compressing the exported .reg files

#### $BackupTarget
Folder to save the backups to.

#### $DailyLimit
Number of previous daily backups to keep.  Default is 31.

#### $MonthlyLimit
Number of previous monthly backups to keep.  Default is 36.

#### $Pause
Pause at the end of the script before exiting.  Default is true.

#### $ShowProgress
Show progress bars.  It updates somewhat infrequently as to only slows down things a bit instead of completely killing the performance.

#### $Parallelization

Limit to the number of concurrently running reg.exe instances.  You can increase this slowly until performance starts to decrease.