using System;
using System.Collections.Generic;
using System.Text;
using System.Management.Automation;

namespace Microsoft.Test.ModuleDiscovery
{
    [System.ComponentModel.RunInstaller(true)]
    public class ModuleDiscoveryTestSnapIn : PSSnapIn
    {
        public override string Name
        {
            get { return "Microsoft.Test.ModuleDiscovery.BinaryModule"; }
        }

        public override string Vendor
        {
            get { return "Microsoft"; }
        }

        public override string Description
        {
            get { return "This snapin contains cmdlets for testing module discovery."; }
        }

        public override string[] Formats
        {
            get
            {
                return new string[] { "Microsoft.Test.ModuleDiscovery.BinaryModule.Format.ps1xml" };
            }
        }

        public override string[] Types
        {
            get
            {
                return new string[] { "Microsoft.Test.ModuleDiscovery.BinaryModule.Types.ps1xml" };
            }
        }
    }
}
