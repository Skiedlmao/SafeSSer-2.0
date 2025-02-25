if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
{
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $script = $PSCommandPath
    if (-not $script) { $script = $MyInvocation.MyCommand.Path }
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
    $psi.Verb = "runas"
    try { 
        [System.Diagnostics.Process]::Start($psi) | Out-Null 
        exit
    }
    catch { 
        Write-Error "Script requires administrator privileges."
        exit
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(650, 500)
$form.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 40)
$form.Icon = [System.Drawing.SystemIcons]::Shield

$titleBar = New-Object System.Windows.Forms.Panel
$titleBar.Size = New-Object System.Drawing.Size(650, 50)
$titleBar.Location = New-Object System.Drawing.Point(0, 0)
$titleBar.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 60)
$form.Controls.Add($titleBar)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Service Manager"
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
$titleLabel.TextAlign = 'MiddleLeft'
$titleLabel.Size = New-Object System.Drawing.Size(550, 50)
$titleLabel.Location = New-Object System.Drawing.Point(15, 0)
$titleBar.Controls.Add($titleLabel)

$statusIndicator = New-Object System.Windows.Forms.Label
$statusIndicator.Text = "Ready"
$statusIndicator.ForeColor = [System.Drawing.Color]::LightGreen
$statusIndicator.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
$statusIndicator.TextAlign = 'MiddleRight'
$statusIndicator.Size = New-Object System.Drawing.Size(120, 50)
$statusIndicator.Location = New-Object System.Drawing.Point(430, 0)
$titleBar.Controls.Add($statusIndicator)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "X"
$closeButton.ForeColor = [System.Drawing.Color]::White
$closeButton.BackColor = [System.Drawing.Color]::FromArgb(180, 50, 50)
$closeButton.FlatStyle = 'Flat'
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.Size = New-Object System.Drawing.Size(50, 50)
$closeButton.Location = New-Object System.Drawing.Point(600, 0)
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$titleBar.Controls.Add($closeButton)
$closeButton.Add_Click({ $form.Close() })

$drag = $false
$startPoint = New-Object System.Drawing.Point
$titleBar.Add_MouseDown({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:drag = $true
        $script:startPoint = $e.Location
    }
})
$titleBar.Add_MouseMove({
    param($sender, $e)
    if ($script:drag) {
        $current = $form.Location
        $form.Location = New-Object System.Drawing.Point($current.X + $e.X - $script:startPoint.X, $current.Y + $e.Y - $script:startPoint.Y)
    }
})
$titleBar.Add_MouseUp({ $script:drag = $false })

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start All Services"
$startButton.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Regular)
$startButton.Size = New-Object System.Drawing.Size(200, 45)
$startButton.Location = New-Object System.Drawing.Point(20, 70)
$startButton.FlatStyle = 'Flat'
$startButton.BackColor = [System.Drawing.Color]::FromArgb(80, 130, 80)
$startButton.ForeColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$form.Controls.Add($startButton)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "Refresh Status"
$refreshButton.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Regular)
$refreshButton.Size = New-Object System.Drawing.Size(200, 45)
$refreshButton.Location = New-Object System.Drawing.Point(240, 70)
$refreshButton.FlatStyle = 'Flat'
$refreshButton.BackColor = [System.Drawing.Color]::FromArgb(70, 100, 150)
$refreshButton.ForeColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$form.Controls.Add($refreshButton)

$autoStartCheckbox = New-Object System.Windows.Forms.CheckBox
$autoStartCheckbox.Text = "Auto-start on load"
$autoStartCheckbox.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Regular)
$autoStartCheckbox.Size = New-Object System.Drawing.Size(200, 30)
$autoStartCheckbox.Location = New-Object System.Drawing.Point(460, 77)
$autoStartCheckbox.ForeColor = [System.Drawing.Color]::White
$autoStartCheckbox.Checked = $true
$form.Controls.Add($autoStartCheckbox)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Disabled Services:"
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$statusLabel.Size = New-Object System.Drawing.Size(200, 30)
$statusLabel.Location = New-Object System.Drawing.Point(20, 130)
$form.Controls.Add($statusLabel)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ReadOnly = $true
$outputBox.ScrollBars = 'Vertical'
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Regular)
$outputBox.Size = New-Object System.Drawing.Size(610, 320)
$outputBox.Location = New-Object System.Drawing.Point(20, 160)
$outputBox.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 30)
$outputBox.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$form.Controls.Add($outputBox)

$services = @(
    "SysMain", 
    "CDPUserSvc", 
    "PcaSvc", 
    "DPS", 
    "EventLog", 
    "Schedule", 
    "WSearch", 
    "Dusmsvc", 
    "Appinfo",
    "DiagTrack",
    "WdiServiceHost",
    "WdiSystemHost"
)

