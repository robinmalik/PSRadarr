# About

A PowerShell module to help with automation around the Radarr application. Not tested on Linux (yet!).

See the [Changelog](CHANGELOG.md) for a list of changes.

<br>

# Getting Started:

1. Install the module from the PowerShell Gallery: `Install-Module -Name PSRadarr`.
2. Save your Radarr configuration. To use the default protocol of `http` and port of `7878` run:
   ```powershell
   Set-RadarrConfiguration -Server 'myserver.domain.com' -APIKey 'myapikey' -RootFolderPath 'D:\Movies'
   ```
   To use a different protocol or port, run:
   ```powershell
   Set-RadarrConfiguration -Server 'myserver.domain.com' -APIKey 'myapikey' -Protocol 'https' -Port 443
   ```
3. Try a command from the 'Simple Examples' below.

<br>

# Simple Examples:

**Get all movies**:
```powershell
Get-RadarrMovie
```

**Add a movie by IMDB ID**:
```powershell
$Profile = Get-RadarrQualityProfile -Name '720p-webdl'
Add-RadarrMovie -IMDBID 'tt0095016' -QualityProfile $Profile.id
```

**Add a movie by a known IMDBID and initiate a search for it**:
```powershell
$Profile = Get-RadarrQualityProfile -Name '720p-webdl'
Add-RadarrMovie -IMDBID 'tt0095016' -QualityProfile $Profile.id -Search
```

**Search TMDB (via Radarr) for a movie**:
```powershell
Search-RadarrMovie -Name '8-bit Christmas'
```

**Search TMDB (via Radarr) for a movie and add to Radarr using the TMDBID (or IMDBID)**:
```powershell
$MovieRequired = Search-RadarrMovie -Name '8-bit Christmas' -ExactMatch
$Profile = Get-RadarrQualityProfile -Name '720p-webdl'
Add-RadarrMovie -TMDBID $MovieRequired.tmdbId -QualityProfile $Profile.id
```
or
```powershell
Add-RadarrMovie -IMDBID $MovieRequired.imdbId -QualityProfile $Profile.id
```



**Set the monitor status to $False for an existing movie**:
```powershell
$Movie = Get-RadarrMovie -Title '8-bit Christmas'
Set-RadarrMovie -Movie $Movie.id -Monitor $False
```

# Known Issues

* Does not cater to multiple instances yet.
