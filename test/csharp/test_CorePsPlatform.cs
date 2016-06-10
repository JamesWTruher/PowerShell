using Xunit;
using System;
using System.IO;
using System.Diagnostics;
using System.Management.Automation;

namespace PSTests
{
    [Collection("AssemblyLoadContext")]
    public static class PlatformTests
    {
        [CiFact]
        public static void TestIsCore()
        {
            Assert.True(Platform.IsCore);
        }

        [CiFact]
        public static void TestHasCom()
        {
            Assert.False(Platform.HasCom());
        }

        [CiFact]
        public static void TestHasAmsi()
        {
            Assert.False(Platform.HasAmsi());
        }

        [CiFact]
        public static void TestUsesCodeSignedAssemblies()
        {
            Assert.False(Platform.UsesCodeSignedAssemblies());
        }

        [CiFact]
        public static void TestHasDriveAutoMounting()
        {
            Assert.False(Platform.HasDriveAutoMounting());
        }

        [CiFact]
        public static void TestHasRegistrySupport()
        {
            Assert.False(Platform.HasRegistrySupport());
        }

        [CiFact]
        public static void TestGetUserName()
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = @"/usr/bin/env",
                Arguments = "whoami",
                RedirectStandardOutput = true,
                UseShellExecute = false
            };
            using (Process process = Process.Start(startInfo))
            {
                // Get output of call to whoami without trailing newline
                string username = process.StandardOutput.ReadToEnd().Trim();
                process.WaitForExit();

                // The process should return an exit code of 0 on success
                Assert.Equal(0, process.ExitCode);
                // It should be the same as what our platform code returns
                Assert.Equal(username, Platform.NonWindowsGetUserName());
            }
        }

        [CiFact(Skip="Bad arguments for OS X")]
        public static void TestGetMachineName()
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = @"/usr/bin/env",
                Arguments = "hostname",
                RedirectStandardOutput = true,
                UseShellExecute = false
            };
            using (Process process = Process.Start(startInfo))
            {
                 // Get output of call to hostname without trailing newline
                string hostname = process.StandardOutput.ReadToEnd().Trim();
                process.WaitForExit();

                // The process should return an exit code of 0 on success
                Assert.Equal(0, process.ExitCode);
                // It should be the same as what our platform code returns
                Assert.Equal(hostname, System.Management.Automation.Environment.MachineName);
            }
        }

        [CiFact(Skip="Bad arguments for OS X")]
        public static void TestGetFQDN()
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = @"/usr/bin/env",
                Arguments = "hostname --fqdn",
                RedirectStandardOutput = true,
                UseShellExecute = false
            };
            using (Process process = Process.Start(startInfo))
            {
                 // Get output of call to hostname without trailing newline
                string hostname = process.StandardOutput.ReadToEnd().Trim();
                process.WaitForExit();

                // The process should return an exit code of 0 on success
                Assert.Equal(0, process.ExitCode);
                // It should be the same as what our platform code returns
                Assert.Equal(hostname, Platform.NonWindowsGetHostName());
            }
        }

        [CiFact(Skip="Bad arguments for OS X")]
        public static void TestGetDomainName()
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = @"/usr/bin/env",
                Arguments = "dnsdomainname",
                RedirectStandardOutput = true,
                UseShellExecute = false
            };
            using (Process process = Process.Start(startInfo))
            {
                 // Get output of call to hostname without trailing newline
                string domainName = process.StandardOutput.ReadToEnd().Trim();
                process.WaitForExit();

                // The process should return an exit code of 0 on success
                Assert.Equal(0, process.ExitCode);
                // It should be the same as what our platform code returns
                Assert.Equal(domainName, Platform.NonWindowsGetDomainName());
            }
        }

        [CiFact]
        public static void TestIsExecutable()
        {
            Assert.True(Platform.NonWindowsIsExecutable("/bin/ls"));
        }

        [CiFact]
        public static void TestIsNotExecutable()
        {
            Assert.False(Platform.NonWindowsIsExecutable("/etc/hosts"));
        }

        [CiFact]
        public static void TestDirectoryIsNotExecutable()
        {
            Assert.False(Platform.NonWindowsIsExecutable("/etc"));
        }

        [CiFact]
        public static void TestFileIsNotHardLink()
        {
            string path = @"/tmp/nothardlink";
            if (File.Exists(path))
            {
                File.Delete(path);
            }

            File.Create(path);

            FileSystemInfo fd = new FileInfo(path);

            // Since this is the only reference to the file, it is not considered a
            // hardlink by our API (though all files are hardlinks on Linux)
            Assert.False(Platform.NonWindowsIsHardLink(fd));

            File.Delete(path);
        }

        [CiFact]
        public static void TestFileIsHardLink()
        {
            string path = @"/tmp/originallink";
            if (File.Exists(path))
            {
                File.Delete(path);
            }

            File.Create(path);

            string link = "/tmp/newlink";

            if (File.Exists(link))
            {
                File.Delete(link);
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = @"/usr/bin/env",
                Arguments = "ln " + path + " " + link,
                RedirectStandardOutput = true,
                UseShellExecute = false
            };

            using (Process process = Process.Start(startInfo))
            {
                process.WaitForExit();
                Assert.Equal(0, process.ExitCode);
            }


            // Since there are now two references to the file, both are considered
            // hardlinks by our API (though all files are hardlinks on Linux)
            FileSystemInfo fd = new FileInfo(path);
            Assert.True(Platform.NonWindowsIsHardLink(fd));

            fd = new FileInfo(link);
            Assert.True(Platform.NonWindowsIsHardLink(fd));

            File.Delete(path);
            File.Delete(link);
        }

        [CiFact]
        public static void TestDirectoryIsNotHardLink()
        {
            string path = @"/tmp";

            FileSystemInfo fd = new FileInfo(path);

            Assert.False(Platform.NonWindowsIsHardLink(fd));
        }

        [CiFact]
        public static void TestNonExistantIsHardLink()
        {
            // A file that should *never* exist on a test machine:
            string path = @"/tmp/ThisFileShouldNotExistOnTestMachines";

            // If the file exists, then there's a larger issue that needs to be looked at
            Assert.False(File.Exists(path));

            // Convert `path` string to FileSystemInfo data type. And now, it should return true
            FileSystemInfo fd = new FileInfo(path);
            Assert.False(Platform.NonWindowsIsHardLink(fd));
        }

        [CiFact]
        public static void TestFileIsSymLink()
        {
            string path = @"/tmp/originallink";
            if (File.Exists(path))
            {
                File.Delete(path);
            }

            File.Create(path);

            string link = "/tmp/newlink";

            if (File.Exists(link))
            {
                File.Delete(link);
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = @"/usr/bin/env",
                Arguments = "ln -s " + path + " " + link,
                RedirectStandardOutput = true,
                UseShellExecute = false
            };

            using (Process process = Process.Start(startInfo))
            {
                process.WaitForExit();
                Assert.Equal(0, process.ExitCode);
            }

            FileSystemInfo fd = new FileInfo(path);
            Assert.False(Platform.NonWindowsIsSymLink(fd));

            fd = new FileInfo(link);
            Assert.True(Platform.NonWindowsIsSymLink(fd));

            File.Delete(path);
            File.Delete(link);
        }

        [CiFact]
        public static void TestCommandLineArgvReturnsAnElement()
        {
            string testCommand= "Today";

            string[] retval = Platform.CommandLineToArgv(testCommand);

            Assert.Equal(1, retval.Length);
        }

        [CiFact]
        public static void TestCommandLineArgvWWithSpaces()
        {
            string testCommand= "Today is a good day or is it";

            string[] retval = Platform.CommandLineToArgv(testCommand);

            Assert.Equal("Today", retval[0]);
            Assert.Equal("is", retval[1]);
            Assert.Equal("a", retval[2]);
            Assert.Equal("good", retval[3]);
            Assert.Equal("day", retval[4]);
            Assert.Equal("or", retval[5]);
            Assert.Equal("is", retval[6]);
            Assert.Equal("it", retval[7]);
        }

        [CiFact]
        public static void TestCommandLineToArgvWTabsAreTreatedAsSpaces()
        {
            string testCommand = "Today \t is a good day";

            string[] retval = Platform.CommandLineToArgv(testCommand);

            Assert.Equal("Today", retval[0]);
            Assert.Equal("is", retval[1]);
            Assert.Equal("a", retval[2]);
            Assert.Equal("good", retval[3]);
            Assert.Equal("day", retval[4]);
        }

        [CiFact]
        public static void TestCommandLineToArgvWQuotesAreArgs()
        {
            string testCommand = "Today is \"a good\" day";

            string[] retval = Platform.CommandLineToArgv(testCommand);

            Assert.Equal(4, retval.Length);
            Assert.Equal("Today", retval[0]);
            Assert.Equal("is", retval[1]);
            Assert.Equal("\"a good\"", retval[2]);
            Assert.Equal("day", retval[3]);
        }

        [CiFact]
        public static void TestCommandLineToArgvWEvenNumberBackSlashes()
        {
            string test1 = "a\\b c d";
            string test2 = "a\\b\\c d";
            string test3 = "a \\b\\c\\d";
            string test4 = "a\\\\\\b";
            string[] retval;

            retval = Platform.CommandLineToArgv(test1);

            Assert.Equal(3, retval.Length);
            Assert.Equal("a\\b", retval[0]);
            Assert.Equal("c", retval[1]);
            Assert.Equal("d", retval[2]);

            retval = Platform.CommandLineToArgv(test2);

            Assert.Equal(2, retval.Length);
            Assert.Equal("a\\b\\c", retval[0]);
            Assert.Equal("d", retval[1]);

            retval = Platform.CommandLineToArgv(test3);

            Assert.Equal(2, retval.Length);
            Assert.Equal("a", retval[0]);
            Assert.Equal("\\b\\c\\d", retval[1]);

            retval = Platform.CommandLineToArgv(test4);

            Assert.Equal(1, retval.Length);
            Assert.Equal("a\\\\\\b", retval[0]);
        }

        [CiFact]
        public static void TestCommandLineToArgvwOddNumberWithBackSlashes()
        {
            string test1 = "a\\\"b";
            string test2 = "a\\\\\\\"b";
            string[] retval;

            retval = Platform.CommandLineToArgv(test1);

            Assert.Equal(1, retval.Length);
            Assert.Equal("a\\\"b", retval[0]);

            retval = Platform.CommandLineToArgv(test2);

            Assert.Equal(1, retval.Length);
            Assert.Equal("a\\\\\\\"b", retval[0]);
        }
    }
}
