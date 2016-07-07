using namespace System.Diagnostics

Describe "Console host tests" -Tags DRT {
    $pathToPS = if ($env:DEVPATH) { $env:DEVPATH } else { $PSHOME }
    $powershell = Join-Path -Path $pathToPS -ChildPath "powershell"

    Context "CommandLine" {
        It "simple -args" {
            & $powershell -noprofile { $args[0] } -args "hello world" | Should Be "hello world"
        }

        It "array -args" {
            & $powershell -noprofile { $args[0] } -args 1,(2,3) | Should Be 1
            (& $powershell -noprofile { $args[1] } -args 1,(2,3))[1]  | Should Be 3
        }
    }

    Context "Pipe to/from powershell" {
        $p = [PSCustomObject]@{X=10;Y=20}

        It "xml input" {
            $p | & $powershell -noprofile { $input | Foreach-Object {$a = 0} { $a += $_.X + $_.Y } { $a } } | Should Be 30
            $p | & $powershell -noprofile -inputFormat xml { $input | Foreach-Object {$a = 0} { $a += $_.X + $_.Y } { $a } } | Should Be 30
        }

        It "text input" {
            # Join (multiple lines) and remove whitespace (we don't care about spacing) to verify we converted to string (by generating a table)
            $p | & $powershell -noprofile -inputFormat text { -join ($input -replace "\s","") } | Should Be "XY--1020"
        }

        It "xml output" {
            & $powershell -noprofile { [PSCustomObject]@{X=10;Y=20} } | Foreach-Object {$a = 0} { $a += $_.X + $_.Y } { $a } | Should Be 30
            & $powershell -noprofile -outputFormat xml { [PSCustomObject]@{X=10;Y=20} } | Foreach-Object {$a = 0} { $a += $_.X + $_.Y } { $a } | Should Be 30
        }

        It "text output" {
            # Join (multiple lines) and remove whitespace (we don't care about spacing) to verify we converted to string (by generating a table)
            -join (& $powershell -noprofile -outputFormat text { [PSCustomObject]@{X=10;Y=20} }) -replace "\s","" | Should Be "XY--1020"
        }
    }

    function NewProcessStartInfo([string]$CommandLine, [switch]$RedirectStdIn)
    {
        return [ProcessStartInfo]@{
            FileName               = $powershell
            Arguments              = $CommandLine
            RedirectStandardInput  = $RedirectStdIn
            RedirectStandardOutput = $true
            RedirectStandardError  = $true
            UseShellExecute        = $false
        }
    }

    function RunPowerShell([ProcessStartInfo]$si)
    {
        $process = [Process]::Start($si)

        return $process
    }

    function EnsureChildHasExited([Process]$process, [int]$WaitTimeInMS = 15000)
    {
        $process.WaitForExit($WaitTimeInMS)

        if (!$process.HasExited)
        {
            $process.HasExited | Should Be $true
            $process.Kill()
        }
    }

    Context "Redirected standard output" {
        It "Simple redirected output" {
            $si = NewProcessStartInfo "-noprofile 1+1"
            $process = RunPowerShell $si
            $process.StandardOutput.ReadToEnd() | Should Be 2
            EnsureChildHasExited $process
        }
    }

    Context "Input redirected but not reading from stdin (not really interactive)" {
        # Tests under this context are testing that we do not read from StandardInput
        # even though it is redirected - we want to make sure we don't hang.
        # So none of these tests should close StandardInput

        It "Redirected input w/ implict -Command w/ -NonInteractive" {
            $si = NewProcessStartInfo "-NonInteractive -noprofile 1+1" -RedirectStdIn
            $process = RunPowerShell $si
            $process.StandardOutput.ReadToEnd() | Should Be 2
            EnsureChildHasExited $process
        }

        It "Redirected input w/ implicit -Command w/o -NonInteractive" {
            $si = NewProcessStartInfo "-noprofile 1+1" -RedirectStdIn
            $process = RunPowerShell $si
            $process.StandardOutput.ReadToEnd() | Should Be 2
            EnsureChildHasExited $process
        }

        It "Redirected input w/ explict -Command w/ -NonInteractive" {
            $si = NewProcessStartInfo "-NonInteractive -noprofile -Command 1+1" -RedirectStdIn
            $process = RunPowerShell $si
            $process.StandardOutput.ReadToEnd() | Should Be 2
            EnsureChildHasExited $process
        }

        It "Redirected input w/ explicit -Command w/o -NonInteractive" {
            $si = NewProcessStartInfo "-noprofile -Command 1+1" -RedirectStdIn
            $process = RunPowerShell $si
            $process.StandardOutput.ReadToEnd() | Should Be 2
            EnsureChildHasExited $process
        }

        It "Redirected input w/ -File w/ -NonInteractive" {
            '1+1' | Out-File -Encoding Ascii -FilePath TestDrive:test.ps1 -Force
            $si = NewProcessStartInfo "-noprofile -NonInteractive -File $testDrive\test.ps1" -RedirectStdIn
            $process = RunPowerShell $si
            $process.StandardOutput.ReadToEnd() | Should Be 2
            EnsureChildHasExited $process
        }

        It "Redirected input w/ -File w/o -NonInteractive" {
            '1+1' | Out-File -Encoding Ascii -FilePath TestDrive:test.ps1 -Force
            $si = NewProcessStartInfo "-noprofile -File $testDrive\test.ps1" -RedirectStdIn
            $process = RunPowerShell $si
            $process.StandardOutput.ReadToEnd() | Should Be 2
            EnsureChildHasExited $process
        }
    }

    Context "Redirected standard input for 'interactive' use" {
        $nl = [Environment]::Newline

        # All of the following tests replace the prompt (either via an initial command or interactively)
        # so that we can read StandardOutput and realiably know exactly what the prompt is.

        It "Interactive redirected input" {
            $si = NewProcessStartInfo "-noprofile -nologo" -RedirectStdIn
            $process = RunPowerShell $si
            $process.StandardInput.Write("`$function:prompt = { 'PS> ' }`n")
            $null = $process.StandardOutput.ReadLine()
            $process.StandardInput.Write("1+1`n")
            $process.StandardOutput.ReadLine() | Should Be "PS> 1+1"
            $process.StandardOutput.ReadLine() | Should Be "2"
            $process.StandardInput.Write("1+2`n")
            $process.StandardOutput.ReadLine() | Should Be "PS> 1+2"
            $process.StandardOutput.ReadLine() | Should Be "3"
            $process.StandardInput.Close()
            $process.StandardOutput.ReadToEnd() | Should Be "PS> "
            EnsureChildHasExited $process
        }

        It "Interactive redirected input w/ initial command" {
            $si = NewProcessStartInfo "-noprofile -noexit ""`$function:prompt = { 'PS> ' }""" -RedirectStdIn
            $process = RunPowerShell $si
            $process.StandardInput.Write("1+1`n")
            $process.StandardOutput.ReadLine() | Should Be "PS> 1+1"
            $process.StandardOutput.ReadLine() | Should Be "2"
            $process.StandardInput.Write("1+2`n")
            $process.StandardOutput.ReadLine() | Should Be "PS> 1+2"
            $process.StandardOutput.ReadLine() | Should Be "3"
            $process.StandardInput.Close()
            $process.StandardOutput.ReadToEnd() | Should Be "PS> "
            EnsureChildHasExited $process
        }

        It "Redirected input explicit prompting (-File -)" {
            $si = NewProcessStartInfo "-noprofile -File -" -RedirectStdIn
            $process = RunPowerShell $si
            $process.StandardInput.Write("`$function:prompt = { 'PS> ' }`n")
            $null = $process.StandardOutput.ReadLine()
            $process.StandardInput.Write("1+1`n")
            $process.StandardOutput.ReadLine() | Should Be "PS> 1+1"
            $process.StandardOutput.ReadLine() | Should Be "2"
            $process.StandardInput.Close()
            $process.StandardOutput.ReadToEnd() | Should Be "PS> "
            EnsureChildHasExited $process
        }

        It "Redirected input no prompting (-Command -)" {
            $si = NewProcessStartInfo "-noprofile -" -RedirectStdIn
            $process = RunPowerShell $si
            $process.StandardInput.Write("1+1`n")
            $process.StandardInput.Close()
            $process.StandardOutput.ReadToEnd() | Should Be "2${nl}"
            EnsureChildHasExited $process
        }

        It "Redirected input w/ nested prompt" {
            $si = NewProcessStartInfo "-noprofile -noexit ""`$function:prompt = { 'PS' + ('>'*(`$nestedPromptLevel+1)) + ' ' }""" -RedirectStdIn
            $process = RunPowerShell $si
            $process.StandardInput.Write("`$host.EnterNestedPrompt()`n")
            $process.StandardOutput.ReadLine() | Should Be "PS> `$host.EnterNestedPrompt()"
            $process.StandardInput.Write("exit`n")
            $process.StandardOutput.ReadLine() | Should Be "PS>> exit"
            $process.StandardInput.Close()
            $process.StandardOutput.ReadToEnd() | Should Be "PS> "
            EnsureChildHasExited $process
        }
    }
}
