## [1.0.0] - 2026-07-28

- 💥 [Breaking] `Set-RadarrConfiguration`, `Set-RadarrDefaultServer` and `Get-RadarrDefaultServer` have been removed in favour of the context functions. Existing `PSRadarrConfig.json` files are migrated to named contexts automatically on first use; the old file is left in place for you to delete.
- ✨ [New] `Save-RadarrContext`, `Get-RadarrContext`, `Select-RadarrContext`, `Remove-RadarrContext` - Named contexts replace the single configuration file. A context is identified by a name of your choosing rather than by its server name, so multiple Radarr instances on the same host (differing only by port) can now be saved and switched between.
- ✨ [New] Almost everything else in the module is new/rewritten, attempting to align the module more closely with `PSSonarr`.

## [0.0.1] - 2024-12-24

- 🎉 A very quick, initial release!