function Remove-RadarrContext
{
	<#
		.SYNOPSIS
			Removes a saved context.

		.DESCRIPTION
			This function removes a saved context from disk and/or from session memory.

		.PARAMETER Name
			The name of the context to remove. Tab-completion is supported.

		.EXAMPLE
			Remove-RadarrContext -Name 'radarr4k'

		.NOTES
			Use Get-RadarrContext to list the available contexts.
	#>

	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
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
		[String]$Name
	)

	$ContextDirectory = Get-ContextDirectory
	$ContextFile = Join-Path $ContextDirectory "$Name.json"
	$ActiveFile = Join-Path $ContextDirectory 'active'

	# A context may exist on disk (persisted) and/or in memory (an ephemeral context saved with -Persist $false)
	$OnDisk = Test-Path $ContextFile
	$InMemory = ($script:ActiveContext -is [PSCustomObject]) -and ($script:ActiveContext.Name -eq $Name)

	if(-not $OnDisk -and -not $InMemory)
	{
		Write-Error "Context '$Name' not found. Use Get-RadarrContext to list available contexts."
		return
	}

	# $PSCmdlet.ShouldProcess automatically handles -WhatIf and -Confirm prompts
	if($PSCmdlet.ShouldProcess("$Name.json", "Remove context '$Name'"))
	{
		# Delete the context file (only present for persisted contexts)
		if($OnDisk)
		{
			Remove-Item -Path $ContextFile -Force
			Write-Verbose -Message "Function: $($MyInvocation.MyCommand): Context file '$Name.json' removed."
		}

		# Housekeeping: If the deleted context is currently active in the session, clear it.
		# $script:ActiveContext may be an ephemeral context object (PSCustomObject) or a selected context name (string).
		if($InMemory -or ($script:ActiveContext -eq $Name))
		{
			$script:ActiveContext = $null
			Write-Verbose -Message "Function: $($MyInvocation.MyCommand): Cleared active context session variable."
		}

		# Housekeeping: If the deleted context was the persisted default, remove the active file
		if(Test-Path $ActiveFile)
		{
			$PersistedActive = (Get-Content $ActiveFile -Raw).Trim()
			if($PersistedActive -eq $Name)
			{
				Remove-Item -Path $ActiveFile -Force
				Write-Verbose -Message "Function: $($MyInvocation.MyCommand): Persisted active context file cleared."
			}
		}
	}
}
