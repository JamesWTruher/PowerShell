//! @file followSymLink.cpp
//! @author George FLeming <v-geflem@microsoft.com>
//! @brief returns whether a path is a symbolic link

#include <errno.h>
#include <unistd.h>
#include <string>
#include <iostream>
#include "followsymlink.h"

//! @brief Followsymlink determines target path of a sym link
//!
//! Followsymlink
//!
//! @param[in] fileName
//! @parblock
//! A pointer to the buffer that contains the file name
//!
//! char* is marshaled as an LPStr, which on Linux is UTF-8.
//! @endparblock
//!
//! @exception errno Passes these errors via errno to GetLastError:
//! - ERROR_INVALID_PARAMETER: parameter is not valid
//! - ERROR_FILE_NOT_FOUND: file does not exist
//! - ERROR_ACCESS_DENIED: access is denied
//! - ERROR_INVALID_ADDRESS: attempt to access invalid address
//! - ERROR_STOPPED_ON_SYMLINK: too many symbolic links
//! - ERROR_GEN_FAILURE: I/O error occurred
//! - ERROR_INVALID_NAME: file provided is not a symbolic link
//! - ERROR_INVALID_FUNCTION: incorrect function
//! - ERROR_BAD_PATH_NAME: pathname is too long
//! - ERROR_OUTOFMEMORY insufficient kernal memory
//!
//! @retval target path, or NULL if unsuccessful
//!

char* FollowSymLink(const char* fileName)
{
    errno = 0;  

    // Check parameters
    if (!fileName)
    {
        errno = ERROR_INVALID_PARAMETER;
        return NULL;
    }

    char actualpath [PATH_MAX + 1];
    char* realPath = realpath(fileName, actualpath);

    if  (sizeof(realPath) == -1)
    {
        switch(errno)
        {
        case EACCES:
            errno = ERROR_ACCESS_DENIED;
            break;
        case EFAULT:
            errno = ERROR_INVALID_ADDRESS;
            break;
        case EINVAL:
            errno = ERROR_INVALID_NAME;
            break;
        case EIO:
            errno = ERROR_GEN_FAILURE;
            break;
        case ELOOP:
            errno = ERROR_STOPPED_ON_SYMLINK;
            break;
        case ENAMETOOLONG:
            errno = ERROR_BAD_PATH_NAME;
            break;
        case ENOENT:
            errno = ERROR_FILE_NOT_FOUND;
            break;
        case ENOMEM:
            errno = ERROR_OUTOFMEMORY;
            break;
        case ENOTDIR:
            errno = ERROR_BAD_PATH_NAME;
            break;
        default:
            errno = ERROR_INVALID_FUNCTION;
        }
        return NULL;
    }

    return strndup(realPath, strlen(actualpath + 1));
}
