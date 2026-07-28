function Add-RadarrMovie
{
	<#
		.SYNOPSIS
			Add a movie to Radarr by IMDB or TMDB ID.

		.DESCRIPTION
			Adds a movie to Radarr using an external database ID. The function looks the movie up through
			Radarr's lookup service, then adds it with the specified quality profile, monitoring state and
			minimum availability.

			If the movie is already in Radarr it is returned as-is rather than added again, with warnings
			raised where the existing quality profile or monitoring state differs from what was requested.
			This makes the command safe to re-run from a provisioning script.

		.PARAMETER IMDBID
			The IMDB ID of the movie to add. Can include or exclude the 'tt' prefix.

		.PARAMETER TMDBID
			The TMDB (The Movie Database) ID of the movie to add.

		.PARAMETER QualityProfileId
			The ID of the quality profile to assign to the movie. Use Get-RadarrQualityProfile to list them.

		.PARAMETER Monitored
			Whether the movie should be monitored. Defaults to $true. Pass $false to add a movie without
			Radarr searching for or grabbing it.

		.PARAMETER MinimumAvailability
			The point at which Radarr considers the movie available to search for. Valid values are
			'announced', 'inCinemas' and 'released'. Defaults to 'released'.

		.PARAMETER Search
			If specified, initiates a search for the movie after adding it.

		.EXAMPLE
			Add-RadarrMovie -IMDBID 'tt1375666' -QualityProfileId 1

		.EXAMPLE
			Add-RadarrMovie -TMDBID '27205' -QualityProfileId 1 -Search

		.EXAMPLE
			Add-RadarrMovie -IMDBID 'tt1375666' -QualityProfileId 1 -Monitored $false

			Adds the movie without monitoring it, so Radarr will not search for it.

		.EXAMPLE
			Add-RadarrMovie -IMDBID 'tt1375666' -QualityProfileId 1 -MinimumAvailability 'inCinemas' -Search

		.NOTES
			The movie must be findable through Radarr's lookup service, and the root folder path stored on
			the active context must be a root folder Radarr knows about. Use Get-RadarrRootFolder to check.
	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'IMDBID')]
		[ValidatePattern('^(tt)?\d{5,9}$')]
		[String]$IMDBID,

		[Parameter(Mandatory = $true, ParameterSetName = 'TMDBID')]
		[ValidatePattern('^\d{1,9}$')]
		[String]$TMDBID,

		[Parameter(Mandatory = $true)]
		[int]
		$QualityProfileId,

		[Parameter(Mandatory = $false)]
		[Boolean]$Monitored = $true,

		[Parameter(Mandatory = $false)]
		[ValidateSet('announced', 'inCinemas', 'released')]
		[String]$MinimumAvailability = 'released',

		[Parameter(Mandatory = $false)]
		[Switch]$Search
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
	#Region Check if already in Radarr before attempting an addition
	Write-Verbose -Message "Checking if the movie already exists"
	try
	{
		if($IMDBID)
		{
			$Movie = Get-RadarrMovie -IMDBID $IMDBID -ErrorAction Stop
		}
		elseif($TMDBID)
		{
			$Movie = Get-RadarrMovie -TMDBID $TMDBID -ErrorAction Stop
		}

		if($Movie)
		{
			Write-Verbose -Message "Movie already exists in Radarr with ID $($Movie.id)."

			if($Movie.qualityProfileId -ne $QualityProfileId)
			{
				Write-Warning -Message "Movie already exists but has a different quality profile (Current: $($Movie.qualityProfileId), Desired: $QualityProfileId). Use 'Set-RadarrMovieQualityProfile' to update the quality profile."
			}

			if($Movie.monitored -ne $Monitored)
			{
				Write-Warning -Message "Movie already exists but its monitoring status differs (Current: $($Movie.monitored), Desired: $Monitored). Use 'Set-RadarrMovieStatus' to change it."
			}

			if($Movie.minimumAvailability -ne $MinimumAvailability)
			{
				Write-Warning -Message "Movie already exists but has a different minimum availability (Current: $($Movie.minimumAvailability), Desired: $MinimumAvailability)."
			}

			return $Movie
		}
	}
	catch
	{
		throw $_
	}
	#EndRegion


	####################################################################################################
	#Region Search for the movie (we need to get the data before adding it)
	Write-Verbose -Message "Using Radarr lookup service to find the movie on TMDB"
	try
	{
		if($TMDBID)
		{
			$Movie = Find-RadarrMovie -TMDBID $TMDBID -ErrorAction Stop
		}
		elseif($IMDBID)
		{
			$Movie = Find-RadarrMovie -IMDBID $IMDBID -ErrorAction Stop
		}

		if(!$Movie)
		{
			throw "Could not find the movie to add"
		}
	}
	catch
	{
		throw $_
	}
	#EndRegion


	####################################################################################################
	#Region Append what we need to add to Radarr for monitoring
	try
	{
		$Movie | Add-Member -MemberType NoteProperty -Name 'qualityProfileId' -Value $QualityProfileId -Force
		$Movie | Add-Member -MemberType NoteProperty -Name 'profileId' -Value $QualityProfileId -Force
		$Movie | Add-Member -MemberType NoteProperty -Name 'monitored' -Value $Monitored -Force
		$Movie | Add-Member -MemberType NoteProperty -Name 'minimumAvailability' -Value $MinimumAvailability -Force
		$Movie | Add-Member -MemberType NoteProperty -Name 'rootFolderPath' -Value $Config.RootFolderPath -Force

		# addOptions is always sent, so that not passing -Search explicitly tells Radarr not to search,
		# rather than leaving the behaviour to the server default:
		$Movie | Add-Member -MemberType NoteProperty -Name 'addOptions' -Value $(
			[PSCustomObject]@{
				searchForMovie = [Boolean]$Search
			}
		) -Force
	}
	catch
	{
		throw $_
	}
	#EndRegion


	####################################################################################################
	#Region make the main request
	Write-Verbose -Message "Adding movie to Radarr"
	try
	{
		$Result = Invoke-RadarrRequest -Path '/movie' -Method POST -Body $Movie -ErrorAction Stop
		return $Result
	}
	catch
	{
		throw $_
	}
	#EndRegion
}
