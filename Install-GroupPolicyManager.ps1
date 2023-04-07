# MIT License

# Copyright (c) 2023- Antti J. Oja <a.oja@outlook.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# Get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = [System.Security.Principal.WindowsPrincipal]::new($myWindowsID)

# Get the security principal for the administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

# Check to see if we are currently running as an administrator
if ($myWindowsPrincipal.IsInRole($adminRole))
{
    # We are running as an administrator, so change the title and background colour to indicate this
    $host.UI.RawUI.WindowTitle = $MyInvocation.MyCommand.Name + "(Elevated)"
    $host.UI.RawUI.BackgroundColor = "DarkBlue"

    Clear-Host
}
else
{
    # We are not running as an administrator, so relaunch as administrator
    Start-Process pwsh.exe -Verb RunAs -ArgumentList $MyInvocation.MyCommand.Name

    # Exit from the current, unelevated, process
    Exit
}

# Set up the message labels
$message = "IMPORTANT"
$question = "Would you like a system restore point generated before proceeding?"

# Set up the choice for generating a System Restore point before continuing
$choices = [System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]]@()
$choices.Add((New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList "&Yes", "Generates a system restore point before proceeding."))
$choices.Add((New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList "&No", "Proceeds without generating a system restore point."))

# Present the choice
$decision = $host.UI.PromptForChoice($message, $question, $choices, 0)

if ($decision -eq 0)
{
    # The user selected 'yes'

    # Generate the restore point with the selected tags
    Checkpoint-Computer -Description "Install Group Policy Manager" -RestorePointType ApplicationInstall
}

# Install the Group Policy Management Console
Get-ChildItem -Path "${env:SystemRoot}\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~*.mum" | ForEach-Object { DISM /Online /NoRestart /Add-Package:"$($_.FullName)" }
Get-ChildItem -Path "${env:SystemRoot}\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~*.mum" | ForEach-Object { DISM /Online /NoRestart /Add-Package:"$($_.FullName)" }

# Write the instructionary closing message
Write-Host

# Wait for any key to be pressed at the end so the shell won't just vanish
Pause
Exit