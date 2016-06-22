﻿//-----------------------------------------------------------------------
// <copyright file="ShowCommand.cs" company="Microsoft">
//     Copyright © Microsoft Corporation.  All rights reserved.
// </copyright>
//-----------------------------------------------------------------------
namespace Microsoft.PowerShell.Commands
{
    using System;
    using System.Collections.Generic;
    using System.Collections.ObjectModel;
    using System.Globalization;
    using System.Management.Automation;
    using System.Management.Automation.Internal;
    using System.Reflection;
    using System.Runtime.InteropServices;
    using System.Text;
    using System.Threading;
    using Microsoft.PowerShell.Commands.ShowCommandExtension;
    
    /// <summary>
    /// Show-Command displays a GUI for a cmdlet, or for all cmdlets if no specific cmdlet is specified.
    /// </summary>
    [Cmdlet(VerbsCommon.Show, "Command", HelpUri = "http://go.microsoft.com/fwlink/?LinkID=217448")]
    public class ShowCommandCommand : PSCmdlet, IDisposable
    {
        #region Private Fields
        /// <summary>
        /// Set to true when ProcessRecord is reached, since it will allways open a window
        /// </summary>
        private bool hasOpenedWindow;

        /// <summary>
        /// Determines if the command should be sent to the pipeline as a string instead of run.
        /// </summary>
        private bool passThrough;

        /// <summary>
        /// Uses ShowCommandProxy to invoke WPF GUI object. 
        /// </summary>
        private ShowCommandProxy showCommandProxy;

        /// <summary>
        /// Data container for all cmdlets. This is populated when show-command is called with no command name.
        /// </summary>
        private List<ShowCommandCommandInfo> commands;

        /// <summary>
        /// List of modules that have been loaded indexed by module name
        /// </summary>
        private Dictionary<string, ShowCommandModuleInfo> importedModules;

        /// <summary>
        /// Record the EndProcessing error.
        /// </summary>
        private PSDataCollection<ErrorRecord> errors = new PSDataCollection<ErrorRecord>();

        /// <summary>
        /// Field used for the CommandName parameter.
        /// </summary>
        private string commandName;

        /// <summary>
        /// Field used for the Height parameter.
        /// </summary>
        private double height;

        /// <summary>
        /// Field used for the Width parameter.
        /// </summary>
        private double width;

        /// <summary>
        /// Field used for the NoCommonParameter parameter.
        /// </summary>
        private SwitchParameter noCommonParameter;

        /// <summary>
        /// A value indicating errors should not cause a message window to be displayed
        /// </summary>
        private SwitchParameter errorPopup;

        /// <summary>
        /// Object used for ShowCommand with a command name that holds the view model created for the command
        /// </summary>
        private object commandViewModelObj;
        #endregion

        /// <summary>
        /// Finalizes an instance of the ShowCommandCommand class
        /// </summary>
        ~ShowCommandCommand()
        {
            this.Dispose(false);
        }

        #region Input Cmdlet Parameter
        /// <summary>
        /// Gets or sets the command name.
        /// </summary>
        [Parameter(Position = 0)]
        [Alias("CommandName")]
        public string Name
        {
            get { return this.commandName; }
            set { this.commandName = value; }
        }

        /// <summary>
        /// Gets or sets the Width.
        /// </summary>
        [Parameter]
        [ValidateRange(300, Int32.MaxValue)]
        public double Height
        {
            get { return this.height; }
            set { this.height = value; }
        }

