function Import-Configuration
{
	[CmdletBinding()]
	param(
	)

	$FileName = 'PSRadarrConfig.json'
	$FilePath = "$HOME/.PSRadarr/$FileName"

	if(Test-Path $FilePath)
	{
		try
		{
			$Script:Config = Get-Content $FilePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
		}
		catch
		{
			throw $_
		}

		# Refine to our default server:
		$Script:Config = $Script:Config | Where-Object { $_.Default -eq $True }
		if(!$Script:Config)
		{
			throw "No default server found in $FilePath. Please run Set-RadarrConfiguration."
		}
	}
	else
	{
		throw "Config file not found at $FilePath. Please run Set-RadarrConfiguration."
	}
}