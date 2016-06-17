/********************************************************************++
Copyright (c) Microsoft Corporation.  All rights reserved.
 
Descripton: 
 
Windows Vista and later support non-traditional UI fallback ie., a 
user on an Arabic machine can choose either French or English(US) as
UI fallback language.

CLR does not support this (non-traditional) fallback mechanism. So 
the static methods in this class calculate appropriate UI Culture 
natively. ConsoleHot uses this API to set correct Thread UICulture.

Dependent on: 
GetThreadPreferredUILanguages 
SetThreadPreferredUILanguages

These methods are available on Windows Vista and later.

--********************************************************************/

using System;
using System.Globalization;
using System.Threading;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32;
using System.Collections.ObjectModel;
using System.Collections.Generic;

using System.Management.Automation;
using Dbg = System.Management.Automation.Diagnostics;
using WORD = System.UInt16;

namespace Microsoft.PowerShell
{
    /// <summary>
    /// Custom culture
    /// </summary>
    internal class VistaCultureInfo : CultureInfo
    {
        private string[] m_fallbacks;
        // Cache the immediate parent and immediate fallback
        private VistaCultureInfo parentCI = null;
        private object syncObject = new object();

        /// <summary>
        /// Constructs a CultureInfo that keeps track of fallbacks
        /// </summary>
        /// <param name="name">Name of the culture to construct.</param>
        /// <param name="fallbacks">
        /// ordered,null-delimited list of fallbacks
        /// </param>
        public VistaCultureInfo(string name,
            string[] fallbacks)
            : base(name)
        {
            m_fallbacks = fallbacks;
        }

        /// <summary>
        /// Returns Parent culture for the current CultureInfo.
        /// If Parent.Name is null or empty, then chooses the immediate fallback 
        /// If it is not empty, otherwise just returns Parent.
        /// </summary>
        public override CultureInfo Parent
        {
            get
            {
                // First traverse the parent heirarchy as established by CLR.
                // This is required because there is difference in the parent heirarchy
                // between CLR and Windows for Chinese. Ex: Native windows has
                // zh-CN->zh-Hans->neutral whereas CLR has zh-CN->zh-CHS->zh-Hans->neutral
                if ((null != base.Parent) && (!string.IsNullOrEmpty(base.Parent.Name)))
                {
                    return ImmediateParent;
                }

                
                // Check whether we have any fallback specified
                // MUI_MERGE_SYSTEM_FALLBACK | MUI_MERGE_USER_FALLBACK
                // returns fallback cultures (specified by the user)
                // and also adds neutral culture where appropriate.
                // Ex: ja-jp ja en-us en 
                while((null != m_fallbacks) && (m_fallbacks.Length > 0))
                {
                    string fallback = m_fallbacks[0];
                    string[] fallbacksForParent = null;

                    if (m_fallbacks.Length > 1)
                    {
                        fallbacksForParent = new string[m_fallbacks.Length - 1];
                        Array.Copy(m_fallbacks, 1, fallbacksForParent, 0, m_fallbacks.Length - 1);
                    }

                    try
                    {
                        return new VistaCultureInfo(fallback, fallbacksForParent);
                    }
                    // if there is any exception constructing the culture..catch..and go to
                    // the next culture in the list.
                    catch (ArgumentException)
                    {
                        m_fallbacks = fallbacksForParent;
                    }
                } 

                //no fallbacks..just return base parent
                return base.Parent;
            }
        }

