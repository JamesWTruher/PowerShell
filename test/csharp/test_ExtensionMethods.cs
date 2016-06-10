using Xunit;
using System;
using System.Management.Automation;

namespace PSTests
{
    [Collection("AssemblyLoadContext")]
    public static class PSTypeExtensionsTests
    {
        [CiFact]
        public static void TestIsComObject()
        {
            // It just needs an arbitrary type
            Assert.False(PSTypeExtensions.IsComObject(42.GetType()));
        }
    }
}
