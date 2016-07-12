using System;
using System.Collections.Generic;
using System.Text;
using System.Management.Automation;

namespace Microsoft.Test.ModuleDiscovery
{
    [Cmdlet("Test", "BinaryModuleCmdlet")]
    public class TestModuleDiscoveryCommand : PSCmdlet
    {
        [ValidateNotNull()]
        [Parameter(Mandatory = false, Position=0)]
        public object Parameter
        {
            get { return _parameter; }
            set { _parameter = value; }
        }
        object _parameter = null;




        public TestModuleDiscoveryCommand() { }

        protected override void EndProcessing()
        {
            if (_parameter != null)
            {
                WriteObject(_parameter);
            }
        }
    }
}
