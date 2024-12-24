function Add-RadarrMovie
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'IMDB')]
		[ValidatePattern('^(tt)?\d{5,9}$')]
		[String]$IMDBID,

		[Parameter(Mandatory = $true, ParameterSetName = 'TMDB')]
		[ValidatePattern('^\d{1,9}$')]
		[String]$TMDBID,

		[Parameter(Mandatory = $true)]
		[int]
		$QualityProfileId,

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
	# If using IMDB, ensure the ID is in the correct format
	if($ParameterSetName -eq 'IMDBID' -and $IMDBID -notmatch '^tt')
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
			Write-Warning "Movie already exists in Radarr!"
			return
		}
	}
	catch
	{
		throw $_
	}
	#EndRegion


	####################################################################################################
	#Region Search TMDB for the movie
	Write-Verbose -Message "Using Radarr lookup service to find the movie on TMDB"
	try
	{
		if($TMDBID)
		{
			$Movie = Search-RadarrMovie -TMDBID $TMDBID
		}
		elseif($IMDBID)
		{
			$Movie = Search-RadarrMovie -IMDBID $IMDBID
		}
	}
	catch
	{
		throw $_
	}
	#EndRegion


	####################################################################################################
	# Append what we need to add to Radarr for monitoring:
	$Movie | Add-Member -MemberType NoteProperty -Name 'qualityProfileId' -Value $QualityProfileId -Force
	$Movie | Add-Member -MemberType NoteProperty -Name 'profileId' -Value $QualityProfileId -Force
	$Movie | Add-Member -MemberType NoteProperty -Name 'monitored' -Value $True -Force
	$Movie | Add-Member -MemberType NoteProperty -Name 'rootFolderPath' -Value $Config.RootFolderPath -Force
	#$Movie = $Movie | Select-Object * -ExcludeProperty alternateTitles,originalTitle
	#$MovieRefined = $Movie | Select-Object title,originalTitle,alternateTitles,sortTitle,overview,inCinemas,physicalRelease,images,website,year,hasFile,youTubeTrailerId,studio,rootFolderPath,qualityProfileId,profileId,monitored,minimumAvailability,isAvailable,folderName,runtime,cleanTitle,imdbId,tmdbId,titleSlug,certification,genres,tags,added,ratings,collection,status
	if($Search)
	{
		$Movie | Add-Member -MemberType NoteProperty -Name 'addOptions' -Value $([PSCustomObject]@{ searchForMovie = $true }) -Force
	}


	####################################################################################################
	#Region Define the path, parameters, headers and URI
	try
	{
		$Data = $Movie | ConvertTo-Json -Depth 5
		$DataEncoded = ([System.Text.Encoding]::UTF8.GetBytes($Data))

		$Headers = Get-Headers
		$Path = '/movie'
		$Uri = Get-APIUri -RestEndpoint $Path
	}
	catch
	{
		throw $_
	}
	#EndRegion


	####################################################################################################
	#Region make the main request
	Write-Verbose "Adding: $Uri"
	try
	{
		Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Post -ContentType "application/json" -Body $DataEncoded -ErrorAction Stop
	}
	catch
	{
		throw $_
	}
	#EndRegion
}