        /// <summary>
        /// Gets or sets the Width.
        /// </summary>
        [Parameter]
        [ValidateRange(300, Int32.MaxValue)]
        public double Width
        {
            get { return this.width; }
            set { this.width = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating Common Parameters should not be displayed
        /// </summary>
        [Parameter]
        public SwitchParameter NoCommonParameter
        {
            get { return this.noCommonParameter; }
            set { this.noCommonParameter = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating errors should not cause a message window to be displayed
        /// </summary>
        [Parameter]
        public SwitchParameter ErrorPopup
        {
            get { return this.errorPopup; }
            set { this.errorPopup = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating the command should be sent to the pipeline as a string instead of run
        /// </summary>
        [Parameter]
        public SwitchParameter PassThru
        {
            get
            {
                return this.passThrough;
            }

            set
            {
                this.passThrough = value;
            }
        } // PassThru
        #endregion

        #region Public and Protected Methods
        /// <summary>
        /// Executes a PowerShell script, writing the output objects to the pipeline.
        /// </summary>
        /// <param name="script">Script to execute</param>
        public void RunScript(string script)
        {
            if (this.showCommandProxy == null || string.IsNullOrEmpty(script))
            {
                return;
            }

            if (this.passThrough)
            {
                this.WriteObject(script);
                return;
            }

            if (this.errorPopup)
            {
                this.RunScriptSilentlyAndWithErrorHookup(script);
                return;
            }

            if (this.showCommandProxy.HasHostWindow)
            {
                if (!this.showCommandProxy.SetPendingISECommand(script))
                {
                    this.RunScriptSilentlyAndWithErrorHookup(script);
                }

                return;
            }

            if (!ConsoleInputWithNativeMethods.AddToConsoleInputBuffer(script, true))
            {
                this.WriteDebug(FormatAndOut_out_gridview.CannotWriteToConsoleInputBuffer);
                this.RunScriptSilentlyAndWithErrorHookup(script);
            }
        }

        /// <summary>
        /// Dispose method in IDisposeable
        /// </summary>
        public void Dispose()
        {
            this.Dispose(true);
            GC.SuppressFinalize(this);
        }

        /// <summary>
        /// Initialize a proxy instance for show-command.
        /// </summary>
        protected override void BeginProcessing()
        {
            this.showCommandProxy = new ShowCommandProxy(this);

            if (this.showCommandProxy.ScreenHeight < this.Height)
            {
                ErrorRecord error = new ErrorRecord(
                                    new NotSupportedException(String.Format(CultureInfo.CurrentUICulture, FormatAndOut_out_gridview.PropertyValidate, "Height", this.showCommandProxy.ScreenHeight)),
                                    "PARAMETER_DATA_ERROR",
                                    ErrorCategory.InvalidData,
                                    null);
                this.ThrowTerminatingError(error);
            }

            if (this.showCommandProxy.ScreenWidth < this.Width)
            {
                ErrorRecord error = new ErrorRecord(
                                    new NotSupportedException(String.Format(CultureInfo.CurrentUICulture, FormatAndOut_out_gridview.PropertyValidate, "Width", this.showCommandProxy.ScreenWidth)),
                                    "PARAMETER_DATA_ERROR",
                                    ErrorCategory.InvalidData,
                                    null);
                this.ThrowTerminatingError(error);
            }
        }

        /// <summary>
        /// ProcessRecord with or without CommandName.
        /// </summary>
        protected override void ProcessRecord()
        {
            if (this.commandName == null)
            {
                this.hasOpenedWindow = this.CanProcessRecordForAllCommands();
            }
            else
            {
                this.hasOpenedWindow = this.CanProcessRecordForOneCommand();
            }
        }

        /// <summary>
        /// Optionally displays errors in a message
        /// </summary>
        protected override void EndProcessing()
        {
            if (!this.hasOpenedWindow)
            {
                return;
            }

            // We wait untill the window is loaded and then activate it
            // to work arround the console window gaining activation somewhere 
            // in the end of ProcessRecord, which causes the keyboard focus
            // (and use oif tab key to focus controls) to go away from the window
            this.showCommandProxy.WindowLoaded.WaitOne();
            this.showCommandProxy.ActivateWindow();

            this.WaitForWindowClosedOrHelpNeeded();
            this.RunScript(this.showCommandProxy.GetScript());

            if (this.errors.Count == 0 || !this.errorPopup)
            {
                return;
            }

            StringBuilder errorString = new StringBuilder();

            for (int i = 0; i < this.errors.Count; i++)
            {
                if (i != 0)
                {
                    errorString.AppendLine();
                }

                ErrorRecord error = this.errors[i];
                errorString.Append(error.Exception.Message);
            }

            this.showCommandProxy.ShowErrorString(errorString.ToString());
        }

        /// <summary>
        /// StopProcessing is called close the window when user press Ctrl+C in the command prompt.
        /// </summary>
        protected override void StopProcessing()
        {
            this.showCommandProxy.CloseWindow();
        }

        #endregion

        #region Private Methods
        /// <summary>
        /// Runs the script in a new PowerShell instance and  hooks up error stream to pottentlially display error popup.
        /// This method has the inconvenience of not showing to the console user the script being executed.
        /// </summary>
        /// <param name="script">script to be run</param>
        private void RunScriptSilentlyAndWithErrorHookup(string script)
        {
            // errors are not created here, because there is a field for it used in the final pop up
            PSDataCollection<object> output = new PSDataCollection<object>();

            output.DataAdded += new EventHandler<DataAddedEventArgs>(this.Output_DataAdded);
            this.errors.DataAdded += new EventHandler<DataAddedEventArgs>(this.Error_DataAdded);

            PowerShell ps = PowerShell.Create(RunspaceMode.CurrentRunspace);
            ps.Streams.Error = this.errors;

            ps.Commands.AddScript(script);

            ps.Invoke(null, output, null);
        }

        /// <summary>
        /// Issues an error when this.commandName was not found
        /// </summary>
        private void IssueErrorForNoCommand()
        {
            InvalidOperationException errorException = new InvalidOperationException(
                String.Format(
                    CultureInfo.CurrentUICulture,
                    FormatAndOut_out_gridview.CommandNotFound,
                    this.commandName));
            this.ThrowTerminatingError(new ErrorRecord(errorException, "NoCommand", ErrorCategory.InvalidOperation, this.commandName));
        }

        /// <summary>
        /// Issues an error when there is more than one command matching this.commandName
        /// </summary>
        private void IssueErrorForMoreThanOneCommand()
        {
            InvalidOperationException errorException = new InvalidOperationException(
                String.Format(
                    CultureInfo.CurrentUICulture,
                    FormatAndOut_out_gridview.MoreThanOneCommand,
                    this.commandName,
                    "Show-Command"));
            this.ThrowTerminatingError(new ErrorRecord(errorException, "MoreThanOneCommand", ErrorCategory.InvalidOperation, this.commandName));
        }

        /// <summary>
        /// Called from CommandProcessRecord to run the command that will get the CommandInfo and list of modules
        /// </summary>
        /// <param name="command">command to be retrieved</param>
        /// <param name="modules">list of loaded modules</param>
        private void GetCommandInfoAndModules(out CommandInfo command, out Dictionary<string, ShowCommandModuleInfo> modules)
        {
            command = null;
            modules = null;
            string commandText = this.showCommandProxy.GetShowCommandCommand(this.commandName, true);

            Collection<PSObject> commandResults = this.InvokeCommand.InvokeScript(commandText);

            object[] commandObjects = (object[])commandResults[0].BaseObject;
            object[] moduleObjects = (object[])commandResults[1].BaseObject;
            if (commandResults == null || moduleObjects == null || commandObjects.Length == 0)
            {
                this.IssueErrorForNoCommand();
                return;
            }

            if (commandObjects.Length > 1)
            {
                this.IssueErrorForMoreThanOneCommand();
            }

            command = ((PSObject)commandObjects[0]).BaseObject as CommandInfo;
            if (command == null)
            {
                this.IssueErrorForNoCommand();
                return;
            }

            if (command.CommandType == CommandTypes.Alias)
            {
                commandText = this.showCommandProxy.GetShowCommandCommand(command.Definition, false);
                commandResults = this.InvokeCommand.InvokeScript(commandText);
                if (commandResults == null || commandResults.Count != 1)
                {
                    this.IssueErrorForNoCommand();
                    return;
                }

                command = (CommandInfo)commandResults[0].BaseObject;
            }

            modules = this.showCommandProxy.GetImportedModulesDictionary(moduleObjects);
        }

        /// <summary>
        /// ProcessRecord when a command name is specified.
        /// </summary>
        /// <returns>true if there was no exception processing this record</returns>
        private bool CanProcessRecordForOneCommand()
        {
            CommandInfo commandInfo;
            this.GetCommandInfoAndModules(out commandInfo, out this.importedModules);
            Diagnostics.Assert(commandInfo != null, "GetCommandInfoAndModules would throw a termninating error/exception");

            try
            {
                this.commandViewModelObj = this.showCommandProxy.GetCommandViewModel(new ShowCommandCommandInfo(commandInfo), this.noCommonParameter.ToBool(), this.importedModules, this.Name.IndexOf('\\') != -1);
                this.showCommandProxy.ShowCommandWindow(this.commandViewModelObj, this.passThrough);
            }
            catch (TargetInvocationException ti)
            {
                this.WriteError(new ErrorRecord(ti.InnerException, "CannotProcessRecordForOneCommand", ErrorCategory.InvalidOperation, this.commandName));
                return false;
            }

            return true;
        }

        /// <summary>
        /// ProcessRecord when a command name is not specified.
        /// </summary>
        /// <returns>true if there was no exception processing this record</returns>
        private bool CanProcessRecordForAllCommands()
        {
            Collection<PSObject> rawCommands = this.InvokeCommand.InvokeScript(this.showCommandProxy.GetShowAllModulesCommand());
            
            this.commands = this.showCommandProxy.GetCommandList((object[])rawCommands[0].BaseObject);
            this.importedModules = this.showCommandProxy.GetImportedModulesDictionary((object[])rawCommands[1].BaseObject);

            try
            {
                this.showCommandProxy.ShowAllModulesWindow(this.importedModules, this.commands, this.noCommonParameter.ToBool(), this.passThrough);
            }
            catch (TargetInvocationException ti)
            {
                this.WriteError(new ErrorRecord(ti.InnerException, "CannotProcessRecordForAllCommands", ErrorCategory.InvalidOperation, this.commandName));
                return false;
            }

            return true;
        }

        /// <summary>
        /// Waits untill the window has been closed answering HelpNeeded events
        /// </summary>
        private void WaitForWindowClosedOrHelpNeeded()
        {
            do
            {
                int which = WaitHandle.WaitAny(new WaitHandle[] { this.showCommandProxy.WindowClosed, this.showCommandProxy.HelpNeeded, this.showCommandProxy.ImportModuleNeeded });

                if (which == 0)
                {
                    break;
                }

                if (which == 1)
                {
                    Collection<PSObject> helpResults = this.InvokeCommand.InvokeScript(this.showCommandProxy.GetHelpCommand(this.showCommandProxy.CommandNeedingHelp));
                    this.showCommandProxy.DisplayHelp(helpResults);
                    continue;
                }

                Diagnostics.Assert(which == 2, "which is 0,1 or 2 and 0 and 1 have been eliminated in the ifs above");
                string commandToRun = this.showCommandProxy.GetImportModuleCommand(this.showCommandProxy.ParentModuleNeedingImportModule);
                Collection<PSObject> rawCommands;
                try
                {
                    rawCommands = this.InvokeCommand.InvokeScript(commandToRun);
                }
                catch (RuntimeException e)
                {
                    this.showCommandProxy.ImportModuleFailed(e);
                    continue;
                }

                this.commands = this.showCommandProxy.GetCommandList((object[])rawCommands[0].BaseObject);
                this.importedModules = this.showCommandProxy.GetImportedModulesDictionary((object[])rawCommands[1].BaseObject);
                this.showCommandProxy.ImportModuleDone(this.importedModules, this.commands);
                continue;
            } 
            while (true);
        }

        /// <summary>
        /// Writes the output of a script being run into the pipeline
        /// </summary>
        /// <param name="sender">output collection</param>
        /// <param name="e">output event</param>
        private void Output_DataAdded(object sender, DataAddedEventArgs e)
        {
            this.WriteObject(((PSDataCollection<object>)sender)[e.Index]);
        }

        /// <summary>
        /// Writes the errors of a script being run into the pipeline
        /// </summary>
        /// <param name="sender">error collection</param>
        /// <param name="e">error event</param>
        private void Error_DataAdded(object sender, DataAddedEventArgs e)
        {
            this.WriteError(((PSDataCollection<ErrorRecord>)sender)[e.Index]);
        }

        /// <summary>
        /// Implements IDisposable logic
        /// </summary>
        /// <param name="isDisposing">true if being called from Dispose</param>
        private void Dispose(bool isDisposing)
        {
            if (isDisposing)
            {
                if (this.errors != null)
                {
                    this.errors.Dispose();
                    this.errors = null;
                }
            }
        }
        #endregion

        /// <summary>
        /// Wraps interop code for console input buffer
        /// </summary>
        internal static class ConsoleInputWithNativeMethods
        {
            /// <summary>
            /// Constant used in calls to GetStdHandle
            /// </summary>
            internal const int STD_INPUT_HANDLE = -10;

            /// <summary>
            /// Adds a string to the console input buffer
            /// </summary>
            /// <param name="str">string to add to console input buffer</param>
            /// <param name="newLine">true to add Enter after the string</param>
            /// <returns>true if it was succesfull in adding all characters to console input buffer</returns>
            internal static bool AddToConsoleInputBuffer(string str, bool newLine)
            {
                IntPtr handle = ConsoleInputWithNativeMethods.GetStdHandle(ConsoleInputWithNativeMethods.STD_INPUT_HANDLE);
                if (handle == IntPtr.Zero)
                {
                    return false;
                }

                uint strLen = (uint)str.Length;

                ConsoleInputWithNativeMethods.INPUT_RECORD[] records = new ConsoleInputWithNativeMethods.INPUT_RECORD[strLen + (newLine ? 1 : 0)];

                for (int i = 0; i < strLen; i++)
                {
                    ConsoleInputWithNativeMethods.INPUT_RECORD.SetInputRecord(ref records[i], str[i]);
                }

                uint written;
                if (!ConsoleInputWithNativeMethods.WriteConsoleInput(handle, records, strLen, out written) || written != strLen)
                {
                    // I do not know of a case where written is not going to be strlen. Maybe for some charcater that
                    // is not supported in the console. The API suggests this can happen, 
                    // so we handle it by returning false
                    return false;
                }

                // Enter is written separetely, because if this is a command, and one of the characters in the command was not written
                // (written != strLen) it is desireable to fail (return false) before typing enter and running the command
                if (newLine)
                {
                    ConsoleInputWithNativeMethods.INPUT_RECORD[] enterArray = new ConsoleInputWithNativeMethods.INPUT_RECORD[1];
                    ConsoleInputWithNativeMethods.INPUT_RECORD.SetInputRecord(ref enterArray[0], (char)13);

                    written = 0;
                    if (!ConsoleInputWithNativeMethods.WriteConsoleInput(handle, enterArray, 1, out written))
                    {
                        // I don't think this will happen
                        return false;
                    }

                    Diagnostics.Assert(written == 1, "only Enter is being added and it is a supported character");
                }

                return true;
            }

            /// <summary>
            /// Gets the console handle
            /// </summary>
            /// <param name="nStdHandle">which console handle to get</param>
            /// <returns>the console handle</returns>
            [DllImport("kernel32.dll", SetLastError = true)]
            internal static extern IntPtr GetStdHandle(int nStdHandle);

            /// <summary>
            /// Writes to the console input buffer
            /// </summary>
            /// <param name="hConsoleInput">console handle</param>
            /// <param name="lpBuffer">inputs to be written</param>
            /// <param name="nLength">number of inputs to be written</param>
            /// <param name="lpNumberOfEventsWritten">returned number of inputs actually written</param>
            /// <returns>0 if the function fails</returns>
            [DllImport("kernel32.dll", SetLastError = true)]
            [return: MarshalAs(UnmanagedType.Bool)]
            internal static extern bool WriteConsoleInput(
                IntPtr hConsoleInput,
                INPUT_RECORD[] lpBuffer,
                uint nLength,
                out uint lpNumberOfEventsWritten);

            /// <summary>
            /// A record to be added to the console buffer
            /// </summary>
            internal struct INPUT_RECORD
            {
                /// <summary>
                /// The proper event type for a KeyEvent KEY_EVENT_RECORD
                /// </summary>
                internal const int KEY_EVENT = 0x0001;

                /// <summary>
                /// input buffer event type
                /// </summary>
                internal ushort EventType;

                /// <summary>
                /// The actual event. The original structure is a union of many others, but this is the largest of them
                /// And we don't need other kinds of events
                /// </summary>
                internal KEY_EVENT_RECORD KeyEvent;

                /// <summary>
                /// Sets the necessary fields of <paramref name="inputRecord"/> for a KeyDown event for the <paramref name="character"/>
                /// </summary>
                /// <param name="inputRecord">input record to be set</param>
                /// <param name="character">character to set the record with</param>
                internal static void SetInputRecord(ref INPUT_RECORD inputRecord, char character)
                {
                    inputRecord.EventType = INPUT_RECORD.KEY_EVENT;
                    inputRecord.KeyEvent.bKeyDown = true;
                    inputRecord.KeyEvent.UnicodeChar = character;
                }
            }

            /// <summary>
            /// Type of INPUT_RECORD which is a key
            /// </summary>
            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
            internal struct KEY_EVENT_RECORD
            {
                /// <summary>
                /// true for key down and false for key up, but only needed if wVirtualKeyCode is used
                /// </summary>
                internal bool bKeyDown;

                /// <summary>
                /// repeat count
                /// </summary>
                internal ushort wRepeatCount;

                /// <summary>
                /// virtual key code
                /// </summary>
                internal ushort wVirtualKeyCode;

                /// <summary>
                /// virtual key scan code
                /// </summary>
                internal ushort wVirtualScanCode;

                /// <summary>
                /// character in input. If this is specified, wVirtualKeyCode, and others don't need to be
                /// </summary>
                internal char UnicodeChar;

                /// <summary>
                /// State of keys like Shift and control
                /// </summary>
                internal uint dwControlKeyState;
            }
        }
    }
}
