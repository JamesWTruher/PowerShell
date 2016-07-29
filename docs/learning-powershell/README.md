Learning PowerShell
====

Whether you're a Developer, a DevOps Professional or an IT Professional, this doc will help you getting started with PowerShell.
In this document we'll cover the following:
installing PowerShell, samples walkthrough, PowerShell editor, debugger, testing tools and a map book for experienced bash users to get started with PowerShell faster.

The exercises in this document are intended to give you a solid foundation in how to use PowerShell.
You won't be a PowerShell guru at the end of reading this material but you will be well on your way with the right set of knowledge to start using PowerShell.

If you have 30 minutes now, let’s try it.


Installing PowerShell
----

First you need to set up your computer working environment if you have not done so.
Choose the platform below and follow the instructions.
At the end of this exercise, you should be able to launch the PowerShell session.

- Get PowerShell by installing package
 * [PowerShell on Linux][inst-linux]
 * [PowerShell on OS X][inst-linux]
 * PowerShell on Windows

  For this tutorial, you do not need to install PowerShell if you are running on Windows.
  You can launch PowerShell console by pressing Windows key, typing PowerShell, and clicking on Windows PowerShell.
  However if you want to try out the latest PowerShell, follow the [PowerShell on Windows][inst-win].

- Alternatively you can get the PowerShell by [building it](../../README.md#building-powershell)

[inst-linux]: ../installation/linux.md
[inst-win]: ../installation/windows.md

Getting Started with PowerShell
----
PowerShell commands follow a Verb-Noun semantic with a set of parameters.
It's easy to learn and use PowerShell.
For example, `Get-Process` will display all the running processes on your system.
Let's walk through with a few examples from the [PowerShell Beginner's Guide](powershell-beginners-guide.md).

Now you have learned the basics of PowerShell.
Please continue reading if you want to do some development work in PowerShell.

PowerShell Editor
----

In this section, you will create a PowerShell script using a text editor.
You can use your favorite editor to write scripts.
We use Visual Studio Code (VS Code) which works on Windows, Linux, and OS X.
Click on the following link to create your first PowerShell script.

- [Using Visual Studio Code (VS Code)][use-vscode-editor]

On Windows, you can also use [PowerShell Integrated Scripting Environment (ISE)][use-ise-editor] to edit PowerShell scripts.

[use-vscode-editor]:./using-vscode.md#editing-with-vs-code
[use-ise-editor]:./using-ise.md#editing-with-ise

PowerShell Debugger
----

Debugging can help you find bugs and fix problems in your PowerShell scripts.
Click on the link below to learn more about debugging:

- [Using Visual Studio Code (VS Code)][use-vscode-debugger]
- [PowerShell Command-line Debugging][cli-debugging]

On Windows, you can also use  [ISE][use-ise-debugger] to debug PowerShell scripts.

[use-vscode-debugger]:./using-vscode.md#debugging-with-vs-code
[use-ise-debugger]:./using-ise.md#debugging-with-ise
[cli-debugging]:./debugging-from-commandline.md


PowerShell Testing
----

We recommend using Pester testing tool which is initiated by the PowerShell Community for writing test cases.
To use the tool please read [ Pester Guides](https://github.com/pester/Pester) and [Writing Pester Tests Guidelines](https://github.com/PowerShell/PowerShell/blob/master/docs/testing-guidelines/WritingPesterTests.md).


Map Book for Experienced Bash users
----

TODO: Don & JP to fill in

| Bash           | PowerShell    | Description     |
|:---------------|:--------------|:----------------|
| ls             |dir            |List files and folders
| cd             |cd             |Change directory
| mkdir          |mkdir          |Create a new folder
| Clear, Ctrl+L, Reset | cls | Clear screen


Recommended Training and Reading
----
- Microsoft Virtual Academy: [Getting Started with PowerShell][getstarted-with-powershell]
- [Why Learn PowerShell][why-learn-powershell] by Ed Wilson
- PowerShell Web Docs: [Basic cookbooks][basic-cookbooks]
- [PowerShell eBook][ebook-from-powershell.com] from PowerShell.com
- [PowerShell-related Videos][channel9-learn-powershell] on Channel 9
- [Learn PowerShell Video Library][powershell.com-learn-powershell] from PowerShell.com
- [PowerShell Quick Reference Guides][quick-reference] by PowerShellMagazine.com
- [PowerShell 5 How-To Videos][script-guy-how-to] by Ed Wilson


Commercial Resources
----
- [Windows PowerShell in Action][in-action] by Bruce Payette
- [Introduction to PowerShell][powershell-intro] from Pluralsight
- [PowerShell Training and Tutorials][lynda-training] from Lynda.com


[in-action]: https://www.amazon.com/Windows-PowerShell-Action-Second-Payette/dp/1935182137
[powershell-intro]: https://www.pluralsight.com/courses/powershell-intro
[lynda-training]: https://www.lynda.com/PowerShell-training-tutorials/5779-0.html

[getstarted-with-powershell]: https://channel9.msdn.com/Series/GetStartedPowerShell3
[why-learn-powershell]: https://blogs.technet.microsoft.com/heyscriptingguy/2014/10/18/weekend-scripter-why-learn-powershell/
[basic-cookbooks]: https://msdn.microsoft.com/en-us/powershell/scripting/getting-started/basic-cookbooks
[ebook-from-powershell.com]: http://powershell.com/cs/blogs/ebookv2/default.aspx
[channel9-learn-powershell]: https://channel9.msdn.com/Search?term=powershell#ch9Search
[powershell.com-learn-powershell]: http://powershell.com/cs/media/14/default.aspx
[quick-reference]: http://www.powershellmagazine.com/2014/04/24/windows-powershell-4-0-and-other-quick-reference-guides/
[script-guy-how-to]:https://blogs.technet.microsoft.com/tommypatterson/2015/09/04/ed-wilsons-powershell5-videos-now-on-channel9-2/
