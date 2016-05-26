# Releasing Tests
We currently have more than 8000 tests which server as our BVT/DRT and more than 90000 tests which cover our 
idx/ri/milestone test runs. The prospect of reviewing all of our nearly 100,000 tests before release in August is not 
something that be considered. However, we can produce a set of tests which can be released which improve our quality

We have 3 distinct categorization of tests:

**Checkin Tests**

    These are tests which ensure that we have a base level of coverage and that basic operation is not regressed. 
    Because these should be run with every push, they should run swiftly and be extremely stable. As a goal, they 
    should not take longer than 20-30 minutes in total to execute. They roughly equate to our BVT/DRT/P1. Our 
    current list of BVT/DRT/P1 is in need of pruning - total execution time for BVT/DRT tests in the lab is roughly
    60 minutes.

**Feature Tests**

    These are tests which completely test a feature, but do not test feature/feature interaction. These tests
    roughly equate  to our current P1/P2 tests. It is expected that a large number of current BVT/DRT/P1 tests
    should actually be feature tests.

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
`[Fact]` attribute. We should also build our own xUnit test runner to reduce the reliance on dotnet cli.

## STEX/LAB Interaction
We currently have nearly 200 workflows covering our BVT through Milestone tests, as we move to a OSS release mechanism this
will become onerous, as there is an expectation that we will continue to 

Since Pester can provide xUnit logs, we should 

The tests need to be grouped logically, so they can be easily found. Rather than having the tests co-located with the source
code (because the sheer number of test artifacts will be rather larger than the source code which will cause difficulty in finding
both *test* and *code*), we will create a file system structure

CommandsAndProviders

    Aliases
    Cmdlets
    Functions
    Infrastructure
    ProviderInfrastructure
    Providers

Scripting

    AdvancedFunctions
    Classes
    Debugging
    LanguageandParser
    ScriptInternationalization (P3)

Engine

    EngineAPIs
    ErrorsandExceptions
    Eventing (P3)
    ExtensibleTypeSystem
    HelpSystem
    Jobs (P3)
    LoggingandTracing (P2)
    Modules
    Multi-CLR (P3)
    ParameterBinding
    PS-CIM (P2)
    Runspace
    SessionState
    SQM (P3)
    Transactions (P3)
    ConsoleHost
    FormatandOutput
    HostInterfaces
    TabCompletion

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


## Interacting with 
At the same time that we are preparing our test artifacts for release, we have the opportunity to reduce the complexity of our 
STEX lab 
