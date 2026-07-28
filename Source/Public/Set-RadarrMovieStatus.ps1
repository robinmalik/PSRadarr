function Set-RadarrMovieStatus
{
	<#
		.SYNOPSIS
			Sets the monitoring status of a movie in Radarr.

		.DESCRIPTION
			Updates the monitoring status of a movie in Radarr. When a movie is monitored, Radarr will
			automatically search for and download it. When unmonitored, it will not be automatically
			downloaded.

		.PARAMETER Id
			The Radarr movie ID to update. Accepts pipeline input by property name.

		.PARAMETER Monitored
			Boolean value indicating whether the movie should be monitored (True) or unmonitored (False).

		.EXAMPLE
			Set-RadarrMovieStatus -Id 123 -Monitored $true

		.EXAMPLE
			Set-RadarrMovieStatus -Id 456 -Monitored $false

		.EXAMPLE
			Get-RadarrMovie -Name 'Inception' | Set-RadarrMovieStatus -Monitored $false

		.NOTES
			If the movie is already in the requested state the movie is returned unchanged and no request
			is made.
	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Int]$Id,

		[Parameter(Mandatory = $true)]
		[Alias('Monitor')]
		[Boolean]$Monitored
	)

	begin
	{
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
	}
	process
	{
		####################################################################################################
		#Region Get the movie from Radarr
		Write-Verbose -Message "Getting movie"
		try
		{
			$Movie = Get-RadarrMovie -Id $Id -ErrorAction Stop
			if(!$Movie)
			{
				throw "Movie with ID $Id not found. We cannot modify this."
			}
		}
		catch
		{
			throw $_
		}
		#EndRegion


		####################################################################################################
		#Region Compare monitor status to user submitted status
		if($Monitored -eq $Movie.monitored)
		{
			Write-Verbose -Message "Monitor status is already set to $Monitored"
			return $Movie
		}

		Write-Verbose -Message "Setting monitor status to $Monitored"
		$Movie.monitored = $Monitored
		#EndRegion


		####################################################################################################
		#Region Define the path and clean the body
		try
		{
			# The whole movie object is PUT back, so smart punctuation in the synopsis is normalised to
			# ASCII first to avoid re-encoding it on every round-trip:
			if($Movie.overview)
			{
				$Movie.overview = Convert-SmartPunctuation -String $Movie.overview
			}

			$Path = '/movie/' + $Id
		}
		catch
		{
			throw $_
		}
		#EndRegion


		####################################################################################################
		#Region make the main request
		Write-Verbose -Message "Updating movie with ID $Id"
		try
		{
			$UpdateResult = Invoke-RadarrRequest -Path $Path -Method PUT -Body $Movie -ErrorAction Stop
			if($UpdateResult)
			{
				return $UpdateResult
			}
			else
			{
				Write-Verbose -Message 'No update result.'
				return
			}
		}
		catch
		{
			throw $_
		}
		#EndRegion
	}
}