        /// <summary>
        /// This is called to create the parent culture (as defined by CLR)
        /// of the current culture.
        /// </summary>
        private VistaCultureInfo ImmediateParent
        {
            get
            {
                if (null == parentCI)
                {
                    lock (syncObject)
                    {
                        if (null == parentCI)
                        {
                            string parentCulture = base.Parent.Name;
                            // remove the parentCulture from the m_fallbacks list.
                            // ie., remove duplicates from the parent heirarchy.
                            string[] fallbacksForTheParent = null;
                            if (null != m_fallbacks)
                            {
                                fallbacksForTheParent = new string[m_fallbacks.Length];
                                int currentIndex = 0;
                                foreach (string culture in m_fallbacks)
                                {
                                    if (!parentCulture.Equals(culture, StringComparison.OrdinalIgnoreCase))
                                    {
                                        fallbacksForTheParent[currentIndex] = culture;
                                        currentIndex++;
                                    }
                                }

                                // There is atlease 1 duplicate in m_fallbacks which was not added to
                                // fallbacksForTheParent array. Resize the array to take care of  this.
                                if (m_fallbacks.Length != currentIndex)
                                {
                                    Array.Resize<string>(ref fallbacksForTheParent, currentIndex);
                                }
                            }
                            parentCI = new VistaCultureInfo(parentCulture, fallbacksForTheParent);
                        }
                    }
                }

                return parentCI;
            }
        }

        /// <summary>
        /// Clones the custom CultureInfo retaining the fallbacks.
        /// </summary>
        /// <returns>Cloned custom CultureInfo</returns>
        public override object Clone()
        {
            return new VistaCultureInfo(base.Name, m_fallbacks);
        }
    }

    /// <summary>
    /// Static wrappers to get User chosen UICulture (for Vista and later)
    /// </summary>
    internal static class NativeCultureResolver
    {
        private static CultureInfo m_uiCulture = null;
        private static CultureInfo m_Culture = null;
        private static object m_syncObject = new object();

        /// <summary>
        /// Gets the UICulture to be used by console host
        /// </summary>
        internal static CultureInfo UICulture
        {
            get
            {
                if (null == m_uiCulture)
                {
                    lock (m_syncObject)
                    {
                        if (null == m_uiCulture)
                        {
                            m_uiCulture = GetUICulture();
                        }
                    }
                }

                return (CultureInfo)m_uiCulture.Clone();
            }
        }

        internal static CultureInfo Culture
        {
            get
            {
                if (null == m_Culture)
                {
                    lock (m_syncObject)
                    {
                        if (null == m_Culture)
                        {
                            m_Culture = GetCulture();
                        }
                    }
                }

                return m_Culture;
            }
        }

        internal static CultureInfo GetUICulture()
        {
            return GetUICulture(true);
        }

        internal static CultureInfo GetCulture()
        {
            return GetCulture(true);
        }

        internal static CultureInfo GetUICulture(bool filterOutNonConsoleCultures)
        {
            if (!IsVistaAndLater())
            {
                m_uiCulture = EmulateDownLevel();
                return m_uiCulture;
            }

            // We are running on Vista
            string langBuffer = GetUserPreferredUILangs(filterOutNonConsoleCultures);
            if (!string.IsNullOrEmpty(langBuffer))
            {
                try
                {
                    string[] fallbacks = langBuffer.Split(new char[] { '\0' },
                            StringSplitOptions.RemoveEmptyEntries);
                    string fallback = fallbacks[0];
                    string[] fallbacksForParent = null;

                    if (fallbacks.Length > 1)
                    {
                        fallbacksForParent = new string[fallbacks.Length - 1];
                        Array.Copy(fallbacks, 1, fallbacksForParent, 0, fallbacks.Length - 1);
                    }

                    m_uiCulture = new VistaCultureInfo(fallback, fallbacksForParent);
                    return m_uiCulture;
                }
                catch (ArgumentException)
                {
                }
            }

            m_uiCulture = EmulateDownLevel();
            return m_uiCulture;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("GoldMan", "#pw17903:UseOfLCID", Justification = "In XP and below GetUserDefaultLocaleName is not available")]
        internal static CultureInfo GetCulture(bool filterOutNonConsoleCultures)
        {
            CultureInfo returnValue;
            try
            {
                if (!IsVistaAndLater())
                {
                    int lcid = GetUserDefaultLCID();
                    returnValue = new CultureInfo(lcid);
                }
                else
                {
                    // Vista and above
                    StringBuilder name = new StringBuilder(16);
                    if (0 == GetUserDefaultLocaleName(name, 16))
                    {
                        // ther is an error retrieving the culture,
                        // just use the current thread's culture
                        returnValue = CultureInfo.CurrentCulture;
                    }
                    else
                    {
                        returnValue = new CultureInfo(name.ToString().Trim());
                    }
                }

                if (filterOutNonConsoleCultures)
                {
                    // filter out languages that console cannot display..
                    // Sometimes GetConsoleFallbackUICulture returns neutral cultures
                    // like "en" on "ar-SA". However neutral culture cannot be 
                    // asssigned as CurrentCulture. CreateSpecificCulture fixes
                    // this problem.
                    returnValue = CultureInfo.CreateSpecificCulture(
                        returnValue.GetConsoleFallbackUICulture().Name);
                }

            }
            catch (ArgumentException)
            {
                // if there is any exception retrieving the 
                // culture, just use the current thread's culture.
                returnValue = CultureInfo.CurrentCulture;
            }

            return returnValue;
        }

