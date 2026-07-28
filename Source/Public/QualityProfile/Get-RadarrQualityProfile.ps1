function Get-RadarrQualityProfile
{
	<#
		.SYNOPSIS
			Retrieves quality profiles from Radarr.

		.DESCRIPTION
			Retrieves quality profile information from Radarr. Can return all quality profiles or filter by
			specific criteria such as ID or name.

		.PARAMETER Id
			The quality profile ID to retrieve.

		.PARAMETER Name
			The name of the quality profile to retrieve.

		.EXAMPLE
			Get-RadarrQualityProfile

		.EXAMPLE
			Get-RadarrQualityProfile -Id '1'

		.EXAMPLE
			Get-RadarrQualityProfile -Name 'HD-1080p'

		.EXAMPLE
			$Profile = Get-RadarrQualityProfile -Name '720p-webdl'
			Add-RadarrMovie -IMDBID 'tt1375666' -QualityProfileId $Profile.id

			Looks up a profile by name and uses its ID when adding a movie.

		.NOTES
			When no parameters are specified, all quality profiles in Radarr are returned.
	#>

	[CmdletBinding(DefaultParameterSetName = 'All')]
	param(
		[Parameter(Mandatory = $false, ParameterSetName = 'Id')]
		[String]$Id,

		[Parameter(Mandatory = $false, ParameterSetName = 'Name')]
		[String]$Name
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
	#Region Define the path
	try
	{
		$Path = '/qualityprofile'
		if($PSCmdlet.ParameterSetName -eq 'Id' -and $Id)
		{
			$Path += "/$Id"
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
		$Data = Invoke-RadarrRequest -Path $Path -Method GET -SuppressWhatIf -ErrorAction Stop
		if($Data)
		{
			if($Name)
			{
				$Data = $Data | Where-Object { $_.name -eq $Name }
			}

			return $Data
		}
	}
	catch
	{
		throw $_
	}
	#EndRegion
}