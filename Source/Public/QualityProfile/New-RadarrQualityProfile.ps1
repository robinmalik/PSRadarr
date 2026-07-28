function New-RadarrQualityProfile
{
	<#
		.SYNOPSIS
			Creates a new quality profile in Radarr.

		.DESCRIPTION
			Creates a new quality profile in Radarr. The allowed qualities are specified by name, e.g. 'WEBDL-720p'.

			The profile is built from Radarr's own quality profile schema, so the quality ordering and the default
			quality groupings (such as the 'WEB 720p' group that contains WEBDL-720p and WEBRip-720p) are preserved
			exactly as Radarr defines them. Only the qualities named in -AllowedQualities are enabled; any group
			containing at least one enabled quality is itself enabled.

		.PARAMETER Name
			The name of the quality profile to create.

		.PARAMETER AllowedQualities
			The names of the qualities to allow in the profile (e.g. 'HDTV-720p', 'WEBDL-1080p', 'Bluray-1080p').

		.PARAMETER Cutoff
			The name of the cutoff quality. Radarr will stop upgrading once a release of this quality (or better)
			has been downloaded. Must be one of the allowed qualities. If not specified, the highest ranked of the
			allowed qualities is used.

			Where the cutoff quality belongs to a quality group, the group is used as the cutoff, as required by
			the Radarr API.

		.PARAMETER UpgradeAllowed
			If specified, Radarr will upgrade already downloaded movies to better qualities (up to the cutoff).

		.PARAMETER MinFormatScore
			The minimum custom format score required for a release to be accepted. Defaults to 0.

		.PARAMETER CutoffFormatScore
			The custom format score at which Radarr stops upgrading. Defaults to 0.

		.PARAMETER MinUpgradeFormatScore
			The minimum custom format score improvement required for an upgrade. Defaults to 1.

		.PARAMETER FormatItems
			An optional array of custom format score items, each with 'format' (custom format ID) and 'score'
			properties, e.g. @(@{ format = 3; score = 10 }). If not specified, the custom formats defined in the
			schema are used with their default scores.

		.EXAMPLE
			New-RadarrQualityProfile -Name '720-WEBDL' -AllowedQualities 'WEBDL-720p'

		.EXAMPLE
			New-RadarrQualityProfile -Name 'HD' -AllowedQualities 'WEBDL-720p', 'WEBDL-1080p' -Cutoff 'WEBDL-1080p' -UpgradeAllowed

		.EXAMPLE
			New-RadarrQualityProfile -Name 'SD Only' -AllowedQualities 'SDTV' -WhatIf

		.NOTES
			Use Get-RadarrQualityProfile to see existing quality profiles.
	#>

	[CmdletBinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory = $true)]
		[String]$Name,

		[Parameter(Mandatory = $true)]
		[ArgumentCompleter({
				param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
				try
				{
					Get-RadarrQualityDefinition | Where-Object { $_.quality.name -like "$wordToComplete*" } | Sort-Object -Property weight | ForEach-Object {
						[System.Management.Automation.CompletionResult]::new("'$($_.quality.name)'", $_.quality.name, 'ParameterValue', "Quality ID: $($_.quality.id)")
					}
				}
				catch {}
			})]
		[String[]]$AllowedQualities,

		[Parameter(Mandatory = $false)]
		[ArgumentCompleter({
				param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
				try
				{
					# Only offer qualities that have been listed in -AllowedQualities, where that is already known:
					$Candidates = Get-RadarrQualityDefinition | Sort-Object -Property weight
					if($fakeBoundParameters.ContainsKey('AllowedQualities'))
					{
						$Candidates = $Candidates | Where-Object { $_.quality.name -in $fakeBoundParameters['AllowedQualities'] }
					}

					$Candidates | Where-Object { $_.quality.name -like "$wordToComplete*" } | ForEach-Object {
						[System.Management.Automation.CompletionResult]::new("'$($_.quality.name)'", $_.quality.name, 'ParameterValue', "Quality ID: $($_.quality.id)")
					}
				}
				catch {}
			})]
		[String]$Cutoff,

		[Parameter(Mandatory = $false)]
		[Switch]$UpgradeAllowed,

		[Parameter(Mandatory = $false)]
		[Int]$MinFormatScore = 0,

		[Parameter(Mandatory = $false)]
		[Int]$CutoffFormatScore = 0,

		[Parameter(Mandatory = $false)]
		[Int]$MinUpgradeFormatScore = 1,

		[Parameter(Mandatory = $false)]
		[Object[]]$FormatItems
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
	#Region Check if a profile with the same name already exists
	Write-Verbose -Message "Checking if a quality profile named '$Name' already exists"
	try
	{
		$Existing = Get-RadarrQualityProfile -Name $Name -ErrorAction Stop
		if($Existing)
		{
			throw "A quality profile named '$Name' already exists (ID: $($Existing.id))."
		}
	}
	catch
	{
		throw $_
	}
	#EndRegion


	####################################################################################################
	#Region Validate the cutoff against the allowed qualities
	if($PSBoundParameters.ContainsKey('Cutoff') -and $Cutoff -notin $AllowedQualities)
	{
		throw "The cutoff quality '$Cutoff' must be one of the allowed qualities."
	}
	#EndRegion


	####################################################################################################
	#Region Build the request body from Radarr's quality profile schema
	# The schema gives us every quality in Radarr's preferred order, along with the default quality groups
	# (e.g. 'WEB 720p' contains both WEBDL-720p and WEBRip-720p). Building on top of it means the profile we
	# create matches the structure Radarr's own UI produces.
	try
	{
		$Body = Invoke-RadarrRequest -Path '/qualityprofile/schema' -Method GET -SuppressWhatIf -ErrorAction Stop
		if(!$Body -or !$Body.items)
		{
			throw "Could not retrieve the quality profile schema from Radarr."
		}

		# Validate the supplied qualities against the qualities Radarr knows about:
		$QualityNames = $Body.items | ForEach-Object {
			if($_.items) { $_.items.quality.name } else { $_.quality.name }
		}
		foreach($Quality in $AllowedQualities)
		{
			if($Quality -notin $QualityNames)
			{
				throw "Unknown quality '$Quality'. Valid qualities are: $($QualityNames -join ', ')"
			}
		}

		# Flag the requested qualities as allowed. A group is allowed if any of its members are, and the ID used
		# to refer to a grouped quality for cutoff purposes is the group's ID, not the quality's own ID:
		$CutoffIds = @{}
		$AllowedInSchemaOrder = [System.Collections.Generic.List[String]]::new()
		foreach($Item in $Body.items)
		{
			if($Item.items)
			{
				# A quality group:
				foreach($Member in $Item.items)
				{
					$Member.allowed = ($Member.quality.name -in $AllowedQualities)
					if($Member.allowed)
					{
						$CutoffIds[$Member.quality.name] = $Item.id
						$AllowedInSchemaOrder.Add($Member.quality.name)
					}
				}
				$Item.allowed = [Bool]($Item.items | Where-Object { $_.allowed })
			}
			else
			{
				# A standalone quality:
				$Item.allowed = ($Item.quality.name -in $AllowedQualities)
				if($Item.allowed)
				{
					$CutoffIds[$Item.quality.name] = $Item.quality.id
					$AllowedInSchemaOrder.Add($Item.quality.name)
				}
			}
		}

		# Where no cutoff was given, use the highest ranked allowed quality. The schema lists items from lowest
		# to highest quality, so that is simply the last allowed one:
		if(!$PSBoundParameters.ContainsKey('Cutoff'))
		{
			$Cutoff = $AllowedInSchemaOrder[-1]
			Write-Verbose -Message "No cutoff specified, using the highest allowed quality: '$Cutoff'"
		}

		$Body.name = $Name
		$Body.upgradeAllowed = [Bool]$UpgradeAllowed
		$Body.cutoff = $CutoffIds[$Cutoff]
		$Body.minFormatScore = $MinFormatScore
		$Body.cutoffFormatScore = $CutoffFormatScore
		$Body.minUpgradeFormatScore = $MinUpgradeFormatScore

		# The schema already lists every custom format Radarr knows about, with its default score, so it is only
		# overwritten where the caller has supplied their own scores:
		if($PSBoundParameters.ContainsKey('FormatItems'))
		{
			$Body.formatItems = @($FormatItems)
		}
	}
	catch
	{
		throw $_
	}
	#EndRegion


	####################################################################################################
	#Region make the main request
	if($PSCmdlet.ShouldProcess("Quality profile '$Name' (allowing: $($AllowedQualities -join ', '); cutoff: $Cutoff)", "Create"))
	{
		Write-Verbose -Message "Creating quality profile '$Name' in Radarr"
		try
		{
			$Result = Invoke-RadarrRequest -Path '/qualityprofile' -Method POST -Body $Body -ErrorAction Stop
			return $Result
		}
		catch
		{
			throw $_
		}
	}
	#EndRegion
}
