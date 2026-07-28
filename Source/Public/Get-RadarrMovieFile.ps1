function Get-RadarrMovieFile
{
	<#
		.SYNOPSIS
			Retrieves file-level data for a movie from Radarr.

		.DESCRIPTION
			Returns the movie file records Radarr holds for a movie, including the path on disk, the
			quality that was grabbed, the release group, the file size and media info. This is the detail
			behind the 'hasFile' property returned by Get-RadarrMovie.

		.PARAMETER MovieId
			The Radarr movie ID. Aliased to 'Id' so a movie object can be piped in directly.

		.EXAMPLE
			Get-RadarrMovieFile -MovieId 123

		.EXAMPLE
			Get-RadarrMovie -Name 'Inception' | Get-RadarrMovieFile

		.EXAMPLE
			Get-RadarrMovieFile -MovieId 123 | Select-Object relativePath, @{n='SizeGB';e={[math]::Round($_.size/1GB,2)}}, @{n='Quality';e={$_.quality.quality.name}}

			Returns a readable summary of what Radarr has on disk for the movie.

		.NOTES
			A movie with no downloaded file returns nothing.
	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('Id')]
		[Int]$MovieId
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
		#Region make the main request
		try
		{
			# Passed as a query parameter rather than built into the path, so the wrapper URL-encodes it:
			$Params = @{
				movieId = $MovieId
			}

			$Data = Invoke-RadarrRequest -Path '/moviefile' -Method GET -Params $Params -SuppressWhatIf -ErrorAction Stop
			if($Data)
			{
				return $Data
			}
			else
			{
				Write-Verbose -Message "No movie file found for movie ID $MovieId."
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
