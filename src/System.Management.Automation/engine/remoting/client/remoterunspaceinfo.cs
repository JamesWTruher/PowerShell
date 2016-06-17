/********************************************************************++
Copyright (c) Microsoft Corporation.  All rights reserved.
--********************************************************************/

using System.Management.Automation.Internal;
using Dbg = System.Management.Automation.Diagnostics;

namespace System.Management.Automation.Runspaces
{
    /// <summary>
    /// Computer target type
    /// </summary>
    public enum TargetMachineType 
    { 
        /// <summary>
        /// Target is a machine with which the session is based on networking
        /// </summary>
        RemoteMachine, 
    
        /// <summary>
        /// Target is a virtual machine with which the session is based on Hyper-V socket
        /// </summary>
        VirtualMachine, 
    
        /// <summary>
        /// Target is a container with which the session is based on Hyper-V socket (Hyper-V
        /// container) or named pipe (windows container)
        /// </summary>
        Container
    }

    /// <summary>
    /// Class that exposes read only properties and which conveys information
    /// about a remote runspace object to the user. The class serves the 
    /// following purpose:
    ///     1. Exposes useful information to the user as properties
    ///     2. Shields the remote runspace object from directly being exposed
    ///        to the user. This way, the user will not be able to directly
    ///        act upon the object, but instead will have to use the remoting
    ///        cmdlets. This will prevent any unpredictable behavior.
    /// </summary>
    public sealed class PSSession
    {
        #region Private Members

        private RemoteRunspace remoteRunspace;
        private String shell;
        private TargetMachineType computerType;

        /// <summary>
        /// Static variable which is incremented to generate id
        /// </summary>
        private static int seed = 0;

        private int sessionid;
        private String name;

        #endregion Private Members

        #region Public Properties

        /// <summary>
        /// Type of the computer target
        /// </summary>
        public TargetMachineType ComputerType
        {
            get
            {
                return computerType;
            }
            set
            {
                computerType = value;
            }
        }

        /// <summary>
        /// Name of the computer target
        /// </summary>
        public String ComputerName
        {
            get
            {
                return remoteRunspace.ConnectionInfo.ComputerName;
            }
        }

        /// <summary>
        /// Id of the container target
        /// </summary>
        public String ContainerId
        {
            get
            {
                if (ComputerType == TargetMachineType.Container)
                {
                    ContainerConnectionInfo connectionInfo = remoteRunspace.ConnectionInfo as ContainerConnectionInfo;
                    return connectionInfo.ContainerProc.ContainerId;
                }
                else
                {
                    return string.Empty;
                }
            }
        }

        /// <summary>
        /// Name of the virtual machine target
        /// </summary>
        public String VMName
        {
            get
            {
                if (ComputerType == TargetMachineType.VirtualMachine)
                {
                    return remoteRunspace.ConnectionInfo.ComputerName;
                }
                else
                {
                    return string.Empty;
                }
            }
        }

        /// <summary>
        /// Guid of the virtual machine target
        /// </summary>
        public Guid? VMId
        {
            get
            {
                if (ComputerType == TargetMachineType.VirtualMachine)
                {
                    VMConnectionInfo connectionInfo = remoteRunspace.ConnectionInfo as VMConnectionInfo;
                    return connectionInfo.VMGuid;
                }
                else
                {
                    return null;
                }
            }
        }

        /// <summary>
        /// Shell which is executed in the remote machine
        /// </summary>
        public String ConfigurationName
        {
            get
            {
                return shell;
            }
        }

        /// <summary>
        /// InstanceID that identifies this runspace
        /// </summary>
        public Guid InstanceId
        {
            get
            {
                return remoteRunspace.InstanceId;
            }
        }

        /// <summary>
        /// SessionId of this runspace. This is unique only across 
        /// a session 
        /// </summary>
        public int Id
        {
            get
            {
                return sessionid;
            }
        }

        /// <summary>
        /// Friendly name for identifying this runspace
        /// </summary>
        public String Name
        {
            get
            {
                return name;
            }

            set
            {
                name = value;
            }
        }
                      
        /// <summary>
        /// Indicates whether the specified runspace is available
        /// for executing commands
        /// </summary>
        public RunspaceAvailability Availability
        {
            get
            {
                return Runspace.RunspaceAvailability;
            }
        }

        /// <summary>
        /// Private data to be used by applications built on top of PowerShell.  
        /// Optionally sent by the remote server when creating a new session / runspace.
        /// </summary>
        public PSPrimitiveDictionary ApplicationPrivateData
        {
            get
            { 
                return this.Runspace.GetApplicationPrivateData(); 
            }
        }

        /// <summary>
        /// The remote runspace object based on which this information object
        /// is derived
        /// </summary>
        /// <remarks>This property is marked internal to allow other cmdlets
        /// to get access to the RemoteRunspace object and operate on it like
        /// for instance test-runspace, close-runspace etc</remarks>
        public Runspace Runspace
        {
            get
            {
                return remoteRunspace;
            }
        }

        #endregion Public Properties

        #region Public Methods

