function Set-RadarrConfiguration
{
	<#
		.SYNOPSIS
			Sets the configuration for connecting to a Radarr server instance.

		.DESCRIPTION
			Saves Radarr server connection settings including server address, port, API key, and API version to a JSON configuration file.
			The configuration is stored in the user's home directory under .PSRadarr/PSRadarrConfig.json.

		.PARAMETER Server
			The URL or hostname of the Radarr server (e.g. 'myserver.domain.com')

		.PARAMETER Port
			The port number that Radarr is listening on. Defaults to 7878.

		.PARAMETER Protocol
			The protocol to use for connecting to the Radarr server. Defaults to 'http'.

		.PARAMETER APIKey
			The API key from your Radarr instance. Can be found in Radarr under Settings > General.

		.PARAMETER APIVersion
			The version of the Radarr API to use. Defaults to 3.

		.PARAMETER RootFolderPath
			The root folder path where movies are stored.

		.PARAMETER Default
			If set to true, marks this server configuration as the default instance for PSRadarr commands. Defaults to true.

		.EXAMPLE
			Set-RadarrConfiguration -Server 'myserver.domain.com' -APIKey 'myapikey' -RootFolderPath 'D:\Movies'

		.NOTES
			File: Set-RadarrConfiguration.ps1
			The configuration file will be created at $HOME/.PSRadarr/PSRadarrConfig.json
	#>

	param (
		[Parameter(Mandatory = $true)]
		[string]$Server,

		[Parameter(Mandatory = $false)]
		[int]$Port = 7878,

		[Parameter(Mandatory = $false)]
		[string]$Protocol = "http",

		[Parameter(Mandatory = $true)]
		[string]$APIKey,

		[Parameter(Mandatory = $false)]
		[Int]$APIVersion = "3",

		[Parameter(Mandatory = $true)]
		[string]$RootFolderPath,

		[Parameter(Mandatory = $false)]
		[bool]$Default = $true
	)

	#############################################################################
	#Region Ensure required paths exist and load existing configuration
	$ConfigDir = Join-Path $HOME ".PSRadarr"
	if(-not (Test-Path -Path $ConfigDir -PathType Container))
	{
		try
		{
			New-Item -Path $ConfigDir -ItemType Directory -ErrorAction Stop | Out-Null
		}
		catch
		{
			throw $_
		}
	}

	# Path to the configuration file
	$ConfigPath = Join-Path $ConfigDir "PSRadarrConfig.json"

	# If the file exists, load existing data
	if(Test-Path -Path $ConfigPath -PathType Leaf)
	{
		[Array]$ConfigData = Get-Content -Path $ConfigPath | ConvertFrom-Json
	}
	else
	{
		$ConfigData = @()
	}
	#EndRegion

	####################################################################################################
	# Construct an object with the data we want to save
	$ServerObject = [Ordered]@{
		"Server"         = $Server
		"Port"           = $Port
		"Protocol"       = $Protocol
		"APIKey"         = $APIKey
		"APIVersion"     = $APIVersion
		"RootFolderPath" = $RootFolderPath
		"Default"        = $Default
	}

	# Check if a server with the same Server and Port exists
	$ExistingServer = $ConfigData | Where-Object { $_.Server -eq $Server -and $_.Port -eq $Port }

	####################################################################################################
	# If the server exists, update its configuration
	if($ExistingServer)
	{
		Write-Verbose -Message "Updating existing server configuration"
		foreach($Entry in $ConfigData)
		{
			if($Entry.Server -eq $Server -and $Entry.Port -eq $Port)
			{
				$Entry.Server = $Server
				$Entry.Port = $Port
				$Entry.Protocol = $Protocol
				$Entry.APIKey = $APIKey
				$Entry.APIVersion = $APIVersion
				$Entry.RootFolderPath = $RootFolderPath
				$Entry.Default = $Default
			}
			else
			{
				$Entry.Default = $false
			}
		}
	}
	else
	{
		# Add the new server configuration
		Write-Verbose -Message "Adding new server configuration"
		$ConfigData += $ServerObject
	}

	####################################################################################################
	#Region Convert to JSON and save to file
	Write-Verbose -Message "Saving configuration to: $ConfigPath"
	try
	{
		$ConfigData | ConvertTo-Json -ErrorAction Stop | Set-Content -Path $ConfigPath -Force -ErrorAction Stop
	}
	catch
	{
		throw $_
	}
	Write-Verbose -Message "Configuration saved successfully to: $ConfigPath"
}

