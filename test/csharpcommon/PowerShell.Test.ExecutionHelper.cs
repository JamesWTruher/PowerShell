using System;
using System.Management.Automation;

namespace PSTests
{
    public class PowerShellTestBase
    {
        public static object ExecuteScript(string script)
        {
            if ( script == null || string.IsNullOrWhiteSpace(script))
            {
                throw new ArgumentException("Script my not be null or empty");
            }
            using(PowerShell ps = PowerShell.Create())
            {
                return ps.AddCommand(script).Invoke();
                
            }
        }
    }

}
