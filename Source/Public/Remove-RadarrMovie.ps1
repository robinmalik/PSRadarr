function Remove-RadarrMovie
{
	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[String]$Id
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
		#Region Define the path, parameters, headers and URI
		try
		{
			$Path = '/movie/' + $Id
			$Uri = Get-APIUri -RestEndpoint $Path
			$Headers = Get-Headers
		}
		catch
		{
			throw $_
		}
		#EndRegion

		####################################################################################################
		#Region make the main request
		if($PSCmdlet.ShouldProcess("Movie with ID: $Id", "Remove"))
		{
			try
			{
				Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Delete -ContentType 'application/json' -ErrorAction Stop
			}
			catch
			{
				Write-Error "Failed to remove movie with ID $Id. Error: $($_.Exception.Message)"
			}
		}
		#EndRegion
	}
}