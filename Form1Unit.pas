unit Form1Unit;

// =============================================================================
// Form1.pas  —  PascalABC-WPF-Designer Ver 2.2.2  메인 폼
//
// 외부 유닛 의존성:
//   Models/   ProjectOptions, ControlInfo
//   Events/   WpfEventMap
//   Editor/   PascalHighlighting, PascalFolding
//   CodeGen/  XamlParser, XamlPreprocessor, PascalCodeGenerator
//   Docking/  DockContents
// =============================================================================

{$reference ICSharpCode.WpfDesign.dll}
{$reference ICSharpCode.WpfDesign.Designer.dll}
{$reference ICSharpCode.WpfDesign.XamlDom.dll}
{$reference AvalonEdit.6.3.1.120\lib\net462\ICSharpCode.AvalonEdit.dll}
{$reference dockpanelsuite.3.1.0\lib\net40\WeifenLuo.WinFormsUI.Docking.dll}
{$reference dockpanelsuite.themevs2015.3.1.1\lib\net40\WeifenLuo.WinFormsUI.Docking.ThemeVS2015.dll}
{$reference PresentationFramework.dll}
{$reference PresentationCore.dll}
{$reference WindowsBase.dll}
{$reference System.Windows.Forms.dll}
{$reference WindowsFormsIntegration.dll}

uses
  System.Windows.Forms,
  System.Collections.Generic,
  ICSharpCode.WpfDesign,
  WeifenLuo.WinFormsUI.Docking,
  // ── 분리된 유닛 ──────────────────────────────────────────────────────────
  ProjectOptions,        // TProjectOptions, TProjectType
  ControlInfo,           // TControlInfo
  WpfEventMap,           // WPF_EVENTS, GetEventParamType, IsWpfEvent
  PascalHighlighting,    // CreatePascalHighlighting
  PascalFolding,         // TPascalFoldingStrategy
  XamlParser,            // ParseXClassInfo, ParseControlsFromXaml, StripEventAttributesForRuntime
  XamlPreprocessor,      // PreprocessXaml, StripCustomNamespaces, PrepareXamlForBuild
  PascalCodeGenerator,   // TPascalCodeGenerator
  VersionResourcePatcher,// TVersionResourcePatcher — 빌드 후 EXE/DLL 에 VERSIONINFO 패치
  DockContents;          // TToolboxDock, TSolutionExplorerDock, TPropertyGridDock,
                          // TOutputDock, TErrorListDock, TMainDocumentDock

// =============================================================================
// Form1
// =============================================================================
type
  Form1 = class(System.Windows.Forms.Form)
  private
    fSurface  : ICSharpCode.WpfDesign.Designer.DesignSurface;
    fPropView : ICSharpCode.WpfDesign.Designer.PropertyGrid.PropertyGridView;
    fXamlEditor : ICSharpCode.AvalonEdit.TextEditor;
    fCodeEditor : ICSharpCode.AvalonEdit.TextEditor;
    fOriginalXaml : string;
    fLoadingXaml  : boolean;

    // 프로젝트
    fProjectPath  : string;
    fXamlFileName : string;
    fPasFileName  : string;
    fProjectType  : TProjectType;
    fClassName    : string;
    fNamespace    : string;

    fOptions   : TProjectOptions;
    fCodeGen   : TPascalCodeGenerator;   // ★ 코드 생성기

    fRunningProcess : System.Diagnostics.Process;

    fBuildProcess     : System.Diagnostics.Process;
    fBuildStopwatch   : System.Diagnostics.Stopwatch;
    fBuildExePath     : string;
    fBuildHadStartErr : boolean;
    fBuildStartErrMsg : string;
    fRunAfterBuild    : boolean;

    menuStrip     : System.Windows.Forms.MenuStrip;

    hostDesign    : System.Windows.Forms.Integration.ElementHost;
    hostLeft      : System.Windows.Forms.Integration.ElementHost;
    hostRight     : System.Windows.Forms.Integration.ElementHost;
    hostXaml      : System.Windows.Forms.Integration.ElementHost;
    hostCode      : System.Windows.Forms.Integration.ElementHost;
    fToolboxPanel : System.Windows.Controls.StackPanel;

    tabControl      : System.Windows.Forms.TabControl;
    tabDesignXaml   : System.Windows.Forms.TabPage;
    tabCode         : System.Windows.Forms.TabPage;

    splitDesignXaml : System.Windows.Forms.SplitContainer;

    // ── DockPanelSuite ──────────────────────────────────────────────────────
    dockPanel        : WeifenLuo.WinFormsUI.Docking.DockPanel;
    dockToolbox      : TToolboxDock;
    dockExplorer     : TSolutionExplorerDock;
    dockProperties   : TPropertyGridDock;
    dockOutput       : TOutputDock;
    dockErrors       : TErrorListDock;
    dockMain         : TMainDocumentDock;

    lvErrors     : System.Windows.Forms.ListView;
    txtOutput    : System.Windows.Forms.RichTextBox;

    trvSolution : System.Windows.Forms.TreeView;

    menuItemLineNum          : System.Windows.Forms.ToolStripMenuItem;
    menuItemHighlight        : System.Windows.Forms.ToolStripMenuItem;
    menuItemWordWrap         : System.Windows.Forms.ToolStripMenuItem;
    menuItemFolding          : System.Windows.Forms.ToolStripMenuItem;
    menuItemResetLayout      : System.Windows.Forms.ToolStripMenuItem;

    // XAML 폴딩
    fFoldingManager  : ICSharpCode.AvalonEdit.Folding.FoldingManager;
    fFoldingStrategy : ICSharpCode.AvalonEdit.Folding.XmlFoldingStrategy;
    fFoldingTimer    : System.Windows.Threading.DispatcherTimer;

    // 코드 에디터 폴딩
    fCodeFoldingManager  : ICSharpCode.AvalonEdit.Folding.FoldingManager;
    fCodeFoldingStrategy : TPascalFoldingStrategy;
    fCodeFoldingTimer    : System.Windows.Threading.DispatcherTimer;

    // 프로젝트 옵션 다이얼로그용 필드
    fDlgTxtFolder    : System.Windows.Forms.TextBox;
    fTxtCompilerPath : System.Windows.Forms.TextBox;
    fNavList         : System.Windows.Forms.ListBox;
    fPanels          : array[0..6] of System.Windows.Forms.Panel;
    fContentPanel    := new System.Windows.Forms.Panel();
    fTxtProjName, fTxtRootNs, fTxtClassName : System.Windows.Forms.TextBox;
    // 옵션 다이얼로그 컴파일러 경로 줄 (OnRowCompResize 에서 참조)
    fDlgRowComp      : System.Windows.Forms.Panel;
    fDlgBtnBrowseComp: System.Windows.Forms.Button;
    fDlgTxtCompPath  : System.Windows.Forms.TextBox;
    // 옵션 다이얼로그 버튼 바 (OnBtnBarLayoutEvent / LayoutDlgBtnBar 에서 참조)
    fDlgBtnBar       : System.Windows.Forms.Panel;
    fDlgBtnOk        : System.Windows.Forms.Button;
    fDlgBtnCancel    : System.Windows.Forms.Button;
    fDlgBtnApply     : System.Windows.Forms.Button;

    // ── 내부 UI 빌더 ────────────────────────────────────────────────────────
    procedure BuildMenu;
    procedure BuildToolbox;
    procedure BuildLayout;
    procedure BuildDockLayout;
    procedure ConnectEvents;

    // ── 툴박스 / 디자이너 이벤트 ────────────────────────────────────────────
    procedure OnToolboxClick(sender: System.Object; e: System.Windows.RoutedEventArgs);
    procedure OnDesignerDoubleClick(sender: System.Object; e: System.Windows.Input.MouseButtonEventArgs);
    procedure OnSelectionChanged(sender: System.Object; e: ICSharpCode.WpfDesign.DesignItemCollectionEventArgs);
    procedure OnUndoStackChanged(sender: System.Object; e: System.EventArgs);

    // ── 탭 / 폼 이벤트 ──────────────────────────────────────────────────────
    procedure OnTabChanged(sender: System.Object; e: System.EventArgs);
    procedure FormKeyDown(sender: System.Object; ke: System.Windows.Forms.KeyEventArgs);
    procedure OnFormClosing(sender: System.Object; e: System.Windows.Forms.FormClosingEventArgs);

    // ── 파일 메뉴 ───────────────────────────────────────────────────────────
    procedure OnNewProject(sender: System.Object; e: System.EventArgs);
    procedure OnSave(sender: System.Object; e: System.EventArgs);
    procedure OnOpen(sender: System.Object; e: System.EventArgs);

    // ── XAML 관련 메뉴 ──────────────────────────────────────────────────────
    procedure OnApplyXaml(sender: System.Object; e: System.Windows.RoutedEventArgs);
    procedure OnApplyXamlMenu(sender: System.Object; e: System.EventArgs);
    procedure OnSyncXamlMenu(sender: System.Object; e: System.EventArgs);

    // ── 보기 메뉴 토글 ──────────────────────────────────────────────────────
    procedure OnToggleLineNumbers(sender: System.Object; e: System.EventArgs);
    procedure OnToggleHighlight(sender: System.Object; e: System.EventArgs);
    procedure OnToggleWordWrap(sender: System.Object; e: System.EventArgs);
    procedure OnToggleFolding(sender: System.Object; e: System.EventArgs);
    procedure OnResetLayout(sender: System.Object; e: System.EventArgs);

    // ── 빌드 / 실행 ─────────────────────────────────────────────────────────
    procedure OnBuild(sender: System.Object; e: System.EventArgs);
    procedure OnRun(sender: System.Object; e: System.EventArgs);
    function  FindPabcCompiler: string;
    procedure StartBuildProcess;
    procedure OnBuildOutputLine(sender: System.Object; e: System.Diagnostics.DataReceivedEventArgs);
    procedure OnBuildErrorLine(sender: System.Object; e: System.Diagnostics.DataReceivedEventArgs);
    procedure OnBuildProcessExited(sender: System.Object; e: System.EventArgs);
    procedure FinishBuild;
    procedure LaunchBuiltExe;
    procedure LaunchControlTestHost;
    procedure OnRunProcessExited(sender: System.Object; e: System.EventArgs);
    procedure KillPreviousBuildProcesses;

    // ── 출력 패널 ───────────────────────────────────────────────────────────
    procedure AppendOutput(text: string; isError: boolean);
    procedure ClearOutput;
    procedure OnOutputCopy(sender: System.Object; e: System.EventArgs);
    procedure OnOutputClear(sender: System.Object; e: System.EventArgs);

    // ── 오류 목록 ───────────────────────────────────────────────────────────
    procedure OnErrorsCopy(sender: System.Object; e: System.EventArgs);
    procedure OnErrorsKeyDown(sender: System.Object; e: System.Windows.Forms.KeyEventArgs);
    procedure ShowBuildErrors(output: string);

    // ── XAML 폴딩 ───────────────────────────────────────────────────────────
    procedure UpdateFolding;
    procedure OnFoldingTimerTick(sender: System.Object; e: System.EventArgs);
    procedure EnableFolding;
    procedure DisableFolding;
    procedure OnXamlTextChanged(sender: System.Object; e: System.EventArgs);

    // ── 코드 에디터 폴딩 ────────────────────────────────────────────────────
    procedure UpdateCodeFolding;
    procedure OnCodeFoldingTimerTick(sender: System.Object; e: System.EventArgs);
    procedure EnableCodeFolding;
    procedure DisableCodeFolding;
    procedure OnCodeTextChanged(sender: System.Object; e: System.EventArgs);

    // ── 코드 에디터 구문 강조 ───────────────────────────────────────────────
    procedure ApplyCodeHighlighting;

    // ── XAML 로드 / 동기화 ─────────────────────────────────────────────────
    procedure LoadXaml(xaml: string);
    procedure LoadDesigner(designXaml: string);
    procedure SyncXamlEditor;
    function  SaveDesignerToString: string;

    // ── 이벤트 핸들러 삽입 ──────────────────────────────────────────────────
    procedure AddEventHandlerToXaml(controlName, eventName, handlerName: string);
    // ★ 변경: procedure → function. 반환값은 코드 에디터에서 커서를 위치시킬 CaretOffset.
    function  AddEventHandlerToCode(handlerName, eventType: string): integer;
    // ★ 추가: Dispatcher.BeginInvoke로 호출할 캐럿 이동 헬퍼 (메서드 참조 방식 — 람다 호환성 문제 회피)
    procedure JumpCodeEditorCaretTo(offset: integer);

    // ── 새 프로젝트 다이얼로그 / 생성 ──────────────────────────────────────
    function  ShowNewProjectDialog(var projType: TProjectType;
                var projName: string; var projFolder: string): boolean;
    procedure CreateNewProject(projType: TProjectType;
                projName: string; projFolder: string);
    procedure OnBrowseClick(sender: System.Object; e: System.EventArgs);
    procedure OnBrowseCompClick(sender: System.Object; e: System.EventArgs);

    // ── 프로젝트 옵션 ───────────────────────────────────────────────────────
    procedure OnProjectOptions(sender: System.Object; e: System.EventArgs);
    procedure ShowProjectOptionsDialog;
    procedure ApplyOptionsToEditors;

    // ── 옵션 다이얼로그 콜백 ────────────────────────────────────────────────
    procedure OnNavListSelectedIndexChanged(sender: System.Object; e: System.EventArgs);
    procedure OnApplyClick(sender: System.Object; e: System.EventArgs);

    // ── 솔루션 탐색기 ───────────────────────────────────────────────────────
    procedure RefreshSolutionExplorer;
    procedure OnSolutionExplorerDoubleClick(sender: System.Object;
                e: System.Windows.Forms.TreeNodeMouseClickEventArgs);
    procedure OnSolutionExplorerRefresh(sender: System.Object; e: System.EventArgs);
    procedure OnSolutionExplorerShowInFolder(sender: System.Object; e: System.EventArgs);

    // ── 옵션 다이얼로그 내부 레이아웃 핸들러 ───────────────────────────────
    procedure OnRowCompResize(sender: System.Object; e: System.EventArgs);
    procedure LayoutDlgBtnBar;
    procedure OnBtnBarLayoutEvent(sender: System.Object; e: System.EventArgs);

    // ── 도움말 ──────────────────────────────────────────────────────────────
    procedure OnAbout(sender: System.Object; e: System.EventArgs);

    // ── 코드 생성 헬퍼 ──────────────────────────────────────────────────────
    procedure RebuildCodeGen;
    function  GenerateCode: string;

  public
    constructor Create;
  end;

// =============================================================================
// 헬퍼: 코드 생성기 재생성 및 코드 생성
// =============================================================================
procedure Form1.RebuildCodeGen;
begin
  fCodeGen := new TPascalCodeGenerator(fOptions, fXamlFileName, fPasFileName);
end;

function Form1.GenerateCode: string;
var
  ns, cls: string;
  newXaml: string;
begin
  RebuildCodeGen();
  case fProjectType of
    ptWpfApp:
    begin
      Result := fCodeGen.GenerateWpfAppCode(fXamlEditor.Text, ns, cls);
      // 클래스명이 바뀌었으면 XAML의 x:Class도 동기화
      if cls <> fClassName then
      begin
        var oldXClass := ns + '.' + fClassName;
        var newXClass := ns + '.' + cls;
        if fXamlEditor.Text.Contains('x:Class="' + oldXClass + '"') then
        begin
          fLoadingXaml := true;
          try
            fXamlEditor.Text := fXamlEditor.Text.Replace(
              'x:Class="' + oldXClass + '"',
              'x:Class="' + newXClass + '"');
          finally
            fLoadingXaml := false;
          end;
        end;
      end;
    end;
    ptWpfControlLibrary:
      Result := fCodeGen.GenerateControlLibCode(fXamlEditor.Text, ns, cls);
  else
    Result := '';
  end;
  fNamespace := ns;
  fClassName := cls;
end;

// =============================================================================
// constructor
// =============================================================================
constructor Form1.Create;
begin
  inherited Create;
  Self.Text   := 'PascalABC-WPF-Designer Ver 2.2.2';
  Self.Width  := 1600;
  Self.Height := 950;

  ICSharpCode.WpfDesign.Designer.BasicMetadata.Register();

  fOptions := new TProjectOptions();

  fProjectPath  := System.IO.Path.GetTempPath() + 'PascalWpfProject\';
  fXamlFileName := 'MainWindow.xaml';
  fPasFileName  := 'MainWindow.pas';
  fProjectType  := ptWpfApp;
  fClassName    := 'MainWindow';
  fNamespace    := 'MyApp';

  if not System.IO.Directory.Exists(fProjectPath) then
    System.IO.Directory.CreateDirectory(fProjectPath);

  BuildToolbox;
  BuildLayout;
  BuildMenu;

  Self.FormClosing += OnFormClosing;

  var defaultXaml :=
    '<Window x:Class="MyApp.MainWindow"' + #13#10 +
    '        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' + #13#10 +
    '        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"' + #13#10 +
    '        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"' + #13#10 +
    '        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"' + #13#10 +
    '        mc:Ignorable="d"' + #13#10 +
    '        Title="MainWindow" Height="450" Width="800">' + #13#10 +
    '    <Grid>' + #13#10 +
    '        <Button x:Name="btnHello" Content="Hello, WPF!" ' +
    'HorizontalAlignment="Left" VerticalAlignment="Top" ' +
    'Margin="20,20,0,0" Width="120" Height="32"' +
    ' Click="btnHello_Click"/>' + #13#10 +
    '    </Grid>' + #13#10 +
    '</Window>';

  LoadXaml(defaultXaml);
  fCodeEditor.Text := GenerateCode();

  ApplyCodeHighlighting();
  if fOptions.CodeFolding then EnableCodeFolding();

  RefreshSolutionExplorer();
end;

// =============================================================================
// ApplyCodeHighlighting
// =============================================================================
procedure Form1.ApplyCodeHighlighting;
begin
  if fCodeEditor = nil then exit;
  if fOptions.CodeHighlight then
  begin
    var hlDef := CreatePascalHighlighting();
    if hlDef <> nil then
      fCodeEditor.SyntaxHighlighting := hlDef
    else
      fCodeEditor.SyntaxHighlighting :=
        ICSharpCode.AvalonEdit.Highlighting.HighlightingManager.Instance.GetDefinition('C#');
  end
  else
    fCodeEditor.SyntaxHighlighting := nil;
end;

// =============================================================================
// 코드 에디터 폴딩
// =============================================================================
procedure Form1.UpdateCodeFolding;
begin
  if (fCodeFoldingManager = nil) or (fCodeFoldingStrategy = nil) then exit;
  try fCodeFoldingStrategy.UpdateFoldings(fCodeFoldingManager, fCodeEditor.Document);
  except end;
