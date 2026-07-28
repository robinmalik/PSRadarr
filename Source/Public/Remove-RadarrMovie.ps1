function Remove-RadarrMovie
{
	<#
		.SYNOPSIS
			Removes a movie from Radarr.

		.DESCRIPTION
			Removes a movie from Radarr using the movie ID. This function supports WhatIf and Confirm parameters
			for safe execution. Optionally can delete associated files and add the movie to import list exclusions.

		.PARAMETER Id
			The Radarr movie ID to remove. Accepts pipeline input by property name.

		.PARAMETER DeleteFiles
			If specified, deletes the actual video files associated with the movie from disk.

		.PARAMETER AddImportExclusion
			If specified, adds the movie to import list exclusions to prevent it from being re-added
			automatically.

		.EXAMPLE
			Remove-RadarrMovie -Id '123'

		.EXAMPLE
			Remove-RadarrMovie -Id '123' -DeleteFiles

		.EXAMPLE
			Remove-RadarrMovie -Id '123' -DeleteFiles -AddImportExclusion

		.EXAMPLE
			Get-RadarrMovie -Name 'Old Film' | Remove-RadarrMovie -DeleteFiles

		.EXAMPLE
			Remove-RadarrMovie -Id '123' -WhatIf

		.NOTES
			This function supports pipeline input and confirmation prompts for safe movie removal.
			Use -DeleteFiles with caution as it will permanently delete video files from disk.

			Note that Radarr's query parameter is 'addImportExclusion', without the 'List' that Sonarr's
			equivalent uses.
	#>

	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[String]$Id,

		[Parameter(Mandatory = $false)]
		[Switch]$DeleteFiles,

		[Parameter(Mandatory = $false)]
		[Switch]$AddImportExclusion
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
		#Region Define the path and parameters
		try
		{
			$Path = '/movie/' + $Id

			# Build query parameters based on switches
			$Params = @{
				deleteFiles        = $DeleteFiles.ToString().ToLower()
				addImportExclusion = $AddImportExclusion.ToString().ToLower()
			}
		}
		catch
		{
			throw $_
		}
		#EndRegion

		####################################################################################################
		#Region make the main request
		$ActionDescription = "Movie with ID: $Id"
		if($DeleteFiles)
		{
			$ActionDescription += " (including files)"
		}
		if($AddImportExclusion)
		{
			$ActionDescription += " (adding to import exclusions)"
		}

		if($PSCmdlet.ShouldProcess($ActionDescription, "Remove"))
		{
			Write-Verbose -Message "Removing movie with ID $Id $(if($DeleteFiles){'and deleting files '})$(if($AddImportExclusion){'and adding to import exclusions'})"
			try
			{
				Invoke-RadarrRequest -Path $Path -Method DELETE -Params $Params -ErrorAction Stop | Out-Null
			}
			catch
			{
				throw $_
			}
		}
		#EndRegion
	}
}
