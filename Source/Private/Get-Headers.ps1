function Get-Headers
{
	[CmdletBinding()]
	param(
	)

	return @{
		'X-Api-Key' = $Config.APIKey
	}
}