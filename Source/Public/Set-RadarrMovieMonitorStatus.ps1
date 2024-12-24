function Set-RadarrMovieMonitorStatus
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Id,

        [Parameter(Mandatory = $true)]
        [bool]$Monitor
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
    #Region Get the movie from Radarr
    Write-Verbose -Message "Getting movie"
    try
    {
        $Movie = Get-RadarrMovie -Id $Id -ErrorAction Stop
        if(!$Movie)
        {
            throw "Movie with ID $Id not found. We cannot modify this."
        }
    }
    catch
    {
        throw $_
    }
    #EndRegion


    ####################################################################################################
    #Region Compare monitor status to user submitted status
    if($Monitor -eq $Movie.monitored)
    {
        Write-Warning -Message "Monitor status is already set to $Monitor"
        return
    }
    else
    {
        Write-Verbose -Message "Setting monitor status to $Monitor"
        $Movie.monitored = $Monitor
    }
    #EndRegion


    ####################################################################################################
    #Region Define the path, parameters, headers and URI
    try
    {
        $Path = '/movie/' + $Id
        $Uri = Get-APIUri -RestEndpoint $Path
        $Headers = Get-Headers
        $global:UpdateJSON = $Movie | ConvertTo-Json -Depth 5
        $DataEncoded = ([System.Text.Encoding]::UTF8.GetBytes($UpdateJSON))
    }
    catch
    {
        throw $_
    }
    #EndRegion


    ####################################################################################################
    #Region make the main request
    Write-Verbose "Updating: $Uri"
    try
    {
        $UpdateResult = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Put -ContentType "application/json" -Body $DataEncoded -ErrorAction Stop
        if($UpdateResult)
        {
            return $UpdateResult
        }
        else
        {
            Write-Verbose -Message 'No update result.'
            return
        }
    }
    catch
    {
        throw $_
    }
    #EndRegion
}