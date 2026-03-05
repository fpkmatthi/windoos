# Windoos 🧰🪟
**Windoos** (Dutch “doos” = box) is a modular Windows VM baseline builder for red team operator VMs.

It uses:
- **Packer** to build Windows images for **VMware** and **VirtualBox**
- **Profiles** (YAML) that map to **modules**
- Modules implemented in **PowerShell** (idempotent where possible)
- **Chocolatey** for most installs (+ optional GitHub/GitLab release fetching)
- **Pester** for validation

This repo supports **Windows 10 Pro** and **Windows 11 Pro** builds as *user-ready* images (no sysprep generalization by default).

## Prereqs
- Packer (HCL2)
- VMware Workstation/Fusion (or compatible VMware build environment)
- VirtualBox
- A Windows ISO + checksum for:
  - Windows 10 Pro
  - Windows 11 Pro

## Quickstart
1) Edit these files:
- `packer/windows_10.json` (WinRM creds, output dir, VM sizing, ISO URL + checksum)

2) Build Windows 10 Pro (VMware):
```powershell
.\build.sh -p vmware -t windows_10 -p commandovm
```

3) Build Windows 11 Pro (VirtualBox):
```powershell
.\build.sh -p virtualbox -t windows_11 -p operator-standard
```

Artifacts go to `dist/` by default.

## Profiles
Profiles live in `profiles/*.yaml`. They are simple lists of module paths:
- `plain`
- `operator-standard`
- `commandovm` (placeholder module)
- `lab-relaxed-security` (guarded stub, lab-only)

## Notes on “reduced protection” builds
This repo includes a **guarded stub** module under `modules/lab/relaxed-security`.
Keep anything that weakens protections:
- clearly labeled (LAB ONLY)
- opt-in via `LAB_MODE=true`
- out of default CI/publish paths

## Adding a module
Create:
`modules/<category>/<name>/Install.ps1`

Then reference it from a profile YAML under `modules:`.

## License
MIT.
