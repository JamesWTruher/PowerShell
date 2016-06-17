/********************************************************************++
Copyright (c) Microsoft Corporation.  All rights reserved.
--********************************************************************/

using System;
using System.Collections;
using System.Management.Automation;
using System.Diagnostics.CodeAnalysis;

namespace Microsoft.PowerShell.Commands
{
    /// <summary>
    /// This cmdlet updates the property of incoming objects and passes them to the 
    /// pipeline. This cmdlet also returns a .NET object with properties that 
    /// defines the update action on a list.
    /// 
    /// This cmdlet is most helpful when the cmdlet author wants the user to do 
    /// update action on object list that are not directly exposed through 
    /// cmdlet parameter. One wants to update a property value which is a list 
    /// (multi-valued parameter for a cmdlet), without exposing the list.
    /// </summary>
    [Cmdlet(VerbsData.Update, "List", DefaultParameterSetName = "AddRemoveSet",
        HelpUri = "http://go.microsoft.com/fwlink/?LinkID=113447", RemotingCapability = RemotingCapability.None)]
    public class UpdateListCommand : PSCmdlet
    {
        /// <summary>
        /// The following is the definition of the input parameter "Add".
        /// Objects to be add to the list
        /// </summary>
        [Parameter(ParameterSetName = "AddRemoveSet")]
        [ValidateNotNullOrEmpty()]
        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Justification = "Cmdlets use arrays for parameters.")]
        public object[] Add
        {
            get { return _add; }
            set { _add = value; }
        }
        private object[] _add;

        /// <summary>
        /// The following is the definition of the input parameter "Remove".
        /// Objects to be removed from the list
        /// </summary>
        [Parameter(ParameterSetName = "AddRemoveSet")]
        [ValidateNotNullOrEmpty()]
        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Justification = "Cmdlets use arrays for parameters.")]
        public object[] Remove
        {
            get { return _remove; }
            set { _remove = value; }
        }
        private object[] _remove;

        /// <summary>
        /// The following is the definition of the input parameter "Replace".
        /// Objects in this list replace the objects in the target list.
        /// </summary>
        [Parameter(Mandatory = true, ParameterSetName = "ReplaceSet")]
        [ValidateNotNullOrEmpty()]
        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays", Justification = "Cmdlets use arrays for parameters.")]
        public object[] Replace
        {
            get { return _replace; }
            set { _replace = value; }
        }
        private object[] _replace;

        /// <summary>
        /// The following is the definition of the input parameter "InputObject".
        /// List of InputObjects where the updates needs to applied to the 
        /// specific property
        /// </summary>
        //[Parameter(ValueFromPipeline = true, ParameterSetName = "AddRemoveSet")]
        //[Parameter(ValueFromPipeline = true, ParameterSetName = "ReplaceSet")]
        [Parameter(ValueFromPipeline = true)]
        [ValidateNotNullOrEmpty()]
        public PSObject InputObject
        {
            get { return _inputobject; }
            set { _inputobject = value; }
        }
        private PSObject _inputobject;

        /// <summary>
        /// The following is the definition of the input parameter "Property".
        /// Defines which property of the input object should be updated with Add and 
        /// Remove actions
        /// </summary>
        //[Parameter(Position = 0, ParameterSetName = "AddRemoveSet")]
        //[Parameter(Position = 0, ParameterSetName = "ReplaceSet")]
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        public string Property
        {
            get { return _property; }
            set { _property = value; }
        }
        private string _property;

        private PSListModifier listModifier;

        /// <summary>
        /// ProcessRecord method.
        /// </summary>
        protected override void ProcessRecord()
        {
            if (Property != null)
            {
                if (InputObject == null)
                {
                    WriteError(NewError("MissingInputObjectParameter", "MissingInputObjectParameter", null));
                }
                else
                {
                    if (listModifier == null)
                    {
                        listModifier = CreatePSListModifier();
                    }

                    PSMemberInfo memberInfo = InputObject.Members[Property];
                    if (memberInfo != null)
                    {
                        try
                        {
                            listModifier.ApplyTo(memberInfo.Value);
                            WriteObject(InputObject);
                        }
                        catch (PSInvalidOperationException e)
                        {
                            WriteError(new ErrorRecord(e, "ApplyFailed", ErrorCategory.InvalidOperation, null));
                        }
                    }
                    else
                    {
                        WriteError(NewError("MemberDoesntExist", "MemberDoesntExist", InputObject, Property));
                    }
                }
            }
        }


        /// <summary>
        /// EndProcessing method.
        /// </summary>
        protected override void EndProcessing()
        {
            if (Property == null)
            {
                if (InputObject != null)
                {
                    ThrowTerminatingError(NewError("MissingPropertyParameter", "MissingPropertyParameter", null));
                }
                else
                {
                    WriteObject(CreateHashtable());
                }
            }
        }

        private Hashtable CreateHashtable()
        {
            Hashtable hash = new Hashtable(2);
            if (Add != null)
            {
                hash.Add("Add", Add);
            }
            if (Remove != null)
            {
                hash.Add("Remove", Remove);
            }
            if (Replace != null)
            {
                hash.Add("Replace", Replace);
            }
            return hash;
        }

        private PSListModifier CreatePSListModifier()
        {
            PSListModifier listModifier = new PSListModifier();
            if (Add != null)
            {
                foreach (object obj in Add)
                {
                    listModifier.Add.Add(obj);
                }
            }
            if (Remove != null)
            {
                foreach (object obj in Remove)
                {
                    listModifier.Remove.Add(obj);
                }
            }
            if (Replace != null)
            {
                foreach (object obj in Replace)
                {
                    listModifier.Replace.Add(obj);
                }
            }
            return listModifier;
        }

        private ErrorRecord NewError(string errorId, string resourceId, object targetObject, params object[] args)
        {
            ErrorDetails details = new ErrorDetails(this.GetType().Assembly, "UpdateListStrings", resourceId, args);
            ErrorRecord errorRecord = new ErrorRecord(
                new InvalidOperationException(details.Message),
                errorId,
                ErrorCategory.InvalidOperation,
                targetObject);
            return errorRecord;
        }
    }
}
