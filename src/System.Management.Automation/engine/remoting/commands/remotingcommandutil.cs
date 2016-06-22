//
//    Copyright (C) Microsoft.  All rights reserved.
//
using System;
using System.Threading;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Remoting;

using System.Management.Automation.Runspaces;
using System.Management.Automation.Host;
using System.IO;
using System.Diagnostics;
using Microsoft.Win32;
using Dbg = System.Management.Automation.Diagnostics;
using System.Management.Automation.Internal;
using System.Management.Automation.Remoting.Client;

namespace Microsoft.PowerShell.Commands
{

    /// <summary>
    /// This enum is used to distinguish two sets of parameters on some of the remoting cmdlets.
    /// </summary>
    internal enum RunspaceParameterSet
    {
        /// <summary>
        /// Use ComputerName parameter set
        /// </summary>
        ComputerName,
        /// <summary>
        /// Use Runspace Parameter set
        /// </summary>
        Runspace
    }

    /// <summary>
    /// This is a static utility class that performs some of the common chore work for the 
    /// the remoting cmdlets.
    /// </summary>
    internal static class RemotingCommandUtil
    {
        /// <summary>
        /// The existence of the following registry confirms that the host machine is a WinPE 
        /// HKLM\System\CurrentControlSet\Control\MiniNT
        /// </summary>
        internal static string WinPEIdentificationRegKey = @"System\CurrentControlSet\Control\MiniNT";

        /// <summary>
        /// IsWinPEHost indicates if the machine on which PowerShell is hosted is WinPE or not.
        /// This is a helper variable used to kep track if the IsWinPE() helper method has 
        /// already checked for the WinPE specific registry key or not.
        /// If the WinPE specific registry key has not yet been checked even 
        /// once then this variable will point to null.
        /// </summary>
        internal static bool? isWinPEHost = null;

        internal static bool HasRepeatingRunspaces(PSSession[] runspaceInfos)
        {
            if (runspaceInfos == null)
            {
                throw PSTraceSource.NewArgumentNullException("runspaceInfos");
            }

            if (runspaceInfos.GetLength(0) == 0)
            {
                throw PSTraceSource.NewArgumentException("runspaceInfos");
            }

            for (int i = 0; i < runspaceInfos.GetLength(0); i++)
            {
                for (int k = 0; k < runspaceInfos.GetLength(0); k++)
                {
                    if (i != k)
                    {
                        if (runspaceInfos[i].Runspace.InstanceId == runspaceInfos[k].Runspace.InstanceId)
                        {
                            return true;
                        }
                    }
                }
            }

            return false;
        }

        static internal bool ExceedMaximumAllowableRunspaces(PSSession[] runspaceInfos)
        {
            if (runspaceInfos == null)
            {
                throw PSTraceSource.NewArgumentNullException("runspaceInfos");
            }

            if (runspaceInfos.GetLength(0) == 0)
            {
                throw PSTraceSource.NewArgumentException("runspaceInfos");
            }

            return false;
        }

        /// <summary>
        /// Checks the prerequisites for a cmdlet and terminates if the cmdlet
        /// is not valid
        /// </summary>
        internal static void CheckRemotingCmdletPrerequisites()
        {
            bool notSupported = true;
            String WSManKeyPath = "Software\\Microsoft\\Windows\\CurrentVersion\\WSMAN\\";

            CheckHostRemotingPrerequisites();

            try
            {
                // the following registry key defines WSMan compatability
                // HKLM\Software\Microsoft\Windows\CurrentVersion\WSMAN\ServiceStackVersion
                string wsManStackValue = null;
                RegistryKey wsManKey = Registry.LocalMachine.OpenSubKey(WSManKeyPath);
                if (wsManKey != null)
                {
                    wsManStackValue = (string)wsManKey.GetValue("ServiceStackVersion");
                }

                Version wsManStackVersion = !string.IsNullOrEmpty(wsManStackValue) ? 
                    new Version(wsManStackValue.Trim()) :
                    System.Management.Automation.Remoting.Client.WSManNativeApi.WSMAN_STACK_VERSION;

                // WSMan stack version must be 2.0 or later.
                if (wsManStackVersion >= new Version(2, 0))
                {
                    notSupported = false;
                }
            }
            catch (FormatException)
            {
                notSupported = true;
            }
            catch (OverflowException)
            {
                notSupported = true;
            }
            catch (ArgumentException)
            {
                notSupported = true;
            }
            catch (System.Security.SecurityException)
            {
                notSupported = true;
            }
            catch (ObjectDisposedException)
            {
                notSupported = true;
            }

            if (notSupported)
            {
                // WSMan is not supported on this platform
                throw new InvalidOperationException(
                     "Windows PowerShell remoting features are not enabled or not supported on this machine.\nThis may be because you do not have the correct version of WS-Management installed or this version of Windows does not support remoting currently.\n For more information, type 'get-help about_remote_requirements'.");
            }
        }

        /// <summary>
        /// IsWinPEHost is a helper method used to identify if the 
        /// PowerShell is hosted on a WinPE machine.
        /// </summary>
        internal static bool IsWinPEHost()
        {
            RegistryKey wsManKey = null;

            if (isWinPEHost == null)
            {
                try
                {
                    // The existence of the following registry confirms that the host machine is a WinPE
                    // HKLM\System\CurrentControlSet\Control\MiniNT
                    wsManKey = Registry.LocalMachine.OpenSubKey(WinPEIdentificationRegKey);

                    if (null != wsManKey)
                    {
                        isWinPEHost = true;
                    }
                    else
                    {
                        isWinPEHost = false;
                    }
                }
                catch (ArgumentException) { }
                catch (System.Security.SecurityException) { }
                catch (ObjectDisposedException) { }
                finally
                {
                    if (wsManKey != null)
                    {
                        wsManKey.Dispose();
                    }
                }
            }

            return isWinPEHost== true? true: false;
        }

        /// <summary>
        /// Facilitates to check if remoting is supported on the host machine.
        /// PowerShell remoting is supported on all Windows SQU's except WinPE.
        /// </summary>
        /// <exception cref="InvalidOperationException">
        /// When PowerShell is hosted on a WinPE machine, the execution 
        /// of this API would result in an InvalidOperationException being 
        /// thrown, indicating that remoting is not supported on a WinPE machine.
        /// </exception>
        internal static void CheckHostRemotingPrerequisites()
        {
            // A registry key indicates if the SKU is WINPE. If this turns out to be true,
            // then an InValidOperation exception is thrown.
            bool isWinPEHost = IsWinPEHost();
            if (isWinPEHost)
            {
                // WSMan is not supported on this platform
                //throw new InvalidOperationException(
                //     "WinPE does not support Windows PowerShell remoting");
                ErrorRecord errorRecord = new ErrorRecord(new InvalidOperationException(StringUtil.Format(RemotingErrorIdStrings.WinPERemotingNotSupported)), null, ErrorCategory.InvalidOperation, null);
                throw new InvalidOperationException(errorRecord.ToString());
            }
        }
    }
}