end;

procedure Form1.OnCodeFoldingTimerTick(sender: System.Object; e: System.EventArgs);
begin
  fCodeFoldingTimer.Stop();
  UpdateCodeFolding();
end;

procedure Form1.EnableCodeFolding;
begin
  if fCodeFoldingManager = nil then
  begin
    fCodeFoldingManager  := ICSharpCode.AvalonEdit.Folding.FoldingManager.Install(fCodeEditor.TextArea);
    fCodeFoldingStrategy := new TPascalFoldingStrategy();
  end;
  UpdateCodeFolding();
  fCodeFoldingTimer.Start();
end;

procedure Form1.DisableCodeFolding;
begin
  fCodeFoldingTimer.Stop();
  if fCodeFoldingManager <> nil then
  begin
    ICSharpCode.AvalonEdit.Folding.FoldingManager.Uninstall(fCodeFoldingManager);
    fCodeFoldingManager  := nil;
    fCodeFoldingStrategy := nil;
  end;
end;

procedure Form1.OnCodeTextChanged(sender: System.Object; e: System.EventArgs);
begin
  if (fCodeFoldingManager <> nil) and fOptions.CodeFolding then
  begin
    fCodeFoldingTimer.Stop();
    fCodeFoldingTimer.Start();
  end;
end;

// =============================================================================
// ApplyOptionsToEditors
// =============================================================================
procedure Form1.ApplyOptionsToEditors;
var
  fontFamily : System.Windows.Media.FontFamily;
begin
  if fXamlEditor = nil then exit;
  fontFamily := new System.Windows.Media.FontFamily(fOptions.FontName);

  // XAML 에디터
  fXamlEditor.FontFamily      := fontFamily;
  fXamlEditor.FontSize        := fOptions.FontSize;
  fXamlEditor.ShowLineNumbers := fOptions.XamlShowLineNum;
  fXamlEditor.WordWrap        := fOptions.WordWrap;
  if fOptions.XamlHighlight then
    fXamlEditor.SyntaxHighlighting :=
      ICSharpCode.AvalonEdit.Highlighting.HighlightingManager.Instance.GetDefinition('XML')
  else
    fXamlEditor.SyntaxHighlighting := nil;
  fXamlEditor.Options.ShowSpaces          := fOptions.ShowWhitespace;
  fXamlEditor.Options.ShowTabs            := fOptions.ShowWhitespace;
  fXamlEditor.Options.IndentationSize     := fOptions.TabSize;
  fXamlEditor.Options.ConvertTabsToSpaces := not fOptions.UseTabs;

  if fOptions.XamlFolding then EnableFolding() else DisableFolding();

  // 메뉴 상태 동기화
  if menuItemLineNum   <> nil then menuItemLineNum.Checked   := fOptions.XamlShowLineNum;
  if menuItemHighlight <> nil then menuItemHighlight.Checked := fOptions.XamlHighlight;
  if menuItemWordWrap  <> nil then menuItemWordWrap.Checked  := fOptions.WordWrap;
  if menuItemFolding   <> nil then menuItemFolding.Checked   := fOptions.XamlFolding;

  // 코드 에디터
  if fCodeEditor = nil then exit;
  fCodeEditor.FontFamily      := fontFamily;
  fCodeEditor.FontSize        := fOptions.FontSize;
  fCodeEditor.ShowLineNumbers := fOptions.CodeShowLineNum;
  fCodeEditor.WordWrap        := fOptions.WordWrap;
  fCodeEditor.Options.ShowSpaces          := fOptions.ShowWhitespace;
  fCodeEditor.Options.ShowTabs            := fOptions.ShowWhitespace;
  fCodeEditor.Options.IndentationSize     := fOptions.TabSize;
  fCodeEditor.Options.ConvertTabsToSpaces := not fOptions.UseTabs;

  ApplyCodeHighlighting();
  if fOptions.CodeFolding then EnableCodeFolding() else DisableCodeFolding();
end;

// =============================================================================
// 프로젝트 옵션 다이얼로그 (ShowProjectOptionsDialog)
// =============================================================================
procedure Form1.ShowProjectOptionsDialog;

  function MakeSeparator: System.Windows.Forms.Panel;
  begin
    Result           := new System.Windows.Forms.Panel();
    Result.Height    := 1;
    Result.Dock      := System.Windows.Forms.DockStyle.Top;
    Result.BackColor := System.Drawing.Color.FromArgb(220, 220, 220);
  end;

  function MakeSectionLabel(text: string): System.Windows.Forms.Label;
  begin
    Result           := new System.Windows.Forms.Label();
    Result.Text      := text;
    Result.Font      := new System.Drawing.Font('Segoe UI', 10, System.Drawing.FontStyle.Bold);
    Result.Height    := 26;
    Result.ForeColor := System.Drawing.Color.FromArgb(60, 60, 140);
  end;

  function MakeLabel(text: string): System.Windows.Forms.Label;
  begin
    Result           := new System.Windows.Forms.Label();
    Result.Text      := text;
    Result.Width     := 170;
    Result.Height    := 22;
    Result.TextAlign := System.Drawing.ContentAlignment.MiddleLeft;
    Result.Font      := new System.Drawing.Font('Segoe UI', 9);
  end;

  function MakeHint(text: string): System.Windows.Forms.Label;
  begin
    Result           := new System.Windows.Forms.Label();
    Result.Text      := text;
    Result.Font      := new System.Drawing.Font('Segoe UI', 8);
    Result.ForeColor := System.Drawing.Color.Gray;
    Result.Height    := 18;
  end;

  function MakeTextBox(val: string; w: integer): System.Windows.Forms.TextBox;
  begin
    Result        := new System.Windows.Forms.TextBox();
    Result.Text   := val;
    Result.Width  := w;
    Result.Height := 23;
    Result.Font   := new System.Drawing.Font('Segoe UI', 9);
  end;

  function MakeCheck(text: string; chk: boolean): System.Windows.Forms.CheckBox;
  begin
    Result          := new System.Windows.Forms.CheckBox();
    Result.Text     := text;
    Result.Checked  := chk;
    Result.AutoSize := true;
    Result.Font     := new System.Drawing.Font('Segoe UI', 9);
  end;

  function MakeCombo(items: array of string; sel: string; w: integer): System.Windows.Forms.ComboBox;
  var
    item: string;
  begin
    Result               := new System.Windows.Forms.ComboBox();
    Result.DropDownStyle := System.Windows.Forms.ComboBoxStyle.DropDownList;
    Result.Width         := w;
    Result.Font          := new System.Drawing.Font('Segoe UI', 9);
    foreach item in items do
    begin
      Result.Items.Add(item);
      if item = sel then Result.SelectedIndex := Result.Items.Count - 1;
    end;
    if Result.SelectedIndex < 0 then Result.SelectedIndex := 0;
  end;

  function MakeSpinner(val, mn, mx, w: integer): System.Windows.Forms.NumericUpDown;
  begin
    Result         := new System.Windows.Forms.NumericUpDown();
    Result.Minimum := mn;
    Result.Maximum := mx;
    Result.Value   := val;
    Result.Width   := w;
    Result.Font    := new System.Drawing.Font('Segoe UI', 9);
  end;

  function MakeRow(lbl: System.Windows.Forms.Label;
                   ctl: System.Windows.Forms.Control): System.Windows.Forms.Panel;
  begin
    Result        := new System.Windows.Forms.Panel();
    Result.Height := 28;
    Result.Dock   := System.Windows.Forms.DockStyle.Top;
    lbl.Top := 3; lbl.Left := 0;
    lbl.Anchor := System.Windows.Forms.AnchorStyles.Left or
                  System.Windows.Forms.AnchorStyles.Top;
    ctl.Top := 3; ctl.Left := 175;
    // ComboBox/NumericUpDown 은 너비를 늘리면 보기 이상해지는 경우가 있어
    // TextBox 계열만 패널 폭에 맞춰 오른쪽까지 자동으로 늘어나도록 한다.
    if (ctl is System.Windows.Forms.TextBox) then
      ctl.Anchor := System.Windows.Forms.AnchorStyles.Left or
                    System.Windows.Forms.AnchorStyles.Top or
                    System.Windows.Forms.AnchorStyles.Right
    else
      ctl.Anchor := System.Windows.Forms.AnchorStyles.Left or
                    System.Windows.Forms.AnchorStyles.Top;
    Result.Controls.Add(lbl);
    Result.Controls.Add(ctl);
    Result.MinimumSize := new System.Drawing.Size(0, Result.Height);
  end;

  function MakeCkPanel(cb: System.Windows.Forms.CheckBox): System.Windows.Forms.Panel;
  begin
    Result        := new System.Windows.Forms.Panel();
    Result.Height := 26;
    Result.Dock   := System.Windows.Forms.DockStyle.Top;
    cb.Top  := 3;
    cb.Left := 175;
    cb.Anchor := System.Windows.Forms.AnchorStyles.Left or
                System.Windows.Forms.AnchorStyles.Top;
    Result.Controls.Add(cb);
  end;

