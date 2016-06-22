﻿/********************************************************************++
Copyright (c) Microsoft Corporation.  All rights reserved.
--********************************************************************/

using System;
using System.Collections.Generic;
using System.Diagnostics.PerformanceData;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Text;

namespace System.Management.Automation.PerformanceData
{
    /// <summary>
    /// A struct that encapuslates the information pertaining to a given counter
    /// like name,type and id.
    /// </summary>
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1815:OverrideEqualsAndOperatorEqualsOnValueTypes")]
    public struct CounterInfo
    {
        #region Private Members
        /// <summary>
        /// Counter Name
        /// </summary>
        private string _Name;
        /// <summary>
        /// Counter Id
        /// </summary>
        private int _Id;
        /// <summary>
        /// Counter Type
        /// </summary>
        private CounterType _Type;

        #endregion

        #region Constructors
        /// <summary>
        /// Constructor
        /// </summary>
        public CounterInfo(int id, CounterType type, string name)
        {
            this._Id = id;
            this._Type = type;
            this._Name = name;
        }

        /// <summary>
        /// Constructor
        /// </summary>
        public CounterInfo(int id, CounterType type)
        {
            this._Id = id;
            this._Type = type;
            this._Name = null;
        }
        #endregion

        #region Properties
        /// <summary>
        /// Getter for Counter Name property
        /// </summary>
        public string Name
        {
            get
            {
                return this._Name;
            }
        }

        /// <summary>
        /// Getter for Counter Id property.
        /// </summary>
        public int Id
        {
            get
            {
                return this._Id;
            }
        }

        /// <summary>
        /// Getter for Counter Type property.
        /// </summary>
        [SuppressMessage("Microsoft.Naming", "CA1721:PropertyNamesShouldNotMatchGetMethods")]
        public CounterType Type
        {
            get
            {
                return this._Type;
            }
        }

        #endregion
    }

    /// <summary>
    /// An abstract class that forms the base class for any CounterSetRegistrar type.
    /// Any client that needs to register a new type of perf counter category with the
    /// PSPerfCountersMgr, should create an instance of CounterSetRegistrarBase's
    /// derived non-abstract type.
    /// The created instance is then passed to PSPerfCounterMgr's AddCounterSetInstance()
    /// method.
    /// 
    /// </summary>
    public abstract class CounterSetRegistrarBase
    {
        #region Private Members
        private readonly Guid _providerId;
        private readonly Guid _counterSetId;
        private readonly string _counterSetName;
        private readonly CounterSetInstanceType _counterSetInstanceType;
        private readonly CounterInfo[] _counterInfoArray;

        #endregion
        
        #region Protected Members
        /// <summary>
        /// A reference to the encapsulated counter set instance.
        /// </summary>
        [SuppressMessage("Microsoft.Design", "CA1051:DoNotDeclareVisibleInstanceFields")]
        protected CounterSetInstanceBase _counterSetInstanceBase;

        /// <summary>
        /// Method that creates an instance of the CounterSetInstanceBase's derived type.
        /// This method is invoked by the PSPerfCountersMgr to retrieve the appropriate
        /// instance of CounterSet to register with its internal datastructure.
        /// </summary>
        protected abstract CounterSetInstanceBase CreateCounterSetInstance();


        #endregion
        
        #region Constructors
        /// <summary>
        /// Constructor that creates an instance of CounterSetRegistrarBase derived type
        /// based on Provider Id, counterSetId, counterSetInstanceType, a collection 
        /// with counters information and an optional counterSetName.
        /// </summary>
        [SuppressMessage("Microsoft.Design", "CA1026:DefaultParametersShouldNotBeUsed")]
        protected CounterSetRegistrarBase(
            Guid providerId,
            Guid counterSetId,
            CounterSetInstanceType counterSetInstType,
            CounterInfo[] counterInfoArray,
            string counterSetName=null)
        {
            this._providerId = providerId;
            this._counterSetId = counterSetId;
            this._counterSetInstanceType = counterSetInstType;
            this._counterSetName = counterSetName;
            if((counterInfoArray == null)
                || (counterInfoArray.Length == 0))
            {
                throw new ArgumentNullException("counterInfoArray");
            }

            this._counterInfoArray = new CounterInfo[counterInfoArray.Length];

            for (int i = 0; i < counterInfoArray.Length; i++)
            {
                this._counterInfoArray[i] =
                    new CounterInfo(
                        counterInfoArray[i].Id,
                        counterInfoArray[i].Type,
                        counterInfoArray[i].Name
                        );
            }
            this._counterSetInstanceBase = null;
        }

