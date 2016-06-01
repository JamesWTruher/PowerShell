# Releasing Tests
We currently have more than 8000 tests which server as our BVT/DRT and more than 90000 tests which make up our 
idx/ri/milestone tests. The prospect of reviewing all of our nearly 100,000 tests before release in August is not 
something that be considered. However, we can produce a set of tests which can be released which help us better
measure quality.

We need have 3 distinct categorization of tests:

**Checkin Tests**

    These are tests which ensure that we have a base level of coverage and that basic operation is not regressed. 
    Because these should be run with every push, they should run swiftly and be extremely stable. As a goal, they 
    should not take longer than 20-30 minutes in total to execute. This category roughly equates to our BVT/DRT/P1
    tests. Our current list of BVT/DRT/P1 is in need of pruning - total execution time for BVT/DRT tests in the lab
    takes about 60 minutes.

**Feature Tests**

    These are tests which completely test a feature, but do not test feature/feature interaction. These tests
    roughly equate  to our current P1/P2 tests. It is expected that a large number of current BVT/DRT/P1 tests
    should actually be feature tests. These tests should be run regularly and should not take more than 4 hours.

**End-To-End Scenario Tests**

    These tests test feature-to-feature interaction, or complete end-to-end scenarios. They roughly equate to our
    current P3 test library. These should have no time limit

## Authoring ##
During the authoring process, the tests should be tagged with the category of test. For Pester, one of three tags should be used:

| TAG     | PURPOSE             |
| ------- | ------------------- |
| CI      | Check in Test       |
| FEATURE | Feature Test        |
| E2E     | End-to-End Scenario |

If a test should not be run on a specific platform, those tests should be skipped. Skipping a test should be done based on Special Variables available on the platform and the `-skip` parameter for the It block

| Variable Name | Platform               |
| ------------- | ---------------------- |
| IsOSX         | Mac                    |
| IsWindows     | Windows (full)         |
| IsLinux       | Linux                  |
| IsCore        | PowerShell on CoreCLR  |

### Composing a Pester Test ###
The following are examples of Pester tests which are specific to platform and/or category
```
Describe "This is a test" {
    It "this is a test which runs on Linux and part of CI" -Tags CI -skip:(! $IsLinux) {
       1 | should be 1
    }
}
```

Pester does not have a mechanism for skipping a block of tests, but that can be done via setting 
`$PSDefaultParameterValues`, the following example shows how multiple tests may be skipped in a describe
block.
```
Describe "No run on Linux" {
    BeforeAll {
        # skip tests on Linux
        if ( $IsLinux ) { $psdefaultparametervalues["It:skip"] = $true }
    }
    AfterAll { $psdefaultparametervalues.Remove("It:skip") }
    It "Test 1" {
        1 | should be 1
    }
    It "Test 2" {
        1 | should be 1
    }
}

Describe "No run on windows" {
    BeforeAll {
        # skip tests on Windows
        if ( $IsWindows ) { $psdefaultparametervalues["It:skip"] = $true }
    }
    AfterAll { $psdefaultparametervalues.remove("It:skip") }
    It "Test 1" {
        1 | should be 1
    }
    It "Test 2" {
        1 | should be 1
    }
}
```
when run, if $IsWindows is true, the tests will be skipped:
```
PS> $IsWindows = $true
PS> invoke-pester .\t3.tests.ps1
Describing No run on Linux
 [+] Test 1 44ms
 [+] Test 2 21ms
Describing No run on windows
 [!] Test 1 25ms
 [!] Test 2 8ms
Tests completed in 99ms
Passed: 2 Failed: 0 Skipped: 2 Pending: 0 Inconclusive: 0
```

for xUnit tests, we need to create similar custom attributes which can then be applied as substitutes for the
`[Fact]` attribute. We should also create our own xUnit test runner to reduce the reliance on dotnet cli (which
seems a bit buggy). For platform exclusion, these should be done via `#if` in the xunit test source.

## Prioritization ##
Since we know that we cannot possibly release all of our tests by Aug17, we need to focus our efforts on the best
ROI. I believe those to be our cmdlets, providers, and our language. Our cmdlets and providers because that's what
our customers will use the most, and where the risk is highest. We have already a large number of powershell scripts
running on core which provide some level of confidence about the base language elements, but changes between 
CORECLR and FullCLR may produce subtle changes which must be found.

### Minimum Viable
In order to release a minimally viable set of tests for Aug17, I suggest prioritization as follows, where we deliver only
CI and Feature tests for the following areas and for priority P0 only. 

CommandsAndProviders

    Aliases (P0)
    Cmdlets (P0) *focus only on those cmdlets which are being delivered*
    Functions (P0)
    Infrastructure (P1)
    ProviderInfrastructure (P1)
    Providers (P0)

Scripting

    AdvancedFunctions (P0)
    Classes (P0)
    Debugging (P0)
    LanguageandParser (P0)
    ScriptInternationalization (P3)

Engine

    EngineAPIs (P2)
    ErrorsandExceptions (P1)
    Eventing (P3)
    ExtensibleTypeSystem (P1)
    HelpSystem (P2)
    Jobs (P3)
    LoggingandTracing (P2)
    Modules (P0)
    Multi-CLR (P3)
    ParameterBinding
    PS-CIM (P2)
    Runspace
    SessionState
    SQM (P3)
    Transactions (P3)
    ConsoleHost 
    FormatandOutput (P2)
    HostInterfaces (P2)
    TabCompletion (P0)

QualityCriteria

    Coverage (P3)
    FxCop (P3)
    Performance

Remoting

    Cmdlets (P2)
    Infrastructure (P2)
    NamedPipeTransport (P2)
    Serialization (P2)

Security

     Cmdlets (P2)
     Signing Infrastructure (P3)

## Interacting with STEX 
At the same time that we are preparing our test artifacts for release, we have the opportunity to reduce the complexity of our 
STEX lab 
We currently have nearly 200 workflows covering our BVT through Milestone tests, as we move to a OSS release mechanism this
will become onerous, as there is an expectation that we will continue to support releases via Windows as well as via GitHub,
NuGet, etc. We should reduce the number of our STEX workflows and simplify the STEX setup to mimic our CI system. This means
that our setup workflows in STEX would clone the sources and run them in place. We would replace the current `installproject.ps1`
logic

Since Pester can provide xUnit logs, we should 

The tests need to be easily executed and easily found which implies logical grouping. Rather than having the tests co-located with the source code (because the sheer number of test artifacts will be rather larger than the source code which will cause difficulty in finding both *test* and *code*), we will create a file system structure which provides both an easy way to locate a test and 
then execute it.

# Running Tests #
It will not be possible to migrate our compendium of tests to github in time for an Aug17 release, or even 
migrate a substantial portion of our BVT tests to be release on Aug17, but we will still need a way take contributions
from the community and assess the quality of those submissions. We cannot rely on our CI system to do any but the
most rudamentary checking, we need to find a way to validate submissions against our larger test base.

I suggest that we follow the current process that we have for taking changes in Git back to SD and then run our full tests 
against private builds. I propose the following:

    1 A private enlistment is created 
    2 The private changes from Git are applied onto that enlistment
    3 A full build is created
        1 if that full build fails, we should reject the PR
    4 5 nebula systems should be reserved for test and the private build installed on them
        1 WTT client must be installed on the system as we will be using our current lab
    5 each system will have one test workflow executed on it, for each of the test types we currently have (BVT/DRT/FEATURE/RI/Milestone)
