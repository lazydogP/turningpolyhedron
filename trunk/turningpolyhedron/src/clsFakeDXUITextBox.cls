VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFakeDXUITextBox"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const m_nLineHeight As Long = 32

Private Declare Function GetCharacterPlacementW Lib "Gdi32.dll" ( _
  ByVal hdc As Long, _
  ByRef lpString As Any, _
  ByVal nCount As Long, _
  ByVal nMaxExtent As Long, _
  ByRef lpResults As GCP_RESULTS, _
  ByVal dwFlags As Long) As Long

Private Declare Function GetTextExtentPoint32W Lib "Gdi32.dll" ( _
  ByVal hdc As Long, _
  ByRef lpString As Any, _
  ByVal c As Long, _
  ByRef lpSize As Any) As Long
Private Const GCP_MAXEXTENT As Long = &H100000

Private Type GCP_RESULTS
  lStructSize As Long
  lpOutString As Long
  lpOrder As Long
  lpDx As Long
  lpCaretPos As Long
  lpClass As Long
  lpGlyphs As Long
  nGlyphs As Long
  nMaxFit As Long
End Type

Private m_nFontZoom As Single
Private m_bMultiLine As Boolean
Private m_bWrap As Boolean
Private m_bLocked As Boolean

Private m_sLines() As String '0-based
Private m_tLineData() As typeFakeDXUITextBoxLineMetric '0-based
Private m_nLineMax As Long
Private m_nLineCount As Long

Private m_tCaret As typeFakeDXUITextBoxPos
Private m_tSelStart As typeFakeDXUITextBoxPos ', m_tSelEnd As typeFakeDXUITextBoxPos
Private m_nCaretTimer As Long '0-31
Private m_bInsertMode As Boolean

Private m_nWidth As Long, m_bSizeDirty As Boolean
Private m_nHeight As Long
Private m_nTextWidth As Long
Private m_nTextHeight As Long

Private m_nScrollValue(1) As Long

Friend Property Get ScrollValue(Optional ByVal nIndex As Long) As Long
ScrollValue = m_nScrollValue(nIndex)
End Property

Friend Property Let ScrollValue(Optional ByVal nIndex As Long, ByVal n As Long)
m_nScrollValue(nIndex) = n
End Property

Friend Sub Clear()
Erase m_sLines, m_tLineData
m_nLineMax = 0
m_nLineCount = 0
End Sub

Friend Sub CalcLineDataIfSizeChanged(Optional ByVal bForce As Boolean)
If bForce Or m_bSizeDirty Then
 CalcLineData
 m_bSizeDirty = False
End If
End Sub

Friend Sub CalcLineData(Optional ByVal nStart As Long = -1, Optional ByVal nEnd As Long = -1)
Dim i As Long, m As Long
Dim lp As Long, lps As Long, w As Long
Dim hd As Long
Dim t As GCP_RESULTS
'///
If nStart < 0 Then
 nStart = 0
 nEnd = m_nLineCount - 1
ElseIf nEnd < 0 Then
 nEnd = nStart
End If
'///calc line width
hd = FakeDXUIDefaultFont.objFont.GetDC
w = m_nWidth / m_nFontZoom
For i = nStart To nEnd
 '///begin
 m = Len(m_sLines(i))
 If m > 0 Then
  lp = StrPtr(m_sLines(i))
  If m_bWrap Then
   '///
   With m_tLineData(i)
    .nLineWidth = m_nWidth
    .nLineHeight = 0
   End With
   '///
   t.lStructSize = Len(t)
   lps = 0
   Do
    t.nGlyphs = m - lps
    GetCharacterPlacementW hd, ByVal (lp + lps + lps), t.nGlyphs, w, t, GCP_MAXEXTENT
    If t.nMaxFit <= 0 Then t.nMaxFit = 1
    'add
    With m_tLineData(i)
     ReDim Preserve .nLineStart(.nLineHeight), .nLineLength(.nLineHeight) 'slow code
     .nLineStart(.nLineHeight) = lps
     .nLineLength(.nLineHeight) = t.nMaxFit
     .nLineHeight = .nLineHeight + 1
    End With
    'next
    lps = lps + t.nMaxFit
   Loop While lps < m
   '///
  Else
   GetTextExtentPoint32W hd, ByVal lp, m, m_tLineData(i).nLineWidth
   With m_tLineData(i)
    .nLineHeight = 1
    ReDim .nLineStart(0), .nLineLength(0)
    .nLineStart(0) = 0
    .nLineLength(0) = m
   End With
  End If
 Else
  With m_tLineData(i)
   .nLineWidth = 0
   .nLineHeight = 1
   ReDim .nLineStart(0), .nLineLength(0)
   .nLineStart(0) = 0
   .nLineLength(0) = m
  End With
 End If
 '///end
