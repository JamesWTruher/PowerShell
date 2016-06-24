Package installation instructions
=================================

To install Open PowerShell from a package, download either the MSI from
[AppVeyor][] for a nightly build, or a released package from our GitHub
[Releases][] page. Once downloaded, double-click the installer and follow the
prompts.

Additionally, we provide APPX/WSA packages (that are compatible on Nano also), but 
these must be self-signed prior to install. See the [`Sign-Package.ps1`][signing] script for details.

[releases]: https://github.com/PowerShell/PowerShell/releases
[signing]: ../../tools/Sign-Package.ps1

Artifact installation instructions
==================================

We publish an archive with CoreCLR and FullCLR bits on every CI build
with [AppVeyor][].

[appveyor]: https://ci.appveyor.com/project/PowerShell/powershell

CoreCLR artifacts
=================

* Download zip package from **artifacts** tab of the particular build.
* Unblock zip file: right-click in file explorer -> properties ->
  check 'Unblock' box -> apply
* Extract zip file to `bin` directory
* `./bin/powershell.exe`

FullCLR artifacts
=================

* Download zip package from **artifacts** tab of the particular build.
* Unblock zip file: right-click in file explorer -> properties ->
  check 'Unblock' box -> apply
* Extract zip file to `$in` directory
* `Start-DevPSGithub -binDir bin`