var
  dlg          : System.Windows.Forms.Form;
  splitDlg     : System.Windows.Forms.SplitContainer;
  contentPanel : System.Windows.Forms.Panel;
  panels       : array[0..6] of System.Windows.Forms.Panel;

  i            : integer;

  // 각 페이지 컨트롤 참조
  txtProjName, txtRootNs, txtClassName, txtProjPath : System.Windows.Forms.TextBox;
  cboProjType                                        : System.Windows.Forms.ComboBox;
  txtAdditArgs                                       : System.Windows.Forms.TextBox;
  chkNoConsole, chkDebug, chkWarnErr, chkAutoClean   : System.Windows.Forms.CheckBox;
  txtOutFile, txtOutDir, txtAsmVer                    : System.Windows.Forms.TextBox;
  txtAsmTitle, txtAsmCompany, txtAsmCopy              : System.Windows.Forms.TextBox;
  chkCopyXaml, chkEmbedAsm                           : System.Windows.Forms.CheckBox;
  chkOptimize, chkInline                              : System.Windows.Forms.CheckBox;
  cboTarget                                           : System.Windows.Forms.ComboBox;
  spnIndent, spnTabSize, spnFontSize                  : System.Windows.Forms.NumericUpDown;
  cboBrace, cboCommentStyle                           : System.Windows.Forms.ComboBox;
  chkUseTabs, chkAutoBegin, chkAutoEnd, chkGenComments: System.Windows.Forms.CheckBox;
  txtFont                                             : System.Windows.Forms.TextBox;
  chkXamlLineNum, chkCodeLineNum                      : System.Windows.Forms.CheckBox;
  chkXamlHL, chkCodeHL                                : System.Windows.Forms.CheckBox;
  chkWordWrap, chkXamlFold, chkCodeFold               : System.Windows.Forms.CheckBox;
  chkShowWS, chkHlLine, chkAutoComp                   : System.Windows.Forms.CheckBox;
  cboStartAct                                         : System.Windows.Forms.ComboBox;
  txtExtProg, txtStartArgs                            : System.Windows.Forms.TextBox;
  chkUseEnv, chkRunBefore                             : System.Windows.Forms.CheckBox;

  // ── 페이지 빌더 ─────────────────────────────────────────────────────────────

  procedure BuildPageInfo(p: System.Windows.Forms.Panel);
  begin
    p.Controls.Add(MakeSectionLabel('프로젝트 정보'));
    txtProjName := MakeTextBox(fOptions.ProjectName, 280);
    cboProjType := MakeCombo(
      ['WPF 애플리케이션 (.exe)', 'WPF 컨트롤 라이브러리 (.dll)'],
      (if fOptions.ProjectType = ptWpfApp then 'WPF 애플리케이션 (.exe)'
       else 'WPF 컨트롤 라이브러리 (.dll)'), 280);
    txtRootNs   := MakeTextBox(fOptions.RootNamespace, 280);
    txtClassName := MakeTextBox(fOptions.ClassName, 280);
    txtProjPath  := MakeTextBox(fProjectPath, 380);

    fTxtProjName := txtProjName;
    fTxtRootNs   := txtRootNs;
    fTxtClassName := txtClassName;

    p.Controls.Add(MakeRow(MakeLabel('프로젝트 경로'), txtProjPath));
    p.Controls.Add(MakeRow(MakeLabel('클래스 이름'), txtClassName));
    p.Controls.Add(MakeRow(MakeLabel('루트 네임스페이스'), txtRootNs));
    p.Controls.Add(MakeRow(MakeLabel('프로젝트 형식'), cboProjType));
    p.Controls.Add(MakeRow(MakeLabel('프로젝트 이름'), txtProjName));
    p.Controls.Add(MakeHint('프로젝트의 기본 정보를 설정합니다.'));
  end;

  procedure BuildPageCompiler(p: System.Windows.Forms.Panel);
  var
    cks           : array[0..3] of System.Windows.Forms.CheckBox;
    ci            : integer;
  begin
    p.Controls.Add(MakeSectionLabel('컴파일러 설정'));

    fDlgTxtCompPath  := MakeTextBox(
      (if fOptions.CompilerPath <> '' then fOptions.CompilerPath else FindPabcCompiler()), 290);
    fTxtCompilerPath := fDlgTxtCompPath;

    fDlgBtnBrowseComp        := new System.Windows.Forms.Button();
    fDlgBtnBrowseComp.Text   := '...';
    fDlgBtnBrowseComp.Width  := 28;
    fDlgBtnBrowseComp.Height := 23;
    fDlgBtnBrowseComp.Top    := 3;
    fDlgBtnBrowseComp.Font   := new System.Drawing.Font('Segoe UI', 9);
    fDlgBtnBrowseComp.Click  += OnBrowseCompClick;
    fDlgBtnBrowseComp.Anchor := System.Windows.Forms.AnchorStyles.Top or
                            System.Windows.Forms.AnchorStyles.Right;

    fDlgRowComp        := new System.Windows.Forms.Panel();
    fDlgRowComp.Height := 28;
    fDlgRowComp.Dock   := System.Windows.Forms.DockStyle.Top;
    var lbl        := MakeLabel('컴파일러 경로');
    lbl.Top        := 3; lbl.Left := 0;
    lbl.Anchor     := System.Windows.Forms.AnchorStyles.Left or
                      System.Windows.Forms.AnchorStyles.Top;
    fDlgTxtCompPath.Top    := 3; fDlgTxtCompPath.Left := 175;
    fDlgTxtCompPath.Anchor := System.Windows.Forms.AnchorStyles.Left or
                              System.Windows.Forms.AnchorStyles.Top;
    fDlgRowComp.Controls.Add(lbl);
    fDlgRowComp.Controls.Add(fDlgTxtCompPath);
    fDlgRowComp.Controls.Add(fDlgBtnBrowseComp);

    // 패널이 리사이즈될 때 텍스트박스가 찾아보기(...) 버튼 바로 앞까지 늘어나도록 처리
    fDlgRowComp.Resize += OnRowCompResize;
    fDlgBtnBrowseComp.Left := fDlgRowComp.Width - fDlgBtnBrowseComp.Width - 4;
    fDlgTxtCompPath.Width := fDlgBtnBrowseComp.Left - fDlgTxtCompPath.Left - 6;

    txtAdditArgs := MakeTextBox(fOptions.AdditionalArgs, 320);
    chkNoConsole := MakeCheck('콘솔 창 숨기기 (/noconsole)', fOptions.NoConsole);
    chkDebug     := MakeCheck('디버그 심볼 포함 (/debug)',    fOptions.DebugInfo);
    chkWarnErr   := MakeCheck('경고를 오류로 처리 (/werr)',   fOptions.WarningsAsErrors);
    chkAutoClean := MakeCheck('빌드 전 .pcu 캐시 자동 삭제',  fOptions.AutoClean);

    cks[0] := chkNoConsole; cks[1] := chkDebug;
    cks[2] := chkWarnErr;   cks[3] := chkAutoClean;
    var ckPanels: array[0..3] of System.Windows.Forms.Panel;
    ci := 0;
    while ci <= 3 do
    begin
      ckPanels[ci] := MakeCkPanel(cks[ci]);
      ci += 1;
    end;

    p.Controls.Add(ckPanels[3]);
    p.Controls.Add(ckPanels[2]);
    p.Controls.Add(ckPanels[1]);
    p.Controls.Add(ckPanels[0]);
    p.Controls.Add(MakeRow(MakeLabel('추가 컴파일 인수'), txtAdditArgs));
    p.Controls.Add(fDlgRowComp);
    p.Controls.Add(MakeHint('PascalABC.NET 컴파일러(pabcnetc.exe) 경로와 빌드 옵션을 설정합니다.'));
  end;

  procedure BuildPageOutput(p: System.Windows.Forms.Panel);
  begin
    p.Controls.Add(MakeSectionLabel('출력 설정'));
    txtOutFile    := MakeTextBox(fOptions.OutputFileName,    280);
    txtOutDir     := MakeTextBox(fOptions.OutputDirectory,   280);
    chkCopyXaml  := MakeCheck('XAML 파일을 출력 디렉터리에 복사', fOptions.CopyXamlToOutput);
    chkEmbedAsm  := MakeCheck('어셈블리 정보 포함',               fOptions.EmbedAssemblyInfo);
    txtAsmTitle   := MakeTextBox(fOptions.AssemblyTitle,     280);
    txtAsmCompany := MakeTextBox(fOptions.AssemblyCompany,   280);
    txtAsmCopy    := MakeTextBox(fOptions.AssemblyCopyright, 280);
    txtAsmVer     := MakeTextBox(fOptions.AssemblyVersion,   140);

    p.Controls.Add(MakeSeparator());
    p.Controls.Add(MakeSectionLabel('어셈블리 정보'));
    p.Controls.Add(MakeRow(MakeLabel('어셈블리 버전'), txtAsmVer));
    p.Controls.Add(MakeRow(MakeLabel('저작권'),        txtAsmCopy));
    p.Controls.Add(MakeRow(MakeLabel('회사'),          txtAsmCompany));
    p.Controls.Add(MakeRow(MakeLabel('제목'),          txtAsmTitle));
    p.Controls.Add(MakeCkPanel(chkEmbedAsm));
    p.Controls.Add(MakeCkPanel(chkCopyXaml));
    p.Controls.Add(MakeRow(MakeLabel('출력 디렉터리'), txtOutDir));
    p.Controls.Add(MakeRow(MakeLabel('출력 파일명'),   txtOutFile));
    p.Controls.Add(MakeHint('빌드 출력 파일 경로와 어셈블리 메타데이터를 설정합니다.'));
  end;

  procedure BuildPageOptimize(p: System.Windows.Forms.Panel);
  begin
    p.Controls.Add(MakeSectionLabel('최적화 설정'));
    cboTarget   := MakeCombo(['AnyCPU', 'x86 (32비트)', 'x64 (64비트)'],
                             fOptions.TargetPlatform, 200);
    chkOptimize := MakeCheck('코드 최적화 (/optimize)', fOptions.OptimizeCode);
    chkInline   := MakeCheck('인라인 확장 (/inline)',   fOptions.InlineExpansion);
    p.Controls.Add(MakeCkPanel(chkInline));
    p.Controls.Add(MakeCkPanel(chkOptimize));
    p.Controls.Add(MakeRow(MakeLabel('대상 플랫폼'), cboTarget));
    p.Controls.Add(MakeHint('컴파일 최적화 옵션을 설정합니다.'));
  end;

  procedure BuildPageCodeStyle(p: System.Windows.Forms.Panel);
  begin
    p.Controls.Add(MakeSectionLabel('코드 스타일'));
    spnIndent       := MakeSpinner(fOptions.IndentSize, 1, 8, 60);
    cboBrace        := MakeCombo(['Pascal (begin/end 같은 줄)', 'Allman (begin 새 줄)'],
                                 fOptions.BraceStyle, 260);
    cboCommentStyle := MakeCombo(['Line (//)', 'Block ({})', 'XML (//)'],
                                 fOptions.CommentStyle, 180);
    chkUseTabs      := MakeCheck('탭 문자 사용',                         fOptions.UseTabs);
    chkAutoBegin    := MakeCheck('procedure/function 뒤 begin 자동 삽입', fOptions.AutoInsertBegin);
    chkAutoEnd      := MakeCheck('begin 뒤 end 자동 완성',               fOptions.AutoInsertEnd);
    chkGenComments  := MakeCheck('이벤트 핸들러에 TODO 주석 생성',         fOptions.GenerateComments);
    p.Controls.Add(MakeCkPanel(chkGenComments));
    p.Controls.Add(MakeCkPanel(chkAutoEnd));
    p.Controls.Add(MakeCkPanel(chkAutoBegin));
    p.Controls.Add(MakeCkPanel(chkUseTabs));
    p.Controls.Add(MakeRow(MakeLabel('주석 스타일'),   cboCommentStyle));
    p.Controls.Add(MakeRow(MakeLabel('중괄호 스타일'), cboBrace));
    p.Controls.Add(MakeRow(MakeLabel('들여쓰기 크기'), spnIndent));
    p.Controls.Add(MakeHint('자동 코드 생성 시 적용되는 스타일을 설정합니다.'));
  end;

  procedure BuildPageEditor(p: System.Windows.Forms.Panel);
  var
    lineNumPanel : System.Windows.Forms.Panel;
    lineNumLabel : System.Windows.Forms.Label;
  begin
    p.Controls.Add(MakeSectionLabel('에디터 설정'));
    txtFont         := MakeTextBox(fOptions.FontName, 180);
    spnFontSize     := MakeSpinner(fOptions.FontSize, 8, 32, 60);
    spnTabSize      := MakeSpinner(fOptions.TabSize,  1,  8, 60);
    chkXamlLineNum  := MakeCheck('XAML 에디터',         fOptions.XamlShowLineNum);
    chkCodeLineNum  := MakeCheck('코드 에디터',         fOptions.CodeShowLineNum);
    chkXamlHL       := MakeCheck('XAML 구문 강조',      fOptions.XamlHighlight);
    chkCodeHL       := MakeCheck('Pascal 구문 강조',    fOptions.CodeHighlight);
    chkWordWrap     := MakeCheck('자동 줄바꿈',          fOptions.WordWrap);
    chkXamlFold     := MakeCheck('XAML XML 폴딩',       fOptions.XamlFolding);
    chkCodeFold     := MakeCheck('Pascal begin/end 폴딩',fOptions.CodeFolding);
    chkShowWS       := MakeCheck('공백 문자 표시',       fOptions.ShowWhitespace);
    chkHlLine       := MakeCheck('현재 줄 강조',         fOptions.HighlightCurrLine);
    chkAutoComp     := MakeCheck('자동 완성',            fOptions.AutoComplete);

    // 줄 번호 표시: 두 체크박스를 같은 행에
    lineNumPanel           := new System.Windows.Forms.Panel();
    lineNumPanel.Height    := 26;
    lineNumPanel.Dock      := System.Windows.Forms.DockStyle.Top;
    lineNumLabel           := MakeLabel('줄 번호 표시');
    lineNumLabel.Top       := 3; lineNumLabel.Left := 0;
    lineNumLabel.Anchor    := System.Windows.Forms.AnchorStyles.Left or
                              System.Windows.Forms.AnchorStyles.Top;
    chkXamlLineNum.Top     := 3; chkXamlLineNum.Left := 175;
    chkXamlLineNum.Anchor  := System.Windows.Forms.AnchorStyles.Left or
                              System.Windows.Forms.AnchorStyles.Top;
    chkCodeLineNum.Top     := 3; chkCodeLineNum.Left := 290;
    chkCodeLineNum.Anchor  := System.Windows.Forms.AnchorStyles.Left or
                              System.Windows.Forms.AnchorStyles.Top;
    lineNumPanel.Controls.Add(lineNumLabel);
    lineNumPanel.Controls.Add(chkXamlLineNum);
    lineNumPanel.Controls.Add(chkCodeLineNum);

    p.Controls.Add(MakeCkPanel(chkAutoComp));
    p.Controls.Add(MakeCkPanel(chkHlLine));
    p.Controls.Add(MakeCkPanel(chkShowWS));
    p.Controls.Add(MakeCkPanel(chkCodeFold));
    p.Controls.Add(MakeCkPanel(chkXamlFold));
    p.Controls.Add(MakeCkPanel(chkWordWrap));
    p.Controls.Add(MakeCkPanel(chkCodeHL));
    p.Controls.Add(MakeCkPanel(chkXamlHL));
    p.Controls.Add(lineNumPanel);
    p.Controls.Add(MakeRow(MakeLabel('탭 너비'),   spnTabSize));
    p.Controls.Add(MakeRow(MakeLabel('폰트 크기'), spnFontSize));
    p.Controls.Add(MakeRow(MakeLabel('폰트'),      txtFont));
    p.Controls.Add(MakeHint('XAML/코드 에디터 표시 옵션을 설정합니다.'));
  end;

  procedure BuildPageDebug(p: System.Windows.Forms.Panel);
  var
    txtExtProgCtl, txtArgsCtl, txtWdCtl: System.Windows.Forms.TextBox;
  begin
    p.Controls.Add(MakeSectionLabel('디버그/실행 설정'));
    cboStartAct   := MakeCombo(['프로젝트 (기본)', '외부 프로그램', 'URL'],
                               fOptions.StartAction, 200);
    txtExtProgCtl := MakeTextBox(fOptions.ExternalProgram, 280);
    txtExtProg    := txtExtProgCtl;
    txtArgsCtl    := MakeTextBox(fOptions.StartArgs,       280);
    txtStartArgs  := txtArgsCtl;
    txtWdCtl      := MakeTextBox(fOptions.WorkingDir,      280);
    chkUseEnv     := MakeCheck('현재 환경 변수 사용',        fOptions.UseEnvVars);
    chkRunBefore  := MakeCheck('빌드 전 프로젝트 저장 확인', fOptions.RunBeforeBuild);

    p.Controls.Add(MakeCkPanel(chkRunBefore));
    p.Controls.Add(MakeCkPanel(chkUseEnv));
    p.Controls.Add(MakeRow(MakeLabel('작업 디렉터리'), txtWdCtl));
    p.Controls.Add(MakeRow(MakeLabel('시작 인수'),     txtArgsCtl));
    p.Controls.Add(MakeRow(MakeLabel('외부 프로그램'), txtExtProgCtl));
    p.Controls.Add(MakeRow(MakeLabel('시작 동작'),     cboStartAct));
    p.Controls.Add(MakeHint('빌드 후 실행 방식과 디버그 환경을 설정합니다.'));
  end;

  // ── 옵션 저장 ─────────────────────────────────────────────────────────────
  procedure SaveOptions;
  begin
    fOptions.ProjectName      := txtProjName.Text.Trim();
    fOptions.RootNamespace    := txtRootNs.Text.Trim();
    fOptions.ClassName        := txtClassName.Text.Trim();
    fOptions.ProjectType      := (if cboProjType.SelectedIndex = 1
                                  then ptWpfControlLibrary else ptWpfApp);
    fOptions.CompilerPath     := fDlgTxtCompPath.Text.Trim();
    fOptions.AdditionalArgs   := txtAdditArgs.Text.Trim();
    fOptions.NoConsole        := chkNoConsole.Checked;
    fOptions.DebugInfo        := chkDebug.Checked;
    fOptions.WarningsAsErrors := chkWarnErr.Checked;
    fOptions.AutoClean        := chkAutoClean.Checked;
    fOptions.OutputFileName   := txtOutFile.Text.Trim();
    fOptions.OutputDirectory  := txtOutDir.Text.Trim();
    fOptions.CopyXamlToOutput := chkCopyXaml.Checked;
    fOptions.EmbedAssemblyInfo:= chkEmbedAsm.Checked;
    fOptions.AssemblyVersion  := txtAsmVer.Text.Trim();
    fOptions.AssemblyTitle    := txtAsmTitle.Text.Trim();
    fOptions.AssemblyCompany  := txtAsmCompany.Text.Trim();
    fOptions.AssemblyCopyright:= txtAsmCopy.Text.Trim();
    fOptions.OptimizeCode     := chkOptimize.Checked;
    fOptions.InlineExpansion  := chkInline.Checked;
    fOptions.TargetPlatform   := cboTarget.Text;
    fOptions.IndentSize       := System.Convert.ToInt32(spnIndent.Value);
    fOptions.UseTabs          := chkUseTabs.Checked;
    fOptions.BraceStyle       := cboBrace.Text;
    fOptions.AutoInsertBegin  := chkAutoBegin.Checked;
    fOptions.AutoInsertEnd    := chkAutoEnd.Checked;
    fOptions.GenerateComments := chkGenComments.Checked;
    fOptions.CommentStyle     := cboCommentStyle.Text;
    fOptions.FontName         := txtFont.Text.Trim();
    fOptions.FontSize         := System.Convert.ToInt32(spnFontSize.Value);
    fOptions.XamlShowLineNum  := chkXamlLineNum.Checked;
    fOptions.CodeShowLineNum  := chkCodeLineNum.Checked;
    fOptions.XamlHighlight    := chkXamlHL.Checked;
    fOptions.CodeHighlight    := chkCodeHL.Checked;
    fOptions.WordWrap         := chkWordWrap.Checked;
    fOptions.XamlFolding      := chkXamlFold.Checked;
    fOptions.CodeFolding      := chkCodeFold.Checked;
    fOptions.TabSize          := System.Convert.ToInt32(spnTabSize.Value);
    fOptions.ShowWhitespace   := chkShowWS.Checked;
    fOptions.HighlightCurrLine:= chkHlLine.Checked;
    fOptions.AutoComplete     := chkAutoComp.Checked;
    fOptions.StartAction      := cboStartAct.Text;
    fOptions.ExternalProgram  := txtExtProg.Text.Trim();
    fOptions.StartArgs        := txtStartArgs.Text.Trim();
    fOptions.UseEnvVars       := chkUseEnv.Checked;
    fOptions.RunBeforeBuild   := chkRunBefore.Checked;
    fProjectType := fOptions.ProjectType;
    ApplyOptionsToEditors();
  end;



// ── 다이얼로그 조립 ──────────────────────────────────────────────────────────
begin
  dlg        := new System.Windows.Forms.Form();
  dlg.Text   := '프로젝트 옵션 — ' + fNamespace;
  dlg.Width  := 760;
  dlg.Height := 580;
  dlg.FormBorderStyle := System.Windows.Forms.FormBorderStyle.Sizable;
  dlg.StartPosition   := System.Windows.Forms.FormStartPosition.CenterParent;
  dlg.MinimumSize     := new System.Drawing.Size(620, 440);
  dlg.Font            := new System.Drawing.Font('Segoe UI', 9);

  fNavList             := new System.Windows.Forms.ListBox();
  fNavList.Dock        := System.Windows.Forms.DockStyle.Fill;
  fNavList.Font        := new System.Drawing.Font('Segoe UI', 9.5);
  fNavList.BorderStyle := System.Windows.Forms.BorderStyle.None;
  fNavList.BackColor   := System.Drawing.Color.FromArgb(245, 245, 250);
  fNavList.ItemHeight  := 28;
  fNavList.Items.Add('  🏷  프로젝트 정보');
  fNavList.Items.Add('  🔧  컴파일러');
  fNavList.Items.Add('  📦  출력 설정');
  fNavList.Items.Add('  ⚡  최적화');
  fNavList.Items.Add('  🎨  코드 스타일');
  fNavList.Items.Add('  📝  에디터');
  fNavList.Items.Add('  ▶  디버그/실행');
  fNavList.SelectedIndex := 0;

  fContentPanel              := new System.Windows.Forms.Panel();
  fContentPanel.Dock         := System.Windows.Forms.DockStyle.Fill;
  fContentPanel.AutoScroll   := true;
  fContentPanel.Padding      := new System.Windows.Forms.Padding(16, 12, 16, 12);
  fContentPanel.BackColor    := System.Drawing.Color.White;

  // 페이지 패널 생성
  i := 0;
  while i <= 6 do
  begin
    panels[i]           := new System.Windows.Forms.Panel();
    fPanels[i]          := panels[i];
    panels[i].Dock      := System.Windows.Forms.DockStyle.Top;
    panels[i].AutoSize  := true;
    panels[i].Visible   := (i = 0);
    i += 1;
  end;

  // 컨트롤 참조 nil 초기화
  txtProjName := nil; txtRootNs := nil; txtClassName := nil;
  fDlgTxtCompPath := nil; txtAdditArgs := nil;
  chkNoConsole := nil; chkDebug := nil; chkWarnErr := nil; chkAutoClean := nil;
  txtOutFile := nil; txtOutDir := nil; chkCopyXaml := nil; chkEmbedAsm := nil;
  txtAsmVer := nil; txtAsmTitle := nil; txtAsmCompany := nil; txtAsmCopy := nil;
  chkOptimize := nil; chkInline := nil; cboTarget := nil;
  spnIndent := nil; cboBrace := nil; cboCommentStyle := nil;
  chkUseTabs := nil; chkAutoBegin := nil; chkAutoEnd := nil; chkGenComments := nil;
  txtFont := nil; spnFontSize := nil; spnTabSize := nil;
  chkXamlLineNum := nil; chkCodeLineNum := nil;
  chkXamlHL := nil; chkCodeHL := nil;
  chkWordWrap := nil; chkXamlFold := nil; chkCodeFold := nil;
  chkShowWS := nil; chkHlLine := nil; chkAutoComp := nil;
  cboStartAct := nil; txtExtProg := nil; txtStartArgs := nil;
  chkUseEnv := nil; chkRunBefore := nil;

  BuildPageInfo(panels[0]);
  BuildPageCompiler(panels[1]);
  BuildPageOutput(panels[2]);
  BuildPageOptimize(panels[3]);
  BuildPageCodeStyle(panels[4]);
  BuildPageEditor(panels[5]);
  BuildPageDebug(panels[6]);

  i := 0;
  while i <= 6 do
  begin
    fContentPanel.Controls.Add(panels[i]);
    i += 1;
  end;

  fNavList.SelectedIndexChanged += OnNavListSelectedIndexChanged;

  splitDlg                  := new System.Windows.Forms.SplitContainer();
  splitDlg.Dock             := System.Windows.Forms.DockStyle.Fill;
  splitDlg.SplitterDistance := 195;
  splitDlg.IsSplitterFixed  := true;
  splitDlg.Panel1.Controls.Add(fNavList);
  splitDlg.Panel2.Controls.Add(fContentPanel);

  // 하단 버튼 바
  fDlgBtnBar           := new System.Windows.Forms.Panel();
  fDlgBtnBar.Dock      := System.Windows.Forms.DockStyle.Bottom;
  fDlgBtnBar.Height    := 44;
  fDlgBtnBar.BackColor := System.Drawing.Color.FromArgb(245, 245, 250);

  fDlgBtnOk              := new System.Windows.Forms.Button();
  fDlgBtnOk.Text         := '확인';
  fDlgBtnOk.Width        := 80; fDlgBtnOk.Height := 28;
  fDlgBtnOk.Top          := 8;
  fDlgBtnOk.Anchor       := System.Windows.Forms.AnchorStyles.Right or
                        System.Windows.Forms.AnchorStyles.Top;
  fDlgBtnOk.BackColor    := System.Drawing.Color.FromArgb(72, 60, 180);
  fDlgBtnOk.ForeColor    := System.Drawing.Color.White;
  fDlgBtnOk.FlatStyle    := System.Windows.Forms.FlatStyle.Flat;
  fDlgBtnOk.FlatAppearance.BorderSize := 0;
  fDlgBtnOk.DialogResult := System.Windows.Forms.DialogResult.OK;

  fDlgBtnCancel              := new System.Windows.Forms.Button();
  fDlgBtnCancel.Text         := '취소';
  fDlgBtnCancel.Width        := 80; fDlgBtnCancel.Height := 28;
  fDlgBtnCancel.Top          := 8;
  fDlgBtnCancel.Anchor       := System.Windows.Forms.AnchorStyles.Right or
                            System.Windows.Forms.AnchorStyles.Top;
  fDlgBtnCancel.FlatStyle    := System.Windows.Forms.FlatStyle.Flat;
  fDlgBtnCancel.DialogResult := System.Windows.Forms.DialogResult.Cancel;

  fDlgBtnApply        := new System.Windows.Forms.Button();
  fDlgBtnApply.Text   := '적용';
  fDlgBtnApply.Width  := 80; fDlgBtnApply.Height := 28;
  fDlgBtnApply.Top    := 8;
  fDlgBtnApply.Anchor := System.Windows.Forms.AnchorStyles.Right or
                     System.Windows.Forms.AnchorStyles.Top;
  fDlgBtnApply.FlatStyle := System.Windows.Forms.FlatStyle.Flat;
  fDlgBtnApply.Click  += OnApplyClick;

  fDlgBtnBar.Controls.Add(fDlgBtnApply);
  fDlgBtnBar.Controls.Add(fDlgBtnCancel);
  fDlgBtnBar.Controls.Add(fDlgBtnOk);

  fDlgBtnBar.Resize += OnBtnBarLayoutEvent;

  dlg.Controls.Add(splitDlg);
  dlg.Controls.Add(fDlgBtnBar);
  dlg.AcceptButton := fDlgBtnOk;
  dlg.CancelButton := fDlgBtnCancel;

  // dlg.Width 설정만으로는 Handle 이 아직 생성되지 않아 fDlgBtnBar.ClientSize 가
  // 부정확할 수 있으므로, Shown 시점에 한 번 더 정렬해 확실히 보이도록 한다.
  dlg.Shown += OnBtnBarLayoutEvent;
  LayoutDlgBtnBar();

  if dlg.ShowDialog() = System.Windows.Forms.DialogResult.OK then
    if (txtProjName <> nil) and (txtRootNs <> nil) then
      SaveOptions();
