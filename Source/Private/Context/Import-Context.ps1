function Import-Context
{
	<#
		.SYNOPSIS
			Resolves and imports the active context.

		.DESCRIPTION
			This function retrieves the active context from disk or memory and returns it as a PSCustomObject.
			It is used internally by other module functions to determine which Radarr instance to target.

			Resolves the active context from (in priority order):
			1. In-memory ephemeral context (Save-RadarrContext -Persist $false)
			2. In-session name override (Select-RadarrContext -Persist $false)
			3. Persisted active context marker file
			4. Persisted context file on disk

			If no context is found, an error is thrown.

		.OUTPUTS
			PSCustomObject containing the active context.

		.NOTES
			This is a private function used internally by other module functions.
	#>

	[CmdletBinding()]
	[OutputType([PSCustomObject])]
	param()

	$ContextDirectory = Get-ContextDirectory

	# 1. In-memory ephemeral context (Save-RadarrContext -Persist $false).
	# $script:ActiveContext holds the complete context object; nothing exists on disk, so return it as-is.
	if($script:ActiveContext -is [PSCustomObject])
	{
		return $script:ActiveContext
	}

	# 2. In-session name override (Select-RadarrContext -Persist $false).
	# $script:ActiveContext holds a context name (string) pointing at a context file on disk.
	$ActiveName = $script:ActiveContext

	# 3. Persisted active context marker file ('active') identifies the default context name.
	if(-not $ActiveName)
	{
		$ActiveFile = Join-Path $ContextDirectory 'active'
		if(-not (Test-Path $ActiveFile))
		{
			# Nothing has been selected yet, so this may be a configuration from before contexts existed:
			Convert-LegacyConfiguration
		}

		if(Test-Path $ActiveFile)
		{
			$ActiveName = (Get-Content $ActiveFile -Raw).Trim()
		}
	}

	if(-not $ActiveName)
	{
		throw 'No context is selected. Run Save-RadarrContext or Select-RadarrContext before using PSRadarr commands.'
	}

	# 4. Load the resolved context file from disk.
	$ContextFile = Join-Path $ContextDirectory "$ActiveName.json"
	if(-not (Test-Path $ContextFile))
	{
		throw "Active context '$ActiveName' was not found. Run Get-RadarrContext to list saved contexts."
	}

	Write-Verbose -Message "Function: $($MyInvocation.MyCommand): Loading context '$ActiveName' from $ContextFile"
	try
	{
		return Get-Content -Path $ContextFile -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
	}
	catch
	{
		throw "Could not read context '$ActiveName' from $ContextFile : $_"
	}
}
