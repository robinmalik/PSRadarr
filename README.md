# About

A PowerShell module to help with automation around the Radarr application. Similar to [PSSonarr](https://github.com/robinmalik/PSSonarr), which does the same for Sonarr.

See the [Changelog](CHANGELOG.md) for a list of changes.

<br>

# Getting Started:

1. Install the module from the PowerShell Gallery:
    ```powershell
    Install-PSResource -Name PSRadarr
    ```
2. Save a context. A context is a named set of connection settings for one Radarr instance. To use the default protocol of `http` and port of `7878` run:
   ```powershell
   Save-RadarrContext -Name 'radarr' -Server 'myserver.domain.com' -APIKey 'myapikey' -RootFolderPath 'D:\Movies'
   ```
   To use a different protocol or port, run:
   ```powershell
   Save-RadarrContext -Name 'radarr' -Server 'myserver.domain.com' -APIKey 'myapikey' -RootFolderPath 'D:\Movies' -Protocol 'https' -Port 443
   ```
   The first context you save becomes the active one, and all commands use the active context. See [Context System](#context-system) below for switching between multiple instances.
3. Try a command from the 'Examples by Action' below.

> If you used `Set-RadarrConfiguration` in an earlier version, your servers are migrated to named contexts automatically the first time you run a command. Run `Get-RadarrContext` to check them, then delete `$HOME/.PSRadarr/PSRadarrConfig.json`.

<br>

# Context System:

Every command talks to whichever context is currently active. A context is identified by a name of your choosing rather than by its server, so several Radarr instances on the same host (differing only by port) can be saved alongside each other.

**Save a context per instance:**
```powershell
Save-RadarrContext -Name 'movies'   -Server 'myserver.domain.com' -Port 7878 -APIKey 'abc123' -RootFolderPath '/storage/Movies'
Save-RadarrContext -Name 'movies4k' -Server 'myserver.domain.com' -Port 7879 -APIKey 'xyz789' -RootFolderPath '/storage/Movies4K'
```

**List contexts** (`*` marks the active one):
```powershell
Get-RadarrContext
```

**Switch context** (tab-completion is supported for `-Name`):
```powershell
Select-RadarrContext -Name movies4k
```

**Switch for the current session only**, leaving the persisted default untouched:
```powershell
Select-RadarrContext -Name movies4k -Persist $false
```

**Save a context in memory only**, writing nothing to disk (useful in CI):
```powershell
Save-RadarrContext -Name 'ci' -Server 'radarr' -APIKey $env:RADARR_API_KEY -RootFolderPath '/storage/Movies' -Persist $false
```

**Remove a context**:
```powershell
Remove-RadarrContext -Name movies4k
```

Contexts are stored as JSON in `$HOME/.PSRadarr/Contexts`. The API key is stored in plain text so that contexts remain portable between machines and containers - anyone able to read that directory can read the key.

<br>

# Examples by Action:

## Movie Management

**Get all movies:**
```powershell
Get-RadarrMovie
```

**Get a movie by IMDB or TMDB ID:**
```powershell
Get-RadarrMovie -IMDBID 'tt1375666'
Get-RadarrMovie -TMDBID '27205'
```

**Search TMDB (via Radarr) for a movie that isn't in the library yet:**
```powershell
Find-RadarrMovie -Name '8-bit Christmas'
```

**Add a movie by IMDB ID:**
```powershell
$Profile = Get-RadarrQualityProfile -Name '720p-webdl'
Add-RadarrMovie -IMDBID 'tt0095016' -QualityProfileId $Profile.id
```

**Add a movie and initiate a search for it immediately:**
```powershell
$Profile = Get-RadarrQualityProfile -Name '720p-webdl'
Add-RadarrMovie -IMDBID 'tt0095016' -QualityProfileId $Profile.id -Search
```

**Add a movie without monitoring it, and only once it has been released:**
```powershell
$Profile = Get-RadarrQualityProfile -Name '720p-webdl'
Add-RadarrMovie -IMDBID 'tt0095016' -QualityProfileId $Profile.id -Monitored $false -MinimumAvailability 'released'
```

**Search TMDB for a movie and add it using the returned TMDBID (or IMDBID):**
```powershell
$MovieRequired = Find-RadarrMovie -Name '8-bit Christmas' -ExactMatch
$Profile = Get-RadarrQualityProfile -Name '720p-webdl'
Add-RadarrMovie -TMDBID $MovieRequired.tmdbId -QualityProfileId $Profile.id
```

**Set the monitor status for an existing movie:**
```powershell
$Movie = Get-RadarrMovie -Name '8-bit Christmas'
Set-RadarrMovieStatus -Id $Movie.id -Monitored $false
```

**Change the quality profile for an existing movie:**
```powershell
$Profile = Get-RadarrQualityProfile -Name '1080p'
Get-RadarrMovie -Name 'Inception' | Set-RadarrMovieQualityProfile -QualityProfileId $Profile.id
```

**Search for a movie already in the library:**
```powershell
Invoke-RadarrMovieSearch -Id 123
```

**Search for everything that is monitored but missing:**
```powershell
Get-RadarrMovie | Where-Object { $_.monitored -and -not $_.hasFile } | Invoke-RadarrMovieSearch
```

**Refresh a movie's metadata and rescan its folder on disk:**
```powershell
Invoke-RadarrMovieRefresh -Name 'Inception'
```

**Get file-level detail (quality, size, release group) for what's on disk:**
```powershell
Get-RadarrMovie -Name 'Inception' | Get-RadarrMovieFile | Select-Object relativePath, @{n='SizeGB';e={[math]::Round($_.size/1GB,2)}}, @{n='Quality';e={$_.quality.quality.name}}
```

**Remove a movie, deleting its files and excluding it from future imports:**
```powershell
Remove-RadarrMovie -Id 123 -DeleteFiles -AddImportExclusion
```

**Get movies releasing in the next 30 days:**
```powershell
Get-RadarrUpcomingMovies
```

**Get movies releasing in a specific window, including unmonitored ones:**
```powershell
Get-RadarrUpcomingMovies -StartDate (Get-Date) -EndDate (Get-Date).AddDays(90) -IncludeUnmonitored
```

## Quality Profile Management

**Get all quality profiles, or a specific one by name:**
```powershell
Get-RadarrQualityProfile
Get-RadarrQualityProfile -Name '720p-webdl'
```

**See the quality names available to build a profile from:**
```powershell
Get-RadarrQualityDefinition | Sort-Object weight | Select-Object quality, weight
```

**Create a new quality profile:**
```powershell
New-RadarrQualityProfile -Name 'HD' -AllowedQualities 'WEBDL-720p', 'WEBDL-1080p' -Cutoff 'WEBDL-1080p' -UpgradeAllowed
```

**Remove a quality profile:**
```powershell
Get-RadarrQualityProfile -Name 'SD Only' | Remove-RadarrQualityProfile
```

## Queue Management

**See what is downloading:**
```powershell
(Get-RadarrQueue).records | Select-Object title, status, timeleft
```

**Include downloads that don't match any known movie:**
```powershell
(Get-RadarrQueue -IncludeUnknownMovieItems).records
```

## Root Folder Management

**List root folders and their free space:**
```powershell
Get-RadarrRootFolder | Select-Object path, @{n='FreeSpaceGB';e={[math]::Round($_.freeSpace/1GB,2)}}
```

## Indexer Management

**List configured indexers:**
```powershell
Get-RadarrIndexer
```

**Find indexers excluded from automatic search:**
```powershell
Get-RadarrIndexer | Where-Object { -not $_.enableAutomaticSearch }
```

## System Management

**Check the instance is reachable, and look for problems:**
```powershell
(Get-RadarrSystem).version
Get-RadarrHealth
```

<br>

# Known Issues

* None currently.
