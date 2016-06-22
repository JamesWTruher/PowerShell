/********************************************************************++
Copyright (c) Microsoft Corporation.  All rights reserved.
--********************************************************************/

using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.Management.Automation;
using System.Management.Automation.Internal;
using Microsoft.PowerShell.Commands.Internal.Format;

namespace Microsoft.PowerShell.Commands
{
    /// <summary>
    /// Class output by Measure-Object
    /// </summary>
    public abstract class MeasureInfo
    {
        /// <summary>
        /// 
        /// property name
        /// 
        /// </summary>
        public string Property
        {
            get { return property; }
            set { property = value; }
        }
        private string property = null;
    }

    /// <summary>
    /// Class output by Measure-Object
    /// </summary>
    public sealed class GenericMeasureInfo : MeasureInfo
    {
        /// <summary>
        /// default ctor
        /// </summary>
        public GenericMeasureInfo()
        {
            average = sum = max = min = null;
        }

        /// <summary>
        /// 
        /// Keeping track of number of objects with a certain property
        /// 
        /// </summary>
        public int Count
        {
            get { return count; }
            set { count = value; }
        }
        private int count;

        /// <summary>
        /// 
        /// The average of property values
        /// 
        /// </summary>
        public double? Average
        {
            get { return average; }
            set { average = value; }
        }
        private double? average;

        /// <summary>
        /// 
        /// The sum of property values
        /// 
        /// </summary>
        public double? Sum
        {
            get { return sum; }
            set { sum = value; }
        }
        private double? sum;

        /// <summary>
        /// 
        /// The max of property values
        /// 
        /// </summary>
        public double? Maximum
        {
            get { return max; }
            set { max = value; }
        }
        private double? max;

        /// <summary>
        /// 
        /// The min of property values
        /// 
        /// </summary>
        public double? Minimum
        {
            get { return min; }
            set { min = value; }
        }
        private double? min;

    }

    /// <summary>
    /// Class output by Measure-Object. 
    /// </summary>
    /// <remarks>
    /// This class is created for fixing "Measure-Object -MAX -MIN  should work with ANYTHING that supports CompareTo"
    /// bug (Win8:343911).  
    /// GenericMeasureInfo class is shipped with PowerShell V2. Fixing this bug requires, changing the type of
    /// Maximum and Minimum properties which would be a breaking change. Hence created a new class to not
    /// have an appcompat issues with PS V2.
    /// </remarks>
    public sealed class GenericObjectMeasureInfo : MeasureInfo
    {
        /// <summary>
        /// default ctor
        /// </summary>
        public GenericObjectMeasureInfo()
        {
            average = sum = null;
            max = min = null;
        }

        /// <summary>
        /// 
        /// Keeping track of number of objects with a certain property
        /// 
        /// </summary>
        public int Count
        {
            get { return count; }
            set { count = value; }
        }
        private int count;

        /// <summary>
        /// 
        /// The average of property values
        /// 
        /// </summary>
        public double? Average
        {
            get { return average; }
            set { average = value; }
        }
        private double? average;

        /// <summary>
        /// 
        /// The sum of property values
        /// 
        /// </summary>
        public double? Sum
        {
            get { return sum; }
            set { sum = value; }
        }
        private double? sum;

        /// <summary>
        /// 
        /// The max of property values
        /// 
        /// </summary>
        public object Maximum
        {
            get { return max; }
            set { max = value; }
        }
        private object max;

        /// <summary>
        /// 
        /// The min of property values
        /// 
        /// </summary>
        public object Minimum
        {
            get { return min; }
            set { min = value; }
        }
        private object min;
    }


    /// <summary>
    /// Class output by Measure-Object
    /// </summary>
    public sealed class TextMeasureInfo : MeasureInfo
    {
        /// <summary>
        /// default ctor
        /// </summary>
        public TextMeasureInfo()
        {
            lines = words = characters = null;
        }

        /// <summary>
        /// 
        /// Keeping track of number of objects with a certain property
        /// 
        /// </summary>
        public int? Lines
        {
            get { return lines; }
            set { lines = value; }
        }
        private int? lines;

