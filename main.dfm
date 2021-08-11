object mainFrm: TmainFrm
  Left = 293
  Top = 219
  Caption = 'HFS ~ HTTP File Server'
  ClientHeight = 391
  ClientWidth = 783
  Color = clBtnFace
  Constraints.MinHeight = 260
  Constraints.MinWidth = 390
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poDesigned
  OnAfterMonitorDpiChanged = FormAfterMonitorDpiChanged
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnKeyUp = FormKeyUp
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object graphSplitter: TSplitter
    Left = 0
    Top = 109
    Width = 783
    Height = 5
    Cursor = crVSplit
    Align = alTop
    AutoSnap = False
    Beveled = True
    MinSize = 15
    ResizeStyle = rsUpdate
    OnMoved = graphSplitterMoved
    ExplicitTop = 86
    ExplicitWidth = 752
  end
  object graphBox: TPaintBox
    Left = 0
    Top = 79
    Width = 783
    Height = 30
    Hint = 'Pink = Out'#13#10'Yellow = In'
    Align = alTop
    ParentShowHint = False
    PopupMenu = graphMenu
    ShowHint = True
    OnPaint = graphBoxPaint
    ExplicitTop = 51
    ExplicitWidth = 752
  end
  object topToolbar: TToolBar
    Left = 0
    Top = 0
    Width = 783
    Height = 55
    AutoSize = True
    ButtonWidth = 150
    Caption = 'topToolbar'
    EdgeBorders = [ebBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Tahoma'
    Font.Style = []
    Images = IconsDM.images
    List = True
    ParentFont = False
    ShowCaptions = True
    TabOrder = 1
    object menuBtn: TToolButton
      Left = 0
      Top = 0
      Hint = 'Hit ALT or F10 to pop it up'
      AutoSize = True
      Caption = 'Menu'
      ImageIndex = 13
      ImageName = '13'
      ParentShowHint = False
      ShowHint = True
      OnClick = menuBtnClick
    end
    object portBtn: TToolButton
      Left = 61
      Top = 0
      AutoSize = True
      Caption = 'Port: any'
      ImageIndex = 38
      ImageName = '38'
      OnClick = portBtnClick
    end
    object ToolButton4: TToolButton
      Left = 142
      Top = 0
      Width = 9
      Caption = 'ToolButton4'
      ImageIndex = 15
      ImageName = '15'
      Style = tbsSeparator
    end
    object ToolButton2: TToolButton
      Left = 151
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 16
      ImageName = '16'
      Style = tbsSeparator
    end
    object modeBtn: TToolButton
      Left = 159
      Top = 0
      Hint = 'Click to switch'#13#10'F5 on keyboard'
      AutoSize = True
      Caption = 'You are in Easy mode'
      ImageIndex = 29
      ImageName = '29'
      ParentShowHint = False
      ShowHint = True
      OnClick = modeBtnClick
    end
    object ToolButton1: TToolButton
      Left = 0
      Top = 0
      Width = 9
      Caption = 'ToolButton1'
      ImageIndex = 13
      ImageName = '13'
      Wrap = True
      Style = tbsSeparator
    end
    object startBtn: TToolButton
      Left = 0
      Top = 31
      Hint = 'Click to switch ON'#13'F4 on keyboard'
      AutoSize = True
      Caption = 'Server is currently OFF'
      ImageIndex = 11
      ImageName = '11'
      ParentShowHint = False
      ShowHint = True
      OnClick = startBtnClick
    end
    object abortBtn: TToolButton
      Left = 154
      Top = 31
      AutoSize = True
      Caption = 'Abort file addition'
      ImageIndex = 25
      ImageName = '25'
      Visible = False
      OnClick = abortBtnClick
    end
    object restoreCfgBtn: TToolButton
      Left = 282
      Top = 31
      Caption = 'Restore my options'
      ImageIndex = 34
      ImageName = '34'
      Visible = False
      OnClick = restoreCfgBtnClick
    end
    object updateBtn: TToolButton
      Left = 432
      Top = 31
      AutoSize = True
      Caption = 'Update now'
      ImageIndex = 10
      ImageName = '10'
      Visible = False
      OnClick = updateBtnClick
    end
  end
  object urlToolbar: TToolBar
    Left = 0
    Top = 55
    Width = 783
    Height = 24
    AutoSize = True
    ButtonWidth = 122
    EdgeBorders = [ebBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Tahoma'
    Font.Style = []
    Images = IconsDM.images
    List = True
    ParentFont = False
    ShowCaptions = True
    TabOrder = 2
    Wrapable = False
    object browseBtn: TToolButton
      Left = 0
      Top = 0
      AutoSize = True
      Caption = 'Open in browser'
      ImageIndex = 26
      ImageName = '26'
      OnClick = browseBtnClick
    end
    object urlBox: TEdit
      Left = 122
      Top = 0
      Width = 433
      Height = 22
      TabOrder = 0
      OnChange = urlBoxChange
    end
    object copyBtn: TToolButton
      Left = 555
      Top = 0
      AutoSize = True
      Caption = 'Copy to clipboard'
      ImageIndex = 16
      ImageName = '16'
      OnClick = copyBtnClick
    end
  end
  object centralPnl: TPanel
    Left = 0
    Top = 114
    Width = 783
    Height = 277
    Align = alClient
    BevelOuter = bvNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object splitV: TSplitter
      Left = 313
      Top = 0
      Height = 166
      Beveled = True
      Constraints.MaxWidth = 3
      Constraints.MinWidth = 3
      ResizeStyle = rsUpdate
      OnMoved = splitVMoved
      ExplicitHeight = 219
    end
    object splitH: TSplitter
      Left = 0
      Top = 166
      Width = 783
      Height = 5
      Cursor = crVSplit
      Align = alBottom
      Beveled = True
      MinSize = 1
      ResizeStyle = rsUpdate
      OnMoved = splitHMoved
      ExplicitTop = 218
      ExplicitWidth = 732
    end
    object logPnl: TPanel
      Left = 316
      Top = 0
      Width = 467
      Height = 166
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object logBox: TRichEdit
        Left = 0
        Top = 23
        Width = 467
        Height = 143
        Align = alClient
        Font.Charset = RUSSIAN_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        HideSelection = False
        ParentFont = False
        PopupMenu = logmenu
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
        Zoom = 100
        OnChange = logBoxChange
        OnMouseDown = logBoxMouseDown
      end
      object logTitle: TPanel
        Left = 0
        Top = 0
        Width = 467
        Height = 23
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object titlePnl: TPanel
          Left = 0
          Top = 0
          Width = 207
          Height = 23
          Align = alClient
          BevelOuter = bvNone
          Caption = 'Log'
          TabOrder = 0
        end
        object logToolbar: TPanel
          Left = 207
          Top = 0
          Width = 260
          Height = 23
          Align = alRight
          AutoSize = True
          BevelOuter = bvNone
          TabOrder = 1
          object collapsedPnl: TPanel
            Left = 0
            Top = 0
            Width = 21
            Height = 23
            Align = alRight
            AutoSize = True
            BevelOuter = bvNone
            TabOrder = 0
            object expandBtn: TSpeedButton
              Left = 0
              Top = 0
              Width = 21
              Height = 23
              Hint = 'Expand toolbar'
              Align = alClient
              Flat = True
              Glyph.Data = {
                EE010000424DEE0100000000000036000000280000000D0000000B0000000100
                180000000000B801000000000000000000000000000000000000C8D0D4C8D0D4
                C8D0D4C8D0D4C8D0D49A775AC8D0D4C8D0D4C8D0D4C8D0D49A775AC8D0D4C8D0
                D473C8D0D4C8D0D4C8D0D4C8D0D49A775A8C05009A775AC8D0D4C8D0D49A775A
                8C05009A775AC8D0D473C8D0D4C8D0D4C8D0D4AC76578C05009A775AC8D0D4C8
                D0D4AC76578C05009A775AC8D0D4C8D0D473C8D0D4C8D0D49A775A8C05009A77
                5AC8D0D4C8D0D49A775A8C05009A775AC8D0D4C8D0D4C8D0D473C8D0D49A775A
                8C05009A775AC8D0D4C8D0D49A775A8C05009A775AC8D0D4C8D0D4C8D0D4C8D0
                D4739A775A8C0500B37E5FC8D0D4C8D0D49A775A8C0500B37E5FC8D0D4C8D0D4
                C8D0D4C8D0D4C8D0D473C8D0D4B17C5C8C05009A775AC8D0D4C8D0D4B17C5C8C
                05009A775AC8D0D4C8D0D4C8D0D4C8D0D473C8D0D4C8D0D49A775A8C0500AF79
                5AC8D0D4C8D0D49A775A8C0500AF795AC8D0D4C8D0D4C8D0D473C8D0D4C8D0D4
                C8D0D49A775A8C05009A775AC8D0D4C8D0D49A775A8C05009A775AC8D0D4C8D0
                D473C8D0D4C8D0D4C8D0D4C8D0D49A775A8C05009A775AC8D0D4C8D0D49A775A
                8C05009A775AC8D0D473C8D0D4C8D0D4C8D0D4C8D0D4C8D0D49A775AC8D0D4C8
                D0D4C8D0D4C8D0D49A775AC8D0D4C8D0D473}
              ParentShowHint = False
              ShowHint = True
              OnClick = expandBtnClick
              ExplicitTop = 1
            end
          end
          object expandedPnl: TPanel
            Left = 21
            Top = 0
            Width = 239
            Height = 23
            Align = alRight
            AutoSize = True
            BevelOuter = bvNone
            TabOrder = 1
            object openFilteredLog: TSpeedButton
              Left = 213
              Top = 0
              Width = 26
              Height = 23
              Hint = 'Copy to editor only lines matched by the search pattern'
              Align = alRight
              Enabled = False
              Flat = True
              Glyph.Data = {
                36060000424D3606000000000000360000002800000020000000100000000100
                18000000000000060000C21E0000C21E00000000000000000000FF00FFFF00FF
                FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
                FF979697756A67A3A2A2FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
                00FFFF00FFFF00FFFF00FFFF00FFFF00FFAEAEAE989898B5B5B5FF00FFFF00FF
                FF00FFFF00FFFF00FFC9A9A3D0AFA9E0B2A8E0B2A8E0B2A8E0B2A8E0B2A88B89
                8A9C6F757890DB749AB5FF00FFFF00FFFF00FFFF00FFFF00FFB8B8B8BCBCBCBD
                BDBDBDBDBDBDBDBDBDBDBDBDBDBDA8A8A89D9D9DB5B5B5B3B3B3FF00FFFF00FF
                FF00FFFF00FFFF00FFCDABA3E4D4C7F6EFE7F6EFE7F6EFE7F6EFE79291939D70
                747185D340B4FF89D1F5FF00FFFF00FFFF00FFFF00FFFF00FFB9B9B9CCCCCCDA
                DADADADADADADADADADADAADADAD9E9E9EB0B0B0C5C5C5CFCFCFFF00FFFF00FF
                FF00FFFF00FFFF00FFCFB0AAEAD8CBF9EADAFBE7D3FBE4CDA7A9AB966C746F89
                DB3DBFFF97D5F3FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFBCBCBCCECECED7
                D7D7D5D5D5D3D3D3B8B8B89C9C9CB3B3B3C9C9C9CFCFCFFF00FFFF00FFC2A5A2
                C29790C29790C29790BC91886A5D5C8473707F6C69837D805A52546886CD2EB2
                FF5B8FAFD9B39CFF00FFFF00FFB7B7B7B0B0B0B0B0B0B0B0B0ADADAD9292929D
                9D9D9B9B9BA3A3A38D8D8DB0B0B0C5C5C5AEAEAEBCBCBCFF00FFFF00FFC2A5A2
                F8E6DDF8E6DDF8E6DDA2817CFFFFFAFFFFFFFFFFECFFE8B8BD91859AB6C78CB9
                D1F5E8D7DCB79EFF00FFFF00FFB7B7B7D6D6D6D6D6D6D6D6D6A5A5A5E2E2E2E2
                E2E2E0E0E0D3D3D3ADADADC0C0C0C2C2C2D6D6D6BEBEBEFF00FFFF00FFC5A7A2
                F6EDE2F8E9D8847876FFFFF9F4FBFFEEF3DFF0F3CDF5F7C4EECBA4CCBBB9FBD7
                B3F7E7D5DDB8A0FF00FFFF00FFB7B7B7D9D9D9D6D6D6A0A0A0E2E2E2E1E1E1DB
                DBDBD8D8D8DADADAC6C6C6C1C1C1CCCCCCD6D6D6BEBEBEFF00FFFF00FFCDABA3
                F8E5D1FED1A5BEAD94F8FEEAE2E5E5DFE1D9DEE1C5DBCEA6E3D5A8D1B8A7FBE3
                C9F7EBDDE0BBA3FF00FFFF00FFB9B9B9D4D4D4C9C9C9B8B8B8E0E0E0D6D6D6D3
                D3D3D1D1D1C7C7C7CACACABEBEBED3D3D3D8D8D8C0C0C0FF00FFFF00FFCEADA7
                F7EDE3F8E9D8D0BE9DEFF6D3DFE4CFDAE0C8D9DCB9D7C7A0DBCEA3D8C3ADFED8
                B2F8E7D5E0BBA3FF00FFFF00FFBABABAD9D9D9D6D6D6C0C0C0DBDBDBD3D3D3D1
                D1D1CECECEC4C4C4C7C7C7C3C3C3CCCCCCD6D6D6C0C0C0FF00FFFF00FFD1B3AD
                FAE7D4FED1A5BB9B81FDFECBE3E1BCE0DFB9DFD5A8DECDABE6E4BDD1BDABFEEF
                DFF7D4C9E2A398FF00FFFF00FFBDBDBDD5D5D5C9C9C9B0B0B0DDDDDDD0D0D0CF
                CFCFCACACAC8C8C8D1D1D1C1C1C1DADADACDCDCDB7B7B7FF00FFFF00FFDCBBAB
                FAF4EFFEEFE0A18D8EEBCC9DF4EDB7EDD5A1EDE0B9ECF2F6DBCAC2C7C0BFE5D0
                C8C48F77BE8D7FFF00FFFF00FFC1C1C1DDDDDDDADADAABABABC5C5C5D5D5D5CA
                CACACFCFCFDDDDDDC8C8C8C4C4C4CBCBCBABABABABABABFF00FFFF00FFE3C1AD
                FBEDDEFED1A5FED1A5B59B97E3C5A5EFD8ABE4D5AFD3C3BAC0B7B9F5F3F1DECC
                C8D8A582FF00FFFF00FFFF00FFC3C3C3D8D8D8C9C9C9C9C9C9B2B2B2C4C4C4CC
                CCCCCACACAC4C4C4BFBFBFDDDDDDCACACAB5B5B5FF00FFFF00FFFF00FFE9C7B0
                FCFCFDFFFEFEFEFCF8F6DFC9C2C5D0BCB4BCB0A8AEC0C5CCD7A990E7C5AFDEBC
                ABFF00FFFF00FFFF00FFFF00FFC5C5C5E1E1E1E2E2E2E1E1E1D1D1D1C8C8C8BF
                BFBFB8B8B8C7C7C7B7B7B7C5C5C5C1C1C1FF00FFFF00FFFF00FFFF00FFECCBB3
                FEFDFDFFFFFEFEFEFEFEFCFAFEF8F1FEF5EAC89C8EBF8E80CDABA3FF00FFFF00
                FFFF00FFFF00FFFF00FFFF00FFC8C8C8E2E2E2E2E2E2E2E2E2E1E1E1DFDFDFDD
                DDDDB2B2B2ABABABB9B9B9FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFF3D3B6
                FEFEFEFEFEFEFDFEFDFCFCFCFCFAF7FCF7F0C9957AE3B58FFF00FFFF00FFFF00
                FFFF00FFFF00FFFF00FFFF00FFCACACAE2E2E2E2E2E2E2E2E2E1E1E1E0E0E0DE
                DEDEAEAEAEBCBCBCFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFF3D3B6
                E7C4AEE7C4AEE6C4ADE5C2ACE5C2ACE5C1A9C49788FF00FFFF00FFFF00FFFF00
                FFFF00FFFF00FFFF00FFFF00FFCACACAC4C4C4C4C4C4C4C4C4C3C3C3C3C3C3C3
                C3C3AFAFAFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF}
              NumGlyphs = 2
              ParentShowHint = False
              ShowHint = True
              OnClick = openLogBtnClick
            end
            object openLogBtn: TSpeedButton
              Left = 187
              Top = 0
              Width = 26
              Height = 23
              Hint = 'Copy to editor'
              Align = alRight
              Flat = True
              Glyph.Data = {
                36040000424D3604000000000000360000002800000010000000100000000100
                2000000000000004000000000000000000000000000000000000FF00FF00FF00
                FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
                FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00
                FF00FF00FF00FF00FF00FF00FF00C9A9A300D0AFA900E0B2A800E0B2A800E0B2
                A800E0B2A800E0B2A800E0B2A800E0B2A800C4958E00FF00FF00FF00FF00FF00
                FF00FF00FF00FF00FF00FF00FF00CDABA300E4D4C700F6EFE700F6EFE700F6EF
                E700F6EFE700F6EFE700F6EFE700F6EFE700D8B29B00FF00FF00FF00FF00FF00
                FF00FF00FF00FF00FF00FF00FF00CFB0AA00EAD8CB00F9EADA00FBE7D300FBE4
                CD00FBE3C900FBE3C900FBDFBF00F7E9D900D8B29B00FF00FF00FF00FF00C2A5
                A200C2979000C2979000C2979000BC918800E7DBD400F9DFC400FBD7B300FBD7
                B300FBD7B300FBD7B300FDD7B200F7E7D500D9B39C00FF00FF00FF00FF00C2A5
                A200F8E6DD00F8E6DD00F8E6DD00D6B0A100EDDFD500F9E4CC00FBDFBF00FBDF
                BF00FBDFBF00FBDFBF00F5DBB800F5E8D700DCB79E00FF00FF00FF00FF00C5A7
                A200F6EDE200F8E9D800F9E9D700DAB49E00EFE3DB00F9DFC400FBD7B300FBD7
                B300FBD7B300FBD7B300FBD7B300F7E7D500DDB8A000FF00FF00FF00FF00CDAB
                A300F8E5D100FED1A500FED1A300E3B28E00F2E9E000FAE8D600FBE3C900FBE3
                C900FBE3C900FBE3C900FBE3C900F7EBDD00E0BBA300FF00FF00FF00FF00CEAD
                A700F7EDE300F8E9D800F8E9D800E5BDA200F4ECE400FDE6CF00FEDCBB00FDDB
                B900FEDAB500FED9B400FED8B200F8E7D500E0BBA300FF00FF00FF00FF00D1B3
                AD00FAE7D400FED1A500FED1A500EAB99400F8F0E900FFFEFE00FEFEFE00FEFA
                F900FEF8EF00FEF4EA00FEEFDF00F7D4C900E2A39800FF00FF00FF00FF00DCBB
                AB00FAF4EF00FEEFE000FEECD900EEC7A800FAF2EA00FDFEFE00FEFEFE00FEFE
                FD00FEFBF900FEF9F100E5D0C800C48F7700BE8D7F00FF00FF00FF00FF00E3C1
                AD00FBEDDE00FED1A500FED1A500F2C39800FDF4EA00FDFEFC00FAFBFA00FAF8
                F800F6F6F600F5F3F100DECCC800D8A58200FF00FF00FF00FF00FF00FF00E9C7
                B000FCFCFD00FFFEFE00FEFCF800F6DFC900E7C2A800E7C0A600E2B69A00DAA8
                8B00D7A99000E7C5AF00DEBCAB00FF00FF00FF00FF00FF00FF00FF00FF00ECCB
                B300FEFDFD00FFFFFE00FEFEFE00FEFCFA00FEF8F100FEF5EA00C89C8E00BF8E
                8000CDABA300FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F3D3
                B600FEFEFE00FEFEFE00FDFEFD00FCFCFC00FCFAF700FCF7F000C9957A00E3B5
                8F00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00F3D3
                B600E7C4AE00E7C4AE00E6C4AD00E5C2AC00E5C2AC00E5C1A900C4978800FF00
                FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00}
              ParentShowHint = False
              ShowHint = True
              OnClick = openLogBtnClick
            end
            object collapseBtn: TSpeedButton
              Left = 0
              Top = 0
              Width = 21
              Height = 23
              Hint = 'Collapse toolbar'
              Align = alRight
              Flat = True
              Glyph.Data = {
                EE010000424DEE0100000000000036000000280000000D0000000B0000000100
                180000000000B801000000000000000000000000000000000000C8D0D4C8D0D4
                9A775AC8D0D4C8D0D4C8D0D4C8D0D49A775AC8D0D4C8D0D4C8D0D4C8D0D4C8D0
                D400C8D0D49A775A8C05009A775AC8D0D4C8D0D49A775A8C05009A775AC8D0D4
                C8D0D4C8D0D4C8D0D400C8D0D4C8D0D49A775A8C0500AC7657C8D0D4C8D0D49A
                775A8C0500AC7657C8D0D4C8D0D4C8D0D400C8D0D4C8D0D4C8D0D49A775A8C05
                009A775AC8D0D4C8D0D49A775A8C05009A775AC8D0D4C8D0D400C8D0D4C8D0D4
                C8D0D4C8D0D49A775A8C05009A775AC8D0D4C8D0D49A775A8C05009A775AC8D0
                D400C8D0D4C8D0D4C8D0D4C8D0D4C8D0D4B37E5F8C05009A775AC8D0D4C8D0D4
                B37E5F8C05009A775A00C8D0D4C8D0D4C8D0D4C8D0D49A775A8C0500B17C5CC8
                D0D4C8D0D49A775A8C0500B17C5CC8D0D400C8D0D4C8D0D4C8D0D4AF795A8C05
                009A775AC8D0D4C8D0D4AF795A8C05009A775AC8D0D4C8D0D400C8D0D4C8D0D4
                9A775A8C05009A775AC8D0D4C8D0D49A775A8C05009A775AC8D0D4C8D0D4C8D0
                D400C8D0D49A775A8C05009A775AC8D0D4C8D0D49A775A8C05009A775AC8D0D4
                C8D0D4C8D0D4C8D0D400C8D0D4C8D0D49A775AC8D0D4C8D0D4C8D0D4C8D0D49A
                775AC8D0D4C8D0D4C8D0D4C8D0D4C8D0D400}
              ParentShowHint = False
              ShowHint = True
              OnClick = collapseBtnClick
            end
            object Bevel1: TBevel
              Left = 21
              Top = 0
              Width = 2
              Height = 23
              Align = alRight
            end
            object searchPnl: TPanel
              Left = 23
              Top = 0
              Width = 164
              Height = 23
              Align = alRight
              AutoSize = True
              BevelOuter = bvNone
              Padding.Left = 5
              TabOrder = 0
              DesignSize = (
                164
                23)
              object logSearchBox: TLabeledEdit
                Left = 45
                Top = 1
                Width = 103
                Height = 22
                Hint = 'Wildcards allowed'
                Anchors = [akTop, akRight]
                EditLabel.Width = 37
                EditLabel.Height = 14
                EditLabel.Caption = 'Search'
                LabelPosition = lpLeft
                ParentShowHint = False
                ShowHint = True
                TabOrder = 0
                OnChange = logSearchBoxChange
                OnKeyPress = logSearchBoxKeyPress
              end
              object logUpDown: TUpDown
                Left = 148
                Top = 0
                Width = 16
                Height = 24
                Anchors = [akTop, akRight]
                Min = -30000
                Max = 30000
                TabOrder = 1
                OnClick = logUpDownClick
              end
            end
          end
        end
      end
    end
    object filesPnl: TPanel
      Left = 0
      Top = 0
      Width = 313
      Height = 166
      Align = alLeft
      BevelOuter = bvNone
      Caption = 'filesPnl'
      TabOrder = 0
      object filesBox: TTreeView
        Left = 0
        Top = 23
        Width = 313
        Height = 143
        Align = alClient
        BevelInner = bvLowered
        BevelOuter = bvSpace
        Constraints.MinWidth = 50
        DragMode = dmAutomatic
        HotTrack = True
        Images = IconsDM.images
        Indent = 25
        MultiSelect = True
        MultiSelectStyle = [msControlSelect, msShiftSelect]
        ParentShowHint = False
        PopupMenu = filemenu
        ShowHint = True
        ShowRoot = False
        SortType = stBoth
        StateImages = IconsDM.images
        TabOrder = 0
        OnAddition = filesBoxAddition
        OnChange = filesBoxChange
        OnCollapsing = filesBoxCollapsing
        OnCompare = filesBoxCompare
        OnCustomDrawItem = filesBoxCustomDrawItem
        OnDblClick = filesBoxDblClick
        OnDeletion = filesBoxDeletion
        OnDragDrop = filesBoxDragDrop
        OnDragOver = filesBoxDragOver
        OnEdited = filesBoxEdited
        OnEditing = filesBoxEditing
        OnEndDrag = filesBoxEndDrag
        OnEnter = filesBoxEnter
        OnExit = filesBoxExit
        OnMouseDown = filesBoxMouseDown
        OnMouseEnter = filesBoxMouseEnter
        OnMouseLeave = filesBoxMouseLeave
        OnMouseUp = filesBoxMouseUp
      end
      object filesTitle: TPanel
        Left = 0
        Top = 0
        Width = 313
        Height = 23
        Align = alTop
        BevelOuter = bvNone
        Caption = 'Virtual File System'
        TabOrder = 1
      end
    end
    object connPnl: TPanel
      Left = 0
      Top = 171
      Width = 783
      Height = 106
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      object sbar: TStatusBar
        Left = 0
        Top = 87
        Width = 783
        Height = 19
        Panels = <
          item
            Width = 2000
          end>
        OnDblClick = sbarDblClick
        OnMouseDown = sbarMouseDown
      end
      object connBox: TListView
        Left = 0
        Top = 0
        Width = 783
        Height = 87
        Align = alClient
        Columns = <
          item
            Caption = 'IP address'
            ImageIndex = 0
            Width = 206
          end
          item
            Alignment = taCenter
            Caption = 'File'
            ImageIndex = 7
            Width = 206
          end
          item
            Alignment = taCenter
            Caption = 'Status'
            Width = 206
          end
          item
            Alignment = taCenter
            Caption = 'Speed'
          end
          item
            Alignment = taCenter
            Caption = 'Time left'
          end
          item
            Alignment = taCenter
            AutoSize = True
            Caption = 'Progress'
          end>
        ColumnClick = False
        FullDrag = True
        GridLines = True
        OwnerData = True
        ReadOnly = True
        RowSelect = True
        ParentShowHint = False
        PopupMenu = connmenu
        ShowHint = True
        SmallImages = IconsDM.images
        TabOrder = 1
        ViewStyle = vsReport
        OnAdvancedCustomDrawSubItem = connBoxAdvancedCustomDrawSubItem
        OnData = connBoxData
      end
    end
  end
  object filemenu: TPopupMenu
    Images = IconsDM.images
    OwnerDraw = True
    OnPopup = filemenuPopup
    Left = 128
    Top = 168
    object Addfiles1: TMenuItem
      Caption = 'Add files...'
      OnClick = Addfiles1Click
    end
    object Addfolder1: TMenuItem
      Caption = 'Add folder from disk...'
      ImageIndex = 8
      ImageName = '8'
      OnClick = Addfolder1Click
    end
    object newfolder1: TMenuItem
      Caption = 'New empty folder'
      ShortCut = 45
      OnClick = newfolder1Click
    end
    object Newlink1: TMenuItem
      Caption = 'New link'
      ImageIndex = 4
      ImageName = '4'
      OnClick = Newlink1Click
    end
    object Remove1: TMenuItem
      Caption = 'Remove'
      ImageIndex = 21
      ImageName = '21'
      ShortCut = 46
      OnClick = Remove1Click
    end
    object Rename1: TMenuItem
      Caption = 'Rename'
      ShortCut = 113
      OnClick = Rename1Click
    end
    object Paste1: TMenuItem
      Caption = 'Paste'
      ImageIndex = 17
      ImageName = '17'
      ShortCut = 16470
      OnClick = Paste1Click
    end
    object Editresource1: TMenuItem
      Caption = 'Edit resource...'
      OnClick = Editresource1Click
    end
    object N7: TMenuItem
      Caption = '-'
    end
    object CopyURL1: TMenuItem
      Caption = 'Copy URL address'
      Default = True
      Hint = 'just double click!'
      ImageIndex = 16
      ImageName = '16'
      ShortCut = 16451
      OnClick = CopyURL1Click
    end
    object CopyURLwithpassword1: TMenuItem
      AutoHotkeys = maManual
      Caption = 'Copy URL with password'
    end
    object Browseit1: TMenuItem
      Caption = 'Browse it'
      ImageIndex = 26
      ImageName = '26'
      ShortCut = 120
      OnClick = Browseit1Click
    end
    object SetURL1: TMenuItem
      Caption = 'Set URL...'
      ImageIndex = 4
      ImageName = '4'
      OnClick = SetURL1Click
    end
    object Openit1: TMenuItem
      Caption = 'Open it'
      ShortCut = 119
      OnClick = Openit1Click
    end
    object Flagasnew1: TMenuItem
      Caption = 'Flag as new'
      OnClick = Flagasnew1Click
    end
    object Resetnewflag1: TMenuItem
      Caption = 'Reset <new> flag'
      OnClick = Resetnewflag1Click
    end
    object Setuserpass1: TMenuItem
      Caption = 'Set user/pass...'
      ImageIndex = 12
      ImageName = '12'
      OnClick = Setuserpass1Click
    end
    object Resetuserpass1: TMenuItem
      Caption = 'Reset user/pass'
      OnClick = Resetuserpass1Click
    end
    object N11: TMenuItem
      Caption = '-'
    end
    object CopyURLwithdifferentaddress1: TMenuItem
      Caption = 'Copy URL with different host address'
    end
    object CopyURLwithfingerprint1: TMenuItem
      Caption = 'Copy URL with fingerprint'
      OnClick = CopyURLwithfingerprint1Click
    end
    object Purge1: TMenuItem
      Caption = 'Purge...'
      OnClick = Purge1Click
    end
    object Switchtovirtual1: TMenuItem
      Caption = 'Change to virtual-folder'
      OnClick = Switchtovirtual1Click
    end
    object Switchtorealfolder1: TMenuItem
      Caption = 'Change to real-folder'
      OnClick = Switchtorealfolder1Click
    end
    object Bindroottorealfolder1: TMenuItem
      Caption = 'Bind root to real-folder'
      OnClick = Bindroottorealfolder1Click
    end
    object Unbindroot1: TMenuItem
      Caption = 'Unbind root'
      OnClick = Unbindroot1Click
    end
    object Defaultpointtoaddfiles1: TMenuItem
      Caption = 'Default point to add files'
      OnClick = Defaultpointtoaddfiles1Click
    end
    object N14: TMenuItem
      Caption = '-'
    end
    object Properties1: TMenuItem
      Caption = 'Properties...'
      ShortCut = 32781
      OnClick = Properties1Click
    end
  end
  object menu: TPopupMenu
    Images = IconsDM.images
    OnPopup = menuPopup
    Left = 40
    object SelfTest1: TMenuItem
      Caption = 'Self Test'
      ImageIndex = 34
      ImageName = '34'
      OnClick = SelfTest1Click
    end
    object Showbandwidthgraph1: TMenuItem
      Caption = 'Show bandwidth graph'
      OnClick = Showbandwidthgraph1Click
    end
    object Otheroptions1: TMenuItem
      Caption = 'Other options'
      object switchMode: TMenuItem
        Caption = 'Switch to expert mode'
        ShortCut = 116
        OnClick = modeBtnClick
      end
      object Accounts1: TMenuItem
        Caption = 'User accounts...'
        ImageIndex = 29
        ImageName = '29'
        ShortCut = 118
        OnClick = Accounts1Click
      end
      object Shellcontextmenu1: TMenuItem
        Caption = 'Integrate in shell context menu'
        ImageIndex = 22
        ImageName = '22'
        OnClick = Shellcontextmenu1Click
      end
      object AutocopyURLonadditionChk: TMenuItem
        AutoCheck = True
        Caption = 'Auto-copy URL on addition'
        Checked = True
      end
      object alwaysontopChk: TMenuItem
        AutoCheck = True
        Caption = 'Always on top'
        OnClick = alwaysontopChkClick
      end
      object sendHFSidentifierChk: TMenuItem
        AutoCheck = True
        Caption = 'Send HFS identifier'
        Checked = True
      end
      object persistentconnectionsChk: TMenuItem
        AutoCheck = True
        Caption = 'Persistent connections'
        Checked = True
        OnClick = persistentconnectionsChkClick
      end
      object DMbrowserTplChk: TMenuItem
        AutoCheck = True
        Caption = 'Specific HTML for download managers'
        Checked = True
      end
      object Graphrefreshrate1: TMenuItem
        Caption = 'Graph refresh rate...'
        OnClick = Graphrefreshrate1Click
      end
      object MIMEtypes1: TMenuItem
        Caption = 'MIME types...'
        ImageIndex = 7
        ImageName = '7'
        OnClick = MIMEtypes1Click
      end
      object Opendirectlyinbrowser1: TMenuItem
        Caption = 'Open directly in browser...'
        OnClick = Opendirectlyinbrowser1Click
      end
      object freeLoginChk: TMenuItem
        AutoCheck = True
        Caption = 'Accept any login for unprotected resources'
      end
      object usecommentasrealmChk: TMenuItem
        AutoCheck = True
        Caption = 'Use comment as realm'
        Checked = True
      end
      object Loginrealm1: TMenuItem
        Caption = 'Login realm...'
        OnClick = Loginrealm1Click
      end
      object HintsfornewcomersChk: TMenuItem
        AutoCheck = True
        Caption = 'Hints for newcomers'
        Checked = True
      end
      object compressedbrowsingChk: TMenuItem
        AutoCheck = True
        Caption = 'Compressed browsing'
        Checked = True
      end
      object modalOptionsChk: TMenuItem
        AutoCheck = True
        Caption = 'Modal dialog for options'
        Checked = True
      end
      object useISOdateChk: TMenuItem
        AutoCheck = True
        Caption = 'Use ISO date format'
        OnClick = useISOdateChkClick
      end
      object browseUsingLocalhostChk: TMenuItem
        AutoCheck = True
        Caption = 'Browse using localhost'
        Checked = True
      end
      object enableNoDefaultChk: TMenuItem
        AutoCheck = True
        Caption = 'Enable ~nodefault'
      end
      object preventStandbyChk: TMenuItem
        AutoCheck = True
        Caption = 'Prevent system standby on network activity'
      end
      object Addicons1: TMenuItem
        Caption = 'Add icons...'
        OnClick = Addicons1Click
      end
      object Changeport1: TMenuItem
        Caption = 'Change port...'
        OnClick = Changeport1Click
      end
      object autoCommentChk: TMenuItem
        AutoCheck = True
        Caption = 'Input comment on file addition'
      end
      object Defaultsorting1: TMenuItem
        Caption = 'Default sorting'
        object Name1: TMenuItem
          Caption = 'Name'
          Checked = True
          GroupIndex = 1
          RadioItem = True
          OnClick = Name1Click
        end
        object Extension1: TMenuItem
          Caption = 'Extension'
          GroupIndex = 1
          RadioItem = True
          OnClick = Extension1Click
        end
        object Size1: TMenuItem
          Caption = 'Size'
          GroupIndex = 1
          RadioItem = True
          OnClick = Size1Click
        end
        object Time1: TMenuItem
          Caption = 'Time'
          GroupIndex = 1
          RadioItem = True
          OnClick = Time1Click
        end
        object Hits1: TMenuItem
          Caption = 'Hits'
          GroupIndex = 1
          RadioItem = True
          OnClick = Hits1Click
        end
      end
      object Editeventscripts1: TMenuItem
        Caption = 'Edit event scripts...'
        ShortCut = 32885
        OnClick = Editeventscripts1Click
      end
      object oemTarChk: TMenuItem
        AutoCheck = True
        Caption = 'OEM file names for TAR archives'
      end
    end
    object HTMLtemplate1: TMenuItem
      Caption = 'HTML template'
      object Edit1: TMenuItem
        Caption = 'Edit...'
        ShortCut = 117
        OnClick = Edit1Click
      end
      object Changefile1: TMenuItem
        Caption = 'Change file...'
        OnClick = Changefile1Click
      end
      object Changeeditor1: TMenuItem
        Caption = 'Change editor...'
        OnClick = Changeeditor1Click
      end
      object Restoredefault1: TMenuItem
        Caption = 'Restore default'
        OnClick = Restoredefault1Click
      end
      object enableMacrosChk: TMenuItem
        AutoCheck = True
        Caption = 'Enable macros'
        Checked = True
        OnClick = enableMacrosChkClick
      end
    end
    object Upload2: TMenuItem
      Caption = 'Upload'
      object Howto1: TMenuItem
        Caption = 'How to?'
        OnClick = Howto1Click
      end
      object N22: TMenuItem
        Caption = '-'
      end
      object deletePartialUploadsChk: TMenuItem
        AutoCheck = True
        Caption = 'Delete partial uploads'
      end
      object Renamepartialuploads1: TMenuItem
        Caption = 'Rename partial uploads...'
        OnClick = Renamepartialuploads1Click
      end
      object numberFilesOnUploadChk: TMenuItem
        AutoCheck = True
        Caption = 'Number files on upload instead of overwriting'
        Checked = True
      end
    end
    object StartExit1: TMenuItem
      Caption = 'Start/Exit'
      object autocopyURLonstartChk: TMenuItem
        AutoCheck = True
        Caption = 'Auto-copy URL on start'
      end
      object startminimizedChk: TMenuItem
        AutoCheck = True
        Caption = 'Start minimized'
      end
      object reloadonstartupChk: TMenuItem
        AutoCheck = True
        Caption = 'Reload on startup VFS file previously open'
        Checked = True
      end
      object saveTotalsChk: TMenuItem
        AutoCheck = True
        Caption = 'Save totals'
        Checked = True
      end
      object autosaveVFSchk: TMenuItem
        AutoCheck = True
        Caption = 'Auto-save VFS on exit'
      end
      object Autoclose1: TMenuItem
        Caption = 'Auto-close'
        object Nodownloadtimeout1: TMenuItem
          Caption = 'No download timeout...'
          OnClick = Nodownloadtimeout1Click
        end
      end
      object only1instanceChk: TMenuItem
        AutoCheck = True
        Caption = 'Only 1 instance'
        Checked = True
      end
      object confirmexitChk: TMenuItem
        AutoCheck = True
        Caption = 'Confirm exit'
      end
      object findExtOnStartupChk: TMenuItem
        AutoCheck = True
        Caption = 'Find external address on startup'
        OnClick = findExtOnStartupChkClick
      end
      object RunHFSwhenWindowsstarts1: TMenuItem
        Caption = 'Run HFS when Windows starts'
        OnClick = RunHFSwhenWindowsstarts1Click
      end
      object trayInsteadOfQuitChk: TMenuItem
        AutoCheck = True
        Caption = 'Minimize to tray clicking the close button [ X ]'
      end
      object quitWithoutAskingToSaveChk: TMenuItem
        AutoCheck = True
        Caption = 'Force quitting (no dialogs)'
      end
    end
    object VirtualFileSystem1: TMenuItem
      Caption = 'Virtual File System'
      object foldersbeforeChk: TMenuItem
        AutoCheck = True
        Caption = 'Folders before'
        Checked = True
        OnClick = foldersbeforeChkClick
      end
      object linksBeforeChk: TMenuItem
        AutoCheck = True
        Caption = 'Links before'
        Checked = True
      end
      object usesystemiconsChk: TMenuItem
        AutoCheck = True
        Caption = 'Use system icons'
        Checked = True
      end
      object loadSingleCommentsChk: TMenuItem
        AutoCheck = True
        Caption = 'Load single comment files'
        Checked = True
      end
      object supportDescriptionChk: TMenuItem
        AutoCheck = True
        Caption = 'Support DESCRIPT.ION'
        Checked = True
      end
      object oemForIonChk: TMenuItem
        AutoCheck = True
        Caption = 'Use OEM for DESCRIPT.ION'
      end
      object recursiveListingChk: TMenuItem
        AutoCheck = True
        Caption = 'Enable recursive listing'
        Checked = True
      end
      object deleteDontAskChk: TMenuItem
        AutoCheck = True
        Caption = 'Skip confirmation on deletion'
      end
      object listfileswithhiddenattributeChk: TMenuItem
        AutoCheck = True
        Caption = 'List files with <hidden> attribute'
      end
      object listfileswithsystemattributeChk: TMenuItem
        AutoCheck = True
        Caption = 'List files with <system> attribute'
      end
      object hideProtectedItemsChk: TMenuItem
        AutoCheck = True
        Caption = 'List protected items only for allowed users'
      end
      object Iconmasks1: TMenuItem
        Caption = 'Icon masks...'
        OnClick = Iconmasks1Click
      end
      object Flagfilesaddedrecently1: TMenuItem
        Caption = 'Flag files added recently...'
        OnClick = Flagfilesaddedrecently1Click
      end
      object Autosaveevery1: TMenuItem
        Caption = 'Auto-save every...'
        OnClick = Autosaveevery1Click
      end
      object backupSavingChk: TMenuItem
        AutoCheck = True
        Caption = 'Backup on save'
        Checked = True
      end
      object Addingfolder1: TMenuItem
        Caption = 'Adding folder'
        object askFolderKindChk: TMenuItem
          Caption = 'Ask'
          Checked = True
          GroupIndex = 1
          RadioItem = True
          OnClick = askFolderKindChkClick
        end
        object defaultToVirtualChk: TMenuItem
          Caption = 'Default to virtual-folder'
          GroupIndex = 1
          RadioItem = True
          OnClick = defaultToVirtualChkClick
        end
        object defaultToRealChk: TMenuItem
          Caption = 'Default to real-folder'
          GroupIndex = 1
          RadioItem = True
          OnClick = defaultToRealChkClick
        end
      end
      object N18: TMenuItem
        Caption = '-'
      end
      object Resetfileshits1: TMenuItem
        Caption = 'Reset files hits'
        OnClick = Resetfileshits1Click
      end
      object Resettotals1: TMenuItem
        Caption = 'Reset totals'
        OnClick = Resettotals1Click
      end
    end
    object Limits1: TMenuItem
      Caption = 'Limits'
      object Speedlimit1: TMenuItem
        Caption = 'Speed limit (disabled)...'
        OnClick = Speedlimit1Click
      end
      object Speedlimitforsingleaddress1: TMenuItem
        Caption = 'Speed limit for single address...'
        OnClick = Speedlimitforsingleaddress1Click
      end
      object Pausestreaming1: TMenuItem
        AutoCheck = True
        Caption = 'Pause streaming'
        Hint = 'Sets speed limit temporarily to zero'
        OnClick = Pausestreaming1Click
      end
      object maxDLs1: TMenuItem
        Caption = 'Max simultaneous downloads...'
        OnClick = maxDLs1Click
      end
      object maxDLsIP1: TMenuItem
        Caption = 'Max simultaneous downloads from single address...'
        OnClick = maxDLsIP1Click
      end
      object maxIPs1: TMenuItem
        Caption = 'Max simultaneous addresses...'
        OnClick = maxIPs1Click
      end
      object maxIPsDLing1: TMenuItem
        Caption = 'Max simultaneous addresses downloading...'
        OnClick = maxIPsDLing1Click
      end
      object Maxconnections1: TMenuItem
        Caption = 'Max connections...'
        OnClick = Maxconnections1Click
      end
      object Maxconnectionsfromsingleaddress1: TMenuItem
        Caption = 'Max connections from single address...'
        OnClick = Maxconnectionsfromsingleaddress1Click
      end
      object Connectionsinactivitytimeout1: TMenuItem
        Caption = 'Connections inactivity timeout...'
        OnClick = Connectionsinactivitytimeout1Click
      end
      object BannedIPaddresses1: TMenuItem
        Caption = 'Bans...'
        ImageIndex = 25
        ImageName = '25'
        OnClick = BannedIPaddresses1Click
      end
      object Minimumdiskspace1: TMenuItem
        Caption = 'Minimum disk space...'
        OnClick = Minimumdiskspace1Click
      end
      object preventLeechingChk: TMenuItem
        AutoCheck = True
        Caption = 'Prevent leeching (download accelerators)'
        Checked = True
      end
      object Allowedreferer1: TMenuItem
        Caption = 'Allowed referer...'
        OnClick = Allowedreferer1Click
      end
      object stopSpidersChk: TMenuItem
        AutoCheck = True
        Caption = 'Stop spiders'
        Checked = True
      end
    end
    object Flashtaskbutton1: TMenuItem
      Caption = 'Flash taskbutton'
      object onDownloadChk: TMenuItem
        AutoCheck = True
        Caption = 'On download'
        GroupIndex = 1
        RadioItem = True
        OnClick = onDownloadChkClick
      end
      object onconnectionChk: TMenuItem
        AutoCheck = True
        Caption = 'On connection'
        GroupIndex = 1
        RadioItem = True
        OnClick = onconnectionChkClick
      end
      object never1: TMenuItem
        Caption = 'Never'
        GroupIndex = 1
        RadioItem = True
        OnClick = never1Click
      end
      object N6: TMenuItem
        Caption = '-'
        GroupIndex = 1
      end
      object beepChk: TMenuItem
        AutoCheck = True
        Caption = 'Also beep'
        GroupIndex = 1
      end
    end
    object Fingerprints1: TMenuItem
      Caption = 'Fingerprints'
      object fingerprintsChk: TMenuItem
        AutoCheck = True
        Caption = 'Enabled'
        Checked = True
      end
      object saveNewFingerprintsChk: TMenuItem
        AutoCheck = True
        Caption = 'Save new calculated fingerprints'
        OnClick = saveNewFingerprintsChkClick
      end
      object Createfingerprintonaddition1: TMenuItem
        Caption = 'Create fingerprint on file addition...'
        OnClick = Createfingerprintonaddition1Click
      end
    end
    object trayicons1: TMenuItem
      Caption = 'Tray icons'
      object MinimizetotrayChk: TMenuItem
        AutoCheck = True
        Caption = 'Minimize to tray'
        Checked = True
      end
      object showmaintrayiconChk: TMenuItem
        AutoCheck = True
        Caption = 'Show main tray icon'
        Checked = True
        OnClick = showmaintrayiconChkClick
      end
      object hetrayiconshows1: TMenuItem
        Caption = 'Main icon shows'
        object Numberofcurrentconnections1: TMenuItem
          AutoCheck = True
          Caption = 'Number of current connections'
          Checked = True
          GroupIndex = 1
          RadioItem = True
          OnClick = Numberofcurrentconnections1Click
        end
        object Numberofloggeddownloads1: TMenuItem
          AutoCheck = True
          Caption = 'Number of logged downloads'
          GroupIndex = 1
          RadioItem = True
          OnClick = Numberofloggeddownloads1Click
        end
        object Numberofloggeduploads1: TMenuItem
          Caption = 'Number of logged uploads'
          GroupIndex = 1
          OnClick = Numberofloggeduploads1Click
        end
        object Numberofloggedhits1: TMenuItem
          Caption = 'Number of logged hits'
          GroupIndex = 1
          OnClick = Numberofloggedhits1Click
        end
        object NumberofdifferentIPaddresses1: TMenuItem
          Caption = 'Number of different IP addresses now connected'
          GroupIndex = 1
          OnClick = NumberofdifferentIPaddresses1Click
        end
        object NumberofdifferentIPaddresseseverconnected1: TMenuItem
          Caption = 'Number of different IP addresses ever connected'
          GroupIndex = 1
          OnClick = NumberofdifferentIPaddresseseverconnected1Click
        end
      end
      object traymessage1: TMenuItem
        Caption = 'Tray message...'
        OnClick = traymessage1Click
      end
      object N8: TMenuItem
        Caption = '-'
      end
      object trayfordownloadChk: TMenuItem
        AutoCheck = True
        Caption = 'Tray icon for each download'
        Checked = True
      end
    end
    object IPaddress1: TMenuItem
      AutoLineReduction = maManual
      Caption = '&IP address'
      object hisIPaddressisusedforURLbuilding1: TMenuItem
        Caption = 'This IP address is used only for URL building'
        Enabled = False
      end
      object N20: TMenuItem
        Caption = '-'
      end
      object N15: TMenuItem
        Caption = '-'
      end
      object Custom1: TMenuItem
        Caption = 'Custom...'
        OnClick = Custom1Click
      end
      object noPortInUrlChk: TMenuItem
        AutoCheck = True
        Caption = 'Don'#39't include port in URL'
        OnClick = noPortInUrlChkClick
      end
      object Findexternaladdress1: TMenuItem
        Caption = 'Find external address'
        OnClick = Findexternaladdress1Click
      end
      object searchbetteripChk: TMenuItem
        AutoCheck = True
        Caption = 'Constantly search for better address'
        Checked = True
      end
    end
    object Acceptconnectionson1: TMenuItem
      Caption = 'Accept connections on'
      object Anyaddress1: TMenuItem
        Caption = 'Any address'
        OnClick = Anyaddress1Click
      end
      object AnyAddressV6: TMenuItem
        Caption = 'Any IPv6 address'
        OnClick = AnyAddressV6Click
      end
    end
    object DynamicDNSupdater1: TMenuItem
      Caption = 'Dynamic DNS updater'
      object CJBtemplate1: TMenuItem
        Caption = 'CJB wizard...'
        OnClick = CJBtemplate1Click
      end
      object NoIPtemplate1: TMenuItem
        Caption = 'No-IP wizard...'
        OnClick = NoIPtemplate1Click
      end
      object DynDNStemplate1: TMenuItem
        Caption = 'DynDNS wizard...'
        OnClick = DynDNStemplate1Click
      end
      object N21: TMenuItem
        Caption = '-'
      end
      object Custom2: TMenuItem
        Caption = 'Custom...'
        OnClick = Custom2Click
      end
      object Seelastserverresponse1: TMenuItem
        Caption = 'See last server response...'
        OnClick = Seelastserverresponse1Click
      end
      object Disable1: TMenuItem
        Caption = 'Disable'
        OnClick = Disable1Click
      end
    end
    object URLencoding1: TMenuItem
      Caption = 'URL encoding'
      object encodeSpacesChk: TMenuItem
        AutoCheck = True
        Caption = 'Encode spaces'
        Checked = True
      end
      object encodenonasciiChk: TMenuItem
        AutoCheck = True
        Caption = 'Encode non-ASCII characters'
      end
      object pwdInPagesChk: TMenuItem
        AutoCheck = True
        Caption = 'Include password in pages (for download managers)'
      end
      object httpsUrlsChk: TMenuItem
        AutoCheck = True
        Caption = 'URLs starting with https instead of http'
      end
    end
    object Debug1: TMenuItem
      Caption = 'De&bug'
      object resetOptions1: TMenuItem
        Caption = 'Temporarily reset options'
        OnClick = resetOptions1Click
      end
      object dumpTrafficChk: TMenuItem
        AutoCheck = True
        Caption = 'Dump traffic'
      end
      object Showcustomizedoptions1: TMenuItem
        Caption = 'Show customized options...'
        OnClick = Showcustomizedoptions1Click
      end
      object highSpeedChk: TMenuItem
        AutoCheck = True
        Caption = 'Experimental high speed handling'
        Checked = True
      end
      object macrosLogChk: TMenuItem
        AutoCheck = True
        Caption = 'Enable macros.log'
      end
      object Runscript1: TMenuItem
        Caption = 'Run script...'
        OnClick = Runscript1Click
      end
      object showMemUsageChk: TMenuItem
        AutoCheck = True
        Caption = 'Show memory usage'
      end
      object noContentdispositionChk: TMenuItem
        AutoCheck = True
        Caption = 'No Content-disposition'
      end
    end
    object Updates1: TMenuItem
      Caption = 'Updates'
      object Checkforupdates1: TMenuItem
        Caption = 'Check for news/updates'
        OnClick = Checkforupdates1Click
      end
      object updateDailyChk: TMenuItem
        AutoCheck = True
        Caption = 'Auto check every day'
        Checked = True
      end
      object keepBakUpdatingChk: TMenuItem
        AutoCheck = True
        Caption = 'Keep old version'
        Checked = True
      end
      object testerUpdatesChk: TMenuItem
        AutoCheck = True
        Caption = 'Updates from official to beta versions'
      end
      object updateAutomaticallyChk: TMenuItem
        AutoCheck = True
        Caption = 'Update automatically'
      end
      object delayUpdateChk: TMenuItem
        AutoCheck = True
        Caption = 'Delay update to serve last requests'
      end
      object Reverttopreviousversion1: TMenuItem
        Caption = 'Revert to previous version'
        OnClick = Reverttopreviousversion1Click
      end
    end
    object Donate1: TMenuItem
      Caption = 'Donate!'
      ImageIndex = 39
      ImageName = '39'
      OnClick = Donate1Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Addfiles2: TMenuItem
      Caption = 'Add files...'
      OnClick = Addfiles1Click
    end
    object Addfolder2: TMenuItem
      Caption = 'Add folder from disk...'
      OnClick = Addfolder1Click
    end
    object Loadfilesystem1: TMenuItem
      Caption = 'Load file system...'
      ImageIndex = 8
      ImageName = '8'
      ShortCut = 16463
      OnClick = Loadfilesystem1Click
    end
    object Loadrecentfiles1: TMenuItem
      Caption = 'Load recent files'
      Visible = False
    end
    object Savefilesystem1: TMenuItem
      Caption = 'Save file system...'
      ImageIndex = 18
      ImageName = '18'
      ShortCut = 16467
      OnClick = Savefilesystem1Click
    end
    object Clearfilesystem1: TMenuItem
      Caption = 'Clear file system'
      ImageIndex = 21
      ImageName = '21'
      OnClick = Clearfilesystem1Click
    end
    object N19: TMenuItem
      Caption = '-'
    end
    object Saveoptions1: TMenuItem
      Caption = 'Save options'
      object tofile1: TMenuItem
        Caption = 'to file'
        ImageIndex = 18
        ImageName = '18'
        OnClick = tofile1Click
      end
      object toregistrycurrentuser1: TMenuItem
        Caption = 'to registry (current user)'
        ImageIndex = 20
        ImageName = '20'
        OnClick = tofile1Click
      end
      object toregistryallusers1: TMenuItem
        Caption = 'to registry (all users)'
        ImageIndex = 20
        ImageName = '20'
        OnClick = tofile1Click
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object Clearoptionsandquit1: TMenuItem
        Caption = 'Clear options and quit'
        ImageIndex = 21
        ImageName = '21'
        OnClick = Clearoptionsandquit1click
      end
      object N10: TMenuItem
        Caption = '-'
      end
      object autoSaveOptionsChk: TMenuItem
        AutoCheck = True
        Caption = 'Auto-save options'
        Checked = True
      end
    end
    object N12: TMenuItem
      Caption = '-'
    end
    object Help1: TMenuItem
      Caption = 'Help'
      Default = True
      object Introduction1: TMenuItem
        Caption = 'Introduction'
        OnClick = Introduction1Click
      end
      object Guide1: TMenuItem
        Caption = 'Full Guide'
        OnClick = Guide1Click
      end
      object FAQ1: TMenuItem
        Caption = 'F.A.Q.'
        OnClick = FAQ1Click
      end
    end
    object Weblinks1: TMenuItem
      Caption = 'Web links'
      object Officialwebsite1: TMenuItem
        Caption = 'Official website'
        ImageIndex = 23
        ImageName = '23'
        OnClick = Officialwebsite1Click
      end
      object Forum1: TMenuItem
        Caption = 'Forum'
        OnClick = Forum1Click
      end
      object License1: TMenuItem
        Caption = 'License'
        OnClick = License1Click
      end
    end
    object UninstallHFS1: TMenuItem
      Caption = 'Uninstall HFS'
      OnClick = UninstallHFS1Click
    end
    object About1: TMenuItem
      Caption = 'About...'
      ImageIndex = 10
      ImageName = '10'
      OnClick = About1Click
    end
    object N13: TMenuItem
      Caption = '-'
    end
    object SwitchON1: TMenuItem
      Caption = 'Switch ON'
      ImageIndex = 4
      ImageName = '4'
      ShortCut = 115
      OnClick = SwitchON1Click
    end
    object Restore1: TMenuItem
      Caption = 'Restore'
      OnClick = Restore1Click
    end
    object Exit1: TMenuItem
      Caption = 'Exit'
      OnClick = Exit1Click
    end
  end
  object connmenu: TPopupMenu
    Images = IconsDM.images
    OnPopup = connmenuPopup
    Left = 248
    Top = 320
    object Kickconnection1: TMenuItem
      Caption = 'Kick connection'
      OnClick = Kickconnection1Click
    end
    object KickIPaddress1: TMenuItem
      Caption = 'Kick IP address'
      OnClick = KickIPaddress1Click
    end
    object Kickallconnections1: TMenuItem
      Caption = 'Kick all connections'
      OnClick = Kickallconnections1Click
    end
    object Kickidleconnections1: TMenuItem
      Caption = 'Kick idle connections'
      OnClick = Kickidleconnections1Click
    end
    object BanIPaddress1: TMenuItem
      Caption = 'Ban IP address'
      ImageIndex = 25
      ImageName = '25'
      OnClick = BanIPaddress1Click
    end
    object Pause1: TMenuItem
      Caption = 'Pause (download-only)'
      OnClick = Pause1Click
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object Viewhttprequest1: TMenuItem
      Caption = 'View http request'
      OnClick = Viewhttprequest1Click
    end
    object trayiconforeachdownload1: TMenuItem
      Caption = 'Tray icon for each download'
      Checked = True
      OnClick = trayiconforeachdownload1Click
    end
    object AddIPasreverseproxy1: TMenuItem
      Caption = 'Add IP as reverse proxy'
      OnClick = AddIPasreverseproxy1Click
    end
  end
  object timer: TTimer
    Enabled = False
    Interval = 100
    OnTimer = timerEvent
    Left = 48
    Top = 112
  end
  object appEvents: TApplicationEvents
    OnHelp = appEventsHelp
    OnMinimize = appEventsMinimize
    OnRestore = appEventsRestore
    OnShowHint = appEventsShowHint
    Left = 592
  end
  object logmenu: TPopupMenu
    Images = IconsDM.images
    OnPopup = logmenuPopup
    Left = 352
    Top = 159
    object Logwhat1: TMenuItem
      Caption = 'Log what'
      object LogtimeChk: TMenuItem
        AutoCheck = True
        Caption = 'Time'
        Checked = True
      end
      object LogdateChk: TMenuItem
        AutoCheck = True
        Caption = 'Date'
      end
      object N9: TMenuItem
        AutoCheck = True
        Caption = '-'
      end
      object logBrowsingChk: TMenuItem
        AutoCheck = True
        Caption = 'Browsing'
        Checked = True
      end
      object LogiconsChk: TMenuItem
        AutoCheck = True
        Caption = 'Icons'
      end
      object logProgressChk: TMenuItem
        AutoCheck = True
        Caption = 'Progress'
      end
      object logBannedChk: TMenuItem
        AutoCheck = True
        Caption = 'Banned'
      end
      object logOnlyServedChk: TMenuItem
        AutoCheck = True
        Caption = 'Only served requests'
        Checked = True
      end
      object N5: TMenuItem
        Caption = '-'
      end
      object logOtherEventsChk: TMenuItem
        AutoCheck = True
        Caption = 'Other events'
        Checked = True
        Hint = 'Like dynamic dns updating...'
      end
      object N16: TMenuItem
        AutoCheck = True
        Caption = '-'
      end
      object logconnectionsChk: TMenuItem
        AutoCheck = True
        Caption = 'Connections'
      end
      object logDisconnectionsChk: TMenuItem
        AutoCheck = True
        Caption = 'Disconnections'
      end
      object logRequestsChk: TMenuItem
        AutoCheck = True
        Caption = 'Requests'
      end
      object DumprequestsChk: TMenuItem
        AutoCheck = True
        Caption = 'Requests dump'
      end
      object logRepliesChk: TMenuItem
        AutoCheck = True
        Caption = 'Replies'
      end
      object logFulldownloadsChk: TMenuItem
        AutoCheck = True
        Caption = 'Full downloads'
        Checked = True
      end
      object logUploadsChk: TMenuItem
        AutoCheck = True
        Caption = 'Uploads'
        Checked = True
      end
      object logDeletionsChk: TMenuItem
        AutoCheck = True
        Caption = 'Deletions'
        Checked = True
      end
      object logBytesreceivedChk: TMenuItem
        AutoCheck = True
        Caption = 'Bytes received'
      end
      object logBytessentChk: TMenuItem
        AutoCheck = True
        Caption = 'Bytes sent'
      end
      object logServerstartChk: TMenuItem
        AutoCheck = True
        Caption = 'Server start'
      end
      object logServerstopChk: TMenuItem
        AutoCheck = True
        Caption = 'Server stop'
      end
    end
    object logOnVideoChk: TMenuItem
      AutoCheck = True
      Caption = 'Log to screen'
      Checked = True
    end
    object Logfile1: TMenuItem
      Caption = 'Log to file...'
      OnClick = Logfile1Click
    end
    object Maxlinesonscreen1: TMenuItem
      Caption = 'Max lines on screen...'
      OnClick = Maxlinesonscreen1Click
    end
    object Apachelogfileformat1: TMenuItem
      Caption = 'Apache log file format...'
      OnClick = Apachelogfileformat1Click
    end
    object Donotlogaddress1: TMenuItem
      Caption = 'Do not log address...'
      OnClick = Donotlogaddress1Click
    end
    object Dontlogsomefiles1: TMenuItem
      Caption = 'Do not log some files...'
      OnClick = Dontlogsomefiles1Click
    end
    object Address2name1: TMenuItem
      Caption = 'Assign name to address...'
      OnClick = Address2name1Click
    end
    object Font1: TMenuItem
      Caption = 'Font...'
      OnClick = Font1Click
    end
    object tabOnLogFileChk: TMenuItem
      AutoCheck = True
      Caption = 'Tabbed instead of multi-line for the log file'
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object Readonly1: TMenuItem
      Caption = 'Read-only'
      OnClick = Readonly1Click
    end
    object Banthisaddress1: TMenuItem
      Caption = 'Ban this address'
      ImageIndex = 11
      ImageName = '11'
      OnClick = Banthisaddress1Click
    end
    object Copy1: TMenuItem
      Caption = 'Copy'
      ImageIndex = 16
      ImageName = '16'
      OnClick = Copy1Click
    end
    object Clear1: TMenuItem
      Caption = 'Clear'
      ImageIndex = 21
      ImageName = '21'
      OnClick = Clear1Click
    end
    object Clearandresettotals1: TMenuItem
      Caption = 'Clear and reset totals'
      OnClick = Clearandresettotals1Click
    end
    object Save1: TMenuItem
      Caption = 'Save'
      ImageIndex = 18
      ImageName = '18'
      OnClick = Save1Click
    end
    object Saveas1: TMenuItem
      Caption = 'Save as...'
      ImageIndex = 18
      ImageName = '18'
      OnClick = Saveas1Click
    end
    object N24: TMenuItem
      Caption = '-'
    end
    object Addresseseverconnected1: TMenuItem
      Caption = 'Addresses ever connected...'
      OnClick = Addresseseverconnected1Click
    end
  end
  object graphMenu: TPopupMenu
    Left = 504
    Top = 48
    object Reset1: TMenuItem
      Caption = 'Reset'
      OnClick = Reset1Click
    end
    object Hide: TMenuItem
      Caption = 'Hide'
      OnClick = HideClick
    end
  end
end
