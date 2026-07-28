function Get-RadarrContext
{
	<#
		.SYNOPSIS
			Lists all contexts from disk and in memory, indicating which one is currently active.

		.DESCRIPTION
			Displays all named contexts saved in $HOME/.PSRadarr/Contexts plus any in-memory context. The
			currently active context is marked with an asterisk (*). API keys are not included in the output
			unless -IncludeAPIKey is specified.

		.PARAMETER IncludeAPIKey
			If specified, the API key is included in the output.

		.EXAMPLE
			Get-RadarrContext

		.EXAMPLE
			Get-RadarrContext | Where-Object { $_.IsActive }

		.OUTPUTS
			PSCustomObject with properties:
				- IsActive: Indicates if the context is currently active.
				- IsEphemeral: Indicates if the context exists in memory only (not persisted to disk).
				- Name: The name of the context.
				- Description: The description of the context.
				- Server, Port, Protocol, APIVersion, RootFolderPath: The connection settings.
	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false)]
		[Switch]$IncludeAPIKey
	)

	$ContextDirectory = Get-ContextDirectory

	# A configuration from before contexts existed still needs to be listed:
	Convert-LegacyConfiguration

	if(-not (Test-Path $ContextDirectory) -and $script:ActiveContext -isnot [PSCustomObject])
	{
		return
	}

	$ContextFiles = Get-ChildItem -Path $ContextDirectory -Filter '*.json' -ErrorAction SilentlyContinue
	if(-not $ContextFiles -and $script:ActiveContext -isnot [PSCustomObject])
	{
		return
	}

	####################################################################################################
	#Region Work out what is active
	# Check for an in-memory context (Save-RadarrContext -Persist $false)
	$EphemeralContext = $null
	if($script:ActiveContext -is [PSCustomObject])
	{
		$EphemeralContext = $script:ActiveContext
	}

	# Determine the active name for disk contexts: string override first, then the persisted file.
	# If an ephemeral context is active, no disk context is marked active.
	$ActiveName = $null
	if(-not $EphemeralContext)
	{
		$ActiveName = $script:ActiveContext
		if(-not $ActiveName)
		{
			$ActiveFile = Join-Path $ContextDirectory 'active'
			if(Test-Path $ActiveFile)
			{
				$ActiveName = (Get-Content $ActiveFile -Raw).Trim()
			}
		}
	}
	#EndRegion


	####################################################################################################
	#Region Emit the disk contexts, then any in-memory context
	foreach($File in $ContextFiles)
	{
		try
		{
			$Context = Get-Content -Path $File.FullName -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
		}
		catch
		{
			Write-Warning -Message "Skipping '$($File.FullName)': the file could not be read as a context. $_"
			continue
		}

		$Output = [Ordered]@{
			IsActive       = ($File.BaseName -eq $ActiveName)
			IsEphemeral    = $false
			Name           = $File.BaseName
			Description    = $Context.Description
			Server         = $Context.Server
			Port           = $Context.Port
			Protocol       = $Context.Protocol
			APIVersion     = $Context.APIVersion
			RootFolderPath = $Context.RootFolderPath
		}
		if($IncludeAPIKey)
		{
			$Output['APIKey'] = $Context.APIKey
		}

		$Output = [PSCustomObject]$Output
		$Output.PSObject.TypeNames.Insert(0, 'PSRadarr.Context')
		$Output
	}

	if($EphemeralContext)
	{
		$Output = [Ordered]@{
			IsActive       = $true
			IsEphemeral    = $true
			Name           = $EphemeralContext.Name
			Description    = $EphemeralContext.Description
			Server         = $EphemeralContext.Server
			Port           = $EphemeralContext.Port
			Protocol       = $EphemeralContext.Protocol
			APIVersion     = $EphemeralContext.APIVersion
			RootFolderPath = $EphemeralContext.RootFolderPath
		}
		if($IncludeAPIKey)
		{
			$Output['APIKey'] = $EphemeralContext.APIKey
		}

		$Output = [PSCustomObject]$Output
		$Output.PSObject.TypeNames.Insert(0, 'PSRadarr.Context')
		$Output
	}
	#EndRegion
}