        /// <summary>
        /// 
        /// The average of property values
        /// 
        /// </summary>
        public int? Words
        {
            get { return words; }
            set { words = value; }
        }
        private int? words;

        /// <summary>
        /// 
        /// The sum of property values
        /// 
        /// </summary>
        public int? Characters
        {
            get { return characters; }
            set { characters = value; }
        }
        private int? characters;

    }

    /// <summary>
    /// measure object cmdlet
    /// </summary>
    [Cmdlet(VerbsDiagnostic.Measure, "Object", DefaultParameterSetName = GenericParameterSet,
        HelpUri = "http://go.microsoft.com/fwlink/?LinkID=113349", RemotingCapability = RemotingCapability.None)]
    [OutputType(typeof(GenericMeasureInfo), typeof(TextMeasureInfo), typeof(GenericObjectMeasureInfo))]
    public sealed class MeasureObjectCommand : PSCmdlet
    {
        /// <summary>
        /// Dictionary to be used by Measure-Object implementation
        /// Keys are strings. Keys are compared with OrdinalIgnoreCase.
        /// </summary>
        /// <typeparam name="V">Value type.</typeparam>
        private class MeasureObjectDictionary<V> : Dictionary<string, V>
            where V : new()
        {
            /// <summary>
            /// default ctor
            /// </summary>
            internal MeasureObjectDictionary() : base(StringComparer.OrdinalIgnoreCase)
            {
            }

            /// <summary>
            /// Attempt to look up the value associated with the
            /// the specified key. If a value is not found, associate
            /// the key with a new value created via the value type's
            /// default constructor.
            /// </summary>
            /// <param name="key">The key to look up</param>
            /// <returns>
            /// The existing value, or a newly-created value.
            /// </returns>
            public V EnsureEntry(string key)
            {
                V val;
                if (!TryGetValue(key, out val))
                {
                    val = new V();
                    this[key] = val;
                }

                return val;
            }
        }

        /// <summary>
        /// Convenience class to track statistics without having
        /// to maintain two sets of MeasureInfo and constantly checking
        /// what mode we're in.
        /// </summary>

        [SuppressMessage("Microsoft.Performance", "CA1812:AvoidUninstantiatedInternalClasses")]
        private class Statistics
        {
            // Common properties
            internal int count = 0;

            // Generic/Numeric statistics
            internal double sum = 0.0;
            internal object max = null;
            internal object min = null;

            // Text statistics
            internal int characters = 0;
            internal int words = 0;
            internal int lines = 0;
        }

        /// <summary>
        /// default constructor
        /// </summary>
        public MeasureObjectCommand()
            : base()
        {
        }

        #region Command Line Switches

        #region Common parameters in both sets

        /// <summary>
        /// incoming object
        /// </summary>
        /// <value></value>
        [Parameter(ValueFromPipeline = true)]
        public PSObject InputObject
        {
            set { inputObject = value; }
            get { return inputObject; }
        }
        private PSObject inputObject = AutomationNull.Value;

        /// <summary>
        /// Properties to be examined
        /// </summary>
        /// <value></value>
        [ValidateNotNullOrEmpty]
        [Parameter(Position = 0)]
        public string[] Property
        {
            get
            {
                return property;
            }
            set
            {
                property = value;
            }
        }
        private string[] property = null;
        #endregion Common parameters in both sets

        /// <summary>
        /// Set to true is Sum is to be returned
        /// </summary>
        /// <value></value>
        [Parameter(ParameterSetName = GenericParameterSet)]
        public SwitchParameter Sum
        {
            get
            {
                return measureSum;
            }
            set
            {
                measureSum = value;
            }
        }
        private bool measureSum;

        /// <summary>
        /// Set to true is Average is to be returned
        /// </summary>
        /// <value></value>
        [Parameter(ParameterSetName = GenericParameterSet)]
        public SwitchParameter Average
        {
            get
            {
                return measureAverage;
            }
            set
            {
                measureAverage = value;
            }
        }
        private bool measureAverage;

