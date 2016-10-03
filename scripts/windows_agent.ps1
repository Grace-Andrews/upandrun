# install_agent.ps1 : This powershell script installs the puppet-agent package from a Puppet Enterprise master
# This version is specifically for the TSE Demo envoronment and includes logic to wait to install the agent
# until the master  is available.
#
# You could call this script like this:
# install.ps1 main:certname=foo custom_attributes:challengePassword=SECRET extension_requests:pp_role=webserver
[CmdletBinding()]

$server          = "master.vm"
$port            = '8140'
$puppet_bin_dir  = Join-Path ([Environment]::GetFolderPath('ProgramFiles')) 'Puppet Labs\Puppet\bin'
$puppet_conf_dir = Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'Puppetlabs\puppet\etc'
$date_time_stamp = (Get-Date -format s) -replace ':', '-'
$install_log     = Join-Path ([System.IO.Path]::GetTempPath()) "$date_time_stamp-puppet-install.log"

# Start with assumption of 64 bit agent package unless probe detects 32 bit.
$arch       = 'x64'
$msi_path   = 'windows-x86_64'
if ((Get-WmiObject Win32_OperatingSystem).OSArchitecture -match '^32') {
  $arch     = 'x86'
  $msi_path = 'windows-i386'
}
$msi_source    = "https://${server}:$port/packages/current/$msi_path/puppet-agent-$arch.msi"
$msi_dest      = Join-Path ([System.IO.Path]::GetTempPath()) "puppet-agent-$arch.msi"
$class_arch    = $msi_path -replace '-', '_'
$pe_repo_class = "pe_repo::platform::$class_arch"
$agent_certname = "windows.vm"

function CustomPuppetConfiguration {
  # Parse optional pre-installation configuration of Puppet settings via
  # command-line arguments. Arguments should be of the form
  #
  #   <section>:<setting>=<value>
  #
  # There are four valid section settings in puppet.conf: "main", "master",
  # "agent", "user". If you provide valid setting and value for one of these
  # four sections, it will end up in <confdir>/puppet.conf.
  #
  # There are two sections in csr_attributes.yaml: "custom_attributes" and
  # "extension_requests". If you provide valid setting and value for one
  # of these two sections, it will end up in <confdir>/csr_attributes.yaml.
  #
  # note:Custom Attributes are only present in the CSR, while Extension
  # Requests are both in the CSR and included as X509 extensions in the
  # signed certificate (and are thus available as "trusted facts" in Puppet).
  #
  # Regex is authoritative for valid sections, settings, and values.  Any input
  # that fails regex will trigger this script to fail with error message.
  $regex = '^(main|master|agent|user|custom_attributes|extension_requests):(.*)=(.*)$'
  $attr_array = @()
  $extn_array = @()
  $match = $null

  foreach ($entry in $arguments) {
    if (! ($match = [regex]::Match($entry,$regex)).Success) {
      Throw "Unable to interpret argument: '$entry'. Expected '<section>:<setting>=<value>' matching regex: '$regex'"
    }
    else {
      $section=$match.groups[1].captures.value
      $setting=$match.groups[2].captures.value
      $value=$match.groups[3].captures.value
      switch ($section) {
        'custom_attributes' {
          # Store the entry in attr_array for later addition to csr_attributes.yaml
          $attr_array += "${setting}: '${value}'"
          break
        }
        'extension_requests' {
          # Store the entry in extn_array for later addition to csr_attributes.yaml
          $extn_array += "${setting}: '${value}'"
          break
        }
        default {
          # Set the specified entry in puppet.conf
          & $puppet_bin_dir\puppet config set $setting $value --section $section
          break
        }
      }
    }
  }
  # If the the length of the attr_array or extn_array is greater than zero, it
  # means we have settings, so we'll create the csr_attributes.yaml file.
  if ($attr_array.length -gt 0 -or $extn_array.length -gt 0) {
    echo('---') | out-file -filepath $puppet_conf_dir\csr_attributes.yaml -encoding UTF8

    if ($attr_array.length -gt 0) {
      echo('custom_attributes:') | out-file -filepath $puppet_conf_dir\csr_attributes.yaml -append -encoding UTF8
      for ($i = 0; $i -lt $attr_array.length; $i++) {
        echo('  ' + $attr_array[$i]) | out-file -filepath $puppet_conf_dir\csr_attributes.yaml -append -encoding UTF8
      }
    }

    if ($extn_array.length -gt 0) {
      echo('extension_requests:') | out-file -filepath $puppet_conf_dir\csr_attributes.yaml -append -encoding UTF8
      for ($i = 0; $i -lt $extn_array.length; $i++) {
        echo('  ' + $extn_array[$i]) | out-file -filepath $puppet_conf_dir\csr_attributes.yaml -append -encoding UTF8
      }
    }
  }
}

function DownloadPuppet {
  Write-Verbose "Downloading the Puppet Agent for Puppet Enterprise on $env:COMPUTERNAME..."
  [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
  $webclient = New-Object system.net.webclient
  try {
    $webclient.DownloadFile($msi_source,$msi_dest)
  }
  catch [Net.WebException] {
    Write-Error "Failed to download the Puppet Agent installer: $msi_source"
    Write-Error "$_"
    Write-Error "Does the Puppet Master have the $pe_repo_class class applied to it?"
    Throw {}
  }
}

function InstallPuppet {
  Write-Verbose "Installing the Puppet Agent on $env:COMPUTERNAME..."
  Write-Verbose "Saving the install log to $install_log"
  $msiexec_args = "/qn /log $install_log /i $msi_dest PUPPET_MASTER_SERVER=$server PUPPET_AGENT_STARTUP_MODE=Manual PUPPET_AGENT_CERTNAME=$agent_certname"
  $msiexec_proc = [System.Diagnostics.Process]::Start('msiexec', $msiexec_args)
  $msiexec_proc.WaitForExit()
  if (@(0, 1641, 3010) -NotContains $msiexec_proc.ExitCode) {
  Throw "Something went wrong with the installation on $env:COMPUTERNAME. Exit code: " + $msiexec_proc.ExitCode + ". Check the install log at $install_log"
  }
  $certname = & $puppet_bin_dir\puppet config print certname
  & $puppet_bin_dir\puppet config set certname $certname --section main
}

function StartPuppetService {
  & $puppet_bin_dir\puppet resource service puppet ensure=running enable=true
}

function MakeMasterHostsEntry {
  $host_entry = "192.168.50.4 $server"
  $host_entry | Out-File -FilePath C:\Windows\System32\Drivers\etc\hosts -Append -Encoding ascii
}

MakeMasterHostsEntry
DownloadPuppet
InstallPuppet
CustomPuppetConfiguration
StartPuppetService
Write-Verbose "Installation has completed."