Next i
'///calc text width and height
m_nTextWidth = 0
m_nTextHeight = 0
For i = 0 To m_nLineCount - 1
 w = m_tLineData(i).nLineWidth
 If m_nTextWidth < w Then m_nTextWidth = w
 m_tLineData(i).nLineOffset = m_nTextHeight
 m_nTextHeight = m_nTextHeight + m_tLineData(i).nLineHeight
Next i
'///
m_nTextWidth = m_nTextWidth + 32 '??
m_nTextHeight = m_nTextHeight * m_nLineHeight
End Sub

Friend Property Get Text() As String
Text = Join(m_sLines, vbCrLf)
End Property

Friend Property Let Text(ByRef s As String)
If m_bMultiLine Then
 m_sLines = Split(s, vbCrLf)
 m_nLineMax = UBound(m_sLines) + 1
 If m_nLineMax <= 0 Then
  m_nLineMax = 1
  ReDim m_sLines(0)
 End If
 ReDim m_tLineData(m_nLineMax - 1)
 m_nLineCount = m_nLineMax
Else
 If m_nLineMax < 1 Then
  m_nLineMax = 1
  ReDim m_sLines(0), m_tLineData(0)
 End If
 m_nLineCount = 1
 m_sLines(0) = s
End If
CalcLineData
End Property

Friend Property Get MultiLine() As Boolean
MultiLine = m_bMultiLine
End Property

Friend Property Let MultiLine(ByVal b As Boolean)
If m_bMultiLine <> b Then
 m_bMultiLine = b
 Text = Text ':-3
End If
End Property

Friend Property Get Locked() As Boolean
Locked = m_bLocked
End Property

Friend Property Let Locked(ByVal b As Boolean)
m_bLocked = b
End Property

Friend Property Get InsertMode() As Boolean
InsertMode = m_bInsertMode
End Property

Friend Property Let InsertMode(ByVal b As Boolean)
m_bInsertMode = b
End Property

Friend Property Get Wrap() As Boolean
Wrap = m_bWrap
End Property

Friend Property Let Wrap(ByVal b As Boolean)
If m_bWrap <> b Then
 m_bWrap = b
 m_bSizeDirty = True
End If
End Property

Friend Property Get TextWidth() As Long
TextWidth = m_nTextWidth
End Property

Friend Property Get TextHeight() As Long
TextHeight = m_nTextHeight
End Property

Friend Property Get Width() As Long
Width = m_nWidth
End Property

Friend Property Let Width(ByVal n As Long)
If m_nWidth <> n Then
 m_nWidth = n
 If m_bWrap Then m_bSizeDirty = True
End If
End Property

Friend Property Get Height() As Long
Height = m_nHeight
End Property

Friend Property Let Height(ByVal n As Long)
'If m_nHeight <> n Then
' m_bHeightChanged = True
 m_nHeight = n
'End If
End Property

Friend Property Get FontZoom() As Single
FontZoom = m_nFontZoom
End Property

Friend Property Let FontZoom(ByVal f As Single)
m_nFontZoom = f
End Property

Friend Function OnKeyEvent(ByVal KeyCode As Long, ByVal Shift As Long, ByVal nEventType As Long) As Boolean
Dim m As Long
'///
'TODO:other
'///
Select Case nEventType
Case 0 'keypress
 If KeyCode >= 0 And KeyCode < 32 Then 'control code
  Select Case KeyCode
  Case 1 'Ctrl+A
  Case 24 'Ctrl+X
  Case 3 'Ctrl+C
  Case 22 'Ctrl+V
  Case 26 'Ctrl+Z
  Case 8 'backspace
  Case 10, 13 'enter
  End Select
  KeyCode = 0
 End If
 If KeyCode Then
  'TODO:
 End If
