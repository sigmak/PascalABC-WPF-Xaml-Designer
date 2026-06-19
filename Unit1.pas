unit Unit1;
{$reference ICSharpCode.WpfDesign.dll}
{$reference ICSharpCode.WpfDesign.Designer.dll}
{$reference ICSharpCode.WpfDesign.XamlDom.dll}
{$reference AvalonEdit.6.3.1.120\lib\net462\ICSharpCode.AvalonEdit.dll}
{$reference PresentationFramework.dll}
{$reference PresentationCore.dll}
{$reference WindowsBase.dll}
{$reference System.Windows.Forms.dll}
{$reference WindowsFormsIntegration.dll}

uses
  System.Windows.Forms,
  System.Collections.Generic,
  ICSharpCode.WpfDesign;

// =============================================================================
// WPF 이벤트 이름 목록 (XAML 파싱 시 이벤트 속성 식별에 사용)
// =============================================================================
const
  WPF_EVENTS: array of string = [
    'Click', 'DoubleClick', 'MouseDown', 'MouseUp', 'MouseMove',
    'MouseEnter', 'MouseLeave', 'MouseWheel', 'KeyDown', 'KeyUp',
    'KeyPress', 'TextChanged', 'TextInput', 'SelectionChanged',
    'Checked', 'Unchecked', 'ValueChanged', 'Loaded', 'Unloaded',
    'GotFocus', 'LostFocus', 'SizeChanged', 'LayoutUpdated',
    'SourceUpdated', 'TargetUpdated', 'DataContextChanged',
    'IsVisibleChanged', 'IsEnabledChanged',
    'PreviewMouseDown', 'PreviewMouseUp', 'PreviewKeyDown', 'PreviewKeyUp',
    'DragEnter', 'DragLeave', 'DragOver', 'Drop',
    'ScrollChanged', 'ContextMenuOpening', 'ContextMenuClosing',
    'ToolTipOpening', 'ToolTipClosing',
    'RequestBringIntoView', 'ManipulationStarted', 'ManipulationDelta',
    'ManipulationCompleted', 'Expanded', 'Collapsed',
    'SelectedItemChanged', 'NodeExpanded', 'NodeCollapsed'
  ];

// =============================================================================
// 새 프로젝트 타입
// =============================================================================
type
  TProjectType = (ptWpfApp, ptWpfControlLibrary);

// =============================================================================
// XAML에서 파싱된 컨트롤 정보
// =============================================================================
type
  TControlInfo = class
    Name     : string;
    TypeName : string;
    Events   : System.Collections.Generic.List<System.Tuple<string,string>>;
    constructor Create(aName, aTypeName: string);
  end;

constructor TControlInfo.Create(aName, aTypeName: string);
begin
  Name     := aName;
  TypeName := aTypeName;
  Events   := new System.Collections.Generic.List<System.Tuple<string,string>>();
end;

// =============================================================================
// 전역 헬퍼 함수
// =============================================================================
function GetEventDelegateType(ctrlType: string; evName: string): string;
var
  rStr : string;
begin
  case evName of
    'Click', 'Checked', 'Unchecked', 'Loaded', 'Unloaded',
    'GotFocus', 'LostFocus':
      rStr := 'System.Windows.RoutedEventHandler';
    'MouseDown', 'MouseUp', 'PreviewMouseDown', 'PreviewMouseUp':
      rStr := 'System.Windows.Input.MouseButtonEventHandler';
    'MouseMove', 'MouseEnter', 'MouseLeave':
      rStr := 'System.Windows.Input.MouseEventHandler';
    'KeyDown', 'KeyUp', 'PreviewKeyDown', 'PreviewKeyUp':
      rStr := 'System.Windows.Input.KeyEventHandler';
    'TextChanged':
      rStr := 'System.Windows.Controls.TextChangedEventHandler';
    'SelectionChanged':
      rStr := 'System.Windows.Controls.SelectionChangedEventHandler';
    'ValueChanged':
      rStr := 'System.Windows.RoutedPropertyChangedEventHandler<double>';
  else
    rStr := 'System.EventHandler';
  end;
  Result := rStr;
end;

function GetEventParamType(ctrlType: string; evName: string): string;
var
  rStr : string;
begin
  case evName of
    'Click', 'Checked', 'Unchecked', 'Loaded', 'Unloaded',
    'GotFocus', 'LostFocus', 'LayoutUpdated':
      rStr := 'System.Windows.RoutedEventArgs';
    'MouseDown', 'MouseUp', 'PreviewMouseDown', 'PreviewMouseUp',
    'DoubleClick':
      rStr := 'System.Windows.Input.MouseButtonEventArgs';
    'MouseMove', 'MouseEnter', 'MouseLeave':
      rStr := 'System.Windows.Input.MouseEventArgs';
    'MouseWheel':
      rStr := 'System.Windows.Input.MouseWheelEventArgs';
    'KeyDown', 'KeyUp', 'PreviewKeyDown', 'PreviewKeyUp':
      rStr := 'System.Windows.Input.KeyEventArgs';
    'TextChanged':
      rStr := 'System.Windows.Controls.TextChangedEventArgs';
    'SelectionChanged':
      rStr := 'System.Windows.Controls.SelectionChangedEventArgs';
    'ValueChanged':
      rStr := 'System.Windows.RoutedPropertyChangedEventArgs<double>';
    'SizeChanged':
      rStr := 'System.Windows.SizeChangedEventArgs';
    'ScrollChanged':
      rStr := 'System.Windows.Controls.ScrollChangedEventArgs';
    'DragEnter', 'DragLeave', 'DragOver', 'Drop':
      rStr := 'System.Windows.DragEventArgs';
  else
    rStr := 'System.EventArgs';
  end;
  Result := rStr;
end;

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

    fRunningProcess : System.Diagnostics.Process;

    menuStrip     : System.Windows.Forms.MenuStrip;
    hostDesign    : System.Windows.Forms.Integration.ElementHost;
    hostLeft      : System.Windows.Forms.Integration.ElementHost;
    hostRight     : System.Windows.Forms.Integration.ElementHost;
    hostXaml      : System.Windows.Forms.Integration.ElementHost;
    hostCode      : System.Windows.Forms.Integration.ElementHost;
    fToolboxPanel : System.Windows.Controls.StackPanel;

    tabControl  : System.Windows.Forms.TabControl;
    tabDesign   : System.Windows.Forms.TabPage;
    tabXaml     : System.Windows.Forms.TabPage;
    tabCode     : System.Windows.Forms.TabPage;

    lvErrors    : System.Windows.Forms.ListView;
    splitMain   : System.Windows.Forms.SplitContainer;
    splitDesign : System.Windows.Forms.SplitContainer;
    splitRight  : System.Windows.Forms.SplitContainer;

    menuItemLineNum   : System.Windows.Forms.ToolStripMenuItem;
    menuItemHighlight : System.Windows.Forms.ToolStripMenuItem;
    menuItemWordWrap  : System.Windows.Forms.ToolStripMenuItem;
    menuItemFolding   : System.Windows.Forms.ToolStripMenuItem;

    fFoldingManager  : ICSharpCode.AvalonEdit.Folding.FoldingManager;
    fFoldingStrategy : ICSharpCode.AvalonEdit.Folding.XmlFoldingStrategy;
    fFoldingTimer    : System.Windows.Threading.DispatcherTimer;

    fDlgTxtFolder : System.Windows.Forms.TextBox;

    procedure BuildMenu;
    procedure BuildToolbox;
    procedure BuildLayout;
    procedure ConnectEvents;

    procedure OnToolboxClick(sender: System.Object; e: System.Windows.RoutedEventArgs);
    procedure OnDesignerDoubleClick(sender: System.Object; e: System.Windows.Input.MouseButtonEventArgs);
    procedure OnSelectionChanged(sender: System.Object; e: ICSharpCode.WpfDesign.DesignItemCollectionEventArgs);
    procedure OnUndoStackChanged(sender: System.Object; e: System.EventArgs);
    procedure OnTabChanged(sender: System.Object; e: System.EventArgs);
    procedure FormKeyDown(sender: System.Object; ke: System.Windows.Forms.KeyEventArgs);
    procedure OnFormClosing(sender: System.Object; e: System.Windows.Forms.FormClosingEventArgs);

    procedure OnNewProject(sender: System.Object; e: System.EventArgs);
    procedure OnSave(sender: System.Object; e: System.EventArgs);
    procedure OnOpen(sender: System.Object; e: System.EventArgs);

    procedure OnApplyXaml(sender: System.Object; e: System.Windows.RoutedEventArgs);
    procedure OnApplyXamlMenu(sender: System.Object; e: System.EventArgs);
    procedure OnSyncXamlMenu(sender: System.Object; e: System.EventArgs);
    procedure OnToggleLineNumbers(sender: System.Object; e: System.EventArgs);
    procedure OnToggleHighlight(sender: System.Object; e: System.EventArgs);
    procedure OnToggleWordWrap(sender: System.Object; e: System.EventArgs);
    procedure OnToggleFolding(sender: System.Object; e: System.EventArgs);

    procedure OnBuild(sender: System.Object; e: System.EventArgs);
    procedure OnRun(sender: System.Object; e: System.EventArgs);
    function  FindPabcCompiler: string;
    procedure OnErrorsCopy(sender: System.Object; e: System.EventArgs);
    procedure OnErrorsKeyDown(sender: System.Object; e: System.Windows.Forms.KeyEventArgs);
    procedure KillPreviousBuildProcesses;

    procedure UpdateFolding;
    procedure OnFoldingTimerTick(sender: System.Object; e: System.EventArgs);
    procedure EnableFolding;
    procedure DisableFolding;
    procedure OnXamlTextChanged(sender: System.Object; e: System.EventArgs);
    procedure OnAbout(sender: System.Object; e: System.EventArgs);

    procedure OnBrowseClick(sender: System.Object; e: System.EventArgs);

    // XAML 처리
    procedure LoadXaml(xaml: string);
    procedure LoadDesigner(designXaml: string);
    procedure SyncXamlEditor;
    function  SaveDesignerToString: string;
    function  StripCustomNamespaces(xaml: string): string;
    function  PreprocessXaml(xaml: string): string;

    function  ParseXClassInfo(xaml: string; var ns: string; var cls: string): boolean;
    function  ParseControlsFromXaml(xaml: string): System.Collections.Generic.List<TControlInfo>;
    function  IsWpfEvent(attrName: string): boolean;
    function  StripEventAttributesForRuntime(xaml: string): string;

    function  PrepareXamlForBuild(xaml: string): string;

    function  GenerateWpfAppCode(xamlFileName: string): string;
    function  GenerateControlLibCode(xamlFileName: string): string;
    function  GenerateInitializeComponent(controls: System.Collections.Generic.List<TControlInfo>): string;

    procedure AddEventHandlerToXaml(controlName: string; eventName: string; handlerName: string);
    procedure AddEventHandlerToCode(handlerName: string; eventType: string);

    function  ShowNewProjectDialog(var projType: TProjectType; var projName: string; var projFolder: string): boolean;
    procedure CreateNewProject(projType: TProjectType; projName: string; projFolder: string);

    procedure ShowBuildErrors(output: string);

  public
    constructor Create;
  end;

