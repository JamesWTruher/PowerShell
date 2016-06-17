﻿/********************************************************************++
Copyright (c) Microsoft Corporation.  All rights reserved.
--********************************************************************/

using System;
using System.Diagnostics.CodeAnalysis;
using System.Text;
using System.Net;
using System.Collections.Generic;
using System.IO;

namespace Microsoft.PowerShell.Commands
{
    /// <summary>
    /// WebResponseObject
    /// </summary>
    public class WebResponseObject
    {
        #region Properties

        /// <summary>
        /// gets or protected sets the Content property
        /// </summary>
        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]        
        public byte[] Content { get; protected set; }

        /// <summary>
        /// gets or sets the BaseResponse property
        /// </summary>
        public WebResponse BaseResponse { get; set; }

        /// <summary>
        /// gets the StatusCode property
        /// </summary>
        public int StatusCode
        {
            get { return (WebResponseHelper.GetStatusCode(BaseResponse)); }
        }

        /// <summary>
        /// gets the StatusDescription property
        /// </summary>
        public string StatusDescription
        {
            get { return (WebResponseHelper.GetStatusDescription(BaseResponse)); }
        }

        /// <summary>
        /// gets the Headers property
        /// </summary>
        public Dictionary<string,string> Headers 
        {
            get
            {
                Dictionary<string, string> headers = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                foreach (string key in BaseResponse.Headers.Keys)
                {
                    headers[key] = BaseResponse.Headers[key];
                }

                return headers;
            }
        }

        private MemoryStream _rawContentStream;
        /// <summary>
        /// gets the RawContentStream property
        /// </summary>
        public MemoryStream RawContentStream 
        {
            get { return (_rawContentStream); }
        }
        
        /// <summary>
        /// gets the RawContentLength property
        /// </summary>
        public long RawContentLength
        {
            get { return (null == RawContentStream ? -1 : RawContentStream.Length); }
        }

        /// <summary>
        /// gets or protected sets the RawContent property
        /// </summary>
        public string RawContent { get; protected set; }

        #endregion Properties

        #region Constructors

        /// <summary>
        /// Constructor for WebResponseObject
        /// </summary>
        /// <param name="response"></param>
        public WebResponseObject(WebResponse response)
            : this(response, null) { }

        /// <summary>
        /// Constructor for WebResponseObject with contentStream
        /// </summary>
        /// <param name="response"></param>
        /// <param name="contentStream"></param>
        public WebResponseObject(WebResponse response, Stream contentStream)
        {
            SetResponse(response, contentStream); 
            InitializeContent();
            InitializeRawContent(response);
        }

        #endregion Constructors

        #region Methods

        /// <summary>
        /// Reads the response content from the web response.
        /// </summary>
        private void InitializeContent()
        {
            this.Content = this.RawContentStream.ToArray();
        }

        private void InitializeRawContent(WebResponse baseResponse)
        {
            StringBuilder raw = ContentHelper.GetRawContentHeader(baseResponse);

            // Use ASCII encoding for the RawContent visual view of the content.
            if (Content.Length > 0)
            {
                raw.Append(this.ToString());               
            }

            this.RawContent = raw.ToString();
        }

        private bool IsPrintable(char c)
        {
            return (Char.IsLetterOrDigit(c) || Char.IsPunctuation(c) || Char.IsSeparator(c) || Char.IsSymbol(c) || Char.IsWhiteSpace(c));
        }

        private void SetResponse(WebResponse response, Stream contentStream)
        {
            if (null == response) { throw new ArgumentNullException("response"); }
            
            BaseResponse = response;

            MemoryStream ms = contentStream as MemoryStream;
            if (null != ms)
            {
                _rawContentStream = ms;
            }
            else
            { 
                Stream st = contentStream;
                if (contentStream == null)
                {
                    st = StreamHelper.GetResponseStream(response);
                }

                long contentLength = response.ContentLength;
                if (0 >= contentLength)
                {
                    contentLength = StreamHelper.DefaultReadBuffer;
                }
                int initialCapacity = (int)Math.Min(contentLength, StreamHelper.DefaultReadBuffer);
                _rawContentStream = new WebResponseContentMemoryStream(st, initialCapacity, null);         

            }
            // set the position of the content stream to the beginning
            _rawContentStream.Position = 0;
        }

        /// <summary>
        /// Returns the string representation of this web response.
        /// </summary>
        /// <returns>The string representation of this web response.</returns>
        public sealed override string ToString()
        {
            char[] stringContent = System.Text.Encoding.ASCII.GetChars(Content);
            for (int counter = 0; counter < stringContent.Length; counter++)
            {
                if (!IsPrintable(stringContent[counter]))
                {
                    stringContent[counter] = '.';
                }
            }

            return new string(stringContent);
        }
    
        #endregion Methods
    }
}