        /// <summary>
        /// Set to true is Max is to be returned
        /// </summary>
        /// <value></value>
        [Parameter(ParameterSetName = GenericParameterSet)]
        public SwitchParameter Maximum
        {
            get
            {
                return measureMax;
            }
            set
            {
                measureMax = value;
            }
        }
        private bool measureMax;

        /// <summary>
        /// Set to true is Min is to be returned
        /// </summary>
        /// <value></value>
        [Parameter(ParameterSetName = GenericParameterSet)]
        public SwitchParameter Minimum
        {
            get
            {
                return measureMin;
            }
            set
            {
                measureMin = value;
            }
        }
        private bool measureMin;

        #region TextMeasure ParameterSet
        /// <summary>
        /// 
        /// </summary>
        /// <value></value>
        [Parameter(ParameterSetName = TextParameterSet)]
        public SwitchParameter Line
        {
            get
            {
                return measureLines;
            }
            set
            {
                measureLines = value;
            }
        }
        private bool measureLines = false;

        /// <summary>
        /// 
        /// </summary>
        /// <value></value>
        [Parameter(ParameterSetName = TextParameterSet)]
        public SwitchParameter Word
        {
            get
            {
                return measureWords;
            }
            set
            {
                measureWords = value;
            }
        }
        private bool measureWords = false;

        /// <summary>
        /// 
        /// </summary>
        /// <value></value>
        [Parameter(ParameterSetName = TextParameterSet)]
        public SwitchParameter Character
        {
            get
            {
                return measureCharacters;
            }
            set
            {
                measureCharacters = value;
            }
        }
        private bool measureCharacters = false;

        /// <summary>
        /// 
        /// </summary>
        /// <value></value>
        [Parameter(ParameterSetName = TextParameterSet)]
        public SwitchParameter IgnoreWhiteSpace
        {
            get
            {
                return ignoreWhiteSpace;
            }
            set
            {
                ignoreWhiteSpace = value;
            }
        }
        private bool ignoreWhiteSpace;

        #endregion TextMeasure ParameterSet
        #endregion Command Line Switches


        /// <summary>
        /// Which parameter set the Cmdlet is in.
        /// </summary>
        private bool IsMeasuringGeneric
        {
            get
            {
                return String.Compare(ParameterSetName, GenericParameterSet, StringComparison.Ordinal) == 0;
            }
        }

        /// <summary>
        /// Collect data about each record that comes in. 
        /// Side effects: Updates totalRecordCount.
        /// </summary>
        protected override void ProcessRecord()
        {
            if (inputObject == null || inputObject == AutomationNull.Value)
            {
                return;
            }

            totalRecordCount++;

            if (Property == null)
                AnalyzeValue(null, inputObject.BaseObject);
            else
                AnalyzeObjectProperties(inputObject);
        }

        /// <summary>
        /// Analyze an object on a property-by-property basis instead
        /// of as a simple value.
        /// Side effects: Updates statistics.
        /// <param name="inObj">The object to analyze.</param>
        /// </summary>
        private void AnalyzeObjectProperties(PSObject inObj)
        {
            // Keep track of which properties are counted for an
            // input object so that repeated properties won't be
            // counted twice. 
            MeasureObjectDictionary<object> countedProperties = new MeasureObjectDictionary<object>();

            // First iterate over the user-specified list of
            // properties...
            foreach (string p in Property)
            {
                MshExpression expression = new MshExpression(p);
                List<MshExpression> resolvedNames = expression.ResolveNames(inObj);
                if (resolvedNames == null || resolvedNames.Count == 0)
                {
                    // Insert a blank entry so we can track
                    // property misses in EndProcessing.
                    if (!expression.HasWildCardCharacters)
                    {
                        string propertyName = expression.ToString();
                        statistics.EnsureEntry(propertyName);
                    }

                    continue;
                }

                // Each property value can potentially refer
                // to multiple properties via globbing. Iterate over
                // the actual property names.
                foreach (MshExpression resolvedName in resolvedNames)
                {
                    string propertyName = resolvedName.ToString();
                    // skip duplicated properties
                    if (countedProperties.ContainsKey(propertyName))
                    {
                        continue;
                    }

                    List<MshExpressionResult> tempExprRes = resolvedName.GetValues(inObj);
                    if (tempExprRes == null || tempExprRes.Count == 0)
                    {
                        // Shouldn't happen - would somehow mean
                        // that the property went away between when
                        // we resolved it and when we tried to get its
                        // value.
                        continue;
                    }

                    AnalyzeValue(propertyName, tempExprRes[0].Result);

                    // Remember resolved propertNames that have been counted
                    countedProperties[propertyName] = null;
                }
            }
        }

