VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsTiming"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Declare Function QueryPerformanceCounter Lib "kernel32.dll" (ByRef lpPerformanceCount As Currency) As Long
Private Declare Function QueryPerformanceFrequency Lib "kernel32.dll" (ByRef lpFrequency As Currency) As Long

Private t1 As Currency, t2 As Currency
Private nFreq As Currency
Private bRun As Boolean

Private Sub Class_Initialize()
QueryPerformanceFrequency nFreq
End Sub

Friend Sub Clear()
t1 = 0
t2 = 0
bRun = False
End Sub

Friend Sub StartTiming()
If Not bRun Then
 QueryPerformanceCounter t2
 bRun = True
End If
End Sub

Friend Sub StopTiming()
On Error Resume Next
Dim a As Currency
If bRun Then
 QueryPerformanceCounter a
 t1 = t1 + a - t2
 bRun = False
End If
End Sub

Friend Function GetMs() As Double
On Error Resume Next
Dim a As Currency
If bRun Then
 QueryPerformanceCounter a
 GetMs = (t1 + a - t2) / nFreq * 1000
Else
 GetMs = t1 / nFreq * 1000
End If
End Function