Case 1 'keydown
 Select Case Shift
 Case 0, vbShiftMask
  Select Case KeyCode
  Case vbKeyLeft
   With m_tCaret
    If .nRow >= 0 And .nRow < m_nLineCount Then
     If .nPosition > 0 Then
      .nPosition = .nPosition - 1
      m_nCaretTimer = 0
     ElseIf .nRow > 0 Then
      .nRow = .nRow - 1
      .nPosition = Len(m_sLines(.nRow))
      m_nCaretTimer = 0
     End If
    Else
     .nRow = 0
     .nPosition = 0
     m_nCaretTimer = 0
    End If
   End With
   'TODO:ensure visible
   If Shift And vbShiftMask Then
    'TODO:
   End If
  Case vbKeyRight
   With m_tCaret
    If .nRow >= 0 And .nRow < m_nLineCount Then
     If .nPosition < Len(m_sLines(.nRow)) Then
      .nPosition = .nPosition + 1
      m_nCaretTimer = 0
     ElseIf .nRow < m_nLineCount - 1 Then
      .nRow = .nRow + 1
      .nPosition = 0
      m_nCaretTimer = 0
     End If
    Else
     .nRow = 0
     .nPosition = 0
     m_nCaretTimer = 0
    End If
   End With
   'TODO:ensure visible
   If Shift And vbShiftMask Then
    'TODO:
   End If
  Case vbKeyUp
  Case vbKeyDown
  Case vbKeyInsert
   m_bInsertMode = Not m_bInsertMode
  Case vbKeyDelete
  Case vbKeyPageUp
  Case vbKeyPageDown
  Case vbKeyHome
  Case vbKeyEnd
  End Select
 Case vbCtrlMask
  Select Case KeyCode
  Case vbKeyHome
  Case vbKeyEnd
  End Select
 End Select
End Select
'///
OnKeyEvent = True '?
End Function

Friend Function OnMouseEvent(ByVal Button As Long, ByVal Shift As Long, ByVal xClient As Single, ByVal yClient As Single, ByVal nEventType As Long) As Boolean
'TODO:
End Function

'Private Sub Command1_Click()
'Dim s As String
'Dim t As GCP_RESULTS
'Dim i As Long, h As Long
'Dim nCaretPos() As Long
'Dim nDistance() As Long
''///
'Set cFnt.LogFont = Picture1.Font
'cFnt.HighQuality = True
''///
's = "LKSCT??xyzwWwfj ZzZ@XwY#!|xd����"
'Picture1.Cls
'Picture1.Print s
''///
'ReDim nCaretPos(1023)
'ReDim nDistance(1023)
't.lStructSize = Len(t)
't.lpDx = VarPtr(nDistance(0))
't.lpCaretPos = VarPtr(nCaretPos(0))
't.nGlyphs = 1024
''///
'h = SelectObject(Picture1.hdc, cFnt.Handle)
'i = GetCharacterPlacementW(Picture1.hdc, ByVal StrPtr(s), Len(s), 0, t, 0)
'SelectObject Picture1.hdc, h
''///
''///
''Debug.Print i And &HFFFF&, (i And &HFFFF0000) \ &H10000
'For i = 0 To t.nGlyphs - 1
' Picture1.Line (nCaretPos(i), 0)-Step(0, 16), vbRed
' Picture1.Line (nCaretPos(i) + nDistance(i), 14)-Step(0, 16), vbBlue
'Next i
''///
'
'End Sub

