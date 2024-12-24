function Get-RadarrMovie
{
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = 'Id')]
        [String]$Id,

        [Parameter(Mandatory = $false, ParameterSetName = 'Name')]
        [Alias('Title')]
        [String]$Name,

        [Parameter(Mandatory = $false, ParameterSetName = 'IMDBID')]
        [ValidatePattern('^(tt)?\d{5,9}$')]
        [String]$IMDBID,

        [Parameter(Mandatory = $false, ParameterSetName = 'TMDBID')]
        [ValidatePattern('^\d{1,9}$')]
        [String]$TMDBID
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
    # If using IMDB, ensure the ID is in the correct format
    if($ParameterSetName -eq 'IMDBID' -and $IMDBID -notmatch '^tt')
    {
        $IMDBID = 'tt' + $IMDBID
    }


    ####################################################################################################
    #Region Define the path, parameters, headers and URI
    try
    {
        $Path = '/movie'
        if($PSCmdlet.ParameterSetName -eq 'Id' -and $Id)
        {
            $Path += "/$Id"
        }

        # Generate the headers and URI
        $Headers = Get-Headers
        $Uri = Get-APIUri -RestEndpoint $Path -Params $Params
    }
    catch
    {
        throw $_
    }
    #EndRegion


    ####################################################################################################
    #Region make the main request
    Write-Verbose "Querying: $Uri"
    try
    {
        $Data = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Get -ContentType 'application/json' -ErrorAction Stop
        if($Data)
        {
            # Filter results based on parameters if specified
            switch($PSCmdlet.ParameterSetName)
            {
                'Name'
                {
                    $Data = $Data | Where-Object { $_.title -eq $Name -or $_.originalTitle -eq $Name }
                }
                'IMDBID'
                {
                    $Data = $Data | Where-Object { $_.imdbId -eq "$IMDBID" }
                }
                'TMDBID'
                {
                    $Data = $Data | Where-Object { $_.tmdbId -eq $TMDBID }
                }
            }

            return $Data
        }
        else
        {
            Write-Warning 'No results found. Does Radarr have any movies?'
            return
        }
    }
    catch
    {
        throw $_
    }
    #EndRegion
}