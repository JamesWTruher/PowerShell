# This is a test entry point script.
#
# Copyright (c) Microsoft Corporation, 2012
#

Import-Module DispatchLayer
InvokeComponent @args -Directory (Split-Path $MyInvocation.MyCommand.Definition)