Friend Sub Render(Optional ByVal nLeft As Single, Optional ByVal nTop As Single, Optional ByVal nOpacity As Single = 1, Optional ByVal bEnabled As Boolean = True, Optional ByVal bFocus As Boolean)
Dim mat As D3DMATRIX
Dim r As D3DRECT
Dim t As GCP_RESULTS, h As Long
Dim nCaretPos() As Long
Dim nDistance() As Long
Dim i As Long, ii As Long, iii As Long
Dim j As Long, jj As Long, jjj As Long
Dim k As Long, kk As Long, kkk As Long
Dim m As Long
Dim lp As Long
Dim nStartLine As Long, nEndLine As Long
Dim clr As Long, clr1 As Long
'///
'TODO:other
'///
clr = nOpacity * 255
clr = ((clr And &H7F&) * &H1000000) Or ((clr > &H7F&) And &H80000000)
clr = clr Or (&H666666 And Not bEnabled)
'///
FakeDXUIDefaultFont.objSprite.Begin D3DXSPRITE_ALPHABLEND
mat.m11 = m_nFontZoom
mat.m22 = m_nFontZoom
mat.m33 = 1
mat.m41 = nLeft - m_nScrollValue(0) * m_nFontZoom
mat.m42 = nTop - m_nScrollValue(1) * m_nFontZoom
mat.m44 = 1
FakeDXUIDefaultFont.objSprite.SetTransform mat
'///
d3dd9.SetSamplerState 0, D3DSAMP_MIPMAPLODBIAS, SingleToLong(-0.5)
If m_nLineCount > 0 Then
 If m_bMultiLine Then
  '///text
  nStartLine = m_nScrollValue(1) \ m_nLineHeight
  nEndLine = nStartLine + CLng(m_nHeight / m_nFontZoom) \ m_nLineHeight + 1
  If m_bWrap Then
   '///perform a binary search
   i = 0
   k = m_nLineCount - 1
   Do
    j = (i + k) \ 2
    ii = m_tLineData(j).nLineOffset
    If nStartLine < ii Then
     k = j - 1
    ElseIf nStartLine >= ii + m_tLineData(j).nLineHeight Then
     i = j + 1
    Else
     i = ii
     Exit Do
    End If
    If i > k Then 'err!
     j = m_nLineCount
     Exit Do
    End If
   Loop
   '///
   For j = j To m_nLineCount - 1
    If i > nEndLine Then Exit For
    With m_tLineData(j)
     m = .nLineHeight
     ii = i + m
     If ii > nStartLine Then
      lp = StrPtr(m_sLines(j))
      k = nStartLine - i
      If k < 0 Then k = 0 Else i = nStartLine
      Do While k < m And i <= nEndLine
       r.Y1 = i * m_nLineHeight
       r.Y2 = r.Y1 + m_nLineHeight
       FakeDXUIDefaultFont.objFont.DrawTextW FakeDXUIDefaultFont.objSprite, ByVal (lp + .nLineStart(k) * 2&), .nLineLength(k), r, DT_VCENTER Or DT_SINGLELINE Or DT_NOCLIP, clr
       i = i + 1
       k = k + 1
      Loop
     End If
    End With
    i = ii
   Next j
   '///TODO:selection
  Else
   If nStartLine < 0 Then nStartLine = 0
   If nEndLine >= m_nLineCount Then nEndLine = m_nLineCount - 1
   For i = nStartLine To nEndLine
    r.Y1 = i * m_nLineHeight
    r.Y2 = r.Y1 + m_nLineHeight
    FakeDXUIDefaultFont.objFont.DrawTextW FakeDXUIDefaultFont.objSprite, ByVal StrPtr(m_sLines(i)), -1, r, DT_VCENTER Or DT_SINGLELINE Or DT_NOCLIP, clr
   Next i
   '///TODO:selection
  End If
 Else
  '///text
  If m_nLineCount > 0 Then
   r.Y2 = m_nHeight / m_nFontZoom
   FakeDXUIDefaultFont.objFont.DrawTextW FakeDXUIDefaultFont.objSprite, ByVal StrPtr(m_sLines(0)), -1, r, DT_VCENTER Or DT_SINGLELINE Or DT_NOCLIP, clr
  End If
  '///TODO:selection
 End If