        /// <summary>
        /// Analyze a value for generic/text statistics.
        /// Side effects: Updates statistics. May set nonNumericError.
        /// <param name="propertyName">The property this value corresponds to.</param>
        /// <param name="objValue">The value to analyze.</param>
        /// </summary>
        private void AnalyzeValue(string propertyName, object objValue)
        {
            if (propertyName == null)
                propertyName = thisObject;

            Statistics stat = statistics.EnsureEntry(propertyName);

            // Update common properties.
            stat.count++;

            if (measureCharacters || measureWords || measureLines)
            {
                string strValue = (objValue == null) ? "" : objValue.ToString();
                AnalyzeString(strValue, stat);
            }

            if (measureAverage || measureSum)
            {
                double numValue = 0.0;
                if (!LanguagePrimitives.TryConvertTo(objValue, out numValue))
                {
                    nonNumericError = true;
                    ErrorRecord errorRecord = new ErrorRecord(
                        PSTraceSource.NewInvalidOperationException(MeasureObjectStrings.NonNumericInputObject, objValue),
                        "NonNumericInputObject",
                        ErrorCategory.InvalidType,
                        objValue);
                    WriteError(errorRecord);
                    return;
               }

               AnalyzeNumber(numValue, stat);
            }

            // Win8:343911 Measure-Object -MAX -MIN  should work with ANYTHING that supports CompareTo
            if (measureMin)
            {
                stat.min = Compare(objValue, stat.min, true);
            }

            if (measureMax)
            {
                stat.max = Compare(objValue, stat.max, false);
            }
        }

        /// <summary>
        /// Compare is a helper function used to find the min/max between the supplied input values.
        /// </summary>
        /// <param name="objValue">
        /// Current input value.
        /// </param>
        /// <param name="statMinOrMaxValue">
        /// Current minimum or maximum value in the statistics.
        /// </param>
        /// <param name="isMin">
        /// Indicates if minimum or maximum value has to be found. 
        /// If true is passed in then the minimum of the two values would be returned.
        /// If false is passed in then maximum of the two values will be returned.</param>
        /// <returns></returns>
        private object Compare(object objValue , object statMinOrMaxValue, bool isMin)
        {
            object currentValue = objValue;
            object statValue = statMinOrMaxValue;
            int factor = isMin ? 1 : -1;

            double temp;
            currentValue = ((objValue != null) && LanguagePrimitives.TryConvertTo<double>(objValue, out temp)) ? temp : currentValue;
            statValue = ((statValue != null) && LanguagePrimitives.TryConvertTo<double>(statValue, out temp)) ? temp : statValue;

            if (currentValue != null && statValue != null && !currentValue.GetType().Equals(statValue.GetType()))
            {
                currentValue = PSObject.AsPSObject(currentValue).ToString();
                statValue = PSObject.AsPSObject(statValue).ToString();
            }

            if ((statValue == null) || 
                ((LanguagePrimitives.Compare(statValue, currentValue, false, CultureInfo.CurrentCulture) * factor) > 0))
            {
                return objValue;
            }

            return statMinOrMaxValue;
        }

        /// <summary>
        /// Class contains util static functions
        /// </summary>
        private static class TextCountUtilities
        {
            /// <summary>
            /// count chars in inStr
            /// </summary>
            /// <param name="inStr">string whose chars are counted</param>
            /// <param name="ignoreWhiteSpace">true to discount white space</param>
            /// <returns>number of chars in inStr</returns>
            internal static int CountChar(string inStr, bool ignoreWhiteSpace)
            {
                if (String.IsNullOrEmpty(inStr))
                {
                    return 0;
                }
                if (!ignoreWhiteSpace)
                {
                    return inStr.Length;
                }
                int len = 0;
                foreach (char c in inStr)
                {
                    if (!char.IsWhiteSpace(c))
                    {
                        len++;
                    }
                }
                return len;
            }
            
