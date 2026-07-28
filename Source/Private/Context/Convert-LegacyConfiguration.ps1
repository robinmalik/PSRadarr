function Convert-LegacyConfiguration
{
	<#
		.SYNOPSIS
			Migrates the legacy PSRadarrConfig.json file to named contexts.

		.DESCRIPTION
			Earlier versions of this module stored every server in a single PSRadarrConfig.json file, keyed
			on the server name, with one entry flagged as the default. This function converts each entry in
			that file into a named context.

			Context names are derived from the server name. Where the same server appears more than once
			(the case that named contexts exist to solve, e.g. two instances on different ports of the same
			host) the port is appended to keep the names unique.

			The entry that was flagged as the default becomes the active context. The legacy file is left in
			place so that it can be checked and removed manually.

			This function is a no-op if there is no legacy file, or if any contexts already exist.

		.NOTES
			This is a private function used internally by other module functions.
	#>

	[CmdletBinding()]
	param()

	$ContextDirectory = Get-ContextDirectory
	$LegacyPath = Join-Path (Split-Path -Path $ContextDirectory -Parent) 'PSRadarrConfig.json'

	####################################################################################################
	#Region Decide whether there is anything to migrate
	if(-not (Test-Path -Path $LegacyPath -PathType Leaf))
	{
		return
	}

	if(Test-Path -Path $ContextDirectory -PathType Container)
	{
		$ExistingContexts = @(Get-ChildItem -Path $ContextDirectory -Filter '*.json' -ErrorAction SilentlyContinue)
		if($ExistingContexts.Count -gt 0)
		{
			return
		}
	}
	#EndRegion


	####################################################################################################
	#Region Read the legacy configuration
	try
	{
		[Array]$LegacyEntries = Get-Content -Path $LegacyPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
	}
	catch
	{
		throw "Could not read the legacy configuration at $LegacyPath : $_"
	}

	if(!$LegacyEntries -or $LegacyEntries.Count -eq 0)
	{
		return
	}
	#EndRegion


	####################################################################################################
	#Region Convert each entry into a named context
	if(-not (Test-Path -Path $ContextDirectory -PathType Container))
	{
		New-Item -ItemType Directory -Path $ContextDirectory -Force -ErrorAction Stop | Out-Null
	}

	# Servers that appear more than once need the port in their name to tell them apart:
	$DuplicateServers = @($LegacyEntries | Group-Object -Property Server | Where-Object { $_.Count -gt 1 }).Name

	$UsedNames = [System.Collections.Generic.List[String]]::new()
	$ActiveName = $null

	foreach($Entry in $LegacyEntries)
	{
		if($Entry.Server -in $DuplicateServers)
		{
			$Name = "$($Entry.Server)-$($Entry.Port)"
		}
		else
		{
			$Name = $Entry.Server
		}

		# Names become file names, so restrict them to characters that are safe everywhere:
		$Name = $Name -replace '[^a-zA-Z0-9._-]', '-'

		# Belt and braces: the legacy file could contain two entries that reduce to the same name.
		if($UsedNames.Contains($Name))
		{
			$Suffix = 2
			while($UsedNames.Contains("$Name-$Suffix"))
			{
				$Suffix++
			}
			$Name = "$Name-$Suffix"
		}
		$UsedNames.Add($Name)

		$Context = [Ordered]@{
			Name           = $Name
			Description    = 'Migrated from PSRadarrConfig.json'
			Server         = $Entry.Server
			Port           = $Entry.Port
			Protocol       = $Entry.Protocol
			APIVersion     = $Entry.APIVersion
			APIKey         = $Entry.APIKey
			RootFolderPath = $Entry.RootFolderPath
		}

		ConvertTo-Json -InputObject $Context -Depth 5 -ErrorAction Stop |
			Set-Content -Path (Join-Path $ContextDirectory "$Name.json") -Force -ErrorAction Stop

		if($Entry.Default -eq $true -and !$ActiveName)
		{
			$ActiveName = $Name
		}
	}

	# If nothing was flagged as the default, fall back to the first entry so that the module is usable:
	if(!$ActiveName)
	{
		$ActiveName = $UsedNames[0]
	}

	$ActiveName | Set-Content -Path (Join-Path $ContextDirectory 'active') -NoNewline -Force -ErrorAction Stop

	Write-Warning -Message "Migrated $($UsedNames.Count) server(s) from PSRadarrConfig.json to named contexts, with '$ActiveName' as the active context. Run Get-RadarrContext to check them, then delete $LegacyPath."
	#EndRegion
}
