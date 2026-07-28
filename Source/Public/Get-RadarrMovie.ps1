function Get-RadarrMovie
{
	<#
		.SYNOPSIS
			Retrieves movies from Radarr.

		.DESCRIPTION
			Retrieves movie information from Radarr. Can return all movies or filter by specific criteria
			such as ID, name, or external database IDs.

			This searches your local Radarr library. To search The Movie Database for a movie that is not
			in Radarr yet, use Find-RadarrMovie.

		.PARAMETER Id
			The Radarr movie ID to retrieve.

		.PARAMETER Name
			The name or title of the movie to retrieve. Searches both title and originalTitle fields.
			Aliased to 'Title'.

		.PARAMETER IMDBID
			The IMDB ID of the movie to retrieve. Can include or exclude the 'tt' prefix.

		.PARAMETER TMDBID
			The TMDB (The Movie Database) ID of the movie to retrieve.

		.EXAMPLE
			Get-RadarrMovie

		.EXAMPLE
			Get-RadarrMovie -Id '1'

		.EXAMPLE
			Get-RadarrMovie -Name 'Inception'

		.EXAMPLE
			Get-RadarrMovie -IMDBID 'tt1375666'

		.EXAMPLE
			Get-RadarrMovie | Where-Object { $_.monitored -and -not $_.hasFile }

			Returns every monitored movie that Radarr does not yet have a file for.

		.NOTES
			When no parameters are specified, all movies in Radarr are returned.

			-TMDBID is filtered by Radarr itself rather than in the pipeline, so it does not transfer the
			whole library. -Name and -IMDBID have no server-side equivalent and are filtered client-side.
	#>

	[CmdletBinding(DefaultParameterSetName = 'All')]
	param(
		[Parameter(Mandatory = $false, ParameterSetName = 'Id')]
		[String]$Id,

		[Parameter(Mandatory = $false, ParameterSetName = 'Name')]
		[Alias('Title')]
		[String]$Name,

		[Parameter(Mandatory = $false, ParameterSetName = 'IMDBID')]
		[ValidatePattern('^(tt)?\d{5,9}$')]
		[String]$IMDBID,

		[Parameter(Mandatory = $false, ParameterSetName = 'TMDBID')]
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
		$Path = '/movie'
		$Params = @{}

		if($PSCmdlet.ParameterSetName -eq 'Id' -and $Id)
		{
			$Path += "/$Id"
		}
		elseif($PSCmdlet.ParameterSetName -eq 'TMDBID')
		{
			# Radarr filters on tmdbId server-side, so the whole library is not transferred just to find
			# one movie. There is no equivalent for title or IMDB ID, which are filtered below.
			$Params['tmdbId'] = $TMDBID
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
		if($Params.Count -gt 0)
		{
			$Data = Invoke-RadarrRequest -Path $Path -Method GET -Params $Params -SuppressWhatIf -ErrorAction Stop
		}
		else
		{
			$Data = Invoke-RadarrRequest -Path $Path -Method GET -SuppressWhatIf -ErrorAction Stop
		}

		if($Data)
		{
			# Filter results based on parameters if specified
			switch($PSCmdlet.ParameterSetName)
			{
				'Name'
				{
					$Data = $Data | Where-Object { $_.title -eq $Name -or $_.originalTitle -eq $Name }
				}
				'IMDBID'
				{
					$Data = $Data | Where-Object { $_.imdbId -eq "$IMDBID" }
				}
			}

			return $Data
		}
		else
		{
			Write-Verbose -Message 'No result found.'
			return
		}
	}
	catch
	{
		throw $_
	}
	#EndRegion
}
