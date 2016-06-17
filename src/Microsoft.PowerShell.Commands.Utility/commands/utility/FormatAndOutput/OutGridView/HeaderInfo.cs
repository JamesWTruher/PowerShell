//
//    Copyright (C) Microsoft.  All rights reserved.
//
namespace Microsoft.PowerShell.Commands
{
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Globalization;
    using System.Management.Automation;

    internal class HeaderInfo
    {
        private List<ColumnInfo> columns = new List<ColumnInfo>();

        internal void AddColumn(ColumnInfo col)
        {
            columns.Add(col);
        }

        internal PSObject AddColumnsToWindow(OutWindowProxy windowProxy, PSObject liveObject)
        {
            PSObject staleObject = new PSObject();

            // Initiate arrays to be of the same size.
            int count = columns.Count;
            string[] propertyNames = new string[count];
            string[] displayNames = new string[count];
            Type[] types = new Type[count];

            count = 0; // Reuse this variabe to count cycles.
            foreach(ColumnInfo column in columns)
            {
                propertyNames[count] = column.StaleObjectPropertyName();
                displayNames[count] = column.DisplayName();
                Object columnValue = null;
                types[count] = column.GetValueType(liveObject, out columnValue);

                // Add a property to the stale object since a column value has been evaluated to get column's type.
                staleObject.Properties.Add(new PSNoteProperty(propertyNames[count], columnValue));

                count++;
            }

            windowProxy.AddColumns(propertyNames, displayNames, types);

            return staleObject;
        }

        internal PSObject CreateStalePSObject(PSObject liveObject)
        {
            PSObject staleObject = new PSObject();
            foreach(ColumnInfo column in columns)
            {
                // Add a property to the stale PSObject.
                staleObject.Properties.Add(new PSNoteProperty(column.StaleObjectPropertyName(),
                                           column.GetValue(liveObject)));
            }
            return staleObject;
        }
    }
}