function Get-DisabledServices {
    $disabledServices = @()
    
    foreach ($serviceName in $services) {
        try {
            if ($serviceName -like "*`**" -or $serviceName -like "*_*") {
                $matchingServices = Get-Service -Name "$serviceName*" -ErrorAction SilentlyContinue
                if ($matchingServices) {
                    foreach ($svc in $matchingServices) {
                        if ($svc.StartType -eq 'Disabled' -or $svc.Status -ne 'Running') {
                            $disabledServices += [PSCustomObject]@{
                                Name = $svc.Name
                                DisplayName = $svc.DisplayName
                                Status = $svc.Status
                                StartType = $svc.StartType
                            }
                        }
                    }
                }
            }
            else {
                $svc = Get-Service -Name $serviceName -ErrorAction Stop
                $wmiObj = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'" -ErrorAction SilentlyContinue
                $startType = "Unknown"
                if ($wmiObj) {
                    $startType = switch ($wmiObj.StartMode) {
                        "Auto" { "Automatic" }
                        "Manual" { "Manual" }
                        "Disabled" { "Disabled" }
                        default { $wmiObj.StartMode }
                    }
                }
                if ($startType -eq 'Disabled' -or $svc.Status -ne 'Running') {
                    $disabledServices += [PSCustomObject]@{
                        Name = $svc.Name
                        DisplayName = $svc.DisplayName
                        Status = $svc.Status
                        StartType = $startType
                    }
                }
            }
        }
        catch {
            $outputBox.AppendText("Warning: Could not find service '$serviceName'`r`n")
        }
    }
    
    return $disabledServices
}

function Start-RequiredServices {
    $outputBox.Clear()
    $statusIndicator.Text = "Working..."
    $statusIndicator.ForeColor = [System.Drawing.Color]::Yellow
    $form.Refresh()
    
    $disabledServices = Get-DisabledServices
    
    if ($disabledServices.Count -eq 0) {
        $outputBox.AppendText("All services are already running!`r`n")
        $statusIndicator.Text = "All Running"
        $statusIndicator.ForeColor = [System.Drawing.Color]::LightGreen
        return
    }
    
    $outputBox.AppendText("Starting necessary services...`r`n`r`n")
    
    foreach ($svc in $disabledServices) {
        try {
            $outputBox.AppendText("Processing $($svc.DisplayName) ($($svc.Name)):`r`n")
            
            if ($svc.StartType -eq 'Disabled') {
                $outputBox.AppendText("  - Changing startup type from Disabled to Automatic...`r`n")
                Set-Service -Name $svc.Name -StartupType Automatic -ErrorAction Stop
            }
            
            if ($svc.Status -ne 'Running') {
                $outputBox.AppendText("  - Starting service...`r`n")
                Start-Service -Name $svc.Name -ErrorAction Stop
                
                $timeout = 10
                $started = $false
                while ($timeout -gt 0 -and -not $started) {
                    $currentSvc = Get-Service -Name $svc.Name
                    if ($currentSvc.Status -eq 'Running') {
                        $started = $true
                    }
                    else {
                        Start-Sleep -Milliseconds 500
                        $timeout--
                    }
                }
                
                $currentSvc = Get-Service -Name $svc.Name
                if ($currentSvc.Status -eq 'Running') {
                    $outputBox.AppendText("  ✓ Service successfully started`r`n`r`n")
                }
                else {
                    $outputBox.AppendText("  ✗ Service failed to start in time`r`n`r`n")
                }
            }
        }
        catch {
            $outputBox.AppendText("  ✗ Error: $($_.Exception.Message)`r`n`r`n")
        }
    }
    
    $remainingDisabled = Get-DisabledServices
    
    if ($remainingDisabled.Count -eq 0) {
        $outputBox.AppendText("`r`nSuccess! All services are now running.`r`n")
        $statusIndicator.Text = "All Running"
        $statusIndicator.ForeColor = [System.Drawing.Color]::LightGreen
    }
    else {
        $outputBox.AppendText("`r`nWarning: Some services could not be started.`r`n")
        $statusIndicator.Text = "Issues Remain"
        $statusIndicator.ForeColor = [System.Drawing.Color]::Orange
    }
}

function Update-StatusDisplay {
    $outputBox.Clear()
    $statusIndicator.Text = "Checking..."
    $statusIndicator.ForeColor = [System.Drawing.Color]::Yellow
    $form.Refresh()
    
    $disabledServices = Get-DisabledServices
    
    if ($disabledServices.Count -eq 0) {
        $outputBox.AppendText("All monitored services are running properly.`r`n")
        $statusIndicator.Text = "All Running"
        $statusIndicator.ForeColor = [System.Drawing.Color]::LightGreen
    }
    else {
        $outputBox.AppendText("The following services need attention:`r`n`r`n")
        foreach ($svc in $disabledServices) {
            $outputBox.AppendText("$($svc.DisplayName) ($($svc.Name))`r`n")
            $outputBox.AppendText("  Status: $($svc.Status)`r`n")
            $outputBox.AppendText("  Startup Type: $($svc.StartType)`r`n`r`n")
        }
        $statusIndicator.Text = "Issues Found"
        $statusIndicator.ForeColor = [System.Drawing.Color]::Orange
    }
}

$startButton.Add_Click({ Start-RequiredServices })
$refreshButton.Add_Click({ Update-StatusDisplay })

Update-StatusDisplay

if ($autoStartCheckbox.Checked) {
    Start-RequiredServices
}

[void]$form.ShowDialog()
