function Get-APIUri
{
	[CmdletBinding()]
	[OutputType([System.String])]
	param(
		[Parameter(Mandatory = $true)]
		[String]
		$RestEndpoint,

		[Parameter(Mandatory = $false)]
		[System.Collections.IDictionary]
		$Params
	)


	# If the endpoint starts with /, strip it off:
	if($RestEndpoint.StartsWith('/'))
	{
		$RestEndpoint = $RestEndpoint.Substring(1)
	}

	# Join the parameters as key=value pairs, and concatenate them with &
	if($Params.Count -gt 0)
	{
		[String]$ParamString = "?" + (($Params.GetEnumerator() | ForEach-Object { $_.Name + '=' + $_.Value }) -join '&')
	}
	else
	{
		[String]$ParamString = $Null
	}

	return "$($Config.Protocol)://$($Config.Server):$($Config.Port)/api/v$($Config.APIVersion)/$($RestEndpoint)$($ParamString)"
}