End If
FakeDXUIDefaultFont.objSprite.End
'///caret
If bFocus Then
 i = (m_nCaretTimer + 1) And &H1F&
 m_nCaretTimer = i
 If i And &H10& Then
  i = i - 27
  If i < 0 Then i = 0
 Else
  i = 16 - i
  If i > 5 Then i = 5
 End If
 If i > 0 Then
  clr = (i * 51&) * nOpacity
  clr = ((clr And &H7F&) * &H1000000) Or ((clr > &H7F&) And &H80000000)
  j = 0
  If m_bInsertMode Then jj = 16 Else jj = 4
  If m_bMultiLine Then k = 0 _
  Else k = CLng(m_nHeight / m_nFontZoom / 2) - m_nLineHeight \ 2
  h = FakeDXUIDefaultFont.objFont.GetDC
  '///
  ii = m_tCaret.nRow
  kk = 0
  If ii < 0 Or Not m_bMultiLine Then ii = 0 _
  Else If ii >= m_nLineCount Then ii = m_nLineCount - 1
  m = Len(m_sLines(ii))
  i = m_tCaret.nPosition
  If i <= 0 Then i = 0 Else If i > m Then i = m
  If m_bMultiLine And m_bWrap Then
   If m > 0 Then
    '///search for sub-lines
    With m_tLineData(ii)
     iii = 0
     kkk = .nLineHeight - 1
     Do
      kk = (iii + kkk) \ 2
      jjj = .nLineStart(kk)
      If i < jjj Then
       kkk = kk - 1
      ElseIf i >= jjj + .nLineLength(kk) Then
       iii = kk + 1
      Else
       Exit Do
      End If
      If iii > kkk Then
       kk = .nLineHeight - 1
       Exit Do
      End If
     Loop
     '///
     jjj = .nLineStart(kk)
     i = i - jjj
     lp = StrPtr(m_sLines(ii)) + jjj * 2&
     m = .nLineLength(kk)
    End With
   End If
  Else
   lp = StrPtr(m_sLines(ii))
  End If
  '///
  If m > 0 Then
   ReDim nCaretPos(m - 1)
   ReDim nDistance(m - 1)
   t.lStructSize = Len(t)
   t.lpDx = VarPtr(nDistance(0))
   t.lpCaretPos = VarPtr(nCaretPos(0))
   t.nGlyphs = m
   GetCharacterPlacementW h, ByVal lp, m, 0, t, 0
   If i < m Then
    j = nCaretPos(i)
    If m_bInsertMode Then jj = j + nDistance(i) Else jj = j + 4
   Else
    j = nCaretPos(m - 1) + nDistance(m - 1)
    If m_bInsertMode Then jj = j + 16 Else jj = j + 4
   End If
  End If
  '///
  If m_bMultiLine Then k = (m_tLineData(ii).nLineOffset + kk) * m_nLineHeight
  '///draw
  j = nLeft + (j - m_nScrollValue(0)) * m_nFontZoom
  jj = nLeft + (jj - m_nScrollValue(0)) * m_nFontZoom
  k = nTop + (k - m_nScrollValue(1)) * m_nFontZoom
  FakeDXGDIStretchBltColored j, k, jj, k + m_nLineHeight * m_nFontZoom, 12, 496, 12, 496, 512, clr
 End If
Else
 m_nCaretTimer = 0
End If
'///
End Sub

'Public Sub FakeDXGDIDrawText(ByRef tFont As typeFakeDXGDILogFont, ByVal lpStr As String, ByVal nLeft As Single, ByVal nTop As Single, Optional ByVal nWidth As Long, Optional ByVal nHeight As Long, Optional ByVal nZoom As Single = 1, Optional ByVal wFormat As D3DXDRAWTEXTFORMAT, _
'Optional ByVal nColor As Long = -1, Optional ByVal nTextLODBias As Single = -0.5, Optional ByVal nShadowColor As Long = 0, Optional ByVal nShadowOffsetX As Long = 2, Optional ByVal nShadowOffsetY As Long = 2, Optional ByVal nShadowLODBias As Single = 1.5, Optional ByVal nAngle As Single, Optional ByVal bSingle As Boolean, Optional ByRef nWidthReturn As Single, Optional ByRef nHeightReturn As Single)
'Dim mat As D3DMATRIX
'Dim p As D3DRECT
'Dim obj As Direct3DDevice9
'If bSingle Then tFont.objSprite.Begin D3DXSPRITE_ALPHABLEND
'Set obj = tFont.objSprite.GetDevice
'mat.m11 = nZoom * Cos(nAngle)
'mat.m12 = nZoom * Sin(nAngle)
'mat.m21 = -mat.m12
'mat.m22 = mat.m11
'mat.m33 = 1
'mat.m41 = nLeft
'mat.m42 = nTop
'mat.m44 = 1
'nWidth = nWidth / nZoom
'nHeight = nHeight / nZoom
'tFont.objSprite.SetTransform mat
'If nShadowColor Then
' p.X1 = nShadowOffsetX
' p.Y1 = nShadowOffsetY
' p.X2 = nWidth + nShadowOffsetX
' p.Y2 = nHeight + nShadowOffsetY
' obj.SetSamplerState 0, D3DSAMP_MIPMAPLODBIAS, SingleToLong(nShadowLODBias)
' tFont.objFont.DrawTextW tFont.objSprite, ByVal StrPtr(lpStr), -1, p, wFormat And Not DT_CALCRECT, nShadowColor
' tFont.objSprite.Flush
'End If
'If nColor Then
' p.X1 = 0
' p.Y1 = 0
' p.X2 = nWidth
' p.Y2 = nHeight
' obj.SetSamplerState 0, D3DSAMP_MIPMAPLODBIAS, SingleToLong(nTextLODBias)
' If wFormat And DT_CALCRECT Then
'  tFont.objFont.DrawTextW tFont.objSprite, ByVal StrPtr(lpStr), -1, p, wFormat, nColor
'  nWidthReturn = p.X2 * nZoom
'  nHeightReturn = p.Y2 * nZoom
' End If
' tFont.objFont.DrawTextW tFont.objSprite, ByVal StrPtr(lpStr), -1, p, wFormat And Not DT_CALCRECT, nColor
' tFont.objSprite.Flush
'End If
'If bSingle Then tFont.objSprite.End
'End Sub

