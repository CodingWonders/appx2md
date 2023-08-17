Import-Module Appx

function AppxListingToMarkdown() 
{
    $winbld = $cmdargs[0]
    $mntDir = $cmdargs[2]
    if ($mntDir -eq "online") { $mntdir = [IO.Path]::GetPathRoot([Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)) }
    if ($winbld -eq "auto")
    {
        if ($cmdargs[2] -eq "online")
        {
            $winbld = [Environment]::OSVersion.Version.Build
        }
        else
        {
            $winbld = (Get-Command "$($mntDir)\Windows\system32\ntoskrnl.exe").Version.Build
        }        
    }
    if ([IO.File]::Exists("$([String]::Join('\', $cmdargs[1], $winbld)).md"))
    {
        Remove-Item "$([String]::Join('\', $cmdargs[1], $winbld)).md"
    }
    Write-Output "# AppX package listing for Windows build $($winbld)"`n`n'| Package Name | Display Name | Publisher ID | Version | Resource ID | Architecture | Installation Location |'`n'|:--:|:--:|:--:|:--:|:--:|:--:|:--|' | Out-File -Encoding utf8 "$([String]::Join('\', $cmdargs[1], $winbld)).md"
    if ($cmdargs[2] -eq "online")
    {
        $appxPkg = Get-AppxProvisionedPackage -Online
    }
    else
    {
        $appxPkg = Get-AppxProvisionedPackage -Path $mntDir
    }
    for ($i = 0; $i -lt $appxPkg.Count; $i++)
    {
         Write-Output "| $($appxPkg[$i].PackageName) | $($appxPkg[$i].DisplayName) | $($appxPkg[$i].PublisherId) | $($appxPkg[$i].Version) | $($appxPkg[$i].ResourceId) | $($appxPkg[$i].Architecture.ToString().Replace('11', 'x64').Trim().Replace('9', 'Neutral').Trim().Replace('0', 'x86').Trim()) | $($appxPkg[$i].InstallLocation.Replace('%SYSTEMDRIVE%', $mntDir).Trim()) |" | Out-File -Append -Encoding utf8 "$([String]::Join('\', $cmdargs[1], $winbld)).md"
    }
    if ($cmdargs[2] -eq "online")
    {
        $option = Read-Host -Prompt "Do you want to get information of non-provisioned AppX packages (Y/N)?"
        switch ($option)
        {
            "Y" {
                $nonProvAppxPkg = Get-AppxPackage
                $matches = $appxPkg | Where-Object { $_.DisplayName -in $nonProvappxPkg.Name }
                $exclusions = $nonProvAppxPkg | Where-Object { $_.Name -in $matches.DisplayName }
                for ($i = 0; $i -lt $nonProvAppxPkg.Count; $i++)
                {
                    if ($exclusions.Contains($nonProvAppxPkg[$i]) -eq $false)
                    {
                        Write-Output "| $($nonProvappxPkg[$i].PackageFamilyName) | $($nonProvappxPkg[$i].Name) | $($nonProvappxPkg[$i].PublisherId) | $($nonProvappxPkg[$i].Version) | $($nonProvappxPkg[$i].ResourceId) | $($nonProvappxPkg[$i].Architecture) | $($nonProvappxPkg[$i].InstallLocation) |" | Out-File -Append -Encoding utf8 "$([String]::Join('\', $cmdargs[1], $winbld)).md"
                    }
                }
            }
            default {
                Write-Host "Skipping non-provisioned AppX packages..."
            }
        }
    }
    Write-Output `n"_Generated using **appx2md**, version 1.0, on $([DateTime]::Now)_" | Out-File -Encoding utf8 -Append "$([String]::Join('\', $cmdargs[1], $winbld)).md"
    if ($cmdargs[0] -eq "auto")
    {
        Write-Output `n`n"**NOTE: appx2md** has guessed the build number because _auto_ has been passed as an argument. If an incorrect guess has been made, please report an issue on the [GitHub repo](https://github.com/CodingWonders/appx2md)" | Out-File -Encoding utf8 -Append "$([String]::Join('\', $cmdargs[1], $winbld)).md"
    }
}

function Main($cmdargs)
{
    if ($cmdargs.Count -eq 3)
    {
        AppxListingToMarkdown
    }
    else
    {
        Write-Host 'appx2md - Version 1.0'`n'Script that gets installed AppX packages and puts them in a Markdown file.'`n`n'USAGE:'`n`n'        appx2md.ps1 [winbuild] [output] [mountdir]'`n`n`n'    [winbuild]        The Windows build number that identifies the output Markdown file. You can either specify the build number, or use'`n'                      "auto" to let the program determine the build number.'`n`n'    [output]          The location of the Markdown file. Please specify a full path.'`n`n'    [mountdir]        The mount directory to get the AppX packages from. You can either specify a full path to the mount directory, or use'`n'                      "online" to get the packages from an online installation.'`n
        Write-Host 'EXAMPLES:'`n`n'        appx2md.ps1 19045 C:\docs online'`n`n'        appx2md.ps1 auto C:\docs C:\WIP_Canary\mount'`n
    }
}

Main($args)