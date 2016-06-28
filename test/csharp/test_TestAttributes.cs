using Xunit;
using System;
using System.Management.Automation.Language;

namespace PSTests
{
    [Collection("AssemblyLoadContext")]
    public static class PSFactTests
    {
        [CiFact]
        public static void TestCiFactFound()
        {
            Assert.True(true);
        }
        [FeatureFact]
        public static void TestFeatureFactFound()
        {
            Assert.True(true);
        }
        [ScenarioFact]
        public static void TestScenarioFactFound()
        {
            Assert.True(true);
        }
        [CiFact(Pending="miss this ci")]
        public static void TestCiFactPending()
        {
            Assert.True(true);
        }
        [FeatureFact(Pending="miss this feature")]
        public static void TestFeatureFactPending()
        {
            Assert.True(true);
        }
        [ScenarioFact(Pending="miss this scenario")]
        public static void TestScenarioFactPending()
        {
            Assert.True(true);
        }
    }
}