end;

procedure Form1.OnProjectOptions(sender: System.Object; e: System.EventArgs);
begin
  ShowProjectOptionsDialog();
end;

// =============================================================================
// 옵션 다이얼로그 콜백
// =============================================================================
procedure Form1.OnNavListSelectedIndexChanged(sender: System.Object; e: System.EventArgs);
var
  idx, j: integer;
begin
  idx := fNavList.SelectedIndex;
  j   := 0;
  while j <= 6 do
  begin
    fPanels[j].Visible := (j = idx);
    j += 1;
  end;
  fContentPanel.AutoScrollPosition := new System.Drawing.Point(0, 0);
end;

procedure Form1.OnApplyClick(sender: System.Object; e: System.EventArgs);
begin
  if (fTxtProjName <> nil) and (fTxtRootNs <> nil) then
    ShowProjectOptionsDialog();   // SaveOptions 는 ShowProjectOptionsDialog 내부에서 호출
end;

// =============================================================================
// 새 프로젝트 다이얼로그
// =============================================================================
function Form1.ShowNewProjectDialog(var projType: TProjectType;
  var projName: string; var projFolder: string): boolean;
var
  dlg       : System.Windows.Forms.Form;
  lstType   : System.Windows.Forms.ListBox;
  txtName   : System.Windows.Forms.TextBox;
  btnBrowse : System.Windows.Forms.Button;
  fDlgBtnOk     : System.Windows.Forms.Button;
  fDlgBtnCancel : System.Windows.Forms.Button;
begin
  Result    := false;
  projType  := ptWpfApp;
  projName  := 'WpfApp1';
  projFolder := System.Environment.GetFolderPath(
    System.Environment.SpecialFolder.MyDocuments);

  dlg        := new System.Windows.Forms.Form();
  dlg.Text   := '새 프로젝트 만들기';
  dlg.Width  := 560; dlg.Height := 420;
  dlg.FormBorderStyle := System.Windows.Forms.FormBorderStyle.FixedDialog;
  dlg.StartPosition   := System.Windows.Forms.FormStartPosition.CenterParent;
  dlg.MaximizeBox := false; dlg.MinimizeBox := false;

  var lblType      := new System.Windows.Forms.Label();
  lblType.Text := '프로젝트 형식';
  lblType.Left := 16; lblType.Top := 16; lblType.Width := 200;
  lblType.Font := new System.Drawing.Font('Segoe UI', 9, System.Drawing.FontStyle.Bold);

  lstType          := new System.Windows.Forms.ListBox();
  lstType.Left     := 16; lstType.Top := 36;
  lstType.Width    := 510; lstType.Height := 140;
  lstType.Font     := new System.Drawing.Font('Segoe UI', 10);
  lstType.Items.Add('WPF 애플리케이션              (.exe)');
  lstType.Items.Add('WPF 사용자 정의 컨트롤 라이브러리  (.dll)');
  lstType.SelectedIndex := 0;

  var lblName      := new System.Windows.Forms.Label();
  lblName.Text := '프로젝트 이름';
  lblName.Left := 16; lblName.Top := 196; lblName.Width := 200;
  lblName.Font := new System.Drawing.Font('Segoe UI', 9, System.Drawing.FontStyle.Bold);

  txtName          := new System.Windows.Forms.TextBox();
  txtName.Left     := 16; txtName.Top := 216;
  txtName.Width    := 510; txtName.Height := 26;
  txtName.Text     := 'WpfApp1';
  txtName.Font     := new System.Drawing.Font('Segoe UI', 10);

  var lblFolder      := new System.Windows.Forms.Label();
  lblFolder.Text := '위치';
  lblFolder.Left := 16; lblFolder.Top := 256; lblFolder.Width := 200;
  lblFolder.Font := new System.Drawing.Font('Segoe UI', 9, System.Drawing.FontStyle.Bold);

  fDlgTxtFolder        := new System.Windows.Forms.TextBox();
  fDlgTxtFolder.Left   := 16; fDlgTxtFolder.Top := 276;
  fDlgTxtFolder.Width  := 420; fDlgTxtFolder.Height := 26;
  fDlgTxtFolder.Text   := projFolder;
  fDlgTxtFolder.Font   := new System.Drawing.Font('Segoe UI', 10);

  btnBrowse        := new System.Windows.Forms.Button();
  btnBrowse.Left   := 444; btnBrowse.Top := 274;
  btnBrowse.Width  := 82; btnBrowse.Height := 28;
  btnBrowse.Text   := '찾아보기...';
  btnBrowse.Click  += OnBrowseClick;

  fDlgBtnOk              := new System.Windows.Forms.Button();
  fDlgBtnOk.Text         := '확인';
  fDlgBtnOk.Left         := 356; fDlgBtnOk.Top := 340;
  fDlgBtnOk.Width        := 80; fDlgBtnOk.Height := 30;
  fDlgBtnOk.DialogResult := System.Windows.Forms.DialogResult.OK;

  fDlgBtnCancel              := new System.Windows.Forms.Button();
  fDlgBtnCancel.Text         := '취소';
  fDlgBtnCancel.Left         := 444; fDlgBtnCancel.Top := 340;
  fDlgBtnCancel.Width        := 80; fDlgBtnCancel.Height := 30;
  fDlgBtnCancel.DialogResult := System.Windows.Forms.DialogResult.Cancel;

  dlg.Controls.Add(lblType);   dlg.Controls.Add(lstType);
  dlg.Controls.Add(lblName);   dlg.Controls.Add(txtName);
  dlg.Controls.Add(lblFolder); dlg.Controls.Add(fDlgTxtFolder);
  dlg.Controls.Add(btnBrowse); dlg.Controls.Add(fDlgBtnOk); dlg.Controls.Add(fDlgBtnCancel);
  dlg.AcceptButton := fDlgBtnOk;
  dlg.CancelButton := fDlgBtnCancel;

  if dlg.ShowDialog() = System.Windows.Forms.DialogResult.OK then
  begin
    projType   := (if lstType.SelectedIndex = 1 then ptWpfControlLibrary else ptWpfApp);
    projName   := txtName.Text.Trim();
    projFolder := fDlgTxtFolder.Text.Trim();
    Result     := true;
  end;
  fDlgTxtFolder := nil;
end;

procedure Form1.OnBrowseClick(sender: System.Object; e: System.EventArgs);
begin
  if fDlgTxtFolder = nil then exit;
  var fd := new System.Windows.Forms.FolderBrowserDialog();
  fd.SelectedPath := fDlgTxtFolder.Text;
  if fd.ShowDialog() = System.Windows.Forms.DialogResult.OK then
    fDlgTxtFolder.Text := fd.SelectedPath;
end;

procedure Form1.OnBrowseCompClick(sender: System.Object; e: System.EventArgs);
begin
  var od := new System.Windows.Forms.OpenFileDialog();
  od.Filter := '실행 파일|pabcnetc.exe|모든 파일|*.*';
  od.Title  := '컴파일러 선택';
  if od.ShowDialog() = System.Windows.Forms.DialogResult.OK then
    if fTxtCompilerPath <> nil then
      fTxtCompilerPath.Text := od.FileName;
end;

// =============================================================================
// 새 프로젝트 생성
// =============================================================================
procedure Form1.CreateNewProject(projType: TProjectType;
  projName: string; projFolder: string);
var
  defaultXaml: string;
begin
  KillPreviousBuildProcesses();

  fProjectPath  := projFolder + '\' + projName + '\';
  fProjectType  := projType;
  fClassName    := projName;
  fNamespace    := projName;

  fOptions.ProjectName   := projName;
  fOptions.RootNamespace := projName;
  fOptions.ClassName     := projName;
  fOptions.ProjectType   := projType;
  fOptions.ProjectPath   := fProjectPath;

  if not System.IO.Directory.Exists(fProjectPath) then
    System.IO.Directory.CreateDirectory(fProjectPath);

  case projType of
    ptWpfApp:
    begin
      fXamlFileName := projName + '.xaml';
      fPasFileName  := projName + '.pas';
      defaultXaml :=
        '<Window x:Class="' + projName + '.' + projName + '"' + #13#10 +
        '        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' + #13#10 +
        '        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"' + #13#10 +
        '        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"' + #13#10 +
        '        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"' + #13#10 +
        '        mc:Ignorable="d"' + #13#10 +
        '        Title="' + projName + '" Height="450" Width="800">' + #13#10 +
        '    <Grid>' + #13#10 +
        '    </Grid>' + #13#10 +
        '</Window>';
    end;
    ptWpfControlLibrary:
    begin
      fXamlFileName := projName + '.xaml';
      fPasFileName  := projName + '.pas';
      defaultXaml :=
        '<UserControl x:Class="' + projName + '.' + projName + '"' + #13#10 +
        '             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' + #13#10 +
        '             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"' + #13#10 +
        '             xmlns:d="http://schemas.microsoft.com/expression/blend/2008"' + #13#10 +
        '             xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"' + #13#10 +
        '             mc:Ignorable="d"' + #13#10 +
        '             d:DesignHeight="300" d:DesignWidth="400">' + #13#10 +
        '    <Grid>' + #13#10 +
        '    </Grid>' + #13#10 +
        '</UserControl>';
    end;
  end;

  LoadXaml(defaultXaml);
  fCodeEditor.Text := GenerateCode();
  ApplyCodeHighlighting();
  if fOptions.CodeFolding then EnableCodeFolding();
  Self.Text := 'PascalABC-WPF-Designer — ' + fProjectPath;
  RefreshSolutionExplorer();
end;

procedure Form1.OnNewProject(sender: System.Object; e: System.EventArgs);
var
  projType  : TProjectType;
  projName  : string;
  projFolder: string;
begin
  if ShowNewProjectDialog(projType, projName, projFolder) then
    CreateNewProject(projType, projName, projFolder);
end;

// =============================================================================
// 출력 패널
// =============================================================================
procedure Form1.AppendOutput(text: string; isError: boolean);
var
  args : array of System.Object;
  d    : System.Action<string, boolean>;
begin
  if txtOutput = nil then exit;
  if txtOutput.InvokeRequired then
  begin
    d := AppendOutput;
    args := new System.Object[2];
    args[0] := text; args[1] := isError;
    txtOutput.Invoke(d, args);
    exit;
  end;
  txtOutput.SelectionStart  := txtOutput.TextLength;
  txtOutput.SelectionLength := 0;
  txtOutput.SelectionColor  := (if isError
    then System.Drawing.Color.FromArgb(255, 90, 90)
    else System.Drawing.Color.FromArgb(220, 220, 220));
  txtOutput.AppendText(text + System.Environment.NewLine);
  txtOutput.SelectionStart := txtOutput.TextLength;
  txtOutput.ScrollToCaret();
end;

procedure Form1.ClearOutput;
var d: System.Action;
begin
  if txtOutput = nil then exit;
  if txtOutput.InvokeRequired then
  begin d := ClearOutput; txtOutput.Invoke(d); exit; end;
  txtOutput.Clear();
end;

procedure Form1.OnOutputCopy(sender: System.Object; e: System.EventArgs);
begin
  if txtOutput.SelectedText <> '' then
    System.Windows.Forms.Clipboard.SetText(txtOutput.SelectedText)
  else if txtOutput.Text <> '' then
    System.Windows.Forms.Clipboard.SetText(txtOutput.Text);
end;

procedure Form1.OnOutputClear(sender: System.Object; e: System.EventArgs);
begin ClearOutput(); end;

procedure Form1.OnRunProcessExited(sender: System.Object; e: System.EventArgs);
begin
  AppendOutput('====== 프로세스 종료 (종료코드: ' +
    fRunningProcess.ExitCode.ToString() + ') ======', false);
end;

// =============================================================================
// 빌드
// =============================================================================
procedure Form1.OnBuild(sender: System.Object; e: System.EventArgs);
var
  xamlPath, pasPath, buildXaml: string;
begin
  if fBuildProcess <> nil then
  try if not fBuildProcess.HasExited then exit; except end;

  KillPreviousBuildProcesses();
  ClearOutput();
  dockOutput.Show();
  dockOutput.Activate();
  AppendOutput('====== 빌드 시작: ' + System.DateTime.Now.ToString('HH:mm:ss') + ' ======', false);

  ParseXClassInfo(fXamlEditor.Text, fNamespace, fClassName);

  if fCodeEditor.Text.Trim() = '' then
    fCodeEditor.Text := GenerateCode();

  xamlPath := fProjectPath + fXamlFileName;
  pasPath  := fProjectPath + fPasFileName;

  try
    buildXaml := PrepareXamlForBuild(fXamlEditor.Text);
    System.IO.File.WriteAllText(xamlPath, buildXaml, System.Text.Encoding.UTF8);
    System.IO.File.WriteAllText(pasPath, fCodeEditor.Text, System.Text.Encoding.UTF8);
    AppendOutput('파일 저장: ' + xamlPath, false);
    AppendOutput('파일 저장: ' + pasPath, false);
  except
    on ex: System.Exception do
    begin
      AppendOutput('파일 저장 오류: ' + ex.Message, true);
      System.Windows.Forms.MessageBox.Show('파일 저장 오류: ' + ex.Message);
      exit;
    end;
  end;
  StartBuildProcess();
end;

procedure Form1.StartBuildProcess;
var
  compilerPath, pasPath, arguments: string;
begin
  fBuildHadStartErr := false;
  fBuildStartErrMsg := '';

  compilerPath := fOptions.CompilerPath;
  if (compilerPath = '') or not System.IO.File.Exists(compilerPath) then
    compilerPath := FindPabcCompiler();

  if compilerPath = '' then
  begin
    AppendOutput('pabcnetc.exe를 찾을 수 없습니다.', true);
    System.Windows.Forms.MessageBox.Show('pabcnetc.exe를 찾을 수 없습니다.', '컴파일러 없음',
      System.Windows.Forms.MessageBoxButtons.OK,
      System.Windows.Forms.MessageBoxIcon.Warning);
    exit;
  end;

  pasPath := fProjectPath + fPasFileName;
  AppendOutput('컴파일러: ' + compilerPath, false);
  AppendOutput('대상: ' + pasPath, false);
  AppendOutput('', false);

  var outExt := (if fProjectType = ptWpfControlLibrary then '.dll' else '.exe');
  fBuildExePath := fProjectPath +
    System.IO.Path.GetFileNameWithoutExtension(fPasFileName) + outExt;

  arguments := '"' + pasPath + '"';
  if fOptions.NoConsole     then arguments += ' /noconsole';
  if fOptions.DebugInfo     then arguments += ' /debug';
  if fOptions.WarningsAsErrors then arguments += ' /werr';
  if fOptions.OptimizeCode  then arguments += ' /optimize';
  if fOptions.AdditionalArgs.Trim() <> '' then
    arguments += ' ' + fOptions.AdditionalArgs.Trim();

  try
    var psi              := new System.Diagnostics.ProcessStartInfo();
    psi.FileName         := compilerPath;
    psi.Arguments        := arguments;
    psi.WorkingDirectory := fProjectPath;
    psi.UseShellExecute  := false;
    psi.CreateNoWindow   := true;
    psi.RedirectStandardOutput := true;
    psi.RedirectStandardError  := true;
    psi.StandardOutputEncoding := System.Text.Encoding.Default;
    psi.StandardErrorEncoding  := System.Text.Encoding.Default;

    fBuildProcess                     := new System.Diagnostics.Process();
    fBuildProcess.StartInfo           := psi;
    fBuildProcess.EnableRaisingEvents := true;
    fBuildProcess.OutputDataReceived  += OnBuildOutputLine;
    fBuildProcess.ErrorDataReceived   += OnBuildErrorLine;
    fBuildProcess.Exited              += OnBuildProcessExited;

    fBuildStopwatch := System.Diagnostics.Stopwatch.StartNew();
    fBuildProcess.Start();
    fBuildProcess.BeginOutputReadLine();
    fBuildProcess.BeginErrorReadLine();
  except
    on ex: System.Exception do
    begin
      AppendOutput('빌드 시작 오류: ' + ex.Message, true);
      System.Windows.Forms.MessageBox.Show('빌드 시작 오류: ' + ex.Message);
    end;
  end;
end;

procedure Form1.OnBuildOutputLine(sender: System.Object;
  e: System.Diagnostics.DataReceivedEventArgs);
begin
  if e.Data = nil then exit;
  AppendOutput(e.Data,
    e.Data.ToLower().Contains('error') or e.Data.Contains('오류'));
end;

procedure Form1.OnBuildErrorLine(sender: System.Object;
  e: System.Diagnostics.DataReceivedEventArgs);
begin
  if e.Data = nil then exit;
  AppendOutput(e.Data, true);
end;

procedure Form1.OnBuildProcessExited(sender: System.Object; e: System.EventArgs);
var act: System.Action;
begin
  try fBuildProcess.WaitForExit(); except end;
  if Self.InvokeRequired then
  begin act := FinishBuild; Self.Invoke(act); end
  else FinishBuild();
end;

procedure Form1.FinishBuild;
var exitCode: integer;
begin
  fBuildStopwatch.Stop();
  exitCode := -1;
  try exitCode := fBuildProcess.ExitCode; except end;

  AppendOutput('', false);
  AppendOutput('====== 빌드 종료 (경과: ' +
    (fBuildStopwatch.ElapsedMilliseconds / 1000.0).ToString('0.00') +
    '초, 종료코드: ' + exitCode.ToString() + ') ======', false);

  if (exitCode = 0) and System.IO.File.Exists(fBuildExePath) then
  begin
    lvErrors.Items.Clear();
    var item := new System.Windows.Forms.ListViewItem('빌드 성공: ' + fBuildExePath);
    item.ForeColor := System.Drawing.Color.FromArgb(0, 128, 0);
    lvErrors.Items.Add(item);

    if fOptions.EmbedAssemblyInfo then
    begin
      var patchErr: string := '';
      if TVersionResourcePatcher.TryPatch(fBuildExePath, fOptions, patchErr) then
        AppendOutput('어셈블리 버전 정보가 ' +
          System.IO.Path.GetFileName(fBuildExePath) + ' 에 적용되었습니다.', false)
      else
        AppendOutput('어셈블리 버전 정보 적용 실패: ' + patchErr, true);
    end;

    if fRunAfterBuild then LaunchBuiltExe();
  end
  else
  begin
    ShowBuildErrors(txtOutput.Text);
    dockErrors.Show();
    dockErrors.Activate();
  end;

  fRunAfterBuild := false;
  RefreshSolutionExplorer();
