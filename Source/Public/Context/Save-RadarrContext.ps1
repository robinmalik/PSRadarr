function Save-RadarrContext
{
	<#
		.SYNOPSIS
			Saves a named context describing how to connect to a Radarr instance.

		.DESCRIPTION
			A context is a named set of connection settings for one Radarr instance. Multiple contexts can be
			saved but only one is active at a time, and the active context is used for all subsequent commands.

			Because a context is identified by its name rather than by its server, several instances on the
			same host can be saved alongside each other, e.g. two instances on different ports.

		.PARAMETER Name
			A unique name for this context, e.g. 'radarr', 'radarr4k', 'home-1080p'. The name is used as a
			file name, so it may only contain letters, numbers, dots, hyphens and underscores.

		.PARAMETER Description
			An optional description for this context.

		.PARAMETER Server
			The URL or hostname of the Radarr server, e.g. 'myserver.domain.com'.

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

		.PARAMETER Persist
			When $true (default), the context is saved to disk and will be available in future sessions.
			When $false, the context is stored in memory for the current session only and no files are
			written to disk.

		.EXAMPLE
			Save-RadarrContext -Name 'radarr' -Server 'myserver.domain.com' -Port 20001 -APIKey 'abc123' -RootFolderPath '/storage/Movies'

		.EXAMPLE
			Save-RadarrContext -Name 'radarr4k' -Server 'myserver.domain.com' -Port 20002 -APIKey 'xyz789' -RootFolderPath '/storage/Movies4K'

		.EXAMPLE
			# In-memory only; nothing written to disk:
			Save-RadarrContext -Name 'ci' -Server 'radarr' -APIKey $env:RADARR_API_KEY -RootFolderPath '/storage/Movies' -Persist $false

		.NOTES
			The API key is stored in plain text so that contexts remain portable between machines and
			containers. Anyone able to read $HOME/.PSRadarr/Contexts can read the key.
	#>

	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[ValidatePattern('^[a-zA-Z0-9._-]+$')]
		[String]$Name,

		[Parameter(Mandatory = $false)]
		[String]$Description = '',

		[Parameter(Mandatory = $true)]
		[ValidatePattern('^[a-zA-Z0-9.-]+$')]
		[String]$Server,

		[Parameter(Mandatory = $false)]
		[Int]$Port = 7878,

		[Parameter(Mandatory = $false)]
		[ValidateSet('http', 'https')]
		[String]$Protocol = 'http',

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]$APIKey,

		[Parameter(Mandatory = $false)]
		[Int]$APIVersion = 3,

		[Parameter(Mandatory = $true)]
		[String]$RootFolderPath,

		[Parameter(Mandatory = $false)]
		[Bool]$Persist = $true
	)

	$ContextDirectory = Get-ContextDirectory

	$Context = [Ordered]@{
		Name           = $Name
		Description    = $Description
		Server         = $Server
		Port           = $Port
		Protocol       = $Protocol
		APIVersion     = $APIVersion
		APIKey         = $APIKey
		RootFolderPath = $RootFolderPath
	}

	####################################################################################################
	#Region In-memory only: store the full context object directly in the session variable
	if(-not $Persist)
	{
		$script:ActiveContext = [PSCustomObject]$Context
		Write-Verbose -Message "Function: $($MyInvocation.MyCommand): Context '$Name' activated in-memory for this session only. No files written to disk."
		return
	}
	#EndRegion


	####################################################################################################
	#Region Write the context to disk
	if(-not (Test-Path $ContextDirectory))
	{
		New-Item -ItemType Directory -Path $ContextDirectory -Force -ErrorAction Stop | Out-Null
	}

	$ContextFile = Join-Path $ContextDirectory "$Name.json"

	if(Test-Path $ContextFile)
	{
		if(-not $PSCmdlet.ShouldProcess("context '$Name'", 'Overwrite existing context'))
		{
			return
		}
	}

	try
	{
		ConvertTo-Json -InputObject $Context -Depth 5 -ErrorAction Stop | Set-Content -Path $ContextFile -Force -ErrorAction Stop
	}
	catch
	{
		throw $_
	}
	#EndRegion


	####################################################################################################
	#Region Auto-activate if this is the first context
	$ActiveFile = Join-Path $ContextDirectory 'active'
	if(-not (Test-Path $ActiveFile))
	{
		$Name | Set-Content -Path $ActiveFile -NoNewline
		Write-Verbose -Message "Function: $($MyInvocation.MyCommand): Context '$Name' saved and set as active."
	}
	else
	{
		Write-Verbose -Message "Function: $($MyInvocation.MyCommand): Context '$Name' saved."
	}
	#EndRegion
}
