function Get-ContextDirectory
{
	<#
		.SYNOPSIS
			Returns the path to the context directory.

		.DESCRIPTION
			Returns the path to the directory that named contexts are stored in: $HOME/.PSRadarr/Contexts.

			Contexts live in their own subdirectory rather than directly in $HOME/.PSRadarr so that they
			cannot be confused with the legacy PSRadarrConfig.json file, or with any manual copies of it,
			that sit alongside.

		.NOTES
			This is a private function used internally by other module functions.
	#>

	[CmdletBinding()]
	[OutputType([String])]
	param()

	$ModuleName = $MyInvocation.MyCommand.ModuleName
	Join-Path (Join-Path $HOME ".$ModuleName") 'Contexts'
}
