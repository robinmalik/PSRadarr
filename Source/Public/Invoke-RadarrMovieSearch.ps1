function Invoke-RadarrMovieSearch
{
	<#
		.SYNOPSIS
			Initiate a search for one or more movies already in Radarr.

		.DESCRIPTION
			Initiates a MoviesSearch command in Radarr to search indexers for the given movies.
			This function triggers the same action as clicking "Search" against a movie in the Radarr
			web interface, and is the counterpart to Add-RadarrMovie -Search for movies that are
			already in the library.

			Every movie is validated against Radarr before the command is sent, and all of them are
			submitted as a single command.

		.PARAMETER Id
			One or more Radarr movie IDs to search for. Accepts pipeline input by property name.

		.EXAMPLE
			Invoke-RadarrMovieSearch -Id 123

		.EXAMPLE
			Invoke-RadarrMovieSearch -Id 123, 456, 789

		.EXAMPLE
			Get-RadarrMovie | Where-Object { $_.monitored -and -not $_.hasFile } | Invoke-RadarrMovieSearch

			Searches for every monitored movie that Radarr does not yet have a file for.

		.NOTES
			The movies must already exist in Radarr. Returns the command object Radarr queued; the search
			itself runs asynchronously, so a successful return means the command was accepted, not that
			anything has been grabbed.
	#>

	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Int32[]]$Id
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

		# Collected across all pipeline input so that a single command is sent, rather than one per movie:
		$MovieIds = [System.Collections.Generic.List[Int32]]::new()
	}
	process
	{
		####################################################################################################
		#Region Validate the movies exist
		foreach($MovieId in $Id)
		{
			try
			{
				$Movie = Get-RadarrMovie -Id $MovieId -ErrorAction Stop
				if(!$Movie)
				{
					throw "Movie with ID $MovieId not found in Radarr."
				}

				$MovieIds.Add($MovieId)
			}
			catch
			{
				throw $_
			}
		}
		#EndRegion
	}
	end
	{
		####################################################################################################
		#Region make the main request
		if($MovieIds.Count -eq 0)
		{
			Write-Verbose -Message 'No movie IDs supplied, nothing to search for.'
			return
		}

		try
		{
			# Note the command name is plural and takes an array, unlike RefreshMovie's singular movieId:
			$CommandBody = @{
				name     = 'MoviesSearch'
				movieIds = @($MovieIds)
			}

			if($PSCmdlet.ShouldProcess("Movies with ID: $($MovieIds -join ', ')", "Search"))
			{
				Write-Verbose -Message "Searching for $($MovieIds.Count) movie(s)"
				$Result = Invoke-RadarrRequest -Path '/command' -Method POST -Body $CommandBody -ErrorAction Stop
				return $Result
			}
		}
		catch
		{
			throw $_
		}
		#EndRegion
	}
}
