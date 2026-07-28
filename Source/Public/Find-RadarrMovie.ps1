function Find-RadarrMovie
{
	<#
		.SYNOPSIS
			Search to find a movie in order to add to Radarr.

		.DESCRIPTION
			This uses the lookup service within Radarr to search for a movie by name, TMDB ID, or IMDB ID.
			It does not search your local Radarr library, but rather The Movie Database (TMDb). To search
			the local library, use Get-RadarrMovie.

		.PARAMETER Name
			The name of the movie to search for.

		.PARAMETER ExactMatch
			Only return results whose title matches -Name exactly.

		.PARAMETER IMDBID
			The IMDB ID of the movie to search for. Can include or exclude the 'tt' prefix.

		.PARAMETER TMDBID
			The TMDB ID of the movie to search for.

		.EXAMPLE
			Find-RadarrMovie -Name "The Matrix"

		.EXAMPLE
			Find-RadarrMovie -Name "The Matrix" -ExactMatch

		.EXAMPLE
			Find-RadarrMovie -IMDBID 'tt1375666'

		.EXAMPLE
			Find-RadarrMovie -TMDBID '27205'

		.NOTES
			If you have the IMDB ID or TMDB ID of a movie, it's better to use this to search.
	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[String]$Name,

		[Parameter(Mandatory = $false, ParameterSetName = 'Name')]
		[Switch]$ExactMatch,

		[Parameter(Mandatory = $true, ParameterSetName = 'IMDBID')]
		[ValidatePattern('^(tt)?\d{5,9}$')]
		[String]$IMDBID,

		[Parameter(Mandatory = $true, ParameterSetName = 'TMDBID')]
		[ValidatePattern('^\d{1,9}$')]
		[String]$TMDBID
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
	# If using IMDB, ensure the ID is in the correct format. This is deliberately guarded on the variable
	# rather than the parameter set name, so it cannot drift out of sync if a set is ever renamed.
	if($IMDBID -and $IMDBID -notmatch '^tt')
	{
		$IMDBID = 'tt' + $IMDBID
	}


	####################################################################################################
	#Region Define the path and parameters
	try
	{
		$Path = '/movie/lookup'

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
			$Params = @{
				imdbId = $IMDBID
			}
		}
		else
		{
			throw 'You must specify a name, TMDBID, or IMDBID.'
		}
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
		$Data = Invoke-RadarrRequest -Path $Path -Method GET -Params $Params -SuppressWhatIf -ErrorAction Stop
		if($Data)
		{
			# If ExactMatch is specified, filter the results to only include the exact match
			if($ExactMatch)
			{
				$Data = $Data | Where-Object { $_.title -eq $Name }
			}

			# The lookup-by-ID endpoints return a single movie, so more than one result means the response
			# was not what this function assumes and callers expecting a single object would break silently.
			if($PSCmdlet.ParameterSetName -match 'ID' -and @($Data).Count -gt 1)
			{
				throw "Multiple movies found for the provided ID. This should not happen!"
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
