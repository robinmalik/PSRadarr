function Invoke-RadarrMovieRefresh
{
	<#
		.SYNOPSIS
			Refreshes a movie in Radarr.

		.DESCRIPTION
			Sends a RefreshMovie command to Radarr for a specific movie. The movie can be identified by
			its Radarr ID or by name. When using -Name, the function resolves the movie through
			Get-RadarrMovie and uses the matching Radarr ID.

			A refresh re-reads the movie's metadata and rescans its folder on disk, which is required
			before Radarr reflects files that were added, removed or renamed outside of Radarr.

		.PARAMETER Id
			The Radarr movie ID to refresh.

		.PARAMETER Name
			The name of the movie to refresh. The function resolves the movie using Get-RadarrMovie.

		.EXAMPLE
			Invoke-RadarrMovieRefresh -Id 58

		.EXAMPLE
			Invoke-RadarrMovieRefresh -Name 'Inception'

		.NOTES
			Returns the command object Radarr queued. The refresh itself runs asynchronously, so a
			successful return means the command was accepted, not that it has finished.
	#>

	[CmdletBinding(DefaultParameterSetName = 'Id')]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'Id', ValueFromPipelineByPropertyName = $true)]
		[Int32]$Id,

		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[Alias('Title')]
		[String]$Name
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
		#Region Resolve movie ID from name if required
		if($PSCmdlet.ParameterSetName -eq 'Name')
		{
			try
			{
				$Movie = Get-RadarrMovie -Name $Name -ErrorAction Stop
				if(!$Movie)
				{
					throw "Movie with name '$Name' not found in Radarr."
				}

				if($Movie -is [System.Array])
				{
					$Movie = @($Movie | Where-Object { $_.title -eq $Name -or $_.originalTitle -eq $Name }) | Select-Object -First 1
					if(!$Movie)
					{
						throw "Movie with name '$Name' not found in Radarr."
					}
				}
				elseif($Movie.title -ne $Name -and $Movie.originalTitle -ne $Name)
				{
					throw "Movie with name '$Name' not found in Radarr."
				}

				$Id = [Int32]$Movie.id
			}
			catch
			{
				throw $_
			}
		}
		#EndRegion


		####################################################################################################
		#Region Build command body and send refresh request
		try
		{
			$CommandBody = @{
				name    = 'RefreshMovie'
				movieId = $Id
			}

			Write-Verbose -Message "Refreshing movie with ID $Id"
			$Result = Invoke-RadarrRequest -Path '/command' -Method POST -Body $CommandBody -ErrorAction Stop
			return $Result
		}
		catch
		{
			throw $_
		}
		#EndRegion
	}
}
