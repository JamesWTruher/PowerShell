using Xunit;
using System;
using System.Management.Automation;

namespace PSTests
{
    [Collection("AssemblyLoadContext")]
    public static class PSVersionInfoTests
    {
        [CiFact]
        public static void TestVersions()
        {
            // test that a non-null version table is returned, and
            // that it does not throw
            Assert.NotNull(PSVersionInfo.GetPSVersionTable());
        }
    }
}
