function Get-RadarrSystem
{
	<#
		.SYNOPSIS
			Gets Radarr system status information.

		.DESCRIPTION
			Returns detailed system status information including version, branch,
			authentication method, database information, operating system, and more.

		.EXAMPLE
			Get-RadarrSystem

		.EXAMPLE
			(Get-RadarrSystem).version

			Returns just the version number of Radarr.

		.NOTES
			This is the cheapest call for confirming that the active context's server address and API key
			are both correct. Use Select-RadarrContext to query a different instance.
	#>

	[CmdletBinding()]
	param(
	)

	####################################################################################################
	#Region Import configuration
	try
	{
		Import-Configuration -ErrorAction Stop
	}
	catch
	{
		throw $_
	}
	#EndRegion


	####################################################################################################
	#Region make the main request
	try
	{
		$Data = Invoke-RadarrRequest -Path '/system/status' -Method GET -SuppressWhatIf -ErrorAction Stop
		return $Data
	}
	catch
	{
		throw $_
	}
	#EndRegion
}