end;

procedure Form1.OnRun(sender: System.Object; e: System.EventArgs);
begin
  fRunAfterBuild := true;
  OnBuild(sender, e);
end;

procedure Form1.LaunchBuiltExe;
begin
  if not System.IO.File.Exists(fBuildExePath) then exit;
  if fProjectType = ptWpfControlLibrary then
  begin LaunchControlTestHost(); exit; end;

  AppendOutput('', false);
  AppendOutput('====== 실행: ' + fBuildExePath + ' ======', false);
  try
    var psi              := new System.Diagnostics.ProcessStartInfo();
    psi.FileName         := fBuildExePath;
    psi.WorkingDirectory := fProjectPath;
    if fOptions.StartArgs.Trim() <> '' then
      psi.Arguments := fOptions.StartArgs.Trim();
    psi.UseShellExecute := false;
    psi.CreateNoWindow  := false;
    fRunningProcess := new System.Diagnostics.Process();
    fRunningProcess.StartInfo := psi;
    fRunningProcess.EnableRaisingEvents := true;
    fRunningProcess.Exited += OnRunProcessExited;
    fRunningProcess.Start();
  except
    on ex: System.Exception do
    begin
      AppendOutput('실행 오류: ' + ex.Message, true);
      System.Windows.Forms.MessageBox.Show('실행 오류: ' + ex.Message);
    end;
  end;
end;

procedure Form1.LaunchControlTestHost;
var
  hostPasPath, hostExePath, hostName, unitName, compilerPath: string;
  sb: System.Text.StringBuilder;
