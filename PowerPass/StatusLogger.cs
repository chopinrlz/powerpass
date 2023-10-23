using System;
using KeePassLib.Interfaces;
namespace PowerPass {
    public sealed class StatusLogger : IStatusLogger {
        #region Fields
        private string _operation = String.Empty;
        private uint _progress = 0;
        private string _text = String.Empty;
        private LogStatusType _statusType = LogStatusType.Info;
        #endregion

        #region Properties
        public string Operation { get { return _operation; } }
        public uint Progress { get { return _progress; } }
        public string Text { get { return _text; } }
        public LogStatusType StatusType { get { return _statusType; } }
        #endregion

        #region IStatusLogger Implementation
        public void StartLogging(string strOperation, bool bWriteOperationToLog) { _operation = strOperation; }
        public void EndLogging() { }
        public bool SetProgress(uint uPercent) { _progress = uPercent; return true; }
        public bool SetText(string strNewText, LogStatusType lsType) { _text = strNewText; _statusType = lsType; return true; }
        public bool ContinueWork() { return true; }
        #endregion
    }
}