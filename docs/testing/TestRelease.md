# Releasing Tests
We currently have more than 8000 tests which server as our BVT/DRT and more than 90000 tests which make up our 
idx/ri/milestone tests. The prospect of reviewing all of our nearly 100,000 tests before release in August is not 
something that be considered. However, we can produce a set of tests which can be released which help us better
measure quality.

We should have 3 distinct categorization of tests:

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

for xUnit tests, we need to create similar custom attributes which can then be applied as substitutes for the
`[Fact]` attribute. We should also create our own xUnit test runner to reduce the reliance on dotnet cli (which
seems a bit buggy).

## Prioritization ##
Since we know that we cannot possibly release all of our tests by Aug17, we need to focus our efforts on the best
ROI. I believe those to be our cmdlets, providers, and our language. Our cmdlets and providers because that's what
our customers will use after they've written `"hello world"` and `1 + 1 -eq 2` and the risk in behavioral changes
between full PS and core is not yet fully known. We need to be sure that our language is consistent a
### Minimum Viable
In order to release a minimally viable set of tests for Aug17, I suggest prioritization as follows, where we deliver only
CI and Feature tests for the following areas. 

CommandsAndProviders

    Aliases (P0)
    Cmdlets (P0)
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


## Interacting with STEX 
At the same time that we are preparing our test artifacts for release, we have the opportunity to reduce the complexity of our 
STEX lab 
We currently have nearly 200 workflows covering our BVT through Milestone tests, as we move to a OSS release mechanism this
will become onerous, as there is an expectation that we will continue to support releases via Windows as well as via GitHub,
NuGet, etc. We should reduce the number of our STEX workflows and simplify the STEX setup to mimic our CI system. This means
that our setup workflows in STEX would clone the sources and run them in place. We would replace the current `installproject.ps1`
logic

Since Pester can provide xUnit logs, we should 

The tests need to be grouped logically, so they can be easily found. Rather than having the tests co-located with the source
code (because the sheer number of test artifacts will be rather larger than the source code which will cause difficulty in finding
both *test* and *code*), we will create a file system structure