// =============================================================================
// constructor
// =============================================================================
constructor Form1.Create;
begin
  inherited Create;
  Self.Text   := 'PascalABC-WPF-Designer Ver 2.0.2';
  Self.Width  := 1600;
  Self.Height := 950;

  ICSharpCode.WpfDesign.Designer.BasicMetadata.Register();

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
  fCodeEditor.Text := GenerateWpfAppCode(fXamlFileName);
end;

// =============================================================================
// ParseXClassInfo
// =============================================================================
function Form1.ParseXClassInfo(xaml: string; var ns: string; var cls: string): boolean;
var
  re : System.Text.RegularExpressions.Regex;
  m  : System.Text.RegularExpressions.Match;
begin
  Result := false;
  ns     := 'MyApp';
  cls    := 'MainWindow';

  re := new System.Text.RegularExpressions.Regex('x:Class\s*=\s*"([^"]+)"');
  m  := re.Match(xaml);
  if not m.Success then exit;

  var full := m.Groups[1].Value;
  var dot  := full.LastIndexOf('.');
  if dot >= 0 then
  begin
    ns  := full.Substring(0, dot);
    cls := full.Substring(dot + 1);
  end
  else
  begin
    ns  := '';
    cls := full;
  end;
  Result := true;
end;

// =============================================================================
// IsWpfEvent
// =============================================================================
function Form1.IsWpfEvent(attrName: string): boolean;
var
  ev: string;
begin
  foreach ev in WPF_EVENTS do
    if attrName = ev then
    begin
      Result := true;
      exit;
    end;
  Result := false;
end;

// =============================================================================
// ParseControlsFromXaml
// =============================================================================
function Form1.ParseControlsFromXaml(xaml: string): System.Collections.Generic.List<TControlInfo>;
var
  result2 : System.Collections.Generic.List<TControlInfo>;
  reTag   : System.Text.RegularExpressions.Regex;
  reAttr  : System.Text.RegularExpressions.Regex;
  reName  : System.Text.RegularExpressions.Regex;
  mTag    : System.Text.RegularExpressions.Match;
  mAttr   : System.Text.RegularExpressions.Match;
  mName   : System.Text.RegularExpressions.Match;
  tagText : string;
  tagName : string;
  ctrlName: string;
  info    : TControlInfo;
begin
  result2 := new System.Collections.Generic.List<TControlInfo>();

  reTag  := new System.Text.RegularExpressions.Regex(
    '<([A-Za-z][A-Za-z0-9]*)\s([^>]*?)(?:/>|>)',
    System.Text.RegularExpressions.RegexOptions.Singleline);
  reAttr := new System.Text.RegularExpressions.Regex('(\w[\w.]*)\s*=\s*"([^"]*)"');
  reName := new System.Text.RegularExpressions.Regex('x:Name\s*=\s*"([^"]+)"');

  mTag := reTag.Match(xaml);
  while mTag.Success do
  begin
    tagName := mTag.Groups[1].Value;
    tagText := mTag.Value;

    mName := reName.Match(tagText);
    if mName.Success then
    begin
      ctrlName := mName.Groups[1].Value;
      info     := new TControlInfo(ctrlName, tagName);

      mAttr := reAttr.Match(tagText);
      while mAttr.Success do
      begin
        var attrName    := mAttr.Groups[1].Value;
        var handlerName := mAttr.Groups[2].Value;
        if IsWpfEvent(attrName) then
          info.Events.Add(System.Tuple.Create(attrName, handlerName));
        mAttr := mAttr.NextMatch();
      end;

      result2.Add(info);
    end;

    mTag := mTag.NextMatch();
  end;

  Result := result2;
end;

// =============================================================================
// StripEventAttributesForRuntime
// =============================================================================
function Form1.StripEventAttributesForRuntime(xaml: string): string;
var
  ev  : string;
  re  : System.Text.RegularExpressions.Regex;
  s   : string;
begin
  s := xaml;
  foreach ev in WPF_EVENTS do
  begin
    re := new System.Text.RegularExpressions.Regex('\s+' + ev + '\s*=\s*"[^"]*"');
    s  := re.Replace(s, '');
  end;
  Result := s;
end;


// =============================================================================
// ★ PrepareXamlForBuild
//   VS 컴파일 XAML과 동일한 방식의 런타임 로딩(XamlObjectWriter +
//   RootObjectInstance)을 위해 XAML을 준비한다.
//   Window/UserControl의 Background, Resources, Title, Width, Height,
//   Content 등 전체 구조를 그대로 유지한다. 이벤트 속성만 제거한다
//   (이벤트는 코드에서 직접 += 로 연결하므로 XAML에는 불필요).
// =============================================================================
function Form1.PrepareXamlForBuild(xaml: string): string;
var
  s  : string;
  re : System.Text.RegularExpressions.Regex;
begin
  s := xaml;

  // XML 선언 제거
  var trimmed := s.TrimStart();
  if trimmed.StartsWith('<?xml') then
  begin
    var declEnd := trimmed.IndexOf('?>');
    if declEnd >= 0 then
      s := trimmed.Substring(declEnd + 2).TrimStart();
  end;

  // 이벤트 속성 제거 (코드에서 직접 연결)
  s := StripEventAttributesForRuntime(s);

  // 디자인 타임 전용 네임스페이스 제거 (안전을 위해 유지)
  re := new System.Text.RegularExpressions.Regex('\s+mc:Ignorable\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');
  re := new System.Text.RegularExpressions.Regex('\s+xmlns:mc\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');
  re := new System.Text.RegularExpressions.Regex('\s+d:\w+\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');
  re := new System.Text.RegularExpressions.Regex('\s+xmlns:d\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');

  // ★ 핵심: Window/UserControl 전체를 그대로 유지한다.
  //   (Background, Resources, Title, Width, Height, Content 전부 보존)
  Result := s;
end;

// =============================================================================
// ★ GenerateInitializeComponent
//   XamlObjectWriter + RootObjectInstance(Self)를 사용해
//   VS 컴파일 앱과 동일하게 XAML 전체를 기존 Self 위에 합친다.
//   → Title/Width/Height/Background/Resources를 별도로 파싱/세팅할 필요 없음.
// =============================================================================
function Form1.GenerateInitializeComponent(controls: System.Collections.Generic.List<TControlInfo>): string;
var
  sb        : System.Text.StringBuilder;
  ctrl      : TControlInfo;
  ctrl2     : TControlInfo;
  ev        : System.Tuple<string,string>;
  hasEvents : boolean;
