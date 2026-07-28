function Set-RadarrMovieQualityProfile
{
	<#
		.SYNOPSIS
			Sets the quality profile for a movie in Radarr.

		.DESCRIPTION
			Updates the quality profile for a movie in Radarr. This determines the quality standards
			that Radarr will use when searching for and downloading a release for this movie.

		.PARAMETER Id
			The Radarr movie ID to update.

		.PARAMETER QualityProfileId
			The ID of the quality profile to assign to the movie.

		.EXAMPLE
			Set-RadarrMovieQualityProfile -Id 123 -QualityProfileId 2

		.EXAMPLE
			Get-RadarrMovie -Name "Inception" | Set-RadarrMovieQualityProfile -QualityProfileId 2

		.NOTES
			Use Get-RadarrQualityProfile to see available quality profiles.
	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)]
		[Int]$Id,

		[Parameter(Mandatory = $true)]
		[ArgumentCompleter({
				param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
				Get-RadarrQualityProfile | Where-Object { $_.id -like "$wordToComplete*" } | ForEach-Object {
					[System.Management.Automation.CompletionResult]::new($_.id, $_.name, 'ParameterValue', "ID: $($_.id)")
				}
			})]
		[Int]$QualityProfileId
	)

	process
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


		####################################################################################################
		#Region Get the movie
		try
		{
			$Movie = Get-RadarrMovie -Id $Id -ErrorAction Stop
			if(!$Movie)
			{
				throw "Movie with ID $Id not found."
			}
		}
		catch
		{
			throw $_
		}
		#EndRegion


		####################################################################################################
		#Region Modify quality profile and prepare request
		try
		{
			# The whole movie object is PUT back, so smart punctuation in the synopsis is normalised to
			# ASCII first to avoid re-encoding it on every round-trip:
			if($Movie.overview)
			{
				$Movie.overview = Convert-SmartPunctuation -String $Movie.overview
			}

			# Set the quality profile ID
			$Movie.qualityProfileId = [Int]$QualityProfileId

			$Path = '/movie/' + "$Id"
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
			$Result = Invoke-RadarrRequest -Path $Path -Method PUT -Body $Movie -ErrorAction Stop
			return $Result
		}
		catch
		{
			throw $_
		}
		#EndRegion
	}
}
