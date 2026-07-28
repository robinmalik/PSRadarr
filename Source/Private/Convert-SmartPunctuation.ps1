function Convert-SmartPunctuation
{
	<#
		.SYNOPSIS
			Aims to replace some comment smart characters with their ASCII equivalents.

		.DESCRIPTION
			Aims to replace some comment smart characters with their ASCII equivalents.
			This file needs BOM encoding in order to correctly 'store' the smart characters.

		.PARAMETER String
			The string to clean

		.EXAMPLE
			Convert-SmartPunctuation "This is a ‘test’"
			Outputs: This is a 'test'
	#>
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory = $true, Position = 0)]
		[String]$String
	)

	Begin
	{
	}
	Process
	{
		$String = $String -replace "’", "'"
		$String = $String -replace "‘", "'"
		$String = $String -replace '“', '"'
		$String = $String -replace '”', '"'
		$String = $String -replace '–', '-'
		return $string
	}
	End
	{
	}
}
