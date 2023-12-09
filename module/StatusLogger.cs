/*
    StatusLogger.cs source code for KeePassLib database access logging
    Copyright 2023 by The Daltas Group LLC.
    The KeePassLib source code is copyright (C) 2003-2023 Dominik Reichl <dominik.reichl@t-online.de>
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
*/

using System;
using KeePassLib.Interfaces;

namespace PowerPass
{
    /// <summary>
    /// Captures status logging from the <see cref="KeePassLib.PwDatabase"/> class.
    /// </summary>
    public sealed class StatusLogger : IStatusLogger
    {
        #region Fields
        private string _operation = String.Empty;
        private uint _progress = 0;
        private string _text = String.Empty;
        private LogStatusType _statusType = LogStatusType.Info;
        #endregion

        #region Properties
        /// <summary>
        /// Gets or sets a flag which instructs this <see cref="StatusLogger"/> to send output
        /// to the <see cref="System.Console"/>.
        /// </summary>
        public bool Echo { get; set; }

        /// <summary>
        /// Gets the operation performed.
        /// </summary>
        public string Operation { get { return _operation; } }

        /// <summary>
        /// Gets the current progress of the operation.
        /// </summary>
        public uint Progress { get { return _progress; } }

        /// <summary>
        /// Gets the text message for the operation.
        /// </summary>
        public string Text { get { return _text; } }

        /// <summary>
        /// Gets the status type for the operation.
        /// </summary>
        public LogStatusType StatusType { get { return _statusType; } }
        #endregion

        #region IStatusLogger Implementation
        /// <summary>
        /// Called by <see cref="KeePassLib.PwDatabase"/> during database operations.
        /// </summary>
        /// <param name="strOperation">The name of the operation.</param>
        /// <param name="bWriteOperationToLog">A flag for writing to a log file.</param>
        public void StartLogging(string strOperation, bool bWriteOperationToLog)
        {
            _operation = strOperation;
            if (Echo)
            {
                Console.WriteLine(_operation);
            }
        }

        /// <summary>
        /// Called by <see cref="KeePassLib.PwDatabase"/> after the end of a database operation.
        /// </summary>
        public void EndLogging() { }

        /// <summary>
        /// Called by <see cref="KeePassLib.PwDatabase"/> to indicate the progress on the current operation.
        /// </summary>
        /// <param name="uPercent">The percent complete of the operation.</param>
        /// <returns>Returns true.</returns>
        public bool SetProgress(uint uPercent)
        {
            _progress = uPercent;
            if (Echo)
            {
                Console.WriteLine("Percent complete: {0:p}", _progress);
            }
            return true;
        }

        /// <summary>
        /// Called by <see cref="KeePassLib.PwDatabase"/> to indicate the text status of the current operation.
        /// </summary>
        /// <param name="strNewText">The current status message.</param>
        /// <param name="lsType">The type of message.</param>
        /// <returns>Returns true.</returns>
        public bool SetText(string strNewText, LogStatusType lsType)
        {
            _text = strNewText; _statusType = lsType;
            if (Echo)
            {
                Console.WriteLine("[{0}] {1}", strNewText, lsType);
            }
            return true;
        }

        /// <summary>
        /// Called by <see cref="KeePassLib.PwDatabase"/> to see if the user cancelled the operation.
        /// </summary>
        /// <returns>Return true.</returns>
        public bool ContinueWork() { return true; }
        #endregion
    }
}