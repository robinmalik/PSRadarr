function Get-RadarrHealth
{
	<#
		.SYNOPSIS
			Gets health status and warnings from Radarr.

		.DESCRIPTION
			Returns health check results from Radarr, including any warnings or errors
			related to system configuration, disk space, indexers, download clients and updates.

		.EXAMPLE
			Get-RadarrHealth

			Returns all health check results from the active Radarr context.

		.EXAMPLE
			Get-RadarrHealth | Where-Object { $_.type -eq 'error' }

			Returns only the health checks that Radarr has raised as errors.

		.NOTES
			An empty result means Radarr reported no health issues.
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
		$Data = Invoke-RadarrRequest -Path '/health' -Method GET -SuppressWhatIf -ErrorAction Stop
		return $Data
	}
	catch
	{
		throw $_
	}
	#EndRegion
}
