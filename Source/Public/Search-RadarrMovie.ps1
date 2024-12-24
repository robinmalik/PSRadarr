function Search-RadarrMovie
{
	<#
		.SYNOPSIS
			Search to find a movie in order to add to Radarr.

		.DESCRIPTION
			This uses the lookup service within Radarr to search for a movie by name, TMDB ID, or IMDB ID.
			It does not search your local Radarr library, but rather The Movie Database (TMDb).

		.PARAMETER Name
			The name of the movie to search for.

		.PARAMETER TMDBID
			The TMDB ID of the movie to search for.

		.PARAMETER IMDBID
			The IMDB ID of the movie to search for.

		.EXAMPLE
			Search-RadarrMovie -Name "The Matrix"

		.NOTES
			If you have the IMDB ID or TMDB ID of a movie, it's better to use this to search.
	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[String]$Name,

		[Parameter(Mandatory = $false, ParameterSetName = 'Name')]
		[Switch]$ExactMatch,

		[Parameter(Mandatory = $true, ParameterSetName = 'TMDBID')]
		[String]$TMDBID,

		[Parameter(Mandatory = $true, ParameterSetName = 'IMDBID')]
		[ValidatePattern('^(tt)?\d{5,9}$')]
		[String]$IMDBID
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
	#Region Define the path, parameters, headers and URI
	try
	{
		$Path = "/movie/lookup"
		if($Name)
		{
			$Params = @{
				term = $Name
			}
		}
		elseif($TMDBID)
		{
			$Path = $Path + '/tmdb'
			$Params = @{
				tmdbId = $TMDBID
			}
		}
		elseif($IMDBID)
		{
			$Path = $Path + '/imdb'

			if($IMDBID -notmatch '^tt')
			{
				$IMDBID = 'tt' + $IMDBID
			}

			$Params = @{
				imdbId = $IMDBID
			}

		}
		else
		{
			throw 'You must specify a name, TMDBID, or IMDBID.'
		}

		# Generate the headers and URI
		$Headers = Get-Headers
		$Uri = Get-APIUri -RestEndpoint $Path -Params $Params
	}
	catch
	{
		throw $_
	}
	#EndRegion


	####################################################################################################
	#Region make the main request
	Write-Verbose "Querying: $Uri"
	try
	{
		$Data = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Get -ContentType 'application/json' -ErrorAction Stop
		if($Data)
		{
			# If ExactMatch is specified, filter the results to only include the exact match
			if($ExactMatch)
			{
				$Data = $Data | Where-Object { $_.title -eq $Name }
			}

			return $Data
		}
		else
		{
			Write-Warning -Message "No movie found."
			return
		}
	}
	catch
	{
		throw $_
	}
	#EndRegion
}