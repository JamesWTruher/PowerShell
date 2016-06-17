//
//    Copyright (C) Microsoft.  All rights reserved.
//

namespace System.Management.Automation
{
    /// <summary>
    /// PinvokeDllNames contains the DLL names to be use for PInvoke in FullCLR/CoreCLR powershell.
    /// 
    /// * When adding a new DLL name here, make sure that you add both the FullCLR and CoreCLR version
    ///   of it. Add the comment '/*COUNT*/' with the new DLL name, and make sure the 'COUNT' is the 
    ///   same for both FullCLR and CoreCLR DLL names.
    /// </summary>
    internal static class PinvokeDllNames
    {
        internal const string QueryDosDeviceDllName = "kernel32.dll";                                        /*1*/
        internal const string CreateSymbolicLinkDllName = "kernel32.dll";                                    /*2*/
        internal const string GetOEMCPDllName = "kernel32.dll";                                              /*3*/
        internal const string DeviceIoControlDllName = "kernel32.dll";                                       /*4*/
        internal const string CreateFileDllName = "kernel32.dll";                                            /*5*/
        internal const string DeleteFileDllName = "kernel32.dll";                                            /*6*/
        internal const string FindCloseDllName = "kernel32.dll";                                             /*7*/
        internal const string GetFileAttributesDllName = "kernel32.dll";                                     /*8*/
        internal const string FindFirstFileDllName = "kernel32.dll";                                         /*9*/
        internal const string FindNextFileDllName = "kernel32.dll";                                          /*10*/
        internal const string RegEnumValueDllName = "advapi32.dll";                                          /*11*/
        internal const string RegOpenKeyExDllName = "advapi32.dll";                                          /*12*/
        internal const string RegOpenKeyTransactedDllName = "advapi32.dll";                                  /*13*/
        internal const string RegQueryInfoKeyDllName = "advapi32.dll";                                       /*14*/
        internal const string RegQueryValueExDllName = "advapi32.dll";                                       /*15*/
        internal const string RegSetValueExDllName = "advapi32.dll";                                         /*16*/
        internal const string RegCreateKeyTransactedDllName = "advapi32.dll";                                /*17*/
        internal const string CryptGenKeyDllName = "advapi32.dll";                                           /*18*/
        internal const string CryptDestroyKeyDllName = "advapi32.dll";                                       /*19*/
        internal const string CryptAcquireContextDllName = "advapi32.dll";                                   /*20*/
        internal const string CryptReleaseContextDllName = "advapi32.dll";                                   /*21*/
        internal const string CryptEncryptDllName = "advapi32.dll";                                          /*22*/
        internal const string CryptDecryptDllName = "advapi32.dll";                                          /*23*/
        internal const string CryptExportKeyDllName = "advapi32.dll";                                        /*24*/
        internal const string CryptImportKeyDllName = "advapi32.dll";                                        /*25*/
        internal const string CryptDuplicateKeyDllName = "advapi32.dll";                                     /*26*/
        internal const string GetLastErrorDllName = "kernel32.dll";                                          /*27*/
        internal const string GetCPInfoDllName = "kernel32.dll";                                             /*28*/
        internal const string CommandLineToArgvDllName = "shell32.dll";                                      /*30*/
        internal const string LocalFreeDllName = "kernel32.dll";                                             /*31*/
        internal const string CloseHandleDllName = "kernel32.dll";                                           /*32*/
        internal const string GetTokenInformationDllName = "advapi32.dll";                                   /*33*/
        internal const string LookupAccountSidDllName = "advapi32.dll";                                      /*34*/
        internal const string OpenProcessTokenDllName = "advapi32.dll";                                      /*35*/
        internal const string DosDateTimeToFileTimeDllName = "kernel32.dll";                                 /*36*/
        internal const string LocalFileTimeToFileTimeDllName = "kernel32.dll";                               /*37*/
        internal const string SetFileTimeDllName = "kernel32.dll";                                           /*38*/
        internal const string SetFileAttributesWDllName = "kernel32.dll";                                    /*39*/
        internal const string CreateHardLinkDllName = "kernel32.dll";                                        /*40*/
        internal const string RegCloseKeyDllName = "advapi32.dll";                                           /*41*/
        internal const string GetFileInformationByHandleDllName = "kernel32.dll";                            /*42*/
        internal const string FindFirstStreamDllName = "kernel32.dll";                                       /*43*/
        internal const string FindNextStreamDllName = "kernel32.dll";                                        /*44*/
        internal const string GetSystemInfoDllName = "kernel32.dll";                                         /*45*/
        internal const string GetCurrentThreadIdDllName = "kernel32.dll";                                    /*46*/
        internal const string SetLocalTimeDllName = "kernel32.dll";                                          /*47*/
        internal const string CryptSetProvParamDllName = "advapi32.dll";                                     /*48*/
        internal const string GetNamedSecurityInfoDllName = "advapi32.dll";                                  /*49*/
        internal const string SetNamedSecurityInfoDllName = "advapi32.dll";                                  /*50*/
        internal const string ConvertStringSidToSidDllName = "advapi32.dll";                                 /*51*/
        internal const string IsValidSidDllName = "advapi32.dll";                                            /*52*/
        internal const string GetLengthSidDllName = "advapi32.dll";                                          /*53*/
        internal const string LsaFreeMemoryDllName = "advapi32.dll";                                         /*54*/
        internal const string InitializeAclDllName = "advapi32.dll";                                         /*55*/
        internal const string GetCurrentProcessDllName = "kernel32.dll";                                     /*56*/
        internal const string GetCurrentThreadDllName = "kernel32.dll";                                      /*57*/
        internal const string OpenThreadTokenDllName = "advapi32.dll";                                       /*58*/
        internal const string LookupPrivilegeValueDllName = "advapi32.dll";                                  /*59*/
        internal const string AdjustTokenPrivilegesDllName = "advapi32.dll";                                 /*60*/
        internal const string GetStdHandleDllName = "kernel32.dll";                                          /*61*/
        internal const string CreateProcessWithLogonWDllName = "advapi32.dll";                               /*62*/
        internal const string CreateProcessDllName = "kernel32.dll";                                         /*63*/
        internal const string ResumeThreadDllName = "kernel32.dll";                                          /*64*/
        internal const string OpenSCManagerWDllName = "advapi32.dll";                                        /*65*/
        internal const string OpenServiceWDllName = "advapi32.dll";                                          /*66*/
        internal const string CloseServiceHandleDllName = "advapi32.dll";                                    /*67*/
        internal const string ChangeServiceConfigWDllName = "advapi32.dll";                                  /*68*/
        internal const string ChangeServiceConfig2WDllName = "advapi32.dll";                                 /*69*/
        internal const string CreateServiceWDllName = "advapi32.dll";                                        /*70*/
        internal const string CreateJobObjectDllName = "kernel32.dll";                                       /*71*/
        internal const string AssignProcessToJobObjectDllName = "kernel32.dll";                              /*72*/
        internal const string QueryInformationJobObjectDllName = "kernel32.dll";                             /*73*/
        internal const string CreateNamedPipeDllName = "kernel32.dll";                                       /*74*/
        internal const string WaitNamedPipeDllName = "kernel32.dll";                                         /*75*/
        internal const string PrivilegeCheckDllName = "advapi32.dll";                                        /*76*/
        internal const string ImpersonateNamedPipeClientDllName = "advapi32.dll";                            /*77*/
        internal const string RevertToSelfDllName = "advapi32.dll";                                          /*78*/
        internal const string CreateProcessInComputeSystemDllName = "vmcompute.dll";                         /*79*/
        internal const string CLSIDFromProgIDDllName = "ole32.dll";                                          /*80*/
        internal const string LoadLibraryEx = "kernel32.dll";                                                /*81*/
        internal const string FreeLibrary = "kernel32.dll";                                                  /*82*/
        internal const string EventActivityIdControlDllName = "advapi32.dll";                                /*83*/
        internal const string GetConsoleCPDllName = "kernel32.dll";                                          /*84*/
        internal const string GetConsoleOutputCPDllName = "kernel32.dll";                                    /*85*/
        internal const string GetConsoleWindowDllName = "kernel32.dll";                                      /*86*/
        internal const string GetDCDllName = "User32.dll";                                                   /*87*/
        internal const string ReleaseDCDllName = "User32.dll";                                               /*88*/
        internal const string TranslateCharsetInfoDllName = "GDI32.dll";                                     /*89*/
        internal const string GetTextMetricsDllName = "GDI32.dll";                                           /*90*/
        internal const string GetCharWidth32DllName = "GDI32.dll";                                           /*91*/
        internal const string FlushConsoleInputBufferDllName = "kernel32.dll";                               /*92*/
        internal const string FillConsoleOutputAttributeDllName = "kernel32.dll";                            /*93*/
        internal const string FillConsoleOutputCharacterDllName = "kernel32.dll";                            /*94*/
        internal const string WriteConsoleDllName = "kernel32.dll";                                          /*95*/
        internal const string GetConsoleTitleDllName = "kernel32.dll";                                       /*96*/
        internal const string SetConsoleTitleDllName = "kernel32.dll";                                       /*97*/
        internal const string GetConsoleModeDllName = "kernel32.dll";                                        /*98*/
        internal const string GetConsoleScreenBufferInfoDllName = "kernel32.dll";                            /*99*/
        internal const string GetFileTypeDllName = "kernel32.dll";                                           /*100*/
        internal const string GetLargestConsoleWindowSizeDllName = "kernel32.dll";                           /*101*/
        internal const string ReadConsoleDllName = "kernel32.dll";                                           /*102*/
        internal const string PeekConsoleInputDllName = "kernel32.dll";                                      /*103*/
        internal const string GetNumberOfConsoleInputEventsDllName = "kernel32.dll";                         /*104*/
        internal const string SetConsoleCtrlHandlerDllName = "kernel32.dll";                                 /*105*/
        internal const string SetConsoleCursorPositionDllName = "kernel32.dll";                              /*106*/
        internal const string SetConsoleModeDllName = "kernel32.dll";                                        /*107*/
        internal const string SetConsoleScreenBufferSizeDllName = "kernel32.dll";                            /*108*/
        internal const string SetConsoleTextAttributeDllName = "kernel32.dll";                               /*109*/
        internal const string SetConsoleWindowInfoDllName = "kernel32.dll";                                  /*110*/
        internal const string WriteConsoleOutputDllName = "kernel32.dll";                                    /*111*/
        internal const string ReadConsoleOutputDllName = "kernel32.dll";                                     /*112*/
        internal const string ScrollConsoleScreenBufferDllName = "kernel32.dll";                             /*113*/
        internal const string SendInputDllName = "user32.dll";                                               /*114*/
        internal const string GetConsoleCursorInfoDllName = "kernel32.dll";                                  /*115*/
        internal const string SetConsoleCursorInfoDllName = "kernel32.dll";                                  /*116*/
        internal const string ReadConsoleInputDllName = "kernel32.dll";                                      /*117*/
    }
}