        /// <summary>
        /// ToString method override
        /// </summary>
        /// <returns>string</returns>
        public override string ToString()
        {
            // PSSession is a PowerShell type name and so should not be localized.
            string formatString = "[PSSession]{0}";
            return StringUtil.Format(formatString, Name);
        }

        #endregion

        #region Internal Methods

        /// <summary>
        /// Internal method to insert a runspace into a PSSession object.
        /// This is used only for Disconnect/Reconnect scenarios where the
        /// new runspace is a reconstructed runspace having the same Guid
        /// as the existing runspace.
        /// </summary>
        /// <param name="remoteRunspace">Runspace to insert</param>
        /// <returns>Boolean indicating if runspace was inserted.</returns>
        internal bool InsertRunspace(RemoteRunspace remoteRunspace)
        {
            if (remoteRunspace == null ||
                remoteRunspace.InstanceId != this.remoteRunspace.InstanceId)
            {
                return false;
            }

            this.remoteRunspace = remoteRunspace;
            return true;
        }

        #endregion

        #region Constructor

        /// <summary>
        /// This constructor will be used to created a remote runspace info
        /// object with a auto generated name
        /// </summary>
        /// <param name="remoteRunspace">Remote runspace object for which 
        /// the info object need to be created</param>
        internal PSSession(RemoteRunspace remoteRunspace)
        {
            this.remoteRunspace = remoteRunspace;

            // Use passed in session Id, if available.
            if (remoteRunspace.PSSessionId != -1)
            {
                sessionid = remoteRunspace.PSSessionId;
            }
            else
            {
                sessionid = System.Threading.Interlocked.Increment(ref seed);
                remoteRunspace.PSSessionId = sessionid;
            }

            // Use passed in friendly name, if available.
            if (!string.IsNullOrEmpty(remoteRunspace.PSSessionName))
            {
                name = remoteRunspace.PSSessionName;
            }
            else
            {
                name = AutoGenerateRunspaceName();
                remoteRunspace.PSSessionName = name;
            }

            // WSMan session
            if (remoteRunspace.ConnectionInfo is WSManConnectionInfo)
            {
                computerType = TargetMachineType.RemoteMachine;

                string fullShellName = WSManConnectionInfo.ExtractPropertyAsWsManConnectionInfo<string>(
                    remoteRunspace.ConnectionInfo,
                    "ShellUri", string.Empty);
                
                shell = GetDisplayShellName(fullShellName);
                return;
            }

            // VM session
            VMConnectionInfo vmConnectionInfo = remoteRunspace.ConnectionInfo as VMConnectionInfo;
            if (vmConnectionInfo != null)
            {
                computerType = TargetMachineType.VirtualMachine;
                shell = vmConnectionInfo.ConfigurationName;
                return;
            }

            // Container session
            ContainerConnectionInfo containerConnectionInfo = remoteRunspace.ConnectionInfo as ContainerConnectionInfo;
            if (containerConnectionInfo != null)
            {
                computerType = TargetMachineType.Container;
                shell = containerConnectionInfo.ContainerProc.ConfigurationName;
                return;
            }

            // We only support WSMan/VM/Container sessions now.
            Dbg.Assert(false, "Invalid Runspace");
        }

        #endregion Constructor

        #region Private Methods

        /// <summary>
        /// Generates and returns the runspace name
        /// </summary>
        /// <returns>auto generated name</returns>
        private String AutoGenerateRunspaceName()
        {
            return "Session" + sessionid.ToString(System.Globalization.NumberFormatInfo.InvariantInfo);
        }

        /// <summary>
        /// Returns shell configuration name with shell prefix removed.
        /// </summary>
        /// <param name="shell">shell configuration name</param>
        /// <returns>display shell name</returns>
        private string GetDisplayShellName(string shell)
        {
            string shellPrefix = System.Management.Automation.Remoting.Client.WSManNativeApi.ResourceURIPrefix;
            int index = shell.IndexOf(shellPrefix, StringComparison.OrdinalIgnoreCase);

            return (index == 0) ? shell.Substring(shellPrefix.Length) : shell;
        }

        #endregion Private Methods

        #region Static Methods

        /// <summary>
        /// Generates a unique runspace id and name.
        /// </summary>
        /// <param name="rtnId">Returned Id</param>
        /// <returns>Returned name</returns>
        internal static String GenerateRunspaceName(out int rtnId)
        {
            int id = System.Threading.Interlocked.Increment(ref seed);
            rtnId = id;
            return ComposeRunspaceName(id);
        }

        /// <summary>
        /// Increments and returns a session unique runspace Id.
        /// </summary>
        /// <returns>Id</returns>
        internal static int GenerateRunspaceId()
        {
            return System.Threading.Interlocked.Increment(ref seed);
        }

        /// <summary>
        /// Creates a runspace name based on a given Id value.
        /// </summary>
        /// <param name="id">Integer Id</param>
        /// <returns>Runspace name</returns>
        internal static string ComposeRunspaceName(int id)
        {
            return "Session" + id.ToString(System.Globalization.NumberFormatInfo.InvariantInfo);
        }

        #endregion
    }
}