        /// <summary>
        /// Copy constructor
        /// </summary>
        protected CounterSetRegistrarBase(
            CounterSetRegistrarBase srcCounterSetRegistrarBase)
        {
            if (srcCounterSetRegistrarBase == null)
            {
                throw new ArgumentNullException("srcCounterSetRegistrarBase");
            }
            this._providerId = srcCounterSetRegistrarBase._providerId;
            this._counterSetId = srcCounterSetRegistrarBase._counterSetId;
            this._counterSetInstanceType = srcCounterSetRegistrarBase._counterSetInstanceType;
            this._counterSetName = srcCounterSetRegistrarBase._counterSetName;

            CounterInfo[] counterInfoArrayRef = srcCounterSetRegistrarBase._counterInfoArray;
            this._counterInfoArray = new CounterInfo[counterInfoArrayRef.Length];

            for (int i = 0; i < counterInfoArrayRef.Length; i++)
            {
                this._counterInfoArray[i] =
                    new CounterInfo(
                        counterInfoArrayRef[i].Id,
                        counterInfoArrayRef[i].Type,
                        counterInfoArrayRef[i].Name);
            }

        }
        #endregion

        #region Properties

        /// <summary>
        /// Getter method for ProviderId property
        /// </summary>
        public Guid ProviderId 
        { 
            get
            {
                return this._providerId;
            }
        }

        /// <summary>
        /// Getter method for CounterSetId property
        /// </summary>
        public Guid CounterSetId
        {
            get
            {
                return this._counterSetId;
            }
        }

        /// <summary>
        /// Getter method for CounterSetName property
        /// </summary>
        public string CounterSetName
        {
            get
            {
                return this._counterSetName;
            }
        }

        /// <summary>
        /// Getter method for CounterSetInstanceType property
        /// </summary>
        public CounterSetInstanceType CounterSetInstType
        {
            get
            {
                return this._counterSetInstanceType;
            }
        }

        /// <summary>
        /// Getter method for array of counters information property
        /// </summary>
        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public CounterInfo[] CounterInfoArray
        {
            get
            {
                return this._counterInfoArray;
            }
        }

        
        /// <summary>
        /// Getter method that returns an instance of the CounterSetInstanceBase's 
        /// derived type
        /// </summary>
        public CounterSetInstanceBase CounterSetInstance
        {
            get
            {
                if (this._counterSetInstanceBase == null)
                {
                    this._counterSetInstanceBase = this.CreateCounterSetInstance();
                }
                return this._counterSetInstanceBase;
            }
        }
        
        #endregion

        
        #region Public Methods

        
        /// <summary>
        /// Method that disposes the referenced instance of the CounterSetInstanceBase's derived type.
        /// This method is invoked by the PSPerfCountersMgr to dispose the appropriate
        /// instance of CounterSet from its internal datastructure as part of PSPerfCountersMgr
        /// cleanup procedure.
        /// </summary>
        public abstract void DisposeCounterSetInstance();
        
        #endregion
    
    }

    /// <summary>
    /// PSCounterSetRegistrar implements the abstract methods of CounterSetRegistrarBase.
    /// Any client that needs to register a new type of perf counter category with the
    /// PSPerfCountersMgr, should create an instance of PSCounterSetRegistrar.
    /// The created instance is then passed to PSPerfCounterMgr's AddCounterSetInstance()
    /// method.
    /// </summary>
    public class PSCounterSetRegistrar : CounterSetRegistrarBase
    {
        #region Constructors
        /// <summary>
        /// Constructor that creates an instance of PSCounterSetRegistrar.
        /// </summary>
        [SuppressMessage("Microsoft.Design", "CA1026:DefaultParametersShouldNotBeUsed")]
        public PSCounterSetRegistrar(
            Guid providerId,
            Guid counterSetId,
            CounterSetInstanceType counterSetInstType,
            CounterInfo[] counterInfoArray,
            string counterSetName = null)
            : base(providerId, counterSetId, counterSetInstType, counterInfoArray, counterSetName)
        {
        }

        /// <summary>
        /// Copy Constructor
        /// </summary>
        public PSCounterSetRegistrar(
            PSCounterSetRegistrar srcPSCounterSetRegistrar)
            : base(srcPSCounterSetRegistrar)
        {
            if (srcPSCounterSetRegistrar == null)
            {
                throw new ArgumentNullException("srcPSCounterSetRegistrar");
            }
        }


        #endregion

        #region CounterSetRegistrarBase Overrides
        
        #region Protected Methods

        /// <summary>
        /// Method that creates an instance of the CounterSetInstanceBase's derived type.
        /// </summary>
        protected override CounterSetInstanceBase CreateCounterSetInstance()
        {
            return new PSCounterSetInstance(this);
        }

        #endregion

        #region Public Methods
        /// <summary>
        /// Method that disposes the referenced instance of the CounterSetInstanceBase's derived type.
        /// </summary>
        public override void DisposeCounterSetInstance()
        {
            base._counterSetInstanceBase.Dispose();
        }
        
        #endregion
       
        
        #endregion

    }

}
