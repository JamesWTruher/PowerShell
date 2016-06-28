![PowerShell Logo](assets/Powershell_64.png) PowerShell
========================

PowerShell is a task automation and configuration management platform,
consisting of a command-line shell and associated scripting language built
using the [.NET Command Line Interface](https://github.com/dotnet/cli).
PowerShell provides full access to COM and WMI, enabling administrators to
automate administrative tasks on both local and remote Windows, Linux and OS X systems.

New to PowerShell?
------------------
If you are new to PowerShell and would like to learn more, we recommend
reviewing the [getting started documentation][getting-started].

[getting-started]: https://msdn.microsoft.com/en-us/powershell/scripting/getting-started/getting-started-with-windows-powershell

Build Status
------------

| Platform     | `master` |
|--------------|----------|
| Ubuntu 14.04 | [![Build Status](https://travis-ci.com/PowerShell/PowerShell.svg?token=31YifM4jfyVpBmEGitCm&branch=master)](https://travis-ci.com/PowerShell/PowerShell) |
| OS X 10.11   | [![Build Status](https://travis-ci.com/PowerShell/PowerShell.svg?token=31YifM4jfyVpBmEGitCm&branch=master)](https://travis-ci.com/PowerShell/PowerShell) |
| Windows      | [![Build status](https://ci.appveyor.com/api/projects/status/jtefab3hpngtyesp/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/powershell/branch/master) |

Get PowerShell
--------------

|                       | Linux | Windows .NET Core | Windows .NET Full | OS X | PSRP |
|-----------------------|-------|-------------------|-------------------|------|------|
| Build from **Source** | [Instructions][build-linux] | [Instructions][build-wc] | [Instructions][build-wf] | [Instructions][build-osx] | [Instructions][pls-omi-provider] |
| Get **Binaries**      | [Releases][releases] | [Releases][releases] | [Artifacts][artifacts] | [Releases][releases] | TBD |

If installing PowerShell from a package, please refer to the installation
documents for [Linux][inst-linux] and [Windows][inst-win].

[releases]: https://github.com/PowerShell/PowerShell/releases
[artifacts]: https://ci.appveyor.com/project/PowerShell/powershell/build/artifacts
[build-wc]: docs/building/windows-core.md
[build-wf]: docs/building/windows-full.md
[build-osx]: docs/building/osx.md
[build-linux]: docs/building/linux.md
[pls-omi-provider]: https://github.com/PowerShell/psl-omi-provider
[inst-linux]: docs/installation/linux.md
[inst-win]: docs/installation/windows.md

Developing and Contributing
--------------------------
If you are new to Git, we recommend you start by reviewing our
[Git basics document][git-basics] where you will find Git installation
instructions, cheat sheets and links to our favorite Git tutorials. We also
recommend, reviewing an example of a [basic Git commit walkthrough][git-commit].

To begin development, you'll need to setup your development environment for
either [Linux][build-linux], [Windows Core][build-wc], [Windows Full][build-wf] or
[OS X][build-osx] and are encouraged to review the
[contribution guidelines][contribution] for specific workflow, test
requirements and coding guidelines.

If you encounter issues, please consult the [known issues][known-issues]
and [FAQ][faq] documents to see if the issue you are running into is
captured and if a workaround exists.  

If do not see your issue captured, please file a [new issue][new-issue] using
the appropriate issue tag.

[git-basics]: docs/git/basics.md
[git-commit]: docs/git/committing.md
[contribution]: .github/CONTRIBUTING.md
[known-issues]: docs/KNOWNISSUES.md
[faq]: docs/FAQ.md
[new-issue]:https://github.com/PowerShell/PowerShell/issues/new


PowerShell Community
--------------------
`TODO` Missing community details

Legal and Licensing
-------------------

`TODO` Missing license details

`TODO` Missing link to contributor agreement

Code of Conduct
---------------

This project has adopted the
[Microsoft Open Source Code of Conduct][conduct-code]. For more information see
the [Code of Conduct FAQ][conduct-faq] or contact
[opencode@microsoft.com][conduct-email] with any additional questions or
comments.

[conduct-code]: http://opensource.microsoft.com/codeofconduct/
[conduct-FAQ]: http://opensource.microsoft.com/codeofconduct/faq/
[conduct-email]: mailto:opencode@microsoft.com
