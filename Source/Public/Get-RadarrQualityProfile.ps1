function Get-RadarrQualityProfile
{
	[CmdletBinding()]
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
	#Region Define the path, parameters, headers and URI
	try
	{
		$Path = '/qualityprofile'
		if($PSCmdlet.ParameterSetName -eq 'Id' -and $Id)
		{
			$Path += "/$Id"
		}

		# Generate the headers and URI
		$Headers = Get-Headers
		$Uri = Get-APIUri -RestEndpoint $Path -Params $Params
	}
	catch
	{
		throw $_
	}
	#EndRegion


	####################################################################################################
	#Region make the main request
	Write-Verbose "Querying: $Uri"
	try
	{
		$Data = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Get -ContentType 'application/json' -ErrorAction Stop
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

}