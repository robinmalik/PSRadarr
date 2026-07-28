function Get-RadarrIndexer
{
	<#
		.SYNOPSIS
			Gets indexer configuration from Radarr.

		.DESCRIPTION
			Returns configured indexers in Radarr. Can filter by indexer ID or name.

		.PARAMETER Id
			The ID of a specific indexer to retrieve.

		.PARAMETER Name
			The name of a specific indexer to retrieve. Supports wildcards.

		.EXAMPLE
			Get-RadarrIndexer

			Returns all configured indexers from the active Radarr context.

		.EXAMPLE
			Get-RadarrIndexer -Id 1

			Returns the indexer with ID 1.

		.EXAMPLE
			Get-RadarrIndexer -Name "NZBgeek"

			Returns the indexer named "NZBgeek".

		.EXAMPLE
			Get-RadarrIndexer -Name "*Usenet*"

			Returns all indexers with "Usenet" in their name.

		.EXAMPLE
			Get-RadarrIndexer | Where-Object { -not $_.enableAutomaticSearch }

			Returns indexers that are excluded from automatic searches.
	#>

	[CmdletBinding(DefaultParameterSetName = 'All')]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'Id', ValueFromPipelineByPropertyName = $true)]
		[Int]$Id,

		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
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
		#Region make the main request
		try
		{
			$Path = '/indexer'

			if($PSCmdlet.ParameterSetName -eq 'Id')
			{
				$Path += "/$Id"
			}

			$Data = Invoke-RadarrRequest -Path $Path -Method GET -SuppressWhatIf -ErrorAction Stop

			if($PSCmdlet.ParameterSetName -eq 'Name')
			{
				$Data = $Data | Where-Object { $_.name -like $Name }
			}

			return $Data
		}
		catch
		{
			throw $_
		}
		#EndRegion
	}
}
