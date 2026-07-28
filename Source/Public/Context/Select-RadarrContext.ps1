function Select-RadarrContext
{
	<#
		.SYNOPSIS
			Selects the context to use.

		.DESCRIPTION
			This function sets the active context, which determines the Radarr instance and API key used for
			subsequent commands.

		.PARAMETER Name
			The name of the context to activate. Tab-completion is supported.

		.PARAMETER Persist
			Specifies whether the selected context should be persisted to disk, defaulting to true. If set to
			false, the context will only be active for the current session and the active marker will not be
			updated.

		.EXAMPLE
			# Switches the active context to 'radarr4k' and persists the change to disk:
			Select-RadarrContext -Name radarr4k

		.EXAMPLE
			# Switches the active context for the current session only:
			Select-RadarrContext -Name localhost -Persist $false

		.NOTES
			Use Get-RadarrContext to list the available contexts.
	#>

	[CmdletBinding()]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'commandAst', Justification = 'Required for autocomplete on parameter.')]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'commandName', Justification = 'Required for autocomplete on parameter.')]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'parameterName', Justification = 'Required for autocomplete on parameter.')]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'fakeBoundParameters', Justification = 'Required for autocomplete on parameter.')]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[ArgumentCompleter({
				param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
				$Contexts = @(Get-RadarrContext -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
				$Contexts |
					Where-Object { $_.Name -like "$WordToComplete*" } |
						ForEach-Object {
							[System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', "$($_.Protocol)://$($_.Server):$($_.Port)")
						}
			})]
		[String]$Name,

		[Parameter(Mandatory = $false)]
		[Bool]$Persist = $true
	)

	$ContextDirectory = Get-ContextDirectory

	# The named context may still be sitting in a configuration from before contexts existed:
	Convert-LegacyConfiguration

	$ContextFile = Join-Path $ContextDirectory "$Name.json"

	if(-not (Test-Path $ContextFile))
	{
		throw "Context '$Name' not found. Use Get-RadarrContext to list available contexts."
	}

	$script:ActiveContext = $Name

	if($Persist)
	{
		$Name | Set-Content -Path (Join-Path $ContextDirectory 'active') -NoNewline
		Write-Verbose -Message "Function: $($MyInvocation.MyCommand): Active context set to '$Name' and persisted."
	}
	else
	{
		Write-Verbose -Message "Function: $($MyInvocation.MyCommand): Active context temporarily set to '$Name' for this session only."
	}
}
