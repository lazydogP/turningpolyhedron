VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "IFakeDXUIEvent"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'Public Sub Click(ByVal obj As clsFakeDXUI)
''
'End Sub
'
'Public Sub Unload(ByVal obj As clsFakeDXUI, ByRef Cancel As Boolean)
''
'End Sub
'
'Public Sub Change(ByVal obj As clsFakeDXUI)
''
'End Sub
'
'Public Sub DblClick(ByVal obj As clsFakeDXUI)
'
'End Sub

'nType: see mdlFakeDXUI
'nParam*: unused
'return value: if Unload then bit0=cancel
Public Function OnEvent(ByVal obj As clsFakeDXUI, ByVal nType As Long, ByVal nParam1 As Long, ByVal nParam2 As Long, ByVal nParam3 As Long) As Long
'
End Function