'//////////////////////////////////////////////////


'  If m_bMultiLine And m_bWrap Then
'   ii = m_tCaret.nRow
'   kk = 0
'   If ii < 0 Or Not m_bMultiLine Then ii = 0 _
'   Else If ii >= m_nLineCount Then ii = m_nLineCount - 1
'   m = Len(m_sLines(ii))
'   i = m_tCaret.nPosition
'   If i > m Then i = m
'   If m > 0 And i > 0 Then
'    '///search for sub-lines
'    With m_tLineData(ii)
'     iii = 0
'     kkk = .nLineHeight - 1
'     Do
'      kk = (iii + kkk) \ 2
'      jjj = .nLineStart(kk)
'      If i < jjj Then
'       kkk = kk - 1
'      ElseIf i >= jjj + .nLineLength(kk) Then
'       iii = kk + 1
'      Else
'       Exit Do
'      End If
'      If iii > kkk Then
'       kk = .nLineHeight - 1
'       Exit Do
'      End If
'     Loop
'     '///
'     jjj = .nLineStart(kk)
'     i = i - jjj
'     lp = StrPtr(m_sLines(ii)) + jjj * 2&
'     m = .nLineLength(kk)
'    End With
'    '///
'    If m > 0 And i > 0 Then
'     ReDim nCaretPos(m - 1)
'     ReDim nDistance(m - 1)
'     t.lStructSize = Len(t)
'     t.lpDx = VarPtr(nDistance(0))
'     t.lpCaretPos = VarPtr(nCaretPos(0))
'     t.nGlyphs = m
'     GetCharacterPlacementW h, ByVal lp, m, 0, t, 0
'     If i < m Then
'      j = nCaretPos(i)
'      If m_bInsertMode Then jj = j + nDistance(i) Else jj = j + 4
'     Else
'      j = nCaretPos(m - 1) + nDistance(m - 1)
'      If m_bInsertMode Then jj = j + 16 Else jj = j + 4
'     End If
'    End If
'   End If
'   k = (m_tLineData(ii).nLineOffset + kk) * m_nLineHeight
'  Else
'   ii = m_tCaret.nRow
'   If ii < 0 Or Not m_bMultiLine Then ii = 0 _
'   Else If ii >= m_nLineCount Then ii = m_nLineCount - 1
'   m = Len(m_sLines(ii))
'   i = m_tCaret.nPosition
'   If i > m Then i = m
'   If m > 0 And i > 0 Then
'    ReDim nCaretPos(m - 1)
'    ReDim nDistance(m - 1)
'    t.lStructSize = Len(t)
'    t.lpDx = VarPtr(nDistance(0))
'    t.lpCaretPos = VarPtr(nCaretPos(0))
'    t.nGlyphs = m
'    GetCharacterPlacementW h, ByVal StrPtr(m_sLines(ii)), m, 0, t, 0
'    If i < m Then
'     j = nCaretPos(i)
'     If m_bInsertMode Then jj = j + nDistance(i) Else jj = j + 4
'    Else
'     j = nCaretPos(m - 1) + nDistance(m - 1)
'     If m_bInsertMode Then jj = j + 16 Else jj = j + 4
'    End If
'   End If
'   If m_bMultiLine Then k = ii * m_nLineHeight
'  End If
'  '///draw
'  j = nLeft + (j - m_nScrollValue(0)) * m_nFontZoom
'  jj = nLeft + (jj - m_nScrollValue(0)) * m_nFontZoom
'  k = nTop + (k - m_nScrollValue(1)) * m_nFontZoom
'  FakeDXGDIStretchBltColored j, k, jj, k + m_nLineHeight * m_nFontZoom, 12, 496, 12, 496, 512, clr