        [DllImport("kernel32.dll", SetLastError = false, CharSet = CharSet.Unicode)]
        internal static extern WORD GetUserDefaultUILanguage();

        /// <summary>
        /// Constructs CultureInfo object without considering any Vista and later 
        /// custom culture fallback logic.
        /// </summary>
        /// <returns>A CultureInfo object</returns>
        [System.Diagnostics.CodeAnalysis.SuppressMessage("GoldMan", "#pw17903:UseOfLCID", Justification = "This is only called In XP and below where GetUserDefaultLocaleName is not available, or as a fallback when GetThreadPreferredUILanguages fails")]
        private static CultureInfo EmulateDownLevel()
        {
            // GetConsoleFallbackUICulture is not required.
            // This is retained in order not to break existing code.
            ushort langId = NativeCultureResolver.GetUserDefaultUILanguage();
            CultureInfo ci = new CultureInfo((int)langId);
            return ci.GetConsoleFallbackUICulture();
        }

        /// <summary>
        /// Checks if the current operating system is Vista or later
        /// </summary>
        /// <returns>
        /// true, if vista and above
        /// false, otherwise.
        /// </returns>
        private static bool IsVistaAndLater()
        {
            // The version number is obtained from MSDN
            // 4 - Windows NT 4.0, Windows Me, Windows 98, or Windows 95. 
            // 5 - Windows Server 2003 R2, Windows Server 2003, Windows XP, or Windows 2000. 
            // 6 - Windows Vista or Windows Server "Longhorn". 

            if (Environment.OSVersion.Version.Major >= 6)
            {
                return true;
            }

            return false;
        }

        /// <summary>
        /// This method is called on vista and above.
        /// Using GetThreadPreferredUILanguages this method gets
        /// the UI languages a user has chosen.
        /// </summary>
        /// <returns>
        /// List of ThredPreferredUILanguages.
        /// </returns>
        /// <remarks>
        /// This method will work only on Vista and later.
        /// </remarks>
        private static string GetUserPreferredUILangs(bool filterOutNonConsoleCultures)
        {
            long numberLangs = 0;
            int bufferSize = 0;
            string returnval = "";


            if (filterOutNonConsoleCultures)
            {
                // Filter out languages that do not support console.
                // The third paramter should be null otherwise this API will not 
                // set Console CodePage filter.
                // The MSDN documentation does not call this out explicitly. Opened
                // Bug 950 (Windows Developer Content) to track this.
                if (!SetThreadPreferredUILanguages(MUI_CONSOLE_FILTER, null, IntPtr.Zero))
                {
                    return returnval;
                }
            }

            // calculate buffer size required
            // MUI_MERGE_SYSTEM_FALLBACK | MUI_MERGE_USER_FALLBACK
            // returns fallback cultures (specified by the user)
            // and also adds neutral culture where appropriate.
            // Ex: ja-jp ja en-us en 
            if (!GetThreadPreferredUILanguages(
                MUI_LANGUAGE_NAME | MUI_MERGE_SYSTEM_FALLBACK | MUI_MERGE_USER_FALLBACK,
                out numberLangs,
                null,
                out bufferSize))
            {
                return returnval;
            }

            // calculate space required to store output.
            // StringBuilder will not work for this case as CLR
            // does not copy the entire string if there are delimiter ('\0')
            // in the middle of a string.
            byte[] langBufferPtr = new byte[bufferSize * 2];

            // Now get the actual value
            if (!GetThreadPreferredUILanguages(
                MUI_LANGUAGE_NAME | MUI_MERGE_SYSTEM_FALLBACK | MUI_MERGE_USER_FALLBACK,
                out numberLangs,
                langBufferPtr, // Pointer to a buffer in which this function retrieves an ordered, null-delimited list.
                out bufferSize))
            {
                return returnval;
            }

            try
            {
                string langBuffer = Encoding.Unicode.GetString(langBufferPtr);
                returnval = langBuffer.Trim().ToLowerInvariant();
                return returnval;
            }
            catch (ArgumentNullException)
            {
            }
            catch (System.Text.DecoderFallbackException)
            {
            }

            return returnval;
        }

