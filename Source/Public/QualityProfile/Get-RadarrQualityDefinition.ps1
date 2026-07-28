function Get-RadarrQualityDefinition
{
	<#
		.SYNOPSIS
			Retrieves quality definitions from Radarr.

		.DESCRIPTION
			Retrieves the quality definitions configured in Radarr. A quality definition describes a single
			quality (e.g. 'WEBDL-720p') along with its weight (the order Radarr ranks it in) and the minimum,
			maximum and preferred file sizes per minute of runtime.

			These are the qualities that can be referenced by name when building a quality profile with
			New-RadarrQualityProfile.

		.PARAMETER Id
			The quality definition ID to retrieve. Note that this is the definition ID, which is not the same
			as the ID of the quality it describes (available as the 'quality.id' property).

		.PARAMETER Name
			The name of the quality to retrieve the definition for, e.g. 'WEBDL-720p'.

		.EXAMPLE
			Get-RadarrQualityDefinition

		.EXAMPLE
			Get-RadarrQualityDefinition -Name 'WEBDL-720p'

		.EXAMPLE
			Get-RadarrQualityDefinition | Sort-Object -Property weight | Select-Object -ExpandProperty quality

		.NOTES
			When no parameters are specified, all quality definitions in Radarr are returned.
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
		$Path = '/qualitydefinition'
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
				$Data = $Data | Where-Object { $_.quality.name -eq $Name }
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
