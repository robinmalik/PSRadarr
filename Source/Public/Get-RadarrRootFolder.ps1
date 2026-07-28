function Get-RadarrRootFolder
{
	<#
		.SYNOPSIS
			Gets root folder configuration from Radarr.

		.DESCRIPTION
			Returns configured root folders in Radarr, including available disk space and folder paths.
			Can filter by root folder ID.

		.PARAMETER Id
			The ID of a specific root folder to retrieve.

		.EXAMPLE
			Get-RadarrRootFolder

			Returns all configured root folders from the active Radarr context.

		.EXAMPLE
			Get-RadarrRootFolder -Id 1

			Returns the root folder with ID 1.

		.EXAMPLE
			Get-RadarrRootFolder | Select-Object path, @{n='FreeSpaceGB';e={[math]::Round($_.freeSpace/1GB,2)}}

			Returns all root folders with their paths and free space in GB.

		.NOTES
			Useful for confirming that the RootFolderPath stored on a context matches a root folder that
			Radarr actually knows about, which Add-RadarrMovie requires.
	#>

	[CmdletBinding(DefaultParameterSetName = 'All')]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'Id', ValueFromPipelineByPropertyName = $true)]
		[Int]$Id
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
			$Path = '/rootfolder'

			if($PSCmdlet.ParameterSetName -eq 'Id')
			{
				$Path += "/$Id"
			}

			$Data = Invoke-RadarrRequest -Path $Path -Method GET -SuppressWhatIf -ErrorAction Stop
			return $Data
		}
		catch
		{
			throw $_
		}
		#EndRegion
	}
}
