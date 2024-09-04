# Function to remove WSUS settings
function Remove-WSUSSettings {
    # Remove registry settings that point to an internal WSUS server
    $wsusRegKeys = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    )

    foreach ($key in $wsusRegKeys) {
        if (Test-Path $key) {
            Remove-Item -Path $key -Recurse -Force
            Write-Host "Removed WSUS registry key: $key"
        }
    }

    # Set Windows Update to pull from the internet
    Write-Host "Configuring Windows Update to pull from the internet..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoAutoUpdate" -Value 0 -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -Value 4 -Force
    Write-Host "Windows Update is now configured to pull from the internet."
}

# Function to install a module if it is not present
function Install-ModuleIfNotPresent {
    param (
        [string]$moduleName
    )
    
    try {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            Write-Host "$moduleName module not found. Installing..."
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
            Install-Module -Name $moduleName -Force -SkipPublisherCheck -ErrorAction Stop
            Write-Host "$moduleName module installed successfully."
        } else {
            Write-Host "$moduleName module is already installed."
        }
    } catch {
        Write-Host "Failed to install $moduleName module. Error: $_"
        exit 1
    }
}

# Remove WSUS settings
Remove-WSUSSettings

# Ensure the necessary modules are installed
Install-ModuleIfNotPresent -moduleName "PSWindowsUpdate"

# Import the PSWindowsUpdate module
try {
    Import-Module PSWindowsUpdate -ErrorAction Stop
    Write-Host "PSWindowsUpdate module imported successfully."
} catch {
    Write-Host "Failed to import PSWindowsUpdate module. Error: $_"
    exit 1
}

# Check for available updates
try {
    Write-Host "Checking for updates..."
    $updates = Get-WindowsUpdate -Verbose -ErrorAction Stop

    if ($null -eq $updates) {
        Write-Host "No updates object returned."
    } elseif ($updates.Count -eq 0) {
        Write-Host "No updates available."
    } else {
        Write-Host "Updates found. Downloading and installing updates..."

        # Install updates without auto-reboot
        Install-WindowsUpdate -AcceptAll -Verbose -IgnoreReboot -ErrorAction Stop

        Write-Host "Updates installed successfully. Please reboot your system manually if necessary."
    }
} catch {
    Write-Host "Failed to check for updates. Error: $_"
    exit 1
}

Pause
