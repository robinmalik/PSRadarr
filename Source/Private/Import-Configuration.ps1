function Import-Configuration
{
	<#
		.SYNOPSIS
			Loads the active context into the module-scoped $Config variable.

		.DESCRIPTION
			Every public function calls this before making a request. The active context is resolved by
			Import-Context and stored in $Script:Config, which Invoke-RadarrRequest reads to build the
			URI and headers.

		.NOTES
			This is a private function used internally by other module functions.
	#>

	[CmdletBinding()]
	param(
	)

	try
	{
		$Script:Config = Import-Context -ErrorAction Stop
	}
	catch
	{
		throw $_
	}
}
