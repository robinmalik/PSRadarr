function Get-RadarrQueue
{
	<#
		.SYNOPSIS
			Gets the download queue from Radarr.

		.DESCRIPTION
			Returns items currently in the download queue, including active downloads
			and queued items. Supports pagination and filtering.

		.PARAMETER Page
			The page number to retrieve (for pagination). Defaults to 1.

		.PARAMETER PageSize
			The number of items per page. Defaults to 20.

		.PARAMETER IncludeUnknownMovieItems
			Include downloads that don't match any known movie.

		.EXAMPLE
			Get-RadarrQueue

			Returns the first 20 items in the download queue.

		.EXAMPLE
			Get-RadarrQueue -PageSize 50

			Returns the first 50 items in the download queue.

		.EXAMPLE
			Get-RadarrQueue -Page 2 -PageSize 10

			Returns items 11-20 from the download queue.

		.EXAMPLE
			Get-RadarrQueue -IncludeUnknownMovieItems

			Returns queue items including downloads that don't match any known movie.

		.EXAMPLE
			(Get-RadarrQueue).records | Where-Object { $_.status -eq 'warning' }

			Returns queue items Radarr has flagged with a warning, e.g. stalled downloads.

		.NOTES
			The queue endpoint returns a paged envelope: the queue items themselves are on the
			'records' property, alongside page, pageSize and totalRecords.
	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false)]
		[Int]$Page = 1,

		[Parameter(Mandatory = $false)]
		[Int]$PageSize = 20,

		[Parameter(Mandatory = $false)]
		[Switch]$IncludeUnknownMovieItems
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
	#Region Define the parameters
	try
	{
		$Params = @{
			page     = $Page
			pageSize = $PageSize
		}

		if($IncludeUnknownMovieItems)
		{
			$Params['includeUnknownMovieItems'] = 'true'
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
		$Data = Invoke-RadarrRequest -Path '/queue' -Method GET -Params $Params -SuppressWhatIf -ErrorAction Stop
		return $Data
	}
	catch
	{
		throw $_
	}
	#EndRegion
}
