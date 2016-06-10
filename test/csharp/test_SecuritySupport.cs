using Xunit;
using System;
using System.Management.Automation;

namespace PSTests
{
    [Collection("AssemblyLoadContext")]
    public static class SecuritySupportTests
    {
        [CiFact]
        public static void TestScanContent()
        {
            Assert.Equal(AmsiUtils.ScanContent("", ""), AmsiUtils.AmsiNativeMethods.AMSI_RESULT.AMSI_RESULT_NOT_DETECTED);
        }

        [CiFact]
        public static void TestCurrentDomain_ProcessExit()
        {
            Assert.Throws<PlatformNotSupportedException>(delegate {
                    AmsiUtils.CurrentDomain_ProcessExit(null, EventArgs.Empty);
                });
        }

        [CiFact]
        public static void TestCloseSession()
        {
            AmsiUtils.CloseSession();
        }

        [CiFact]
        public static void TestUninitialize()
        {
            AmsiUtils.Uninitialize();
        }
    }
}
