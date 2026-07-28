function Remove-RadarrQualityProfile
{
	<#
		.SYNOPSIS
			Removes a quality profile from Radarr.

		.DESCRIPTION
			Removes a quality profile from Radarr, either by ID or by name. This function supports WhatIf and
			Confirm parameters for safe execution.

			Radarr will refuse to remove a quality profile that is still assigned to one or more series. Use
			Set-RadarrSeriesQualityProfile to move those series to another profile first.

		.PARAMETER Id
			The quality profile ID to remove. Accepts pipeline input by property name, so the output of
			Get-RadarrQualityProfile can be piped straight in.

		.PARAMETER Name
			The name of the quality profile to remove. The name is resolved to an ID via Get-RadarrQualityProfile.

		.EXAMPLE
			Remove-RadarrQualityProfile -Id '7'

		.EXAMPLE
			Remove-RadarrQualityProfile -Name '720-WEBDL'

		.EXAMPLE
			Get-RadarrQualityProfile -Name '720-WEBDL' | Remove-RadarrQualityProfile

		.EXAMPLE
			Remove-RadarrQualityProfile -Name '720-WEBDL' -WhatIf

		.NOTES
			Use Get-RadarrQualityProfile to see existing quality profiles.
	#>

	[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Id')]
	param(
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'Id')]
		[String]$Id,

		[Parameter(Mandatory, ParameterSetName = 'Name')]
		[ArgumentCompleter({
				param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
				try
				{
					Get-RadarrQualityProfile | Where-Object { $_.name -like "$wordToComplete*" } | ForEach-Object {
						[System.Management.Automation.CompletionResult]::new("'$($_.name)'", $_.name, 'ParameterValue', "ID: $($_.id)")
					}
				}
				catch {}
			})]
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
		#Region Resolve the profile to remove
		try
		{
			if($PSCmdlet.ParameterSetName -eq 'Name')
			{
				$MatchedProfile = Get-RadarrQualityProfile -Name $Name -ErrorAction Stop
				if(!$MatchedProfile)
				{
					throw "No quality profile named '$Name' was found."
				}
				if(@($MatchedProfile).Count -gt 1)
				{
					throw "More than one quality profile named '$Name' was found. Remove it by ID instead."
				}

				$ProfileId = $MatchedProfile.id
				$ProfileDescription = "Quality profile '$Name' (ID: $ProfileId)"
			}
			else
			{
				$ProfileId = $Id
				$ProfileDescription = "Quality profile with ID: $ProfileId"
			}

			$Path = '/qualityprofile/' + $ProfileId
		}
		catch
		{
			throw $_
		}
		#EndRegion


		####################################################################################################
		#Region make the main request
		if($PSCmdlet.ShouldProcess($ProfileDescription, "Remove"))
		{
			Write-Verbose -Message "Removing quality profile with ID $ProfileId"
			try
			{
				Invoke-RadarrRequest -Path $Path -Method DELETE -ErrorAction Stop | Out-Null
			}
			catch
			{
				throw $_
			}
		}
		#EndRegion
	}
}
