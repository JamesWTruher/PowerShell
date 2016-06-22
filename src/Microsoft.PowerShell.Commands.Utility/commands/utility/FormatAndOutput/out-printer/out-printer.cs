/********************************************************************++
Copyright (c) Microsoft Corporation.  All rights reserved.
--********************************************************************/
using System;
using System.Collections;
using System.Collections.ObjectModel;
using System.Reflection;
using System.Globalization;
using System.Management.Automation;
using System.IO;

using System.Drawing;
using System.Drawing.Printing;

using Microsoft.PowerShell.Commands.Internal.Format;

namespace Microsoft.PowerShell.Commands
{

     /// <summary>
    /// implementation for the out-printer command
    /// </summary>
    [Cmdlet ("Out", "Printer", HelpUri = "http://go.microsoft.com/fwlink/?LinkID=113367")]
    public class OutPrinterCommand : FrontEndCommandBase
    {
        /// <summary>
        /// set inner command
        /// </summary>
        public OutPrinterCommand ()
        {
            this.implementation = new OutputManagerInner ();
        }

        /// <summary>
        /// optional name of the printer to print to
        /// The alias allows "lp -P printer"
        /// </summary>
        [Parameter(Position=0)]
        [Alias("PrinterName")]
        public string Name
        {
            get { return printerName; }
            set { printerName = value; }
        }

        private string printerName;

        /// <summary>
        /// read command line parameters
        /// </summary>
        protected override void BeginProcessing ()
        {
            // set up the Scree Host interface
            OutputManagerInner outInner = (OutputManagerInner)this.implementation;

            outInner.LineOutput = InstantiateLineOutputInterface ();

            // finally call the base class for general hookup
            base.BeginProcessing ();
        }

        /// <summary>
        /// one time initialization: acquire a screen host interface
        /// by creating one on top of a memory buffer
        /// </summary>
        private LineOutput InstantiateLineOutputInterface ()
        {
            PrinterLineOutput printOutput = new PrinterLineOutput (this.printerName);
            return (LineOutput)printOutput;
        }
    }
}




