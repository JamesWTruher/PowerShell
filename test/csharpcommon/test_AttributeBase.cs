using Xunit;
using System;

namespace PSTests
{
    public class PowerShellTestAttribute : FactAttribute
    {
        public string Pending 
        { 
            get { return this.Skip; } 
            set { this.Skip = string.Format("Pending: {0}", value); } 
        }
    }
    public class CiFact : PowerShellTestAttribute { }
    public class FeatureFact : PowerShellTestAttribute { }
    public class ScenarioFact : PowerShellTestAttribute { }

    public class PowerShellTheoryAttribute : TheoryAttribute
    {
        public string Pending 
        { 
            get { return this.Skip; } 
            set { this.Skip = string.Format("Pending: {0}", value); } 
        }
    }
    public class CiTheory : PowerShellTheoryAttribute { }
    public class FeatureTheory : PowerShellTheoryAttribute { }
    public class ScenarioTheory : PowerShellTheoryAttribute { }

}
