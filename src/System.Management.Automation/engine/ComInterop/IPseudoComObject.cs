/********************************************************************++
Copyright (c) Microsoft Corporation.  All rights reserved.
--********************************************************************/

#if !CLR2
using System.Linq.Expressions;
#else
using Microsoft.Scripting.Ast;
#endif

using System;
using System.Dynamic;

namespace System.Management.Automation.ComInterop {
    interface IPseudoComObject {
        DynamicMetaObject GetMetaObject(Expression expression);
    }
}