            /// <summary>
            /// count words in inStr
            /// </summary>
            /// <param name="inStr">string whose words are counted</param>
            /// <returns>number of words in inStr</returns>
            internal static int CountWord(string inStr)
            {
                if (String.IsNullOrEmpty(inStr))
                {
                    return 0;
                }
                int wordCount = 0;
                bool wasAWhiteSpace = true;
                foreach (char c in inStr)
                {
                    if (char.IsWhiteSpace(c))
                    {
                        wasAWhiteSpace = true;
                    }
                    else
                    {
                        if (wasAWhiteSpace)
                        {
                            wordCount++;
                        }
                        wasAWhiteSpace = false;
                    }
                }
                return wordCount;
            }

            /// <summary>
            /// count lines in inStr
            /// </summary>
            /// <param name="inStr">string whose lines are counted</param>
            /// <returns>number of lines in inStr</returns>
            internal static int CountLine(string inStr)
            {
                if (String.IsNullOrEmpty(inStr))
                {
                    return 0;
                }
                int numberOfLines = 0;
                foreach (char c in inStr)
                {
                    if (c == '\n')
                    {
                        numberOfLines++;
                    }
                }
                // 'abc\nd' has two lines
                // but 'abc\n' has one line
                if (inStr[inStr.Length - 1] != '\n')
                {
                    numberOfLines++;
                }
                return numberOfLines;
            }
        }

        /// <summary>
        /// Update text statistics.
        /// <param name="strValue">The text to analyze.</param>
        /// <param name="stat">The Statistics object to update.</param>
        /// </summary>
        private void AnalyzeString(string strValue, Statistics stat)
        {
            if (measureCharacters)
                stat.characters += TextCountUtilities.CountChar(strValue, ignoreWhiteSpace);
            if (measureWords)
                stat.words += TextCountUtilities.CountWord(strValue);
            if (measureLines)
                stat.lines += TextCountUtilities.CountLine(strValue);
        }

        /// <summary>
        /// Update number statistics.
        /// <param name="numValue">The number to analyze.</param>
        /// <param name="stat">The Statistics object to update.</param>
        /// </summary>
        private void AnalyzeNumber(double numValue, Statistics stat)
        {
           if (measureSum || measureAverage)
               stat.sum += numValue;
        }

        /// <summary>
        /// WriteError when a property is not found
        /// </summary>
        /// <param name="propertyName">The missing property.</param>
        /// <param name="errorId">The error ID to write.</param>
        private void WritePropertyNotFoundError(string propertyName, string errorId)
        {
            Diagnostics.Assert(property != null, "no property and no InputObject should have been addressed");
            ErrorRecord errorRecord = new ErrorRecord(
                    PSTraceSource.NewArgumentException("Property"),
                    errorId,
                    ErrorCategory.InvalidArgument,
                    null);
            errorRecord.ErrorDetails = new ErrorDetails(
                this, "MeasureObjectStrings", "PropertyNotFound", propertyName);
            WriteError(errorRecord);
        }

        /// <summary>
        /// Output collected statistics.
        /// Side effects: Updates statistics. Writes objects to stream.
        /// </summary>
        protected override void EndProcessing()
        {
            // Fix for 917114: If Property is not set,
            // and we aren't passed any records at all,
            // output 0s to emulate wc behavior.
            if (totalRecordCount == 0 && Property == null)
            {
                statistics.EnsureEntry(thisObject);
            }

            foreach (string propertyName in statistics.Keys)
            {
                Statistics stat = statistics[propertyName];
                if (stat.count == 0 && Property != null)
                {
                    // Why are there two different ids for this error?
                    string errorId = (IsMeasuringGeneric) ? "GenericMeasurePropertyNotFound" : "TextMeasurePropertyNotFound";
                    WritePropertyNotFoundError(propertyName, errorId);
                    continue;
                }

                MeasureInfo mi = null;
                if (IsMeasuringGeneric)
                {
                    double temp;
                    if ((stat.min == null || LanguagePrimitives.TryConvertTo<double>(stat.min, out temp)) &&
                        (stat.max == null || LanguagePrimitives.TryConvertTo<double>(stat.max, out temp)))
                    {
                        mi = CreateGenericMeasureInfo(stat, true);
                    }
                    else
                    {
                        mi = CreateGenericMeasureInfo(stat, false);
                    }
                }
                else
                    mi = CreateTextMeasureInfo(stat);
                      
                // Set common properties.                 
                if (Property != null)
                    mi.Property = propertyName;

                WriteObject(mi);
            }
        }

