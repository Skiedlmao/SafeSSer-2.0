if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
{
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $script = $PSCommandPath
    if (-not $script) { $script = $MyInvocation.MyCommand.Path }
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
    $psi.Verb = "runas"
    try { [System.Diagnostics.Process]::Start($psi) | Out-Null }
    catch { Write-Error "Script requires administrator privileges." }
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(600,400)
$form.BackColor = [System.Drawing.Color]::FromArgb(35,35,40)

$titleBar = New-Object System.Windows.Forms.Panel
$titleBar.Size = New-Object System.Drawing.Size(600,40)
$titleBar.Location = New-Object System.Drawing.Point(0,0)
$titleBar.BackColor = [System.Drawing.Color]::FromArgb(50,50,60)
$form.Controls.Add($titleBar)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Service Starter"
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(220,220,220)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI",22,[System.Drawing.FontStyle]::Bold)
$titleLabel.TextAlign = 'MiddleLeft'
$titleLabel.Size = New-Object System.Drawing.Size(550,40)
$titleLabel.Location = New-Object System.Drawing.Point(10,0)
$titleBar.Controls.Add($titleLabel)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "X"
$closeButton.ForeColor = [System.Drawing.Color]::White
$closeButton.BackColor = [System.Drawing.Color]::FromArgb(150,50,50)
$closeButton.FlatStyle = 'Flat'
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.Size = New-Object System.Drawing.Size(40,40)
$closeButton.Location = New-Object System.Drawing.Point(560,0)
$titleBar.Controls.Add($closeButton)
$closeButton.Add_Click({ $form.Close() })

$drag = $false
$startPoint = New-Object System.Drawing.Point
$titleBar.Add_MouseDown({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $drag = $true
        $startPoint = $e.Location
    }
})
$titleBar.Add_MouseMove({
    param($sender, $e)
    if ($drag) {
        $current = $form.Location
        $form.Location = New-Object System.Drawing.Point($current.X + $e.X - $startPoint.X, $current.Y + $e.Y - $startPoint.Y)
    }
})
$titleBar.Add_MouseUp({ $drag = $false })

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start Services"
$startButton.Font = New-Object System.Drawing.Font("Segoe UI",18,[System.Drawing.FontStyle]::Regular)
$startButton.Size = New-Object System.Drawing.Size(200,40)
$startButton.Location = New-Object System.Drawing.Point(20,60)
$startButton.FlatStyle = 'Flat'
$startButton.BackColor = [System.Drawing.Color]::FromArgb(70,70,75)
$startButton.ForeColor = [System.Drawing.Color]::FromArgb(240,240,240)
$form.Controls.Add($startButton)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ReadOnly = $true
$outputBox.ScrollBars = 'Vertical'
$outputBox.Font = New-Object System.Drawing.Font("Segoe UI",18,[System.Drawing.FontStyle]::Regular)
$outputBox.Size = New-Object System.Drawing.Size(560,260)
$outputBox.Location = New-Object System.Drawing.Point(20,120)
$outputBox.BackColor = [System.Drawing.Color]::FromArgb(40,40,45)
$outputBox.ForeColor = [System.Drawing.Color]::FromArgb(220,220,220)
$form.Controls.Add($outputBox)

$services = @("SysMain", "CDPUserSvc", "PcaSvc", "DPS", "EventLog", "Schedule", "WSearch", "Dusmsvc", "Appinfo")

$startButton.Add_Click({
    $outputBox.Clear()
    foreach ($service in $services) {
        try {
            $svc = Get-Service -Name $service -ErrorAction Stop
            if ($svc.Status -ne 'Running') {
                Start-Service -Name $service -ErrorAction Stop
                $timeout = 10
                do {
                    Start-Sleep -Seconds 1
                    $svc = Get-Service -Name $service
                    $timeout--
                } while ($svc.Status -eq 'StartPending' -and $timeout -gt 0)
                if ($svc.Status -eq 'Running') {
                    $outputBox.AppendText("Service $service started.`r`n")
                } else {
                    $outputBox.AppendText("Service $service not started or already running.`r`n")
                }
            } else {
                $outputBox.AppendText("Service $service not started or already running.`r`n")
            }
        } catch {
            $outputBox.AppendText("Error processing service $service.`r`n")
        }
    }
})

[System.Windows.Forms.Application]::Run($form)
