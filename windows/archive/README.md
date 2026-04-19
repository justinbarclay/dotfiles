# Archived Windows bootstrap files

These files predate the WinGet DSC setup and are kept for historical reference only.

| File | Replaced by |
|------|-------------|
| `bootstrap.nu` | `windows/setup.winget` (DSC script resources) |
| `winget.json` | `windows/setup.winget` (`WinGetPackage` resources) |

The active bootstrap is now:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\windows\bootstrap.ps1
```

Which calls `winget configure -f windows\setup.winget` declaratively.