        /// <summary>
        /// Create a MeasureInfo object for generic stats.
        /// <param name="stat">The statistics to use.</param>
        /// <returns>A new GenericMeasureInfo object.</returns>
        /// </summary>
        /// <param name="shouldUseGenericMeasureInfo"></param>
        private MeasureInfo CreateGenericMeasureInfo(Statistics stat, bool shouldUseGenericMeasureInfo)
        {
            double? sum = null;
            double? average = null;
            object max = null;
            object min = null;
            
            if (!nonNumericError)
            {
                if (measureSum)
                    sum = stat.sum;
                if (measureAverage && stat.count > 0)
                    average = stat.sum / stat.count;
            }
            
            if (measureMax)
            {
                if (shouldUseGenericMeasureInfo && (stat.max != null))
                {
                    double temp;
                    LanguagePrimitives.TryConvertTo<double>(stat.max, out temp);
                    max = temp;
                }
                else
                {
                    max = stat.max;
                }
            }

            if (measureMin)
            {
                if (shouldUseGenericMeasureInfo && (stat.min != null))
                {
                    double temp;
                    LanguagePrimitives.TryConvertTo<double>(stat.min, out temp);
                    min = temp;
                }
                else
                {
                    min = stat.min;
                }
            }

            if (shouldUseGenericMeasureInfo)
            {
                GenericMeasureInfo gmi = new GenericMeasureInfo();
                gmi.Count = stat.count;
                gmi.Sum = sum;
                gmi.Average = average;
                if (null != max)
                {
                    gmi.Maximum = (double) max;
                }
                if (null != min)
                {
                    gmi.Minimum = (double) min;
                }

                return gmi;
            }
            else
            {
                GenericObjectMeasureInfo gomi = new GenericObjectMeasureInfo();
                gomi.Count = stat.count;
                gomi.Sum = sum;
                gomi.Average = average;
                gomi.Maximum = max;
                gomi.Minimum = min;

                return gomi;
            }
        }            

        /// <summary>
        /// Create a MeasureInfo object for text stats.
        /// <param name="stat">The statistics to use.</param>
        /// <returns>A new TextMeasureInfo object.</returns>
        /// </summary>
        private TextMeasureInfo CreateTextMeasureInfo(Statistics stat)
        {
            TextMeasureInfo tmi = new TextMeasureInfo();

            if (measureCharacters)
                tmi.Characters = stat.characters;
            if (measureWords)
                tmi.Words = stat.words;
            if (measureLines)
                tmi.Lines = stat.lines;

            return tmi;
        }            

        /// <summary>
        /// The observed statistics keyed by property name. If
        /// Property is not set, then the key used will be the
        /// value of thisObject.
        /// </summary>
        private MeasureObjectDictionary<Statistics> statistics = new MeasureObjectDictionary<Statistics>();

        /// <summary>
        /// Whether or not a numeric conversion error occurred.
        /// If true, then average/sum will not be output.
        /// </summary>
        private bool nonNumericError = false;

        /// <summary>
        /// The total number of records encountered.
        /// </summary>
        private int totalRecordCount = 0;
        
        /// <summary>
        /// Parameter set name for measuring objects.
        /// </summary>
        private const string GenericParameterSet = "GenericMeasure";

        /// <summary>
        /// Parameter set name for measuring text.
        /// </summary>
        private const string TextParameterSet = "TextMeasure";

        /// <summary>
        /// Key that statistics are stored under when Property is not set.
        /// </summary>
        private const string thisObject = "$_";

    }
}

