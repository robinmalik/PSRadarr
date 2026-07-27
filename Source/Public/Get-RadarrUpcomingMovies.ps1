function Get-RadarrUpcomingMovies
{
	<#
		.SYNOPSIS
			Retrieves upcoming movies from the Radarr calendar.

		.DESCRIPTION
			Queries the Radarr calendar endpoint (GET /api/v3/calendar) and returns the movies
			airing between StartDate and EndDate.

			Dates are converted to UTC and sent in ISO 8601 format with milliseconds
			(yyyy-MM-ddTHH:mm:ss.fffZ), which is what the Radarr calendar endpoint expects.

		.PARAMETER StartDate
			The start of the period to query. Defaults to the current date and time.

		.PARAMETER EndDate
			The end of the period to query. Defaults to the current date and time plus 7 days.

		.EXAMPLE
			Get-RadarrUpcomingMovies

		.NOTES

	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false)]
		[DateTime]$StartDate = (Get-Date),

		[Parameter(Mandatory = $false)]
		[DateTime]$EndDate = (Get-Date).AddDays(30),

		[Parameter(Mandatory = $false)]
		[Switch]$IncludeUnmonitored
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
	#Region Validate the date range
	if($EndDate -lt $StartDate)
	{
		throw "EndDate ($EndDate) must not be earlier than StartDate ($StartDate)."
	}
	#EndRegion

	####################################################################################################
    #Region Define the path, parameters, headers and URI
	try
    {
        $Path = '/calendar'
        $Headers = Get-Headers

		$Format = 'yyyy-MM-ddTHH:mm:ss.fffZ'
		$Culture = [System.Globalization.CultureInfo]::InvariantCulture
		$Params = @{
			start       = $StartDate.ToUniversalTime().ToString($Format, $Culture)
			end         = $EndDate.ToUniversalTime().ToString($Format, $Culture)
			unmonitored = 'false'
		}

		if($IncludeUnmonitored)
		{
			$Params['unmonitored'] = 'true'
		}
        $Uri = Get-APIUri -RestEndpoint $Path -Params $Params
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
		$Data = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Get -ContentType 'application/json' -ErrorAction Stop
		return $Data
	}
	catch
	{
		throw $_
	}
	#EndRegion
}