        #region Dll Import data

        /// <summary>
        /// Returns the locale identifier for the user default locale. 
        /// </summary>
        /// <returns></returns>
        /// <remarks>
        /// This function can return data from custom locales. Locales are not
        /// guaranteed to be the same from computer to computer or between runs
        /// of an application. If your application must persist or transmit data,
        /// see Using Persistent Locale Data. 
        /// Applications that are intended to run only on Windows Vista and later 
        /// should use GetUserDefaultLocaleName in preference to this function. 
        /// GetUserDefaultLocaleName provides good support for supplemental locales. 
        /// However, GetUserDefaultLocaleName is not supported for versions of Windows
        /// prior to Windows Vista.
        /// </remarks>
        [DllImport("kernel32.dll", SetLastError = false, CharSet = CharSet.Unicode)]
        private static extern int GetUserDefaultLCID();

        /// <summary>
        /// Retrieves the user default locale name.
        /// </summary>
        /// <param name="lpLocaleName"></param>
        /// <param name="cchLocaleName"></param>
        /// <returns>
        /// Returns the size of the buffer containing the locale name, including 
        /// the terminating null character, if successful. The function returns 0 
        /// if it does not succeed. To get extended error information, the applciation
        /// can call GetLastError. Possible returns from GetLastError
        /// include ERR_INSUFFICIENT_BUFFER.
        /// </returns>
        /// <remarks>
        /// 
        /// </remarks>
        [DllImport("kernel32.dll", SetLastError = false, CharSet = CharSet.Unicode)]
        private static extern int GetUserDefaultLocaleName(
            [MarshalAs(UnmanagedType.LPWStr)]
            StringBuilder lpLocaleName,
            int cchLocaleName);

        [DllImport("kernel32.dll", SetLastError = false, CharSet = CharSet.Unicode)]
        private static extern bool SetThreadPreferredUILanguages(int dwFlags,
            StringBuilder pwszLanguagesBuffer,
            IntPtr pulNumLanguages);

        [DllImport("kernel32.dll", SetLastError = false, CharSet = CharSet.Unicode)]
        private static extern bool GetThreadPreferredUILanguages(int dwFlags,
            out long pulNumLanguages,
            [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 2)]
            byte[] pwszLanguagesBuffer,
            out int pcchLanguagesBuffer);

        [DllImport("kernel32.dll", SetLastError = false, CharSet = CharSet.Unicode)]
        internal static extern Int16 SetThreadUILanguage(Int16 langId);

        //private static int MUI_LANGUAGE_ID = 0x4;
        private static int MUI_LANGUAGE_NAME = 0x8;
        private static int MUI_CONSOLE_FILTER = 0x100;
        private static int MUI_MERGE_USER_FALLBACK = 0x20;
        private static int MUI_MERGE_SYSTEM_FALLBACK =  0x10;

        #endregion
    }
}