begin
  sb := new System.Text.StringBuilder();
  sb.AppendLine('procedure ' + fClassName + '.InitializeComponent;');
  sb.AppendLine('var');
  sb.AppendLine('  xamlPath    : string;');
  sb.AppendLine('  fs          : System.IO.FileStream;');
  sb.AppendLine('  xrSettings  : System.Xaml.XamlXmlReaderSettings;');
  sb.AppendLine('  xamlReader  : System.Xaml.XamlXmlReader;');
  sb.AppendLine('  objSettings : System.Xaml.XamlObjectWriterSettings;');
  sb.AppendLine('  objWriter   : System.Xaml.XamlObjectWriter;');
  sb.AppendLine('begin');

  sb.AppendLine('  xamlPath := System.IO.Path.Combine(');
  sb.AppendLine('    System.AppDomain.CurrentDomain.BaseDirectory,');
  sb.AppendLine('    ' + #39 + fXamlFileName + #39 + ');');
  sb.AppendLine('');
  sb.AppendLine('  fs := new System.IO.FileStream(xamlPath,');
  sb.AppendLine('          System.IO.FileMode.Open, System.IO.FileAccess.Read);');
  sb.AppendLine('  try');
  sb.AppendLine('    xrSettings := new System.Xaml.XamlXmlReaderSettings();');
  sb.AppendLine('    xrSettings.LocalAssembly := System.Reflection.Assembly.GetExecutingAssembly();');
  sb.AppendLine('    xamlReader  := new System.Xaml.XamlXmlReader(fs, xrSettings);');
  sb.AppendLine('    objSettings := new System.Xaml.XamlObjectWriterSettings();');
  sb.AppendLine('    objSettings.RootObjectInstance := Self;');
  sb.AppendLine('    objWriter   := new System.Xaml.XamlObjectWriter(');
  sb.AppendLine('                     xamlReader.SchemaContext, objSettings);');
  sb.AppendLine('    System.Xaml.XamlServices.Transform(xamlReader, objWriter);');
  sb.AppendLine('  finally');
  sb.AppendLine('    fs.Close();');
  sb.AppendLine('  end;');
  sb.AppendLine('');

  if controls.Count > 0 then
  begin
    sb.AppendLine('  // 컨트롤 필드 초기화 (FindName) — Self가 루트이므로 직접 가능');
    foreach ctrl in controls do
    begin
      var wpfType := 'System.Windows.Controls.' + ctrl.TypeName;
      case ctrl.TypeName of
        'Window', 'UserControl', 'Page': wpfType := 'System.Windows.' + ctrl.TypeName;
        'TextBlock', 'Image'           : wpfType := 'System.Windows.Controls.' + ctrl.TypeName;
      end;
      sb.AppendLine('  ' + ctrl.Name + ' := Self.FindName(' + #39 + ctrl.Name + #39 + ')' +
        ' as ' + wpfType + ';');
    end;
    sb.AppendLine('');

    hasEvents := false;
    foreach ctrl2 in controls do
      if ctrl2.Events.Count > 0 then hasEvents := true;

    if hasEvents then
    begin
      sb.AppendLine('  // 이벤트 핸들러 연결');
      foreach ctrl2 in controls do
      begin
        foreach ev in ctrl2.Events do
        begin
          sb.AppendLine('  if ' + ctrl2.Name + ' <> nil then');
          sb.AppendLine('    ' + ctrl2.Name + '.' + ev.Item1 + ' += ' + ev.Item2 + ';');
        end;
      end;
    end;
  end;

  sb.AppendLine('end;');
  Result := sb.ToString();
end;

// =============================================================================
// GenerateWpfAppCode
// =============================================================================
function Form1.GenerateWpfAppCode(xamlFileName: string): string;
var
  sb          : System.Text.StringBuilder;
  controls    : System.Collections.Generic.List<TControlInfo>;
  ctrl        : TControlInfo;
  ev          : System.Tuple<string,string>;
  programName : string;
  hasEvents   : boolean;
begin
  var xaml := fXamlEditor.Text;
  ParseXClassInfo(xaml, fNamespace, fClassName);
  controls := ParseControlsFromXaml(xaml);

  programName := fNamespace;  // XAML x:Class의 네임스페이스와 일치 //fClassName + 'App';

  sb := new System.Text.StringBuilder();

  sb.AppendLine('program ' + programName + ';');
  sb.AppendLine('');
  sb.AppendLine('{$apptype windows}');
  sb.AppendLine('{$reference PresentationFramework.dll}');
  sb.AppendLine('{$reference PresentationCore.dll}');
  sb.AppendLine('{$reference WindowsBase.dll}');
  sb.AppendLine('{$reference System.Windows.Forms.dll}');
  sb.AppendLine('{$reference System.Xaml.dll}');   // ★ 추가
  sb.AppendLine('');
  sb.AppendLine('uses');
  sb.AppendLine('  System.Windows,');
  sb.AppendLine('  System.Windows.Controls,');
  sb.AppendLine('  System.Windows.Markup,');
  sb.AppendLine('  System.Xaml,');                 // ★ 추가
  sb.AppendLine('  System.IO,');
  sb.AppendLine('  System.Threading;');
  sb.AppendLine('');

  sb.AppendLine('type');
  sb.AppendLine('  ' + fClassName + ' = class(System.Windows.Window)');

  if controls.Count > 0 then
  begin
    sb.AppendLine('  private');
    foreach ctrl in controls do
    begin
      var wpfType := 'System.Windows.Controls.' + ctrl.TypeName;
      case ctrl.TypeName of
        'Window', 'UserControl': wpfType := 'System.Windows.' + ctrl.TypeName;
      end;
      sb.AppendLine('    ' + ctrl.Name + ' : ' + wpfType + ';');
    end;
  end;

  hasEvents := false;
  foreach ctrl in controls do
    if ctrl.Events.Count > 0 then hasEvents := true;

  if hasEvents then
  begin
    sb.AppendLine('  // ── 이벤트 핸들러 선언 ─────────────────────');
    foreach ctrl in controls do
    begin
      foreach ev in ctrl.Events do
      begin
        var paramType := GetEventParamType(ctrl.TypeName, ev.Item1);
        sb.AppendLine('    procedure ' + ev.Item2 +
          '(sender: System.Object; e: ' + paramType + ');');
      end;
    end;
  end;

  sb.AppendLine('  public');
  sb.AppendLine('    constructor Create;');
  sb.AppendLine('    procedure InitializeComponent;');
  sb.AppendLine('  end;');
  sb.AppendLine('');

  sb.AppendLine('constructor ' + fClassName + '.Create;');
  sb.AppendLine('begin');
  sb.AppendLine('  inherited Create;');
  sb.AppendLine('  InitializeComponent;');
  sb.AppendLine('end;');
  sb.AppendLine('');

  sb.Append(GenerateInitializeComponent(controls));
  sb.AppendLine('');

  if hasEvents then
  begin
    sb.AppendLine('// ── 이벤트 핸들러 구현 ──────────────────────────────────');
    sb.AppendLine('');
    foreach ctrl in controls do
    begin
      foreach ev in ctrl.Events do
      begin
        var paramType := GetEventParamType(ctrl.TypeName, ev.Item1);
        sb.AppendLine('procedure ' + fClassName + '.' + ev.Item2 +
          '(sender: System.Object; e: ' + paramType + ');');
        sb.AppendLine('begin');
        sb.AppendLine('  // TODO: ' + ev.Item2 + ' 구현');
        sb.AppendLine('end;');
        sb.AppendLine('');
      end;
    end;
  end;

  sb.AppendLine('// ── 애플리케이션 진입점 ──────────────────────────────────');
  sb.AppendLine('procedure RunApp;');
  sb.AppendLine('begin');
  sb.AppendLine('  try');
  sb.AppendLine('    var app := new System.Windows.Application();');
  sb.AppendLine('    app.Run(new ' + fClassName + '());');
  sb.AppendLine('  except');
  sb.AppendLine('    on ex: System.Exception do');
  sb.AppendLine('      System.Windows.Forms.MessageBox.Show(');
  sb.AppendLine('        ex.ToString(), ' + #39 + '실행 오류' + #39 + ',');
  sb.AppendLine('        System.Windows.Forms.MessageBoxButtons.OK,');
  sb.AppendLine('        System.Windows.Forms.MessageBoxIcon.Error);');
  sb.AppendLine('  end;');
  sb.AppendLine('end;');
  sb.AppendLine('');
  sb.AppendLine('begin');
  sb.AppendLine('  var t := new System.Threading.Thread(RunApp);');
  sb.AppendLine('  t.SetApartmentState(System.Threading.ApartmentState.STA);');
  sb.AppendLine('  t.IsBackground := false;');
  sb.AppendLine('  t.Start();');
  sb.AppendLine('end.');

  Result := sb.ToString();
end;

// =============================================================================
// GenerateControlLibCode
// =============================================================================
function Form1.GenerateControlLibCode(xamlFileName: string): string;
var
  sb       : System.Text.StringBuilder;
  controls : System.Collections.Generic.List<TControlInfo>;
  ctrl     : TControlInfo;
  ev       : System.Tuple<string,string>;
  unitName : string;
begin
  var xaml := fXamlEditor.Text;
  ParseXClassInfo(xaml, fNamespace, fClassName);
  controls := ParseControlsFromXaml(xaml);

  unitName := fClassName + 'Unit';

  sb := new System.Text.StringBuilder();
  sb.AppendLine('unit ' + unitName + ';');
  sb.AppendLine('');
  sb.AppendLine('{$reference PresentationFramework.dll}');
  sb.AppendLine('{$reference PresentationCore.dll}');
  sb.AppendLine('{$reference WindowsBase.dll}');
  sb.AppendLine('{$reference System.Xaml.dll}');   // ★ 추가  
  sb.AppendLine('');
  sb.AppendLine('uses');
  sb.AppendLine('  System.Windows,');
  sb.AppendLine('  System.Windows.Controls,');
  sb.AppendLine('  System.Windows.Markup,');
  sb.AppendLine('  System.Xaml,');                 // ★ 추가
  sb.AppendLine('  System.IO;');
  sb.AppendLine('');
  sb.AppendLine('type');
  sb.AppendLine('  ' + fClassName + ' = class(System.Windows.Controls.UserControl)');
  sb.AppendLine('  private');

  foreach ctrl in controls do
  begin
    var wpfType := 'System.Windows.Controls.' + ctrl.TypeName;
    sb.AppendLine('    ' + ctrl.Name + ' : ' + wpfType + ';');
  end;

  sb.AppendLine('  public');
  sb.AppendLine('    constructor Create;');
  sb.AppendLine('    procedure InitializeComponent;');
  sb.AppendLine('  end;');
  sb.AppendLine('');
  sb.AppendLine('constructor ' + fClassName + '.Create;');
  sb.AppendLine('begin');
  sb.AppendLine('  inherited Create;');
  sb.AppendLine('  InitializeComponent;');
  sb.AppendLine('end;');
  sb.AppendLine('');
  sb.Append(GenerateInitializeComponent(controls));
  sb.AppendLine('');
  sb.AppendLine('end.');

  Result := sb.ToString();
end;

// =============================================================================
// ShowNewProjectDialog
// =============================================================================
function Form1.ShowNewProjectDialog(var projType: TProjectType; var projName: string; var projFolder: string): boolean;
var
  dlg       : System.Windows.Forms.Form;
  lblType   : System.Windows.Forms.Label;
  lstType   : System.Windows.Forms.ListBox;
  lblName   : System.Windows.Forms.Label;
  txtName   : System.Windows.Forms.TextBox;
  lblFolder : System.Windows.Forms.Label;
  btnBrowse : System.Windows.Forms.Button;
  btnOk     : System.Windows.Forms.Button;
  btnCancel : System.Windows.Forms.Button;
begin
  Result    := false;
  projType  := ptWpfApp;
  projName  := 'WpfApp1';
  projFolder := System.Environment.GetFolderPath(
    System.Environment.SpecialFolder.MyDocuments);

  dlg        := new System.Windows.Forms.Form();
  dlg.Text   := '새 프로젝트 만들기';
  dlg.Width  := 560;
  dlg.Height := 420;
  dlg.FormBorderStyle := System.Windows.Forms.FormBorderStyle.FixedDialog;
  dlg.StartPosition   := System.Windows.Forms.FormStartPosition.CenterParent;
  dlg.MaximizeBox     := false;
  dlg.MinimizeBox     := false;

  lblType      := new System.Windows.Forms.Label();
  lblType.Text := '프로젝트 형식';
  lblType.Left := 16; lblType.Top := 16; lblType.Width := 200;
  lblType.Font := new System.Drawing.Font('Segoe UI', 9, System.Drawing.FontStyle.Bold);

  lstType          := new System.Windows.Forms.ListBox();
  lstType.Left     := 16; lstType.Top := 36;
  lstType.Width    := 510; lstType.Height := 140;
  lstType.Font     := new System.Drawing.Font('Segoe UI', 10);
  lstType.Items.Add('WPF 애플리케이션              (.exe)  — Window를 루트로 하는 독립 실행 앱');
  lstType.Items.Add('WPF 사용자 정의 컨트롤 라이브러리  (.pas)  — UserControl을 상속한 재사용 컨트롤');
  lstType.SelectedIndex := 0;

  lblName      := new System.Windows.Forms.Label();
  lblName.Text := '프로젝트 이름';
  lblName.Left := 16; lblName.Top := 196; lblName.Width := 200;
  lblName.Font := new System.Drawing.Font('Segoe UI', 9, System.Drawing.FontStyle.Bold);

  txtName        := new System.Windows.Forms.TextBox();
  txtName.Left   := 16; txtName.Top := 216;
  txtName.Width  := 510; txtName.Height := 26;
  txtName.Text   := 'WpfApp1';
  txtName.Font   := new System.Drawing.Font('Segoe UI', 10);

  lblFolder      := new System.Windows.Forms.Label();
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

  btnOk              := new System.Windows.Forms.Button();
  btnOk.Text         := '확인';
  btnOk.Left         := 356; btnOk.Top := 340;
  btnOk.Width        := 80; btnOk.Height := 30;
  btnOk.DialogResult := System.Windows.Forms.DialogResult.OK;

  btnCancel              := new System.Windows.Forms.Button();
  btnCancel.Text         := '취소';
  btnCancel.Left         := 444; btnCancel.Top := 340;
  btnCancel.Width        := 80; btnCancel.Height := 30;
  btnCancel.DialogResult := System.Windows.Forms.DialogResult.Cancel;

  dlg.Controls.Add(lblType);
  dlg.Controls.Add(lstType);
  dlg.Controls.Add(lblName);
  dlg.Controls.Add(txtName);
  dlg.Controls.Add(lblFolder);
  dlg.Controls.Add(fDlgTxtFolder);
  dlg.Controls.Add(btnBrowse);
  dlg.Controls.Add(btnOk);
  dlg.Controls.Add(btnCancel);
  dlg.AcceptButton := btnOk;
  dlg.CancelButton := btnCancel;

  if dlg.ShowDialog() = System.Windows.Forms.DialogResult.OK then
  begin
    if lstType.SelectedIndex = 1 then
      projType := ptWpfControlLibrary
    else
      projType := ptWpfApp;
    projName   := txtName.Text.Trim();
    projFolder := fDlgTxtFolder.Text.Trim();
    Result     := true;
  end;

  fDlgTxtFolder := nil;
end;

// =============================================================================
// OnBrowseClick
// =============================================================================
procedure Form1.OnBrowseClick(sender: System.Object; e: System.EventArgs);
begin
  if fDlgTxtFolder = nil then exit;
  var fd := new System.Windows.Forms.FolderBrowserDialog();
  fd.SelectedPath := fDlgTxtFolder.Text;
  if fd.ShowDialog() = System.Windows.Forms.DialogResult.OK then
    fDlgTxtFolder.Text := fd.SelectedPath;
end;

// =============================================================================
// CreateNewProject
// =============================================================================
procedure Form1.CreateNewProject(projType: TProjectType; projName: string; projFolder: string);
var
  defaultXaml: string;
begin
  KillPreviousBuildProcesses();

  fProjectPath  := projFolder + '\' + projName + '\';
  fProjectType  := projType;
  fClassName    := projName;
  fNamespace    := projName;

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

  case projType of
    ptWpfApp:            fCodeEditor.Text := GenerateWpfAppCode(fXamlFileName);
    ptWpfControlLibrary: fCodeEditor.Text := GenerateControlLibCode(fXamlFileName);
  end;

  Self.Text := 'PascalABC-WPF-Designer — ' + fProjectPath;
end;

// =============================================================================
// OnNewProject
// =============================================================================
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
// OnBuild  ★ 핵심 수정: ExtractInnerXamlForBuild 사용
// =============================================================================
procedure Form1.OnBuild(sender: System.Object; e: System.EventArgs);
var
  xamlPath    : string;
  pasPath     : string;
  tempBat     : string;
  compilerPath: string;
  exitCode    : integer;
  hadError    : boolean;
  errMsg      : string;
  exePath     : string;
  buildXaml   : string;
begin
  hadError := false;
  errMsg   := '';
  exitCode := -1;

  KillPreviousBuildProcesses();

  ParseXClassInfo(fXamlEditor.Text, fNamespace, fClassName);

  // 코드 탭에 내용이 없을 때만 자동 생성 (사용자 코드 보호)
  if fCodeEditor.Text.Trim() = '' then
  begin
    case fProjectType of
      ptWpfApp:            fCodeEditor.Text := GenerateWpfAppCode(fXamlFileName);
      ptWpfControlLibrary: fCodeEditor.Text := GenerateControlLibCode(fXamlFileName);
    end;
  end;

  xamlPath := fProjectPath + fXamlFileName;
  pasPath  := fProjectPath + fPasFileName;
  tempBat  := fProjectPath + 'build.bat';

  try
    // ★ 수정: Window 래핑 대신 내부 콘텐츠(Grid 등)만 추출하여 저장
    buildXaml := PrepareXamlForBuild(fXamlEditor.Text);
    System.IO.File.WriteAllText(xamlPath, buildXaml, System.Text.Encoding.UTF8);
    System.IO.File.WriteAllText(pasPath, fCodeEditor.Text, System.Text.Encoding.UTF8);
  except
    on ex: System.Exception do
    begin errMsg := ex.Message; hadError := true; end;
  end;
  if hadError then begin
    System.Windows.Forms.MessageBox.Show('파일 저장 오류: ' + errMsg); exit;
  end;

  compilerPath := FindPabcCompiler();
  if compilerPath = '' then
  begin
    System.Windows.Forms.MessageBox.Show(
      'pabcnetc.exe를 찾을 수 없습니다.', '컴파일러 없음',
      System.Windows.Forms.MessageBoxButtons.OK,
      System.Windows.Forms.MessageBoxIcon.Warning);
    exit;
  end;

  try
    var bat := new System.Text.StringBuilder();
    bat.AppendLine('@echo off');
    bat.AppendLine('"' + compilerPath + '" "' + pasPath + '"');
    bat.AppendLine('exit %ERRORLEVEL%');
    System.IO.File.WriteAllText(tempBat, bat.ToString(), System.Text.Encoding.Default);
  except
    on ex: System.Exception do
    begin errMsg := ex.Message; hadError := true; end;
  end;
  if hadError then begin
    System.Windows.Forms.MessageBox.Show('빌드 스크립트 오류: ' + errMsg); exit;
  end;

  try
    var psi              := new System.Diagnostics.ProcessStartInfo();
    psi.FileName         := 'cmd.exe';
    psi.Arguments        := '/c "' + tempBat + '"';
    psi.WorkingDirectory := fProjectPath;
    psi.UseShellExecute  := true;
    psi.CreateNoWindow   := false;
    psi.WindowStyle      := System.Diagnostics.ProcessWindowStyle.Minimized;
    var proc := new System.Diagnostics.Process();
    proc.StartInfo := psi;
    proc.Start();
    proc.WaitForExit(60000);
    if not proc.HasExited then
    begin
      try proc.Kill(); except end;
      errMsg := '컴파일 시간 초과'; hadError := true;
    end
    else
      exitCode := proc.ExitCode;
  except
    on ex: System.Exception do
    begin errMsg := ex.Message; hadError := true; end;
  end;

  try
    if System.IO.File.Exists(tempBat) then System.IO.File.Delete(tempBat);
  except end;

  if hadError then
  begin
    lvErrors.Items.Clear();
    var item := new System.Windows.Forms.ListViewItem('빌드 오류: ' + errMsg);
    item.ForeColor := System.Drawing.Color.Red;
    lvErrors.Items.Add(item);
    System.Windows.Forms.MessageBox.Show('빌드 오류: ' + errMsg);
    exit;
  end;

  exePath := fProjectPath +
    System.IO.Path.GetFileNameWithoutExtension(fPasFileName) + '.exe';

  if System.IO.File.Exists(exePath) then
  begin
    lvErrors.Items.Clear();
    var item := new System.Windows.Forms.ListViewItem('빌드 성공: ' + exePath);
    item.ForeColor := System.Drawing.Color.FromArgb(0, 128, 0);
    lvErrors.Items.Add(item);
    System.Windows.Forms.MessageBox.Show(
      '빌드 성공!' + #13#10 + exePath, '빌드',
      System.Windows.Forms.MessageBoxButtons.OK,
      System.Windows.Forms.MessageBoxIcon.Information);
  end
  else
  begin
    lvErrors.Items.Clear();
    var item := new System.Windows.Forms.ListViewItem(
      '빌드 실패 — 콘솔 창 오류를 확인하세요. (종료코드: ' + exitCode.ToString() + ')');
    item.ForeColor := System.Drawing.Color.Red;
    lvErrors.Items.Add(item);
    System.Windows.Forms.MessageBox.Show(
      '빌드 실패 — 콘솔 창의 오류 메시지를 확인하세요.', '빌드 실패',
      System.Windows.Forms.MessageBoxButtons.OK,
      System.Windows.Forms.MessageBoxIcon.Error);
  end;
end;

// =============================================================================
// OnRun
// =============================================================================
procedure Form1.OnRun(sender: System.Object; e: System.EventArgs);
var
  exePath: string;
begin
  OnBuild(sender, e);
  exePath := fProjectPath +
    System.IO.Path.GetFileNameWithoutExtension(fPasFileName) + '.exe';
  if System.IO.File.Exists(exePath) then
  begin
    try
      fRunningProcess := System.Diagnostics.Process.Start(exePath);
    except
      on ex: System.Exception do
        System.Windows.Forms.MessageBox.Show('실행 오류: ' + ex.Message);
    end;
  end;
end;

// =============================================================================
// OnSave
// =============================================================================
procedure Form1.OnSave(sender: System.Object; e: System.EventArgs);
var
  dlg: System.Windows.Forms.SaveFileDialog;
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
    System.Windows.Forms.MessageBox.Show(
      'XAML: ' + dlg.FileName + #13#10 + 'PAS: ' + pasPath + #13#10 + '저장 완료!');
  end;
end;

// =============================================================================
// OnOpen
// =============================================================================
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
    begin
      System.Windows.Forms.MessageBox.Show('읽기 오류: ' + ex.Message);
      exit;
    end;
  end;

  KillPreviousBuildProcesses();
  fProjectPath  := System.IO.Path.GetDirectoryName(dlg.FileName) + '\';
  fXamlFileName := System.IO.Path.GetFileName(dlg.FileName);
  fPasFileName  := System.IO.Path.ChangeExtension(fXamlFileName, '.pas');
  Self.Text     := 'PascalABC-WPF-Designer — ' + fProjectPath;

  ParseXClassInfo(xaml, fNamespace, fClassName);

  if xaml.Contains('<UserControl') then
    fProjectType := ptWpfControlLibrary
  else
    fProjectType := ptWpfApp;

  LoadXaml(xaml);

  pasPath := fProjectPath + fPasFileName;
  if System.IO.File.Exists(pasPath) then
    fCodeEditor.Text := System.IO.File.ReadAllText(pasPath)
  else
  begin
    case fProjectType of
      ptWpfApp:            fCodeEditor.Text := GenerateWpfAppCode(fXamlFileName);
      ptWpfControlLibrary: fCodeEditor.Text := GenerateControlLibCode(fXamlFileName);
    end;
  end;
end;

// =============================================================================
// OnTabChanged
// =============================================================================
procedure Form1.OnTabChanged(sender: System.Object; e: System.EventArgs);
begin
  if tabControl.SelectedTab = tabCode then
  begin
    ParseXClassInfo(fXamlEditor.Text, fNamespace, fClassName);
    // 코드 탭이 비어있을 때만 자동 생성 (사용자 코드 보호)
    if fCodeEditor.Text.Trim() = '' then
    begin
      case fProjectType of
        ptWpfApp:            fCodeEditor.Text := GenerateWpfAppCode(fXamlFileName);
        ptWpfControlLibrary: fCodeEditor.Text := GenerateControlLibCode(fXamlFileName);
      end;
    end;
  end;
end;

// =============================================================================
// AddEventHandlerToCode
// =============================================================================
procedure Form1.AddEventHandlerToCode(handlerName: string; eventType: string);
var
  code   : string;
  marker : string;
  paramT : string;
begin
  code   := fCodeEditor.Text;
  marker := '// ── 이벤트 핸들러 구현 ──────────────────────────────────';

  if code.Contains('procedure ' + fClassName + '.' + handlerName) then exit;

  paramT := eventType;
  if paramT = '' then paramT := 'System.Windows.RoutedEventArgs';

  var handler := new System.Text.StringBuilder();
  handler.AppendLine('procedure ' + fClassName + '.' + handlerName +
    '(sender: System.Object; e: ' + paramT + ');');
  handler.AppendLine('begin');
  handler.AppendLine('  // TODO: ' + handlerName);
  handler.AppendLine('end;');
  handler.AppendLine('');

  if code.Contains(marker) then
    code := code.Replace(marker,
      marker + System.Environment.NewLine + System.Environment.NewLine + handler.ToString())
  else
    code := code + System.Environment.NewLine + handler.ToString();

  fCodeEditor.Text := code;
end;

// =============================================================================
// OnDesignerDoubleClick
// =============================================================================
procedure Form1.OnDesignerDoubleClick(sender: System.Object;
  e: System.Windows.Input.MouseButtonEventArgs);
var
  selectedItems: System.Collections.Generic.ICollection<ICSharpCode.WpfDesign.DesignItem>;
  item         : ICSharpCode.WpfDesign.DesignItem;
  controlName  : string;
  controlType  : string;
  eventName    : string;
  handlerName  : string;
begin
  if fSurface.DesignContext = nil then exit;
  selectedItems := fSurface.DesignContext.Services.Selection.SelectedItems;
  if selectedItems.Count = 0 then exit;

  item := nil;
  var en := selectedItems.GetEnumerator();
  if en.MoveNext() then item := en.Current;
  if item = nil then exit;

  var nameProp := item.Properties['Name'];
  if (nameProp <> nil) and (nameProp.ValueOnInstance <> nil) then
    controlName := nameProp.ValueOnInstance.ToString()
  else
    controlName := '';

  controlType := item.ComponentType.Name;

  case controlType of
    'Button'     : eventName := 'Click';
    'TextBox'    : eventName := 'TextChanged';
    'CheckBox',
    'RadioButton': eventName := 'Checked';
    'ComboBox',
    'ListBox'    : eventName := 'SelectionChanged';
    'Slider'     : eventName := 'ValueChanged';
  else             eventName := 'Loaded';
  end;

  if controlName <> '' then
    handlerName := controlName + '_' + eventName
  else
    handlerName := controlType + '_' + eventName;

  AddEventHandlerToXaml(controlName, eventName, handlerName);

  var paramType := GetEventParamType(controlType, eventName);
  AddEventHandlerToCode(handlerName, paramType);

  tabControl.SelectedTab := tabCode;

  System.Windows.Forms.MessageBox.Show(
    '이벤트 핸들러 생성: ' + handlerName + #13#10 + '코드 탭에서 구현하세요.',
    '이벤트 연결',
    System.Windows.Forms.MessageBoxButtons.OK,
    System.Windows.Forms.MessageBoxIcon.Information);
end;

// =============================================================================
// AddEventHandlerToXaml
// =============================================================================
procedure Form1.AddEventHandlerToXaml(controlName: string; eventName: string; handlerName: string);
var
  xaml   : string;
  pattern: string;
begin
  xaml := fXamlEditor.Text;
  if controlName = '' then exit;
  pattern := 'x:Name="' + controlName + '"';
  if not xaml.Contains(pattern) then exit;
  if xaml.Contains(eventName + '="' + handlerName + '"') then exit;
  xaml := xaml.Replace(pattern, pattern + ' ' + eventName + '="' + handlerName + '"');
  fXamlEditor.Text := xaml;
end;

function Form1.PreprocessXaml(xaml: string): string;
var
  s        : string;
  re       : System.Text.RegularExpressions.Regex;
  doc      : System.Xml.XmlDocument;
  root     : System.Xml.XmlElement;
  inner    : string;
  resInner : string;
  bgInner  : string;
  w, h     : string;
  sizeStr  : string;
begin
  s := xaml;

  s := StripEventAttributesForRuntime(s);

  re := new System.Text.RegularExpressions.Regex('\s+x:Class\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');
  re := new System.Text.RegularExpressions.Regex('\s+mc:Ignorable\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');
  re := new System.Text.RegularExpressions.Regex('\s+xmlns:mc\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');
  re := new System.Text.RegularExpressions.Regex('\s+xmlns:d\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');
  re := new System.Text.RegularExpressions.Regex('\s+d:\w+\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');

  var trimmed := s.TrimStart();
  if trimmed.StartsWith('<Window') or trimmed.StartsWith('<UserControl') then
  begin
    s := StripCustomNamespaces(s);
    try
      doc  := new System.Xml.XmlDocument();
      doc.LoadXml(s);
      root := doc.DocumentElement;

      w := root.GetAttribute('Width');
      h := root.GetAttribute('Height');
      if w = '' then w := root.GetAttribute('d:DesignWidth');
      if h = '' then h := root.GetAttribute('d:DesignHeight');
      if w = '' then w := '800';
      if h = '' then h := '450';
      sizeStr := ' Width="' + w + '" Height="' + h + '"';

      // 속성 요소(Window.Background, Window.Resources)와
      // 실제 콘텐츠 자식을 분리
      resInner := '';
      bgInner  := '';
      inner    := '';
      var n: System.Xml.XmlNode;
      foreach n in root.ChildNodes do
      begin
        if n.NodeType <> System.Xml.XmlNodeType.Element then continue;
        if n.LocalName.EndsWith('.Resources') then
          resInner := (n as System.Xml.XmlElement).InnerXml
        else if n.LocalName.EndsWith('.Background') then
          bgInner := (n as System.Xml.XmlElement).InnerXml
        else if not n.LocalName.Contains('.') then
          inner := inner + n.OuterXml;
        // 그 외 속성 요소(Window.Style 등)는 디자이너 미리보기에서 무시
      end;
    except
      inner    := '';
      resInner := '';
      bgInner  := '';
      sizeStr  := ' Width="800" Height="450"';
    end;

    var resBlock := '';
    if resInner <> '' then resBlock := '<Grid.Resources>' + resInner + '</Grid.Resources>';
    var bgBlock := '';
    if bgInner <> '' then bgBlock := '<Grid.Background>' + bgInner + '</Grid.Background>';

    Result :=
      '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
      '      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"' +
      sizeStr + '>' +
      resBlock + bgBlock + inner + '</Grid>';
    exit;
  end;

  Result := StripCustomNamespaces(s);
end;

// =============================================================================
// StripCustomNamespaces
// =============================================================================
function Form1.StripCustomNamespaces(xaml: string): string;
var
  prefixes: System.Collections.Generic.List<string>;
  m       : System.Text.RegularExpressions.Match;
  re      : System.Text.RegularExpressions.Regex;
  prefix  : string;
  s       : string;
begin
  s        := xaml;
  prefixes := new System.Collections.Generic.List<string>();
  re       := new System.Text.RegularExpressions.Regex('xmlns:(\w+)="clr-namespace:[^"]*"');
  m := re.Match(s);
  while m.Success do
  begin
    prefixes.Add(m.Groups[1].Value);
    m := m.NextMatch();
  end;
  foreach prefix in prefixes do
  begin
    s := System.Text.RegularExpressions.Regex.Replace(s, '<' + prefix + ':[^>]*/>', '');
    s := System.Text.RegularExpressions.Regex.Replace(s,
      '<' + prefix + ':[^>]*>[\s\S]*?</' + prefix + ':[^>]*>', '');
    s := System.Text.RegularExpressions.Regex.Replace(s,
      '\s+\w[\w.]*="\{[^"]*' + prefix + ':[^"]*\}"', '');
    s := System.Text.RegularExpressions.Regex.Replace(s,
      '\s+xmlns:' + prefix + '="clr-namespace:[^"]*"', '');
  end;
  Result := s;
end;

// =============================================================================
// SaveDesignerToString
// =============================================================================
function Form1.SaveDesignerToString: string;
var
  sw        : System.IO.StringWriter;
  xwSettings: System.Xml.XmlWriterSettings;
  xw        : System.Xml.XmlWriter;
begin
  if fSurface.DesignContext = nil then begin Result := ''; exit; end;
  sw                            := new System.IO.StringWriter();
  xwSettings                    := new System.Xml.XmlWriterSettings();
  xwSettings.Indent             := true;
  xwSettings.IndentChars        := '  ';
  xwSettings.OmitXmlDeclaration := true;
  xw := System.Xml.XmlWriter.Create(sw, xwSettings);
  fSurface.SaveDesigner(xw);
  xw.Flush();
  Result := sw.ToString();
end;

// =============================================================================
// SyncXamlEditor
// =============================================================================
procedure Form1.SyncXamlEditor;
var
  designerXml : string;
  currentXaml : string;
  innerXml    : string;
  doc         : System.Xml.XmlDocument;
  newXaml     : string;
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
      fXamlEditor.Text := currentXaml;
      exit;
    end;

    try
      var fullDoc := new System.Xml.XmlDocument();
      fullDoc.LoadXml(currentXaml);
      var fullRoot := fullDoc.DocumentElement;

      var toRemove := new System.Collections.Generic.List<System.Xml.XmlNode>();
      var child : System.Xml.XmlNode;
      foreach child in fullRoot.ChildNodes do
        if not child.LocalName.Contains('.') then
          toRemove.Add(child);
      var n: System.Xml.XmlNode;
      foreach n in toRemove do
        fullRoot.RemoveChild(n);

      if innerXml.Trim() <> '' then
      begin
        var tempDoc := new System.Xml.XmlDocument();
        tempDoc.LoadXml('<r xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
          ' xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' +
          innerXml + '</r>');
        var imp: System.Xml.XmlNode;
        foreach imp in tempDoc.DocumentElement.ChildNodes do
          fullRoot.AppendChild(fullDoc.ImportNode(imp, true));
      end;

      var sw2      := new System.IO.StringWriter();
      var xws2     := new System.Xml.XmlWriterSettings();
      xws2.Indent  := true;
      xws2.IndentChars        := '    ';
      xws2.OmitXmlDeclaration := true;
      var xw2 := System.Xml.XmlWriter.Create(sw2, xws2);
      fullDoc.WriteTo(xw2);
      xw2.Flush();
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
// LoadDesigner
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

// =============================================================================
// LoadXaml
// =============================================================================
procedure Form1.LoadXaml(xaml: string);
var
  designXaml: string;
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
    try
      LoadDesigner(designXaml);
    except
      on ex: System.Exception do
        System.Windows.Forms.MessageBox.Show('XAML 로드 오류: ' + ex.Message);
    end;
  finally
    fLoadingXaml := false;
  end;
end;

// =============================================================================
// ConnectEvents
// =============================================================================
procedure Form1.ConnectEvents;
var
  undoSvc: ICSharpCode.WpfDesign.Designer.Services.UndoService;
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
begin
  SyncXamlEditor();
end;

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
begin
  SyncXamlEditor();
end;

procedure Form1.UpdateFolding;
begin
  if (fFoldingManager = nil) or (fFoldingStrategy = nil) then exit;
  try fFoldingStrategy.UpdateFoldings(fFoldingManager, fXamlEditor.Document);
  except end;
end;

procedure Form1.OnFoldingTimerTick(sender: System.Object; e: System.EventArgs);
begin
  fFoldingTimer.Stop();
  UpdateFolding();
end;

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
    fFoldingManager  := nil;
    fFoldingStrategy := nil;
  end;
end;

procedure Form1.OnXamlTextChanged(sender: System.Object; e: System.EventArgs);
begin
  if (fFoldingManager <> nil) and menuItemFolding.Checked then
  begin
    fFoldingTimer.Stop();
    fFoldingTimer.Start();
  end;
end;

procedure Form1.OnToggleLineNumbers(sender: System.Object; e: System.EventArgs);
begin
  fXamlEditor.ShowLineNumbers := menuItemLineNum.Checked;
  fCodeEditor.ShowLineNumbers := menuItemLineNum.Checked;
end;

procedure Form1.OnToggleHighlight(sender: System.Object; e: System.EventArgs);
begin
  if menuItemHighlight.Checked then
    fXamlEditor.SyntaxHighlighting :=
      ICSharpCode.AvalonEdit.Highlighting.HighlightingManager.Instance.GetDefinition('XML')
  else
    fXamlEditor.SyntaxHighlighting := nil;
end;

procedure Form1.OnToggleWordWrap(sender: System.Object; e: System.EventArgs);
begin
  fXamlEditor.WordWrap := menuItemWordWrap.Checked;
  fCodeEditor.WordWrap := menuItemWordWrap.Checked;
end;

procedure Form1.OnToggleFolding(sender: System.Object; e: System.EventArgs);
begin
  if menuItemFolding.Checked then EnableFolding() else DisableFolding();
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
      begin
        procs[idx].Kill();
        procs[idx].WaitForExit(2000);
      end;
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
    psi.FileName            := 'where';
    psi.Arguments           := 'pabcnetc.exe';
    psi.UseShellExecute     := false;
    psi.RedirectStandardOutput := true;
    psi.CreateNoWindow      := true;
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
// OnErrorsCopy
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

// =============================================================================
// OnErrorsKeyDown
// =============================================================================
procedure Form1.OnErrorsKeyDown(sender: System.Object; e: System.Windows.Forms.KeyEventArgs);
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

// =============================================================================
// ShowBuildErrors
// =============================================================================
procedure Form1.ShowBuildErrors(output: string);
var
  lines: array of string;
  line : string;
  item : System.Windows.Forms.ListViewItem;
  re   : System.Text.RegularExpressions.Regex;
  m    : System.Text.RegularExpressions.Match;
begin
  lvErrors.Items.Clear();
  if output.Trim() = '' then
  begin
    item := new System.Windows.Forms.ListViewItem('빌드 실패 — 콘솔 창을 확인하세요.');
    item.ForeColor := System.Drawing.Color.Red;
    lvErrors.Items.Add(item);
  end
  else
  begin
    re    := new System.Text.RegularExpressions.Regex('([^(]+)\((\d+)\)\s*:\s*(.+)');
    lines := output.Split([#13, #10]);
    foreach line in lines do
    begin
      if line.Trim() = '' then continue;
      m := re.Match(line.Trim());
      if m.Success then
      begin
        item := new System.Windows.Forms.ListViewItem(m.Groups[3].Value);
        item.SubItems.Add(m.Groups[2].Value);
        item.SubItems.Add(m.Groups[1].Value);
        item.ForeColor := System.Drawing.Color.Red;
      end
      else
      begin
        item := new System.Windows.Forms.ListViewItem(line.Trim());
        item.SubItems.Add(''); item.SubItems.Add('');
      end;
      lvErrors.Items.Add(item);
    end;
  end;
end;

// =============================================================================
// BuildMenu
// =============================================================================
procedure Form1.BuildMenu;
var
  fileMenu, viewMenu, buildMenu, helpMenu: System.Windows.Forms.ToolStripMenuItem;
  newItem, openItem, saveItem            : System.Windows.Forms.ToolStripMenuItem;
  applyItem, syncItem                    : System.Windows.Forms.ToolStripMenuItem;
  buildItem, runItem, aboutItem          : System.Windows.Forms.ToolStripMenuItem;
begin
  menuStrip := new System.Windows.Forms.MenuStrip();

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

  viewMenu  := new System.Windows.Forms.ToolStripMenuItem('보기(&V)');
  applyItem := new System.Windows.Forms.ToolStripMenuItem('XAML 적용(&Y)');
  syncItem  := new System.Windows.Forms.ToolStripMenuItem('XAML 동기화(&X)');
  applyItem.Click += OnApplyXamlMenu;
  syncItem.Click  += OnSyncXamlMenu;
  viewMenu.DropDownItems.Add(applyItem);
  viewMenu.DropDownItems.Add(syncItem);
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

  menuItemFolding              := new System.Windows.Forms.ToolStripMenuItem('XML 폴딩(&F)');
  menuItemFolding.CheckOnClick := true;
  menuItemFolding.Checked      := true;
  menuItemFolding.Click        += OnToggleFolding;
  viewMenu.DropDownItems.Add(menuItemFolding);

  buildMenu := new System.Windows.Forms.ToolStripMenuItem('빌드(&B)');
  buildItem := new System.Windows.Forms.ToolStripMenuItem('빌드(&B)    F6');
  runItem   := new System.Windows.Forms.ToolStripMenuItem('실행(&R)    F5');
  buildItem.Click += OnBuild;
  runItem.Click   += OnRun;
  buildMenu.DropDownItems.Add(buildItem);
  buildMenu.DropDownItems.Add(runItem);

  helpMenu        := new System.Windows.Forms.ToolStripMenuItem('도움말(&H)');
  aboutItem       := new System.Windows.Forms.ToolStripMenuItem('정보(&A)...');
  aboutItem.Click += OnAbout;
  helpMenu.DropDownItems.Add(aboutItem);

  menuStrip.Items.Add(fileMenu);
  menuStrip.Items.Add(viewMenu);
  menuStrip.Items.Add(buildMenu);
  menuStrip.Items.Add(helpMenu);
  Self.Controls.Add(menuStrip);
  Self.MainMenuStrip := menuStrip;

  Self.KeyPreview := true;
  Self.KeyDown    += FormKeyDown;
end;

// =============================================================================
// BuildToolbox
// =============================================================================
procedure Form1.BuildToolbox;
var
  scroll      : System.Windows.Controls.ScrollViewer;
  title       : System.Windows.Controls.TextBlock;
  expLayout   : System.Windows.Controls.Expander;
  expCommon   : System.Windows.Controls.Expander;
  panelLayout : System.Windows.Controls.StackPanel;
  panelCommon : System.Windows.Controls.StackPanel;

  procedure AddBtn(panel: System.Windows.Controls.StackPanel; name: string; typeName: string);
  var
    btn : System.Windows.Controls.Button;
    sp  : System.Windows.Controls.StackPanel;
    icon: System.Windows.Controls.TextBlock;
    lbl : System.Windows.Controls.TextBlock;
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
    else
      icon.Text := '◆';
    end;
    lbl                   := new System.Windows.Controls.TextBlock();
    lbl.Text              := name;
    lbl.FontSize          := 12;
    lbl.VerticalAlignment := System.Windows.VerticalAlignment.Center;
    sp.Children.Add(icon);
    sp.Children.Add(lbl);
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
  var
    exp: System.Windows.Controls.Expander;
    hdr: System.Windows.Controls.TextBlock;
  begin
    hdr            := new System.Windows.Controls.TextBlock();
    hdr.Text       := header;
    hdr.FontWeight := System.Windows.FontWeights.Bold;
    hdr.FontSize   := 12;
    exp            := new System.Windows.Controls.Expander();
    exp.Header     := hdr;
    exp.IsExpanded := true;
    exp.Margin     := new System.Windows.Thickness(0, 2, 0, 2);
    Result         := exp;
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
// BuildLayout
// =============================================================================
procedure Form1.BuildLayout;
var
  mainPanel    : System.Windows.Forms.Panel;
  toolboxPanel : System.Windows.Forms.Panel;
  propPanel    : System.Windows.Forms.Panel;
  editorGrid   : System.Windows.Controls.Grid;
  editorRow0   : System.Windows.Controls.RowDefinition;
  editorRow1   : System.Windows.Controls.RowDefinition;
  applyBtn     : System.Windows.Controls.Button;
  errPanel     : System.Windows.Forms.Panel;
  errLabel     : System.Windows.Forms.Label;
  colMsg, colLine, colFile: System.Windows.Forms.ColumnHeader;
begin
  fPropView       := new ICSharpCode.WpfDesign.Designer.PropertyGrid.PropertyGridView();
  hostRight       := new System.Windows.Forms.Integration.ElementHost();
  hostRight.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostRight.Child := fPropView;
  propPanel       := new System.Windows.Forms.Panel();
  propPanel.Dock  := System.Windows.Forms.DockStyle.Fill;
  propPanel.Controls.Add(hostRight);

  hostDesign      := new System.Windows.Forms.Integration.ElementHost();
  hostDesign.Dock := System.Windows.Forms.DockStyle.Fill;

  fXamlEditor                    := new ICSharpCode.AvalonEdit.TextEditor();
  fXamlEditor.FontFamily         := new System.Windows.Media.FontFamily('Consolas');
  fXamlEditor.FontSize           := 13;
  fXamlEditor.ShowLineNumbers    := true;
  fXamlEditor.SyntaxHighlighting :=
    ICSharpCode.AvalonEdit.Highlighting.HighlightingManager.Instance.GetDefinition('XML');
  fXamlEditor.WordWrap           := false;
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

  fCodeEditor                    := new ICSharpCode.AvalonEdit.TextEditor();
  fCodeEditor.FontFamily         := new System.Windows.Media.FontFamily('Consolas');
  fCodeEditor.FontSize           := 13;
  fCodeEditor.ShowLineNumbers    := true;
  fCodeEditor.WordWrap           := false;
  fCodeEditor.HorizontalScrollBarVisibility := System.Windows.Controls.ScrollBarVisibility.Auto;
  fCodeEditor.VerticalScrollBarVisibility   := System.Windows.Controls.ScrollBarVisibility.Auto;
  hostCode       := new System.Windows.Forms.Integration.ElementHost();
  hostCode.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostCode.Child := fCodeEditor;

  tabControl      := new System.Windows.Forms.TabControl();
  tabControl.Dock := System.Windows.Forms.DockStyle.Fill;
  tabControl.SelectedIndexChanged += OnTabChanged;
  tabDesign := new System.Windows.Forms.TabPage('🎨 디자인');
  tabDesign.Controls.Add(hostDesign);
  tabXaml   := new System.Windows.Forms.TabPage('📄 XAML');
  tabXaml.Controls.Add(hostXaml);
  tabCode   := new System.Windows.Forms.TabPage('💻 코드');
  tabCode.Controls.Add(hostCode);
  tabControl.TabPages.Add(tabDesign);
  tabControl.TabPages.Add(tabXaml);
  tabControl.TabPages.Add(tabCode);

  errLabel           := new System.Windows.Forms.Label();
  errLabel.Text      := '오류 목록';
  errLabel.Dock      := System.Windows.Forms.DockStyle.Top;
  errLabel.Font      := new System.Drawing.Font('Segoe UI', 9, System.Drawing.FontStyle.Bold);
  errLabel.BackColor := System.Drawing.Color.FromArgb(230, 230, 230);
  errLabel.Height    := 22;

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

  colMsg      := new System.Windows.Forms.ColumnHeader();
  colMsg.Text := '오류 메시지'; colMsg.Width := 500;
  colLine      := new System.Windows.Forms.ColumnHeader();
  colLine.Text := '줄'; colLine.Width := 60;
  colFile      := new System.Windows.Forms.ColumnHeader();
  colFile.Text := '파일'; colFile.Width := 200;
  lvErrors.Columns.Add(colMsg);
  lvErrors.Columns.Add(colLine);
  lvErrors.Columns.Add(colFile);

  errPanel      := new System.Windows.Forms.Panel();
  errPanel.Dock := System.Windows.Forms.DockStyle.Fill;
  errPanel.Controls.Add(lvErrors);
  errPanel.Controls.Add(errLabel);

  splitRight                  := new System.Windows.Forms.SplitContainer();
  splitRight.Dock             := System.Windows.Forms.DockStyle.Fill;
  splitRight.Orientation      := System.Windows.Forms.Orientation.Vertical;
  splitRight.SplitterDistance := 1100;
  splitRight.Panel1.Controls.Add(tabControl);
  splitRight.Panel2.Controls.Add(propPanel);

  toolboxPanel      := new System.Windows.Forms.Panel();
  toolboxPanel.Dock := System.Windows.Forms.DockStyle.Fill;
  toolboxPanel.Controls.Add(hostLeft);

  splitDesign                  := new System.Windows.Forms.SplitContainer();
  splitDesign.Dock             := System.Windows.Forms.DockStyle.Fill;
  splitDesign.Orientation      := System.Windows.Forms.Orientation.Vertical;
  splitDesign.SplitterDistance := 5;
  splitDesign.Panel1.Controls.Add(toolboxPanel);
  splitDesign.Panel2.Controls.Add(splitRight);

  splitMain                  := new System.Windows.Forms.SplitContainer();
  splitMain.Dock             := System.Windows.Forms.DockStyle.Fill;
  splitMain.Orientation      := System.Windows.Forms.Orientation.Horizontal;
  splitMain.SplitterDistance := 750;
  splitMain.Panel1.Controls.Add(splitDesign);
  splitMain.Panel2.Controls.Add(errPanel);

  mainPanel      := new System.Windows.Forms.Panel();
  mainPanel.Dock := System.Windows.Forms.DockStyle.Fill;
  mainPanel.Controls.Add(splitMain);
  Self.Controls.Add(mainPanel);

  fFoldingTimer          := new System.Windows.Threading.DispatcherTimer();
  fFoldingTimer.Interval := System.TimeSpan.FromMilliseconds(500);
  fFoldingTimer.Tick     += OnFoldingTimerTick;
  fXamlEditor.TextChanged += OnXamlTextChanged;
end;

// =============================================================================
// OnToolboxClick
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
  begin
    t := asms[i].GetType(tname);
    i += 1;
  end;
  if t = nil then
  begin
    System.Windows.Forms.MessageBox.Show('타입 없음: ' + tname);
    exit;
  end;
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
      if childProp.IsCollection then
        childProp.CollectionElements.Add(newItem)
      else
        childProp.SetValue(newItem);
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

procedure Form1.FormKeyDown(sender: System.Object; ke: System.Windows.Forms.KeyEventArgs);
begin
  if ke.KeyCode = System.Windows.Forms.Keys.F5 then
    OnRun(sender, System.EventArgs.Empty)
  else if ke.KeyCode = System.Windows.Forms.Keys.F6 then
    OnBuild(sender, System.EventArgs.Empty);
end;

procedure Form1.OnFormClosing(sender: System.Object;
  e: System.Windows.Forms.FormClosingEventArgs);
begin
  KillPreviousBuildProcesses();
end;

// =============================================================================
// OnAbout
// =============================================================================
procedure Form1.OnAbout(sender: System.Object; e: System.EventArgs);
begin
  System.Windows.Forms.MessageBox.Show(
    'PascalABC-WPF-Designer Ver 2.0.2' + System.Environment.NewLine + System.Environment.NewLine +
    '■ VS 호환 XAML 지원' + System.Environment.NewLine +
    '  · x:Class, x:Name, 이벤트 속성 100% 호환' + System.Environment.NewLine +
    '  · mc:Ignorable, d:DesignHeight/Width 지원' + System.Environment.NewLine + System.Environment.NewLine +
    '■ 프로젝트 템플릿' + System.Environment.NewLine +
    '  · WPF 애플리케이션 (Window 루트)' + System.Environment.NewLine +
    '  · WPF 사용자 정의 컨트롤 라이브러리 (UserControl 루트)' + System.Environment.NewLine + System.Environment.NewLine +
    '■ 자동 코드 생성' + System.Environment.NewLine +
    '  · InitializeComponent() 자동 생성' + System.Environment.NewLine +
    '  · FindName() 컨트롤 바인딩' + System.Environment.NewLine +
    '  · 이벤트 핸들러 시그니처 자동 생성' + System.Environment.NewLine + System.Environment.NewLine +
    'Built with PascalABC.NET 3.11.1.3833' + System.Environment.NewLine +
    'ICSharpCode.WpfDesign + AvalonEdit' + System.Environment.NewLine + System.Environment.NewLine +
    'made by sigmak (dwfree74@gmail.com) with claude.ai ',
    '정보',
    System.Windows.Forms.MessageBoxButtons.OK,
    System.Windows.Forms.MessageBoxIcon.Information);
end;

// =============================================================================
begin
  System.Threading.Thread.CurrentThread.SetApartmentState(
    System.Threading.ApartmentState.STA);
  System.Windows.Forms.Application.EnableVisualStyles();
  System.Windows.Forms.Application.Run(new Form1());
end.