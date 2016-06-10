using Xunit;
using System;
using System.Management.Automation;

namespace PSTests
{
    // Not static because a test requires non-const variables
    [Collection("AssemblyLoadContext")]
    public class MshSnapinInfoTests
    {
        // Test that it does not throw an exception
        [CiFact]
        public void TestReadRegistryInfo()
        {
            Version someVersion = null;
            string someString = null;
            PSSnapInReader.ReadRegistryInfo(out someVersion, out someString, out someString, out someString, out someString, out someVersion);
        }

        // PublicKeyToken is null on Linux
        [CiFact]
        public void TestReadCoreEngineSnapIn()
        {
            PSSnapInInfo pSSnapInInfo = PSSnapInReader.ReadCoreEngineSnapIn();
            Assert.Contains("PublicKeyToken=null", pSSnapInInfo.AssemblyName);
        }
    }
}