begin
  unitName    := System.IO.Path.GetFileNameWithoutExtension(fPasFileName);
  hostName    := unitName + '_TestHost';
  hostPasPath := fProjectPath + hostName + '.pas';
  hostExePath := fProjectPath + hostName + '.exe';

  AppendOutput('', false);
  AppendOutput('====== 컨트롤 테스트 호스트 생성 ======', false);

  sb := new System.Text.StringBuilder();
  sb.AppendLine('program ' + hostName + ';');
  sb.AppendLine('');
  sb.AppendLine('{$apptype windows}');
  sb.AppendLine('{$reference PresentationFramework.dll}');
  sb.AppendLine('{$reference PresentationCore.dll}');
  sb.AppendLine('{$reference WindowsBase.dll}');
  sb.AppendLine('{$reference System.Windows.Forms.dll}');
  sb.AppendLine('{$reference ' + unitName + '.dll}');
  sb.AppendLine('');
  sb.AppendLine('uses System.Windows, System.Threading;');
  sb.AppendLine('');
  sb.AppendLine('procedure RunHost;');
  sb.AppendLine('begin');
  sb.AppendLine('  try');
  sb.AppendLine('    var app  := new System.Windows.Application();');
  sb.AppendLine('    var ctrl := new ' + fClassName + '();');
  sb.AppendLine('    var win  := new System.Windows.Window();');
  sb.AppendLine('    win.Title := ' + #39 + '컨트롤 테스트: ' + fClassName + #39 + ';');
  sb.AppendLine('    win.Content := ctrl;');
  sb.AppendLine('    win.SizeToContent := System.Windows.SizeToContent.WidthAndHeight;');
  sb.AppendLine('    win.MinWidth := 200; win.MinHeight := 100;');
  sb.AppendLine('    app.Run(win);');
  sb.AppendLine('  except');
  sb.AppendLine('    on ex: System.Exception do');
  sb.AppendLine('      System.Windows.Forms.MessageBox.Show(');
  sb.AppendLine('        ex.ToString(), ' + #39 + '테스트 호스트 오류' + #39 + ',');
  sb.AppendLine('        System.Windows.Forms.MessageBoxButtons.OK,');
  sb.AppendLine('        System.Windows.Forms.MessageBoxIcon.Error);');
  sb.AppendLine('  end;');
  sb.AppendLine('end;');
  sb.AppendLine('');
  sb.AppendLine('begin');
  sb.AppendLine('  var t := new System.Threading.Thread(RunHost);');
  sb.AppendLine('  t.SetApartmentState(System.Threading.ApartmentState.STA);');
  sb.AppendLine('  t.IsBackground := false;');
  sb.AppendLine('  t.Start(); t.Join();');
  sb.AppendLine('end.');

  try
    System.IO.File.WriteAllText(hostPasPath, sb.ToString(), System.Text.Encoding.UTF8);
    AppendOutput('파일 저장: ' + hostPasPath, false);
  except
    on ex: System.Exception do
    begin AppendOutput('호스트 파일 저장 오류: ' + ex.Message, true); exit; end;
  end;

  compilerPath := fOptions.CompilerPath;
  if (compilerPath = '') or not System.IO.File.Exists(compilerPath) then
    compilerPath := FindPabcCompiler();
  if compilerPath = '' then
  begin AppendOutput('pabcnetc.exe를 찾을 수 없습니다.', true); exit; end;

  try
    var psi              := new System.Diagnostics.ProcessStartInfo();
    psi.FileName         := compilerPath;
    psi.Arguments        := '"' + hostPasPath + '" /noconsole';
    psi.WorkingDirectory := fProjectPath;
    psi.UseShellExecute  := false;
    psi.CreateNoWindow   := true;
    psi.RedirectStandardOutput := true;
    psi.RedirectStandardError  := true;
    psi.StandardOutputEncoding := System.Text.Encoding.Default;
    psi.StandardErrorEncoding  := System.Text.Encoding.Default;

    var hostProc := new System.Diagnostics.Process();
    hostProc.StartInfo := psi;
    hostProc.Start();
    var outText := hostProc.StandardOutput.ReadToEnd();
    var errText := hostProc.StandardError.ReadToEnd();
    hostProc.WaitForExit();

    if outText.Trim() <> '' then AppendOutput(outText, false);
    if errText.Trim() <> '' then AppendOutput(errText, true);

    if (hostProc.ExitCode <> 0) or not System.IO.File.Exists(hostExePath) then
    begin AppendOutput('테스트 호스트 빌드 실패.', true); exit; end;

    AppendOutput('테스트 호스트 빌드 성공: ' + hostExePath, false);
    AppendOutput('====== 실행: ' + hostExePath + ' ======', false);

    var runPsi              := new System.Diagnostics.ProcessStartInfo();
    runPsi.FileName         := hostExePath;
    runPsi.WorkingDirectory := fProjectPath;
    runPsi.UseShellExecute  := false;
    runPsi.CreateNoWindow   := false;
    fRunningProcess := new System.Diagnostics.Process();
    fRunningProcess.StartInfo := runPsi;
    fRunningProcess.EnableRaisingEvents := true;
    fRunningProcess.Exited += OnRunProcessExited;
    fRunningProcess.Start();
  except
    on ex: System.Exception do
    begin
      AppendOutput('테스트 호스트 실행 오류: ' + ex.Message, true);
      System.Windows.Forms.MessageBox.Show('테스트 호스트 실행 오류: ' + ex.Message);
    end;
  end;
end;

// =============================================================================
// 저장 / 열기
// =============================================================================
procedure Form1.OnSave(sender: System.Object; e: System.EventArgs);
var dlg: System.Windows.Forms.SaveFileDialog;
begin
  dlg          := new System.Windows.Forms.SaveFileDialog();
  dlg.Filter   := 'XAML 파일|*.xaml|모든 파일|*.*';
  dlg.FileName := fXamlFileName;
  dlg.InitialDirectory := fProjectPath;
  if dlg.ShowDialog() = System.Windows.Forms.DialogResult.OK then
  begin
    System.IO.File.WriteAllText(dlg.FileName, fXamlEditor.Text, System.Text.Encoding.UTF8);
    var pasPath := System.IO.Path.ChangeExtension(dlg.FileName, '.pas');
    System.IO.File.WriteAllText(pasPath, fCodeEditor.Text, System.Text.Encoding.UTF8);
    fProjectPath  := System.IO.Path.GetDirectoryName(dlg.FileName) + '\';
    fXamlFileName := System.IO.Path.GetFileName(dlg.FileName);
    fPasFileName  := System.IO.Path.GetFileName(pasPath);
    Self.Text := 'PascalABC-WPF-Designer — ' + fProjectPath;
    RefreshSolutionExplorer();
    System.Windows.Forms.MessageBox.Show(
      'XAML: ' + dlg.FileName + #13#10 + 'PAS: ' + pasPath + #13#10 + '저장 완료!');
  end;
end;

procedure Form1.OnOpen(sender: System.Object; e: System.EventArgs);
var
  dlg    : System.Windows.Forms.OpenFileDialog;
  xaml   : string;
  pasPath: string;
begin
  dlg        := new System.Windows.Forms.OpenFileDialog();
  dlg.Filter := 'XAML 파일|*.xaml|모든 파일|*.*';
  if dlg.ShowDialog() <> System.Windows.Forms.DialogResult.OK then exit;

  try
    xaml := System.IO.File.ReadAllText(dlg.FileName);
  except
    on ex: System.Exception do
    begin System.Windows.Forms.MessageBox.Show('읽기 오류: ' + ex.Message); exit; end;
  end;

  KillPreviousBuildProcesses();
  fProjectPath  := System.IO.Path.GetDirectoryName(dlg.FileName) + '\';
  fXamlFileName := System.IO.Path.GetFileName(dlg.FileName);
  fPasFileName  := System.IO.Path.ChangeExtension(fXamlFileName, '.pas');
  Self.Text     := 'PascalABC-WPF-Designer — ' + fProjectPath;

  ParseXClassInfo(xaml, fNamespace, fClassName);
  fProjectType := (if xaml.Contains('<UserControl') then ptWpfControlLibrary else ptWpfApp);

  fOptions.ProjectPath   := fProjectPath;
  fOptions.ProjectType   := fProjectType;
  fOptions.RootNamespace := fNamespace;
  fOptions.ClassName     := fClassName;

  LoadXaml(xaml);

  pasPath := fProjectPath + fPasFileName;
  if System.IO.File.Exists(pasPath) then
    fCodeEditor.Text := System.IO.File.ReadAllText(pasPath)
  else
    fCodeEditor.Text := GenerateCode();

  ApplyCodeHighlighting();
  if fOptions.CodeFolding then EnableCodeFolding();
  RefreshSolutionExplorer();
end;

// =============================================================================
// 탭 전환
// =============================================================================
procedure Form1.OnTabChanged(sender: System.Object; e: System.EventArgs);
begin
  if tabControl.SelectedTab = tabCode then
  begin
    ParseXClassInfo(fXamlEditor.Text, fNamespace, fClassName);
    if fCodeEditor.Text.Trim() = '' then
    begin
      fCodeEditor.Text := GenerateCode();
      ApplyCodeHighlighting();
    end;
  end;
end;

// =============================================================================
// 이벤트 핸들러 삽입
// =============================================================================
// ★ 변경: function으로 변경. 반환값은 fCodeEditor에서 커서를 위치시킬 CaretOffset.
//   - 핸들러가 이미 존재하면: 그 procedure의 'begin' 바로 다음 줄 시작 오프셋 반환
//   - 새로 생성하면: 새로 삽입된 handler의 'begin' 바로 다음 줄(TODO 줄) 시작 오프셋 반환
//   - 실패 시 -1 반환
function Form1.AddEventHandlerToCode(handlerName: string; eventType: string): integer;
var
  code, marker, indent, paramT: string;
  existingIdx, beginIdx: integer;
  doc: ICSharpCode.AvalonEdit.Document.TextDocument;

  // charIdx가 위치한 줄의 "다음 줄" 시작 오프셋을 구한다.
  // AvalonEdit Document의 줄 경계 API를 사용하므로 \r\n / \n 차이에 영향받지 않는다.
  function OffsetAfterLineOf(charIdx: integer): integer;
  var
    line: ICSharpCode.AvalonEdit.Document.DocumentLine;
  begin
    line := doc.GetLineByOffset(charIdx);
    if line.NextLine <> nil then
      Result := line.NextLine.Offset
    else
      Result := doc.TextLength;
  end;

begin
  Result := -1;
  code   := fCodeEditor.Text;
  marker := '// ── 이벤트 핸들러 구현 ──────────────────────────────────';

  // ── 케이스 1: 이미 존재하는 핸들러 → 그 begin 다음 줄로 이동 ──────────────
  existingIdx := code.IndexOf('procedure ' + fClassName + '.' + handlerName);
  if existingIdx >= 0 then
  begin
    doc      := fCodeEditor.Document;   // 텍스트 변경 전이므로 현재 Document 그대로 사용
    beginIdx := code.IndexOf('begin', existingIdx);
    if beginIdx >= 0 then
      Result := OffsetAfterLineOf(beginIdx)
    else
      Result := existingIdx;
    exit;
  end;

  // ── 케이스 2: 새로 생성 ────────────────────────────────────────────────
  paramT := (if eventType <> '' then eventType else 'System.Windows.RoutedEventArgs');

  indent := '';
  var ii := 0;
  while ii < fOptions.IndentSize do
  begin
    indent += (if fOptions.UseTabs then #9 else ' ');
    ii += 1;
  end;

  var handler := new System.Text.StringBuilder();
  if fOptions.GenerateComments then
    handler.AppendLine('// ' + handlerName + ' 이벤트 핸들러');
  handler.AppendLine('procedure ' + fClassName + '.' + handlerName +
    '(sender: System.Object; e: ' + paramT + ');');
  handler.AppendLine('begin');
  if fOptions.GenerateComments then
    handler.AppendLine(indent + '// TODO: ' + handlerName)
  else
    handler.AppendLine(indent);
  handler.AppendLine('end;');
  handler.AppendLine('');

  var handlerStr := handler.ToString();
  var insertPos: integer;

  if code.Contains(marker) then
  begin
    var insertText := marker + System.Environment.NewLine +
                       System.Environment.NewLine + handlerStr;
    insertPos := code.IndexOf(marker);
    code := code.Replace(marker, insertText);
    insertPos += Length(marker + System.Environment.NewLine + System.Environment.NewLine);
  end
  else
  begin
    insertPos := Length(code) + Length(System.Environment.NewLine);
    code := code + System.Environment.NewLine + handlerStr;
  end;

  fCodeEditor.Text := code;          // 텍스트 갱신 → Document 새로 생성됨
  doc := fCodeEditor.Document;       // 갱신된 Document 참조

  // handlerStr 안에서 'begin'의 절대 위치 = insertPos + (handlerStr 내 'begin' 인덱스)
  var beginRelIdx := handlerStr.IndexOf('begin');
  if beginRelIdx >= 0 then
    Result := OffsetAfterLineOf(insertPos + beginRelIdx)
  else
    Result := insertPos;
end;

procedure Form1.AddEventHandlerToXaml(controlName, eventName, handlerName: string);
var xaml: string;
begin
  xaml := fXamlEditor.Text;
  if controlName = '' then exit;
  var pattern := 'x:Name="' + controlName + '"';
  if not xaml.Contains(pattern) then exit;
  if xaml.Contains(eventName + '="' + handlerName + '"') then exit;
  xaml := xaml.Replace(pattern, pattern + ' ' + eventName + '="' + handlerName + '"');
  fXamlEditor.Text := xaml;
end;

// ★ 추가: Dispatcher.BeginInvoke로 호출되는 캐럿 이동 헬퍼.
//   메서드 참조(System.Action<integer>) 방식으로 호출하므로 PascalABC.NET의
//   익명 메서드/람다 문법 버전 차이에 영향받지 않는다.
procedure Form1.JumpCodeEditorCaretTo(offset: integer);
var loc: ICSharpCode.AvalonEdit.Document.TextLocation;
begin
  if fCodeEditor = nil then exit;
  if (offset < 0) or (offset > fCodeEditor.Document.TextLength) then exit;
  fCodeEditor.CaretOffset := offset;
  loc := fCodeEditor.Document.GetLocation(offset);
  fCodeEditor.ScrollTo(loc.Line, loc.Column);
  fCodeEditor.Focus();
  System.Windows.Input.Keyboard.Focus(fCodeEditor.TextArea);
end;

// =============================================================================
// 디자이너 더블클릭
// =============================================================================
procedure Form1.OnDesignerDoubleClick(sender: System.Object;
  e: System.Windows.Input.MouseButtonEventArgs);
var
  selectedItems : System.Collections.Generic.ICollection<ICSharpCode.WpfDesign.DesignItem>;
  item          : ICSharpCode.WpfDesign.DesignItem;
  controlName, controlType, eventName, handlerName: string;
  caretOffset   : integer;
  jumpAction    : System.Action<integer>;
begin
  if fSurface.DesignContext = nil then exit;
  selectedItems := fSurface.DesignContext.Services.Selection.SelectedItems;
  if selectedItems.Count = 0 then exit;

  item := nil;
  var en := selectedItems.GetEnumerator();
  if en.MoveNext() then item := en.Current;
  if item = nil then exit;

  var nameProp := item.Properties['Name'];
  controlName := (if (nameProp <> nil) and (nameProp.ValueOnInstance <> nil)
                  then nameProp.ValueOnInstance.ToString() else '');
  controlType := item.ComponentType.Name;

  case controlType of
    'Button'                 : eventName := 'Click';
    'TextBox'                : eventName := 'TextChanged';
    'CheckBox', 'RadioButton': eventName := 'Checked';
    'ComboBox', 'ListBox'    : eventName := 'SelectionChanged';
    'Slider'                 : eventName := 'ValueChanged';
  else                         eventName := 'Loaded';
  end;

  handlerName := (if controlName <> '' then controlName else controlType) + '_' + eventName;

  AddEventHandlerToXaml(controlName, eventName, handlerName);
  caretOffset := AddEventHandlerToCode(handlerName, GetEventParamType(controlType, eventName));

  tabControl.SelectedTab := tabCode;
  AppendOutput('이벤트 핸들러로 이동: ' + handlerName, false);

  // ElementHost 안 WPF 컨트롤이 탭 전환 직후 바로 포커스를 못 받는 경우가 있어
  // Dispatcher에 한 틱 미뤄서 처리 (VS의 더블클릭 → 코드 점프와 동일한 체감)
  if caretOffset >= 0 then
  begin
    jumpAction := JumpCodeEditorCaretTo;
    fCodeEditor.Dispatcher.BeginInvoke(
      System.Windows.Threading.DispatcherPriority.Background,
      jumpAction, caretOffset);
  end;
end;

// =============================================================================
// 디자이너 로드 / XAML 동기화
// =============================================================================
procedure Form1.LoadDesigner(designXaml: string);
var
  strReader: System.IO.StringReader;
  xmlReader: System.Xml.XmlReader;
  settings : ICSharpCode.WpfDesign.Designer.Xaml.XamlLoadSettings;
  scroll   : System.Windows.Controls.ScrollViewer;
begin
  if fFoldingManager <> nil then
  begin
    ICSharpCode.AvalonEdit.Folding.FoldingManager.Uninstall(fFoldingManager);
    fFoldingManager  := nil;
    fFoldingStrategy := nil;
  end;
  fSurface  := new ICSharpCode.WpfDesign.Designer.DesignSurface();
  settings  := new ICSharpCode.WpfDesign.Designer.Xaml.XamlLoadSettings();
  strReader := new System.IO.StringReader(designXaml);
  xmlReader := new System.Xml.XmlTextReader(strReader);
  fSurface.LoadDesigner(xmlReader, settings);
  scroll := new System.Windows.Controls.ScrollViewer();
  scroll.HorizontalScrollBarVisibility := System.Windows.Controls.ScrollBarVisibility.Auto;
  scroll.VerticalScrollBarVisibility   := System.Windows.Controls.ScrollBarVisibility.Auto;
  scroll.Content   := fSurface;
  hostDesign.Child := scroll;
  ConnectEvents();
  if (menuItemFolding <> nil) and menuItemFolding.Checked then
    EnableFolding();
end;

procedure Form1.LoadXaml(xaml: string);
var designXaml: string;
begin
  fOriginalXaml    := xaml;
  fXamlEditor.Text := xaml;
  try
    designXaml := PreprocessXaml(xaml);
  except
    on ex: System.Exception do
    begin
      System.Windows.Forms.MessageBox.Show('XAML 전처리 오류: ' + ex.Message);
      exit;
    end;
  end;
  fLoadingXaml := true;
  try
    try LoadDesigner(designXaml);
    except
      on ex: System.Exception do
        System.Windows.Forms.MessageBox.Show('XAML 로드 오류: ' + ex.Message);
    end;
  finally
    fLoadingXaml := false;
  end;
end;

procedure Form1.ConnectEvents;
var undoSvc: ICSharpCode.WpfDesign.Designer.Services.UndoService;
begin
  if fSurface.DesignContext = nil then exit;
  fSurface.DesignContext.Services.Selection.SelectionChanged += OnSelectionChanged;
  undoSvc := fSurface.DesignContext.Services.GetService(
    typeof(ICSharpCode.WpfDesign.Designer.Services.UndoService)
  ) as ICSharpCode.WpfDesign.Designer.Services.UndoService;
  if undoSvc <> nil then
    undoSvc.UndoStackChanged += OnUndoStackChanged;
  fSurface.MouseDoubleClick += OnDesignerDoubleClick;
end;

procedure Form1.OnSelectionChanged(sender: System.Object;
  e: ICSharpCode.WpfDesign.DesignItemCollectionEventArgs);
begin
  if fSurface.DesignContext = nil then exit;
  fPropView.SelectedItems := fSurface.DesignContext.Services.Selection.SelectedItems;
end;

procedure Form1.OnUndoStackChanged(sender: System.Object; e: System.EventArgs);
begin SyncXamlEditor(); end;

procedure Form1.OnApplyXaml(sender: System.Object; e: System.Windows.RoutedEventArgs);
begin
  var xaml := fXamlEditor.Text.Trim();
  if xaml <> '' then LoadXaml(xaml);
end;

procedure Form1.OnApplyXamlMenu(sender: System.Object; e: System.EventArgs);
begin
  var xaml := fXamlEditor.Text.Trim();
  if xaml <> '' then LoadXaml(xaml);
end;

procedure Form1.OnSyncXamlMenu(sender: System.Object; e: System.EventArgs);
begin SyncXamlEditor(); end;

function Form1.SaveDesignerToString: string;
var
  sw        : System.IO.StringWriter;
  xwSettings: System.Xml.XmlWriterSettings;
  xw        : System.Xml.XmlWriter;
begin
  if fSurface.DesignContext = nil then begin Result := ''; exit; end;
  sw                           := new System.IO.StringWriter();
  xwSettings                   := new System.Xml.XmlWriterSettings();
  xwSettings.Indent            := true;
  xwSettings.IndentChars       := '  ';
  xwSettings.OmitXmlDeclaration:= true;
  xw := System.Xml.XmlWriter.Create(sw, xwSettings);
  fSurface.SaveDesigner(xw);
  xw.Flush();
  Result := sw.ToString();
end;

procedure Form1.SyncXamlEditor;
var
  designerXml, currentXaml, innerXml, newXaml: string;
  doc : System.Xml.XmlDocument;
begin
  if fLoadingXaml then exit;
  designerXml := SaveDesignerToString();
  if designerXml = '' then exit;

  currentXaml := fXamlEditor.Text;
  var trimCurrent := currentXaml.TrimStart();

  if trimCurrent.StartsWith('<Window') or trimCurrent.StartsWith('<UserControl') then
  begin
    try
      doc := new System.Xml.XmlDocument();
      doc.LoadXml(designerXml);
      innerXml := doc.DocumentElement.InnerXml;
    except
      fXamlEditor.Text := currentXaml; exit;
    end;

    try
      var fullDoc  := new System.Xml.XmlDocument();
      fullDoc.LoadXml(currentXaml);
      var fullRoot := fullDoc.DocumentElement;

      var toRemove := new System.Collections.Generic.List<System.Xml.XmlNode>();
      var child : System.Xml.XmlNode;
      foreach child in fullRoot.ChildNodes do
        if not child.LocalName.Contains('.') then toRemove.Add(child);
      var n: System.Xml.XmlNode;
      foreach n in toRemove do fullRoot.RemoveChild(n);

      if innerXml.Trim() <> '' then
      begin
        var tempDoc := new System.Xml.XmlDocument();
        tempDoc.LoadXml(
          '<r xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
          ' xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' +
          innerXml + '</r>');
        var imp: System.Xml.XmlNode;
        foreach imp in tempDoc.DocumentElement.ChildNodes do
          fullRoot.AppendChild(fullDoc.ImportNode(imp, true));
      end;

      var sw2      := new System.IO.StringWriter();
      var xws2     := new System.Xml.XmlWriterSettings();
      xws2.Indent  := true; xws2.IndentChars := '    ';
      xws2.OmitXmlDeclaration := true;
      var xw2 := System.Xml.XmlWriter.Create(sw2, xws2);
      fullDoc.WriteTo(xw2); xw2.Flush();
      newXaml := sw2.ToString();

      fOriginalXaml    := newXaml;
      fXamlEditor.Text := newXaml;
    except
      fXamlEditor.Text := designerXml;
    end;
  end
  else
  begin
    fOriginalXaml    := designerXml;
    fXamlEditor.Text := designerXml;
  end;

  if (fFoldingManager <> nil) and menuItemFolding.Checked then
    UpdateFolding();
end;

// =============================================================================
// XAML 폴딩
// =============================================================================
procedure Form1.UpdateFolding;
begin
  if (fFoldingManager = nil) or (fFoldingStrategy = nil) then exit;
  try fFoldingStrategy.UpdateFoldings(fFoldingManager, fXamlEditor.Document);
  except end;
end;

procedure Form1.OnFoldingTimerTick(sender: System.Object; e: System.EventArgs);
begin fFoldingTimer.Stop(); UpdateFolding(); end;

procedure Form1.EnableFolding;
begin
  if fFoldingManager = nil then
  begin
    fFoldingManager  := ICSharpCode.AvalonEdit.Folding.FoldingManager.Install(fXamlEditor.TextArea);
    fFoldingStrategy := new ICSharpCode.AvalonEdit.Folding.XmlFoldingStrategy();
  end;
  UpdateFolding();
  fFoldingTimer.Start();
end;

procedure Form1.DisableFolding;
begin
  fFoldingTimer.Stop();
  if fFoldingManager <> nil then
  begin
    ICSharpCode.AvalonEdit.Folding.FoldingManager.Uninstall(fFoldingManager);
    fFoldingManager := nil; fFoldingStrategy := nil;
  end;
end;

procedure Form1.OnXamlTextChanged(sender: System.Object; e: System.EventArgs);
begin
  if (fFoldingManager <> nil) and menuItemFolding.Checked then
  begin fFoldingTimer.Stop(); fFoldingTimer.Start(); end;
end;

// =============================================================================
// 보기 메뉴 토글
// =============================================================================
procedure Form1.OnToggleLineNumbers(sender: System.Object; e: System.EventArgs);
begin
  fOptions.XamlShowLineNum    := menuItemLineNum.Checked;
  fOptions.CodeShowLineNum    := menuItemLineNum.Checked;
  fXamlEditor.ShowLineNumbers := menuItemLineNum.Checked;
  fCodeEditor.ShowLineNumbers := menuItemLineNum.Checked;
end;

procedure Form1.OnToggleHighlight(sender: System.Object; e: System.EventArgs);
begin
  fOptions.XamlHighlight := menuItemHighlight.Checked;
  if menuItemHighlight.Checked then
    fXamlEditor.SyntaxHighlighting :=
      ICSharpCode.AvalonEdit.Highlighting.HighlightingManager.Instance.GetDefinition('XML')
  else
    fXamlEditor.SyntaxHighlighting := nil;
end;

procedure Form1.OnToggleWordWrap(sender: System.Object; e: System.EventArgs);
begin
  fOptions.WordWrap    := menuItemWordWrap.Checked;
  fXamlEditor.WordWrap := menuItemWordWrap.Checked;
  fCodeEditor.WordWrap := menuItemWordWrap.Checked;
end;

procedure Form1.OnToggleFolding(sender: System.Object; e: System.EventArgs);
begin
  fOptions.XamlFolding := menuItemFolding.Checked;
  if menuItemFolding.Checked then EnableFolding() else DisableFolding();
end;

// ★ 변경: SplitContainer 분할 방향 토글 → DockPanelSuite 레이아웃 초기화로 대체.
//   왼쪽/오른쪽/하단 패널을 모두 Auto-Hide 해제하고 기본 위치로 되돌려
//   "각 DockPanel을 최소화하면 중앙이 확장된다"는 동작을 언제든 원상복구할 수 있게 한다.
procedure Form1.OnResetLayout(sender: System.Object; e: System.EventArgs);
begin
  if dockPanel = nil then exit;
  dockToolbox.DockState    := DockState.DockLeft;
  dockExplorer.DockState   := DockState.DockRight;
  dockProperties.DockState := DockState.DockRight;
  dockOutput.DockState     := DockState.DockBottom;
  dockErrors.DockState     := DockState.DockBottom;

  // 오른쪽: 탐색기 위 / 속성 아래로 다시 쌓기
  dockProperties.Show(dockExplorer.Pane, DockAlignment.Bottom, 0.5);
  // 하단: 출력 / 오류 목록을 같은 탭 그룹으로
  dockErrors.Show(dockOutput.Pane, nil);

  dockToolbox.Width  := 220;
  dockExplorer.Width := 260;
  dockOutput.Height  := 200;
end;

// =============================================================================
// KillPreviousBuildProcesses
// =============================================================================
procedure Form1.KillPreviousBuildProcesses;
var
  exeNameOnly: string;
  procs      : array of System.Diagnostics.Process;
  idx        : integer;
begin
  if fBuildProcess <> nil then
  begin
    try if not fBuildProcess.HasExited then fBuildProcess.Kill(); except end;
    fBuildProcess := nil;
  end;
  try
    procs := System.Diagnostics.Process.GetProcessesByName('pabcnetc');
    for idx := 0 to procs.Length - 1 do
    try if not procs[idx].HasExited then procs[idx].Kill(); except end;
  except end;

  if fRunningProcess <> nil then
  begin
    try if not fRunningProcess.HasExited then fRunningProcess.Kill(); except end;
    fRunningProcess := nil;
  end;
  try
    exeNameOnly := System.IO.Path.GetFileNameWithoutExtension(fPasFileName);
    procs := System.Diagnostics.Process.GetProcessesByName(exeNameOnly);
    for idx := 0 to procs.Length - 1 do
    try
      if not procs[idx].HasExited then
      begin procs[idx].Kill(); procs[idx].WaitForExit(2000); end;
    except end;
  except end;
  try
    var hostName := System.IO.Path.GetFileNameWithoutExtension(fPasFileName) + '_TestHost';
    procs := System.Diagnostics.Process.GetProcessesByName(hostName);
    for idx := 0 to procs.Length - 1 do
    try
      if not procs[idx].HasExited then
      begin procs[idx].Kill(); procs[idx].WaitForExit(2000); end;
    except end;
  except end;
  System.Threading.Thread.Sleep(200);
end;

// =============================================================================
// FindPabcCompiler
// =============================================================================
function Form1.FindPabcCompiler: string;
var
  candidates: array of string;
  path      : string;
begin
  Result := '';
  try
    var regPath := System.Convert.ToString(
      Microsoft.Win32.Registry.GetValue(
        'HKEY_LOCAL_MACHINE\SOFTWARE\PascalABC.NET', 'InstallDir', ''));
    if (regPath <> '') and System.IO.File.Exists(regPath + '\pabcnetc.exe') then
    begin Result := regPath + '\pabcnetc.exe'; exit; end;
  except end;

  candidates := [
    'C:\Program Files\PascalABC.NET\pabcnetc.exe',
    'C:\Program Files (x86)\PascalABC.NET\pabcnetc.exe',
    System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData) +
      '\PascalABC.NET\pabcnetc.exe',
    System.AppDomain.CurrentDomain.BaseDirectory + 'pabcnetc.exe'
  ];
  foreach path in candidates do
    if System.IO.File.Exists(path) then begin Result := path; exit; end;

  try
    var psi := new System.Diagnostics.ProcessStartInfo();
    psi.FileName               := 'where';
    psi.Arguments              := 'pabcnetc.exe';
    psi.UseShellExecute        := false;
    psi.RedirectStandardOutput := true;
    psi.CreateNoWindow         := true;
    var proc   := System.Diagnostics.Process.Start(psi);
    var output := proc.StandardOutput.ReadToEnd().Trim();
    proc.WaitForExit();
    if output <> '' then
    begin
      var first := output.Split([#13, #10])[0];
      if System.IO.File.Exists(first) then Result := first;
    end;
  except end;
end;

// =============================================================================
// 오류 목록
// =============================================================================
procedure Form1.OnErrorsCopy(sender: System.Object; e: System.EventArgs);
var
  sb  : System.Text.StringBuilder;
  item: System.Windows.Forms.ListViewItem;
begin
  if lvErrors.SelectedItems.Count = 0 then exit;
  sb := new System.Text.StringBuilder();
  foreach item in lvErrors.SelectedItems do
  begin
    sb.Append(item.Text); sb.Append(#9);
    if item.SubItems.Count > 1 then sb.Append(item.SubItems[1].Text);
    sb.Append(#9);
    if item.SubItems.Count > 2 then sb.Append(item.SubItems[2].Text);
    sb.AppendLine();
  end;
  System.Windows.Forms.Clipboard.SetText(sb.ToString());
end;

procedure Form1.OnErrorsKeyDown(sender: System.Object;
  e: System.Windows.Forms.KeyEventArgs);
begin
  if e.Control and (e.KeyCode = System.Windows.Forms.Keys.C) then
  begin OnErrorsCopy(sender, System.EventArgs.Empty); e.Handled := true; end
  else if e.Control and (e.KeyCode = System.Windows.Forms.Keys.A) then
  begin
    var i: integer;
    for i := 0 to lvErrors.Items.Count - 1 do
      lvErrors.Items[i].Selected := true;
    e.Handled := true;
  end;
end;

procedure Form1.ShowBuildErrors(output: string);
var
  lines : array of string;
  line  : string;
  item  : System.Windows.Forms.ListViewItem;
  re    : System.Text.RegularExpressions.Regex;
  m     : System.Text.RegularExpressions.Match;
begin
  lvErrors.Items.Clear();
  if output.Trim() = '' then
  begin
    item := new System.Windows.Forms.ListViewItem('빌드 실패 — 출력 탭을 확인하세요.');
    item.ForeColor := System.Drawing.Color.Red;
    lvErrors.Items.Add(item);
    exit;
  end;
  re    := new System.Text.RegularExpressions.Regex('([^(]+)\((\d+)\)\s*:\s*(.+)');
  lines := output.Split([#13, #10]);
  foreach line in lines do
  begin
    if line.Trim() = '' then continue;
    if line.StartsWith('======') then continue;
    m := re.Match(line.Trim());
    if m.Success then
    begin
      item := new System.Windows.Forms.ListViewItem(m.Groups[3].Value);
      item.SubItems.Add(m.Groups[2].Value);
      item.SubItems.Add(m.Groups[1].Value);
      item.ForeColor := System.Drawing.Color.Red;
      lvErrors.Items.Add(item);
    end;
  end;
  if lvErrors.Items.Count = 0 then
  begin
    item := new System.Windows.Forms.ListViewItem('빌드 실패 — 출력 탭에서 전체 로그를 확인하세요.');
    item.ForeColor := System.Drawing.Color.Red;
    lvErrors.Items.Add(item);
  end;
end;

// =============================================================================
// 솔루션 탐색기
// =============================================================================
procedure Form1.RefreshSolutionExplorer;
var
  rootNode, projNode, fileNode: System.Windows.Forms.TreeNode;
  files: array of string;
  f, ext, fname, icon: string;
begin
  if trvSolution = nil then exit;
  trvSolution.BeginUpdate();
  trvSolution.Nodes.Clear();
  rootNode     := new System.Windows.Forms.TreeNode(
    '솔루션 ' + #39 + fNamespace + #39 + ' (1개 프로젝트)');
  projNode     := new System.Windows.Forms.TreeNode(fNamespace);
  projNode.Tag := fProjectPath;

  if System.IO.Directory.Exists(fProjectPath) then
  try
    files := System.IO.Directory.GetFiles(fProjectPath);
    System.Array.Sort(files);
    foreach f in files do
    begin
      ext   := System.IO.Path.GetExtension(f).ToLower();
      fname := System.IO.Path.GetFileName(f);
      case ext of
        '.xaml': icon := '📄 ';
        '.pas' : icon := '💻 ';
        '.exe' : icon := '⚙ ';
        '.dll' : icon := '📦 ';
        '.pcu' : icon := '🗃 ';
      else icon := '   ';
      end;
      fileNode     := new System.Windows.Forms.TreeNode(icon + fname);
      fileNode.Tag := f;
      projNode.Nodes.Add(fileNode);
    end;
  except end;

  rootNode.Nodes.Add(projNode);
  trvSolution.Nodes.Add(rootNode);
  rootNode.Expand(); projNode.Expand();
  trvSolution.EndUpdate();
end;

procedure Form1.OnSolutionExplorerDoubleClick(sender: System.Object;
  e: System.Windows.Forms.TreeNodeMouseClickEventArgs);
var path, ext: string;
begin
  if (e.Node = nil) or (e.Node.Tag = nil) then exit;
  path := e.Node.Tag.ToString();
  if not System.IO.File.Exists(path) then exit;
  ext := System.IO.Path.GetExtension(path).ToLower();
  if (ext = '.xaml') and
     (System.IO.Path.GetFileName(path).ToLower() = fXamlFileName.ToLower()) then
    tabControl.SelectedTab := tabDesignXaml
  else if (ext = '.pas') and
          (System.IO.Path.GetFileName(path).ToLower() = fPasFileName.ToLower()) then
    tabControl.SelectedTab := tabCode
  else
  try System.Diagnostics.Process.Start('explorer.exe', '/select,"' + path + '"');
  except end;
end;

procedure Form1.OnSolutionExplorerRefresh(sender: System.Object; e: System.EventArgs);
begin RefreshSolutionExplorer(); end;

procedure Form1.OnSolutionExplorerShowInFolder(sender: System.Object; e: System.EventArgs);
var path: string;
begin
  if (trvSolution.SelectedNode = nil) or (trvSolution.SelectedNode.Tag = nil) then exit;
  path := trvSolution.SelectedNode.Tag.ToString();
  try
    if System.IO.File.Exists(path) then
      System.Diagnostics.Process.Start('explorer.exe', '/select,"' + path + '"')
    else if System.IO.Directory.Exists(path) then
      System.Diagnostics.Process.Start('explorer.exe', '"' + path + '"');
  except end;
end;

// =============================================================================
// 메뉴 빌드
// =============================================================================
procedure Form1.BuildMenu;
var
  fileMenu, viewMenu, buildMenu, projMenu, helpMenu: System.Windows.Forms.ToolStripMenuItem;
  newItem, openItem, saveItem, applyItem, syncItem  : System.Windows.Forms.ToolStripMenuItem;
  buildItem, runItem, aboutItem, projOptItem         : System.Windows.Forms.ToolStripMenuItem;
  toolboxViewItem, explorerViewItem, propsViewItem   : System.Windows.Forms.ToolStripMenuItem;
  outputViewItem, errorsViewItem                     : System.Windows.Forms.ToolStripMenuItem;
begin
  menuStrip := new System.Windows.Forms.MenuStrip();

  // 파일
  fileMenu := new System.Windows.Forms.ToolStripMenuItem('파일(&F)');
  newItem  := new System.Windows.Forms.ToolStripMenuItem('새 프로젝트(&N)...');
  openItem := new System.Windows.Forms.ToolStripMenuItem('열기(&O)...');
  saveItem := new System.Windows.Forms.ToolStripMenuItem('저장(&S)');
  newItem.Click  += OnNewProject;
  openItem.Click += OnOpen;
  saveItem.Click += OnSave;
  fileMenu.DropDownItems.Add(newItem);
  fileMenu.DropDownItems.Add(openItem);
  fileMenu.DropDownItems.Add(saveItem);

  // 프로젝트
  projMenu    := new System.Windows.Forms.ToolStripMenuItem('프로젝트(&P)');
  projOptItem := new System.Windows.Forms.ToolStripMenuItem('프로젝트 옵션(&O)...    Alt+Enter');
  projOptItem.Click += OnProjectOptions;
  projMenu.DropDownItems.Add(projOptItem);

  // 보기
  viewMenu  := new System.Windows.Forms.ToolStripMenuItem('보기(&V)');
  applyItem := new System.Windows.Forms.ToolStripMenuItem('XAML 적용(&Y)');
  syncItem  := new System.Windows.Forms.ToolStripMenuItem('XAML 동기화(&X)');
  applyItem.Click += OnApplyXamlMenu;
  syncItem.Click  += OnSyncXamlMenu;
  
  viewMenu.DropDownItems.Add(applyItem);
  viewMenu.DropDownItems.Add(syncItem);
  viewMenu.DropDownItems.Add(new System.Windows.Forms.ToolStripSeparator());

  var splitOrientItem := new System.Windows.Forms.ToolStripMenuItem('디자인/XAML 분할 전환(&Z)');
  splitOrientItem.Click += (sender, e) ->
    begin
      if splitDesignXaml = nil then exit;
      if splitDesignXaml.Orientation = System.Windows.Forms.Orientation.Vertical then
        splitDesignXaml.Orientation := System.Windows.Forms.Orientation.Horizontal
      else
        splitDesignXaml.Orientation := System.Windows.Forms.Orientation.Vertical;
    end;
  viewMenu.DropDownItems.Add(splitOrientItem);
  viewMenu.DropDownItems.Add(new System.Windows.Forms.ToolStripSeparator());    

  // ★ 변경: 분할 방향 토글 → 도킹 패널 표시/숨김 메뉴로 교체
  toolboxViewItem        := new System.Windows.Forms.ToolStripMenuItem('도구 상자(&T)');
  toolboxViewItem.Click  += (sender, e) -> //procedure(sender: System.Object; e: System.EventArgs)
    begin
      if dockToolbox <> nil then begin dockToolbox.Show(); dockToolbox.Activate(); end;
    end;

  explorerViewItem       := new System.Windows.Forms.ToolStripMenuItem('솔루션 탐색기(&E)');
  explorerViewItem.Click += (sender, e) -> //procedure(sender: System.Object; e: System.EventArgs)
    begin
      if dockExplorer <> nil then begin dockExplorer.Show(); dockExplorer.Activate(); end;
    end;
  propsViewItem          := new System.Windows.Forms.ToolStripMenuItem('속성(&P)');
  propsViewItem.Click    += (sender, e) -> //procedure(sender: System.Object; e: System.EventArgs)
    begin
      if dockProperties <> nil then begin dockProperties.Show(); dockProperties.Activate(); end;
    end;
  outputViewItem         := new System.Windows.Forms.ToolStripMenuItem('출력(&O)');
  outputViewItem.Click   += (sender, e) -> //procedure(sender: System.Object; e: System.EventArgs)
    begin
      if dockOutput <> nil then begin dockOutput.Show(); dockOutput.Activate(); end;
    end;
  errorsViewItem         := new System.Windows.Forms.ToolStripMenuItem('오류 목록(&R)');
  errorsViewItem.Click   += (sender, e) -> //procedure(sender: System.Object; e: System.EventArgs)
    begin
      if dockErrors <> nil then begin dockErrors.Show(); dockErrors.Activate(); end;
    end;
  viewMenu.DropDownItems.Add(toolboxViewItem);
  viewMenu.DropDownItems.Add(explorerViewItem);
  viewMenu.DropDownItems.Add(propsViewItem);
  viewMenu.DropDownItems.Add(outputViewItem);
  viewMenu.DropDownItems.Add(errorsViewItem);
  viewMenu.DropDownItems.Add(new System.Windows.Forms.ToolStripSeparator());

  menuItemResetLayout       := new System.Windows.Forms.ToolStripMenuItem('레이아웃 초기화(&L)');
  menuItemResetLayout.Click += OnResetLayout;
  viewMenu.DropDownItems.Add(menuItemResetLayout);
  viewMenu.DropDownItems.Add(new System.Windows.Forms.ToolStripSeparator());

  menuItemLineNum              := new System.Windows.Forms.ToolStripMenuItem('라인 번호(&L)');
  menuItemLineNum.CheckOnClick := true;
  menuItemLineNum.Checked      := true;
  menuItemLineNum.Click        += OnToggleLineNumbers;
  viewMenu.DropDownItems.Add(menuItemLineNum);

  menuItemHighlight              := new System.Windows.Forms.ToolStripMenuItem('구문 강조(&I)');
  menuItemHighlight.CheckOnClick := true;
  menuItemHighlight.Checked      := true;
  menuItemHighlight.Click        += OnToggleHighlight;
  viewMenu.DropDownItems.Add(menuItemHighlight);

  menuItemWordWrap              := new System.Windows.Forms.ToolStripMenuItem('자동 줄바꿈(&W)');
  menuItemWordWrap.CheckOnClick := true;
  menuItemWordWrap.Checked      := false;
  menuItemWordWrap.Click        += OnToggleWordWrap;
  viewMenu.DropDownItems.Add(menuItemWordWrap);

  menuItemFolding              := new System.Windows.Forms.ToolStripMenuItem('XML 폴딩(&D)');
  menuItemFolding.CheckOnClick := true;
  menuItemFolding.Checked      := true;
  menuItemFolding.Click        += OnToggleFolding;
  viewMenu.DropDownItems.Add(menuItemFolding);

  // 빌드
  buildMenu := new System.Windows.Forms.ToolStripMenuItem('빌드(&B)');
  buildItem := new System.Windows.Forms.ToolStripMenuItem('빌드(&B)    F6');
  runItem   := new System.Windows.Forms.ToolStripMenuItem('실행(&R)    F5');
  buildItem.Click += OnBuild;
  runItem.Click   += OnRun;
  buildMenu.DropDownItems.Add(buildItem);
  buildMenu.DropDownItems.Add(runItem);

  // 도움말
  helpMenu        := new System.Windows.Forms.ToolStripMenuItem('도움말(&H)');
  aboutItem       := new System.Windows.Forms.ToolStripMenuItem('정보(&A)...');
  aboutItem.Click += OnAbout;
  helpMenu.DropDownItems.Add(aboutItem);

  menuStrip.Items.Add(fileMenu);
  menuStrip.Items.Add(projMenu);
  menuStrip.Items.Add(viewMenu);
  menuStrip.Items.Add(buildMenu);
  menuStrip.Items.Add(helpMenu);
  Self.Controls.Add(menuStrip);
  Self.MainMenuStrip := menuStrip;

  Self.KeyPreview := true;
  Self.KeyDown    += FormKeyDown;
end;

// =============================================================================
// 툴박스
// =============================================================================
procedure Form1.BuildToolbox;
var
  scroll      : System.Windows.Controls.ScrollViewer;
  title       : System.Windows.Controls.TextBlock;
  expLayout   : System.Windows.Controls.Expander;
  expCommon   : System.Windows.Controls.Expander;
  panelLayout : System.Windows.Controls.StackPanel;
  panelCommon : System.Windows.Controls.StackPanel;

  procedure AddBtn(panel: System.Windows.Controls.StackPanel;
                   name: string; typeName: string);
  var
    btn  : System.Windows.Controls.Button;
    sp   : System.Windows.Controls.StackPanel;
    icon : System.Windows.Controls.TextBlock;
    lbl  : System.Windows.Controls.TextBlock;
  begin
    sp             := new System.Windows.Controls.StackPanel();
    sp.Orientation := System.Windows.Controls.Orientation.Horizontal;
    icon                   := new System.Windows.Controls.TextBlock();
    icon.FontFamily        := new System.Windows.Media.FontFamily('Segoe UI Symbol');
    icon.FontSize          := 13;
    icon.Width             := 20;
    icon.TextAlignment     := System.Windows.TextAlignment.Center;
    icon.VerticalAlignment := System.Windows.VerticalAlignment.Center;
    icon.Margin            := new System.Windows.Thickness(2, 0, 4, 0);
    case name of
      'Grid'        : icon.Text := '▦';
      'StackPanel'  : icon.Text := '☰';
      'Canvas'      : icon.Text := '▭';
      'DockPanel'   : icon.Text := '⊞';
      'WrapPanel'   : icon.Text := '⊡';
      'Button'      : icon.Text := '⬜';
      'TextBox'     : icon.Text := '▤';
      'Label'       : icon.Text := 'A';
      'CheckBox'    : icon.Text := '☑';
      'ComboBox'    : icon.Text := '⊟';
      'ListBox'     : icon.Text := '≡';
      'ListView'    : icon.Text := '⊟';
      'TreeView'    : icon.Text := '⊞';
      'Image'       : icon.Text := '▨';
      'TextBlock'   : icon.Text := 'T';
      'Slider'      : icon.Text := '⊸';
      'ProgressBar' : icon.Text := '▬';
      'RadioButton' : icon.Text := '◎';
      'Border'      : icon.Text := '▢';
      'ScrollViewer': icon.Text := '↕';
      'TabControl'  : icon.Text := '⊞';
      'GroupBox'    : icon.Text := '▭';
      'Expander'    : icon.Text := '▼';
      'DataGrid'    : icon.Text := '▦';
      'DatePicker'  : icon.Text := '📅';
      'PasswordBox' : icon.Text := '●';
    else icon.Text := '◆';
    end;
    lbl                   := new System.Windows.Controls.TextBlock();
    lbl.Text              := name;
    lbl.FontSize          := 12;
    lbl.VerticalAlignment := System.Windows.VerticalAlignment.Center;
    sp.Children.Add(icon); sp.Children.Add(lbl);
    btn                            := new System.Windows.Controls.Button();
    btn.Content                    := sp;
    btn.Tag                        := typeName;
    btn.Margin                     := new System.Windows.Thickness(1);
    btn.Padding                    := new System.Windows.Thickness(4, 3, 4, 3);
    btn.HorizontalAlignment        := System.Windows.HorizontalAlignment.Stretch;
    btn.HorizontalContentAlignment := System.Windows.HorizontalAlignment.Left;
    btn.BorderThickness            := new System.Windows.Thickness(0);
    btn.Background                 := System.Windows.Media.Brushes.Transparent;
    btn.Click                      += OnToolboxClick;
    panel.Children.Add(btn);
  end;

  function MakeExpander(header: string): System.Windows.Controls.Expander;
  var hdr: System.Windows.Controls.TextBlock;
  begin
    hdr            := new System.Windows.Controls.TextBlock();
    hdr.Text       := header;
    hdr.FontWeight := System.Windows.FontWeights.Bold;
    hdr.FontSize   := 12;
    Result            := new System.Windows.Controls.Expander();
    Result.Header     := hdr;
    Result.IsExpanded := true;
    Result.Margin     := new System.Windows.Thickness(0, 2, 0, 2);
  end;

begin
  fToolboxPanel            := new System.Windows.Controls.StackPanel();
  fToolboxPanel.Background := System.Windows.Media.Brushes.White;

  title            := new System.Windows.Controls.TextBlock();
  title.Text       := '도구 상자';
  title.FontSize   := 13;
  title.FontWeight := System.Windows.FontWeights.Bold;
  title.Padding    := new System.Windows.Thickness(6);
  title.Background := new System.Windows.Media.SolidColorBrush(
    System.Windows.Media.Color.FromRgb(240, 240, 240));
  fToolboxPanel.Children.Add(title);

  panelLayout        := new System.Windows.Controls.StackPanel();
  panelLayout.Margin := new System.Windows.Thickness(8, 2, 0, 2);
  AddBtn(panelLayout, 'Grid',         'System.Windows.Controls.Grid');
  AddBtn(panelLayout, 'StackPanel',   'System.Windows.Controls.StackPanel');
  AddBtn(panelLayout, 'Canvas',       'System.Windows.Controls.Canvas');
  AddBtn(panelLayout, 'DockPanel',    'System.Windows.Controls.DockPanel');
  AddBtn(panelLayout, 'WrapPanel',    'System.Windows.Controls.WrapPanel');
  AddBtn(panelLayout, 'ScrollViewer', 'System.Windows.Controls.ScrollViewer');
  expLayout         := MakeExpander('레이아웃');
  expLayout.Content := panelLayout;
  fToolboxPanel.Children.Add(expLayout);

  panelCommon        := new System.Windows.Controls.StackPanel();
  panelCommon.Margin := new System.Windows.Thickness(8, 2, 0, 2);
  AddBtn(panelCommon, 'Button',      'System.Windows.Controls.Button');
  AddBtn(panelCommon, 'TextBox',     'System.Windows.Controls.TextBox');
  AddBtn(panelCommon, 'TextBlock',   'System.Windows.Controls.TextBlock');
  AddBtn(panelCommon, 'Label',       'System.Windows.Controls.Label');
  AddBtn(panelCommon, 'CheckBox',    'System.Windows.Controls.CheckBox');
  AddBtn(panelCommon, 'RadioButton', 'System.Windows.Controls.RadioButton');
  AddBtn(panelCommon, 'ComboBox',    'System.Windows.Controls.ComboBox');
  AddBtn(panelCommon, 'ListBox',     'System.Windows.Controls.ListBox');
  AddBtn(panelCommon, 'ListView',    'System.Windows.Controls.ListView');
  AddBtn(panelCommon, 'TreeView',    'System.Windows.Controls.TreeView');
  AddBtn(panelCommon, 'DataGrid',    'System.Windows.Controls.DataGrid');
  AddBtn(panelCommon, 'Image',       'System.Windows.Controls.Image');
  AddBtn(panelCommon, 'Slider',      'System.Windows.Controls.Slider');
  AddBtn(panelCommon, 'ProgressBar', 'System.Windows.Controls.ProgressBar');
  AddBtn(panelCommon, 'Border',      'System.Windows.Controls.Border');
  AddBtn(panelCommon, 'TabControl',  'System.Windows.Controls.TabControl');
  AddBtn(panelCommon, 'GroupBox',    'System.Windows.Controls.GroupBox');
  AddBtn(panelCommon, 'Expander',    'System.Windows.Controls.Expander');
  AddBtn(panelCommon, 'DatePicker',  'System.Windows.Controls.DatePicker');
  AddBtn(panelCommon, 'PasswordBox', 'System.Windows.Controls.PasswordBox');
  expCommon         := MakeExpander('공용 컨트롤');
  expCommon.Content := panelCommon;
  fToolboxPanel.Children.Add(expCommon);

  scroll         := new System.Windows.Controls.ScrollViewer();
  scroll.Content := fToolboxPanel;
  scroll.VerticalScrollBarVisibility := System.Windows.Controls.ScrollBarVisibility.Auto;
  hostLeft       := new System.Windows.Forms.Integration.ElementHost();
  hostLeft.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostLeft.Child := scroll;
end;

// =============================================================================
// 레이아웃 빌드 (DockPanelSuite 기반)
// =============================================================================
// ★ 변경: 기존 splitMain/splitDesign/splitRight/splitExplorerProps (SplitContainer 4개)를
//   전부 제거하고 DockPanelSuite의 DockPanel + 6개 DockContent로 재구성한다.
//
//   - hostRight(속성), trvSolution(솔루션 탐색기), txtOutput(출력), lvErrors(오류 목록)는
//     기존과 동일하게 생성하되, SplitContainer.Panel.Controls.Add(...) 대신
//     각각의 DockContent 생성자에 그대로 전달한다.
//   - hostDesign / hostXaml / hostCode / tabControl(디자인+XAML, 코드 탭)은
//     splitDesignXaml에 묶인 그대로 두고, 그 tabControl 전체를
//     TMainDocumentDock(중앙 고정 문서 영역)에 넣는다.
//   - 각 DockContent를 Hide()(Auto-Hide) 시키면 DockPanelSuite가 자동으로
//     중앙 Document 영역(tabControl)을 확장해준다 — SplitContainer로는
//     불가능했던 부분.
procedure Form1.BuildLayout;
begin
  // 내부적으로 실제 컨트롤들을 만들고 DockPanelSuite로 배치한다.
  BuildDockLayout();
end;

procedure Form1.BuildDockLayout;
var
  editorGrid    : System.Windows.Controls.Grid;
  editorRow0, editorRow1 : System.Windows.Controls.RowDefinition;
  applyBtn      : System.Windows.Controls.Button;
  colMsg, colLine, colFile: System.Windows.Forms.ColumnHeader;
  mainPanel     : System.Windows.Forms.Panel;
begin
  // ── 속성 그리드 (WPF PropertyGridView → ElementHost) ───────────────────
  fPropView       := new ICSharpCode.WpfDesign.Designer.PropertyGrid.PropertyGridView();
  hostRight       := new System.Windows.Forms.Integration.ElementHost();
  hostRight.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostRight.Child := fPropView;

  // ── 솔루션 탐색기 (TreeView) ─────────────────────────────────────────────
  trvSolution               := new System.Windows.Forms.TreeView();
  trvSolution.Dock          := System.Windows.Forms.DockStyle.Fill;
  trvSolution.Font          := new System.Drawing.Font('Segoe UI', 9);
  trvSolution.HideSelection := false;
  trvSolution.NodeMouseDoubleClick += OnSolutionExplorerDoubleClick;

  var ctxMenu          := new System.Windows.Forms.ContextMenuStrip();
  var refreshItem      := new System.Windows.Forms.ToolStripMenuItem('새로 고침(&R)');
  var showInFolderItem := new System.Windows.Forms.ToolStripMenuItem('파일 탐색기에서 보기(&E)');
  refreshItem.Click      += OnSolutionExplorerRefresh;
  showInFolderItem.Click += OnSolutionExplorerShowInFolder;
  ctxMenu.Items.Add(refreshItem);
  ctxMenu.Items.Add(showInFolderItem);
  trvSolution.ContextMenuStrip := ctxMenu;

  // ── 디자인 캔버스 (WPF DesignSurface → ElementHost) ─────────────────────
  hostDesign      := new System.Windows.Forms.Integration.ElementHost();
  hostDesign.Dock := System.Windows.Forms.DockStyle.Fill;

  // ── XAML 에디터 ─────────────────────────────────────────────────────────
  fXamlEditor                    := new ICSharpCode.AvalonEdit.TextEditor();
  fXamlEditor.FontFamily         := new System.Windows.Media.FontFamily(fOptions.FontName);
  fXamlEditor.FontSize           := fOptions.FontSize;
  fXamlEditor.ShowLineNumbers    := fOptions.XamlShowLineNum;
  fXamlEditor.SyntaxHighlighting :=
    ICSharpCode.AvalonEdit.Highlighting.HighlightingManager.Instance.GetDefinition('XML');
  fXamlEditor.WordWrap           := fOptions.WordWrap;
  fXamlEditor.HorizontalScrollBarVisibility := System.Windows.Controls.ScrollBarVisibility.Auto;
  fXamlEditor.VerticalScrollBarVisibility   := System.Windows.Controls.ScrollBarVisibility.Auto;

  editorGrid        := new System.Windows.Controls.Grid();
  editorRow0        := new System.Windows.Controls.RowDefinition();
  editorRow0.Height := System.Windows.GridLength.Auto;
  editorRow1        := new System.Windows.Controls.RowDefinition();
  editorRow1.Height := new System.Windows.GridLength(1, System.Windows.GridUnitType.Star);
  editorGrid.RowDefinitions.Add(editorRow0);
  editorGrid.RowDefinitions.Add(editorRow1);
  applyBtn         := new System.Windows.Controls.Button();
  applyBtn.Content := '▶ XAML 적용';
  applyBtn.Height  := 28;
  applyBtn.Margin  := new System.Windows.Thickness(0, 0, 0, 2);
  applyBtn.Click   += OnApplyXaml;
  System.Windows.Controls.Grid.SetRow(applyBtn, 0);
  editorGrid.Children.Add(applyBtn);
  System.Windows.Controls.Grid.SetRow(fXamlEditor, 1);
  editorGrid.Children.Add(fXamlEditor);
  hostXaml       := new System.Windows.Forms.Integration.ElementHost();
  hostXaml.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostXaml.Child := editorGrid;

  // ── 코드 에디터 ─────────────────────────────────────────────────────────
  fCodeEditor                    := new ICSharpCode.AvalonEdit.TextEditor();
  fCodeEditor.FontFamily         := new System.Windows.Media.FontFamily(fOptions.FontName);
  fCodeEditor.FontSize           := fOptions.FontSize;
  fCodeEditor.ShowLineNumbers    := fOptions.CodeShowLineNum;
  fCodeEditor.WordWrap           := fOptions.WordWrap;
  fCodeEditor.HorizontalScrollBarVisibility := System.Windows.Controls.ScrollBarVisibility.Auto;
  fCodeEditor.VerticalScrollBarVisibility   := System.Windows.Controls.ScrollBarVisibility.Auto;
  fCodeEditor.Options.IndentationSize     := fOptions.TabSize;
  fCodeEditor.Options.ConvertTabsToSpaces := not fOptions.UseTabs;
  hostCode       := new System.Windows.Forms.Integration.ElementHost();
  hostCode.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostCode.Child := fCodeEditor;

  // ── 디자인 + XAML 탭 내부의 좌우 분할 (디자인 캔버스 / XAML 에디터) ──────
  //   ※ 이 SplitContainer는 "메인 문서 영역 내부"의 분할이므로 유지한다.
  //   DockPanelSuite로 교체 대상은 왼쪽 툴박스 / 오른쪽 탐색기·속성 / 하단
  //   출력·오류 목록이며, 탭 내부 구조는 요청 범위가 아니다.
  splitDesignXaml                  := new System.Windows.Forms.SplitContainer();
  splitDesignXaml.Dock             := System.Windows.Forms.DockStyle.Fill;
  splitDesignXaml.Orientation      := System.Windows.Forms.Orientation.Vertical;
  splitDesignXaml.SplitterDistance := 700;
  splitDesignXaml.Panel1.Controls.Add(hostDesign);
  splitDesignXaml.Panel2.Controls.Add(hostXaml);

  // ── 중앙 문서 탭: 디자인+XAML / 코드 ────────────────────────────────────
  tabControl      := new System.Windows.Forms.TabControl();
  tabControl.Dock := System.Windows.Forms.DockStyle.Fill;
  tabControl.SelectedIndexChanged += OnTabChanged;

  tabDesignXaml := new System.Windows.Forms.TabPage('🎨 디자인 + XAML');
  tabDesignXaml.Controls.Add(splitDesignXaml);
  tabCode := new System.Windows.Forms.TabPage('💻 코드');
  tabCode.Controls.Add(hostCode);
  tabControl.TabPages.Add(tabDesignXaml);
  tabControl.TabPages.Add(tabCode);

  // ── 오류 목록 (ListView) ─────────────────────────────────────────────────
  lvErrors               := new System.Windows.Forms.ListView();
  lvErrors.Dock          := System.Windows.Forms.DockStyle.Fill;
  lvErrors.View          := System.Windows.Forms.View.Details;
  lvErrors.FullRowSelect := true;
  lvErrors.GridLines     := true;
  lvErrors.MultiSelect   := true;
  lvErrors.Font          := new System.Drawing.Font('Consolas', 9);
  lvErrors.KeyDown       += OnErrorsKeyDown;
  var errMenu  := new System.Windows.Forms.ContextMenuStrip();
  var copyItem := new System.Windows.Forms.ToolStripMenuItem('복사(&C)' + #9 + 'Ctrl+C');
  copyItem.Click += OnErrorsCopy;
  errMenu.Items.Add(copyItem);
  lvErrors.ContextMenuStrip := errMenu;

  colMsg := new System.Windows.Forms.ColumnHeader();
  colMsg.Text := '오류 메시지'; colMsg.Width := 500;
  colLine := new System.Windows.Forms.ColumnHeader();
  colLine.Text := '줄'; colLine.Width := 60;
  colFile := new System.Windows.Forms.ColumnHeader();
  colFile.Text := '파일'; colFile.Width := 200;
  lvErrors.Columns.Add(colMsg);
  lvErrors.Columns.Add(colLine);
  lvErrors.Columns.Add(colFile);

  // ── 출력 (RichTextBox) ───────────────────────────────────────────────────
  txtOutput                := new System.Windows.Forms.RichTextBox();
  txtOutput.Dock           := System.Windows.Forms.DockStyle.Fill;
  txtOutput.ReadOnly       := true;
  txtOutput.BackColor      := System.Drawing.Color.FromArgb(30, 30, 30);
  txtOutput.ForeColor      := System.Drawing.Color.FromArgb(220, 220, 220);
  txtOutput.Font           := new System.Drawing.Font('Consolas', 9.5);
  txtOutput.BorderStyle    := System.Windows.Forms.BorderStyle.None;
  txtOutput.WordWrap       := true;
  txtOutput.HideSelection  := false;
  var outMenu  := new System.Windows.Forms.ContextMenuStrip();
  var outCopy  := new System.Windows.Forms.ToolStripMenuItem('복사(&C)' + #9 + 'Ctrl+C');
  var outClear := new System.Windows.Forms.ToolStripMenuItem('지우기(&L)');
  outCopy.Click  += OnOutputCopy;
  outClear.Click += OnOutputClear;
  outMenu.Items.Add(outCopy); outMenu.Items.Add(outClear);
  txtOutput.ContextMenuStrip := outMenu;

  // ── DockPanelSuite 메인 패널 생성 ────────────────────────────────────────
  dockPanel              := new WeifenLuo.WinFormsUI.Docking.DockPanel();
  dockPanel.Dock         := System.Windows.Forms.DockStyle.Fill;
  dockPanel.DocumentStyle := DocumentStyle.DockingWindow;  // Document 영역도 일반 도킹창처럼 동작
  dockPanel.Theme        := new WeifenLuo.WinFormsUI.Docking.VS2015LightTheme();

  mainPanel      := new System.Windows.Forms.Panel();
  mainPanel.Dock := System.Windows.Forms.DockStyle.Fill;
  mainPanel.Controls.Add(dockPanel);
  Self.Controls.Add(mainPanel);

  // ── 6개 DockContent 생성 및 배치 ─────────────────────────────────────────
  // 1) 중앙 문서 영역: 항상 고정, 닫기/Auto-Hide 불가
  dockMain := new TMainDocumentDock(tabControl);
  dockMain.Show(dockPanel, DockState.Document);

  // 2) 왼쪽: 도구 상자
  dockToolbox := new TToolboxDock(hostLeft);
  dockToolbox.Show(dockPanel, DockState.DockLeft);
  dockToolbox.Width := 220;

  // 3) 오른쪽 위: 솔루션 탐색기
  dockExplorer := new TSolutionExplorerDock(trvSolution);
  dockExplorer.Show(dockPanel, DockState.DockRight);
  dockExplorer.Width := 260;

  // 4) 오른쪽 아래: 속성 그리드 (탐색기 바로 아래에 쌓기)
  dockProperties := new TPropertyGridDock(hostRight);
  dockProperties.Show(dockExplorer.Pane, DockAlignment.Bottom, 0.5);

  // 5) 하단: 출력
  dockOutput := new TOutputDock(txtOutput);
  dockOutput.Show(dockPanel, DockState.DockBottom);
  dockOutput.Height := 200;

  // 6) 하단: 오류 목록 (출력과 같은 탭 그룹으로 묶기)
  dockErrors := new TErrorListDock(lvErrors);
  dockErrors.Show(dockOutput.Pane, nil);

  // ── XAML 폴딩 타이머 ─────────────────────────────────────────────────────
  fFoldingTimer          := new System.Windows.Threading.DispatcherTimer();
  fFoldingTimer.Interval := System.TimeSpan.FromMilliseconds(500);
  fFoldingTimer.Tick     += OnFoldingTimerTick;
  fXamlEditor.TextChanged += OnXamlTextChanged;

  // ── 코드 폴딩 타이머 ─────────────────────────────────────────────────────
  fCodeFoldingTimer          := new System.Windows.Threading.DispatcherTimer();
  fCodeFoldingTimer.Interval := System.TimeSpan.FromMilliseconds(800);
  fCodeFoldingTimer.Tick     += OnCodeFoldingTimerTick;
  fCodeEditor.TextChanged    += OnCodeTextChanged;
end;

// =============================================================================
// 툴박스 클릭
// =============================================================================
procedure Form1.OnToolboxClick(sender: System.Object; e: System.Windows.RoutedEventArgs);
var
  tname    : string;
  t        : System.Type;
  newItem  : ICSharpCode.WpfDesign.DesignItem;
  rootItem : ICSharpCode.WpfDesign.DesignItem;
  childProp: ICSharpCode.WpfDesign.DesignItemProperty;
begin
  if fSurface.DesignContext = nil then exit;
  tname := (sender as System.Windows.Controls.Button).Tag.ToString();
  t     := nil;
  var asms := System.AppDomain.CurrentDomain.GetAssemblies();
  var i    := 0;
  while (i < asms.Length) and (t = nil) do
  begin t := asms[i].GetType(tname); i += 1; end;
  if t = nil then
  begin System.Windows.Forms.MessageBox.Show('타입 없음: ' + tname); exit; end;
  try
    var inst     := System.Activator.CreateInstance(t);
    if inst = nil then exit;
    var services := fSurface.DesignContext.Services;
    rootItem     := fSurface.DesignContext.RootItem;
    var grp      := rootItem.OpenGroup('Add ' + tname);
    newItem      := services.Component.RegisterComponentForDesigner(inst);
    childProp    := rootItem.ContentProperty;
    if childProp <> nil then
    begin
      if childProp.IsCollection then childProp.CollectionElements.Add(newItem)
      else childProp.SetValue(newItem);
    end;
    grp.Commit();
    var arr := new ICSharpCode.WpfDesign.DesignItem[1];
    arr[0]  := newItem;
    services.Selection.SetSelectedComponents(arr);
    SyncXamlEditor();
  except
    on ex: System.Exception do
      System.Windows.Forms.MessageBox.Show('컨트롤 추가 실패: ' + ex.Message);
  end;
end;

// =============================================================================
// 키보드 단축키
// =============================================================================
procedure Form1.FormKeyDown(sender: System.Object; ke: System.Windows.Forms.KeyEventArgs);
begin
  if ke.KeyCode = System.Windows.Forms.Keys.F5 then
    OnRun(sender, System.EventArgs.Empty)
  else if ke.KeyCode = System.Windows.Forms.Keys.F6 then
    OnBuild(sender, System.EventArgs.Empty)
  else if ke.Alt and (ke.KeyCode = System.Windows.Forms.Keys.Enter) then
  begin
    OnProjectOptions(sender, System.EventArgs.Empty);
    ke.Handled := true;
  end;
end;

procedure Form1.OnFormClosing(sender: System.Object;
  e: System.Windows.Forms.FormClosingEventArgs);
begin KillPreviousBuildProcesses(); end;

// =============================================================================
// 정보 대화상자
// =============================================================================
// =============================================================================
// 옵션 다이얼로그 내부 레이아웃 핸들러
// =============================================================================
procedure Form1.OnRowCompResize(sender: System.Object; e: System.EventArgs);
begin
  fDlgBtnBrowseComp.Left := fDlgRowComp.ClientSize.Width - fDlgBtnBrowseComp.Width - 4;
  fDlgTxtCompPath.Width  := fDlgBtnBrowseComp.Left - fDlgTxtCompPath.Left - 6;
end;

procedure Form1.LayoutDlgBtnBar;
begin
  if fDlgBtnBar.ClientSize.Width <= 0 then exit;
  fDlgBtnOk.Left     := fDlgBtnBar.ClientSize.Width - 16 - fDlgBtnOk.Width;
  fDlgBtnCancel.Left := fDlgBtnOk.Left - 8 - fDlgBtnCancel.Width;
  fDlgBtnApply.Left  := fDlgBtnCancel.Left - 8 - fDlgBtnApply.Width;
end;

procedure Form1.OnBtnBarLayoutEvent(sender: System.Object; e: System.EventArgs);
begin
  LayoutDlgBtnBar();
end;

// =============================================================================
// 정보 대화상자
// =============================================================================
procedure Form1.OnAbout(sender: System.Object; e: System.EventArgs);
begin
  System.Windows.Forms.MessageBox.Show(
    'PascalABC-WPF-Designer Ver 2.2.2' + System.Environment.NewLine + System.Environment.NewLine +
    '■ 리팩토링 구조' + System.Environment.NewLine +
    '  Models/   : ProjectOptions, ControlInfo' + System.Environment.NewLine +
    '  Events/   : WpfEventMap' + System.Environment.NewLine +
    '  Editor/   : PascalHighlighting, PascalFolding' + System.Environment.NewLine +
    '  CodeGen/  : XamlParser, XamlPreprocessor, PascalCodeGenerator' + System.Environment.NewLine +
    '  Docking/  : DockContents (DockPanelSuite)' + System.Environment.NewLine +
    '  Form1.pas : UI + 이벤트 핸들러 + 빌드/실행' + System.Environment.NewLine + System.Environment.NewLine +
    '■ 주요 기능' + System.Environment.NewLine +
    '  · Pascal/PascalABC.NET 구문 강조 (XSHD)' + System.Environment.NewLine +
    '  · begin/end 블록 폴딩' + System.Environment.NewLine +
    '  · 프로젝트 옵션 (Alt+Enter)' + System.Environment.NewLine +
    '  · DockPanelSuite 기반 도킹 레이아웃 (도구상자/탐색기/속성/출력/오류 최소화 가능)' + System.Environment.NewLine + System.Environment.NewLine +
    'Built with PascalABC.NET 3.11.1.3833' + System.Environment.NewLine +
    'ICSharpCode.WpfDesign + AvalonEdit + DockPanelSuite' + System.Environment.NewLine + System.Environment.NewLine +
    'made by sigmak (dwfree74@gmail.com) with claude.ai',
    '정보',
    System.Windows.Forms.MessageBoxButtons.OK,
    System.Windows.Forms.MessageBoxIcon.Information);
end;

// =============================================================================
// 진입점
// =============================================================================
begin
  System.Threading.Thread.CurrentThread.SetApartmentState(
    System.Threading.ApartmentState.STA);
  System.Windows.Forms.Application.EnableVisualStyles();
  System.Windows.Forms.Application.Run(new Form1());
end.