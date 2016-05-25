# Releasing Tests
We currently have more than 8000 tests which server as our BVT/DRT and more than 90000 tests which cover our 
idx/ri/milestone test runs. The prospect of reviewing all of our nearly 100,000 tests before release in August is not 
something that be considered. However, we can produce a set of tests which can be released which improve our quality

We have 3 distinct categorization of tests:
*Checkin Tests*
   These are tests which ensure that we have a base level of coverage and that basic operation is not regressed. 
   Because these should be run with every push, they should run swiftly and be extremely stable. As a goal, they 
   should not take longer than 20-30 minutes in total to execute. They roughly equate to our BVT/DRT/P1.
   Our current list of BVT/DRT/P1 is in need of pruning - total execution time for BVT/DRT tests in the lab is
   roughly 60 minutes.
*Feature Tests*
   These are tests which completely test a feature, but do not test feature/feature interaction. These tests roughly equate
   to our current P1/P2 tests. It is expected that a large number of current BVT/DRT/P1 tests should actually be feature tests.
*End-To-End Scenario Tests*
   These tests test feature-to-feature interaction, or complete end-to-end scenarios. They roughly equate to our current 
   P3 test library. These should have no time limit

During the authoring process, the tests should be tagged with the category of test. For Pester, one of three tags should be used:
| TAG | PURPOSE |
| CI  | Check in Test |
| FEATURE | Feature Test |
| E2E | End-to-End Scenario |

## STEX/LAB Interaction
We currently have nearly 200 workflows covering our BVT through Milestone tests

As set of tags should be u

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
    ScriptInternationalization
Engine
    EngineAPIs
    ErrorsandExceptions
    Eventing
    ExtensibleTypeSystem
    HelpSystem
    Jobs
    LoggingandTracing
    Modules
    Multi-CLR
    ParameterBinding
    PS-CIM
    Runspace
    SessionState
    SQM
    Transactions
    ConsoleHost
    FormatandOutput
    HostInterfaces
    TabCompletion
QualityCriteria
    Coverage
    FxCop
    Performance
Remoting
    Cmdlets
    Infrastructure
    NamedPipeTransport
    Serialization
Security


## Interacting with 
At the same time that we are preparing our test artifacts for release, we have the opportunity to reduce the complexity of our 
STEX lab 
