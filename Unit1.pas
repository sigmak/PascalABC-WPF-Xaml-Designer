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

type
  Form1 = class(System.Windows.Forms.Form)
  private
    fSurface : ICSharpCode.WpfDesign.Designer.DesignSurface;
    fPropView: ICSharpCode.WpfDesign.Designer.PropertyGrid.PropertyGridView;
    fXamlEditor   : ICSharpCode.AvalonEdit.TextEditor;  // XAML 탭 에디터
    fCodeEditor   : ICSharpCode.AvalonEdit.TextEditor;  // 코드 탭 에디터
    fOriginalXaml : string;
    fLoadingXaml  : boolean;

    // 프로젝트 관련
    fProjectPath  : string;  // 현재 프로젝트 폴더
    fXamlFileName : string;  // MainWindow.xaml
    fPasFileName  : string;  // MainWindow.pas

    menuStrip     : System.Windows.Forms.MenuStrip;
    hostDesign    : System.Windows.Forms.Integration.ElementHost;
    hostLeft      : System.Windows.Forms.Integration.ElementHost;
    hostRight     : System.Windows.Forms.Integration.ElementHost;
    hostXaml          : System.Windows.Forms.Integration.ElementHost;
    hostCode          : System.Windows.Forms.Integration.ElementHost;
    fToolboxPanel : System.Windows.Controls.StackPanel;

    // 탭 컨트롤 (디자인 / XAML / 코드)
    tabControl        : System.Windows.Forms.TabControl;
    tabDesign         : System.Windows.Forms.TabPage;
    tabXaml           : System.Windows.Forms.TabPage;
    tabCode           : System.Windows.Forms.TabPage;

    // 오류 목록 패널
    lvErrors          : System.Windows.Forms.ListView;
    splitMain         : System.Windows.Forms.SplitContainer;  // 상하 분할 (메인/오류)
    splitDesign       : System.Windows.Forms.SplitContainer;  // 좌우 분할 (툴박스/탭+속성)
    splitRight        : System.Windows.Forms.SplitContainer;  // 좌우 분할 (탭/속성)

    // 보기 메뉴 체크 항목
    menuItemLineNum   : System.Windows.Forms.ToolStripMenuItem;
    menuItemHighlight : System.Windows.Forms.ToolStripMenuItem;
    menuItemWordWrap  : System.Windows.Forms.ToolStripMenuItem;
    menuItemFolding   : System.Windows.Forms.ToolStripMenuItem;

    // XML 폴딩
    fFoldingManager  : ICSharpCode.AvalonEdit.Folding.FoldingManager;
    fFoldingStrategy : ICSharpCode.AvalonEdit.Folding.XmlFoldingStrategy;
    fFoldingTimer    : System.Windows.Threading.DispatcherTimer;

    procedure BuildMenu;
    procedure BuildToolbox;
    procedure BuildLayout;
    procedure ConnectEvents;

    // 이벤트 핸들러
    procedure OnToolboxClick(sender: System.Object; e: System.Windows.RoutedEventArgs); // ← 별도 핸들러
    // 선언부에서 시그니처 변경
    procedure OnDesignerDoubleClick(sender: System.Object; e: System.Windows.Input.MouseButtonEventArgs);
    procedure OnSelectionChanged(sender: System.Object; e: ICSharpCode.WpfDesign.DesignItemCollectionEventArgs);
    procedure OnUndoStackChanged(sender: System.Object; e: System.EventArgs);
    procedure OnTabChanged(sender: System.Object; e: System.EventArgs);
    
    procedure FormKeyDown(sender: System.Object; ke: System.Windows.Forms.KeyEventArgs);    

    // 파일 메뉴
    procedure OnNewProject(sender: System.Object; e: System.EventArgs);
    procedure OnSave(sender: System.Object; e: System.EventArgs);
    procedure OnOpen(sender: System.Object; e: System.EventArgs);

    // 보기 메뉴
    procedure OnApplyXaml(sender: System.Object; e: System.Windows.RoutedEventArgs);
    procedure OnApplyXamlMenu(sender: System.Object; e: System.EventArgs);
    procedure OnSyncXamlMenu(sender: System.Object; e: System.EventArgs);  // 메뉴용 WinForms
    procedure OnToggleLineNumbers(sender: System.Object; e: System.EventArgs);
    procedure OnToggleHighlight(sender: System.Object; e: System.EventArgs);
    procedure OnToggleWordWrap(sender: System.Object; e: System.EventArgs);
    procedure OnToggleFolding(sender: System.Object; e: System.EventArgs);

    // 빌드 메뉴
    procedure OnBuild(sender: System.Object; e: System.EventArgs);
    procedure OnRun(sender: System.Object; e: System.EventArgs);
    function  FindPabcCompiler: string;
    procedure OnErrorsCopy(sender: System.Object; e: System.EventArgs);
    procedure OnErrorsKeyDown(sender: System.Object; e: System.Windows.Forms.KeyEventArgs);

    // 폴딩
    procedure UpdateFolding;
    procedure OnFoldingTimerTick(sender: System.Object; e: System.EventArgs);
    procedure EnableFolding;
    procedure DisableFolding;
    procedure OnXamlTextChanged(sender: System.Object; e: System.EventArgs);
    procedure OnAbout(sender: System.Object; e: System.EventArgs);
    // XAML/코드 처리
    procedure LoadXaml(xaml: string);
    procedure LoadDesigner(designXaml: string);
    procedure SyncXamlEditor;
    function  SaveDesignerToString: string;
    function  StripCustomNamespaces(xaml: string): string;
    function  PreprocessXaml(xaml: string): string;

    // 프로젝트/코드 생성
    function  GeneratePasCode(xamlFileName: string): string;
    procedure AddEventHandlerToXaml(controlName: string; eventName: string; handlerName: string);
    procedure AddEventHandlerToCode(handlerName: string);
    procedure ShowBuildErrors(output: string);
  public
    constructor Create;
  end;

// ═════════════════════════════════════════════
constructor Form1.Create;
begin
  inherited Create;
  Self.Text   := 'PascalABC-WPF-Xaml-Designer Ver 1.2.4';
  Self.Width  := 1600;
  Self.Height := 950;

  ICSharpCode.WpfDesign.Designer.BasicMetadata.Register();

  fProjectPath  := System.IO.Path.GetTempPath() + 'PascalWpfProject\';
  fXamlFileName := 'MainWindow.xaml';
  fPasFileName  := 'MainWindow.pas';

  if not System.IO.Directory.Exists(fProjectPath) then
    System.IO.Directory.CreateDirectory(fProjectPath);

  BuildToolbox;
  BuildLayout;
  BuildMenu;

  LoadXaml(
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
    '      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"' +
    '      Background="White" Width="600" Height="400">' +
    '  <Button x:Name="btnHello" Width="100" Height="30" Content="Hello"' +
    '          HorizontalAlignment="Left" VerticalAlignment="Top"' +
    '          Margin="20,20,0,0"/>' +
    '</Grid>'
  );

  // 초기 코드 에디터 내용 생성
  fCodeEditor.Text := GeneratePasCode(fXamlFileName);
end;

// ═════════════════════════════════════════════
// PascalABC.NET WPF 코드비하인드 템플릿 생성
function Form1.GeneratePasCode(xamlFileName: string): string;
var
  sb: System.Text.StringBuilder;
begin
  sb := new System.Text.StringBuilder();
  sb.AppendLine('unit MainUnit;');          // ← MainWindow → MainUnit
  sb.AppendLine('');
  sb.AppendLine('{$reference PresentationFramework.dll}');
  sb.AppendLine('{$reference PresentationCore.dll}');
  sb.AppendLine('{$reference WindowsBase.dll}');
  sb.AppendLine('');
  sb.AppendLine('uses');
  sb.AppendLine('  System.Windows,');
  sb.AppendLine('  System.Windows.Controls;');
  sb.AppendLine('');
  sb.AppendLine('type');
  sb.AppendLine('  MainWindow = class(System.Windows.Window)');
  sb.AppendLine('  public');
  sb.AppendLine('    constructor Create;');
  sb.AppendLine('  end;');
  sb.AppendLine('');
  sb.AppendLine('constructor MainWindow.Create;');
  sb.AppendLine('begin');
  sb.AppendLine('  inherited Create;');
  sb.AppendLine('  System.Windows.Application.LoadComponent(');
  sb.AppendLine('    Self,');
  sb.AppendLine(
    System.String.Format('    new System.Uri(''{0}'', System.UriKind.Relative)',
      [xamlFileName])
  );
  sb.AppendLine('  );');
  sb.AppendLine('end;');
  sb.AppendLine('');
  sb.AppendLine('// ─── 이벤트 핸들러 ───────────────────────────');
  sb.AppendLine('');
  sb.AppendLine('begin');
  sb.AppendLine('  var app := new System.Windows.Application();');
  sb.AppendLine('  app.Run(new MainWindow());');
  sb.AppendLine('end.');
  Result := sb.ToString();
end;

// ═════════════════════════════════════════════
// 디자이너에서 컨트롤 더블클릭 → 이벤트 핸들러 자동 생성
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

  // 첫 번째 선택 아이템
  item := nil;
  var enumerator := selectedItems.GetEnumerator();
  if enumerator.MoveNext() then
    item := enumerator.Current;
  if item = nil then exit;

  // 컨트롤 이름 (x:Name 속성)
  var nameProp := item.Properties['Name'];
  if (nameProp <> nil) and (nameProp.ValueOnInstance <> nil) then
    controlName := nameProp.ValueOnInstance.ToString()
  else
    controlName := '';

  // 컨트롤 타입명 (짧은 이름)
  controlType := item.ComponentType.Name;

  // 컨트롤 타입별 기본 이벤트 결정
  case controlType of
    'Button'     : eventName := 'Click';
    'TextBox'    : eventName := 'TextChanged';
    'CheckBox'   : eventName := 'Checked';
    'ComboBox'   : eventName := 'SelectionChanged';
    'ListBox'    : eventName := 'SelectionChanged';
    'Slider'     : eventName := 'ValueChanged';
    'RadioButton': eventName := 'Checked';
  else
    eventName := 'Loaded';
  end;

  // 핸들러명 생성: controlName_eventName 또는 controlType_eventName
  if controlName <> '' then
    handlerName := controlName + '_' + eventName
  else
    handlerName := controlType + '_' + eventName;

  // XAML에 이벤트 속성 추가
  AddEventHandlerToXaml(controlName, eventName, handlerName);

  // 코드에 핸들러 추가
  AddEventHandlerToCode(handlerName);

  // 코드 탭으로 전환
  tabControl.SelectedTab := tabCode;

  System.Windows.Forms.MessageBox.Show(
    '이벤트 핸들러 생성: ' + handlerName + #13#10 +
    '코드 탭에서 구현하세요.',
    '이벤트 연결', System.Windows.Forms.MessageBoxButtons.OK,
    System.Windows.Forms.MessageBoxIcon.Information);
end;

// ═════════════════════════════════════════════
// XAML에 이벤트 속성 추가
procedure Form1.AddEventHandlerToXaml(controlName: string; eventName: string; handlerName: string);
var
  xaml   : string;
  pattern: string;
  replace: string;
begin
  xaml := fXamlEditor.Text;

  // controlName이 있으면 해당 컨트롤 찾아서 이벤트 추가
  if controlName <> '' then
  begin
    // x:Name="controlName" 을 포함한 태그에 이벤트 속성 추가
    pattern := 'x:Name="' + controlName + '"';
    if xaml.Contains(pattern) then
    begin
      // 이미 이벤트가 있으면 추가하지 않음
      if not xaml.Contains(eventName + '="' + handlerName + '"') then
        replace := pattern + ' ' + eventName + '="' + handlerName + '"'
      else
        replace := pattern;
      xaml := xaml.Replace(pattern, replace);
    end;
  end;

  fXamlEditor.Text := xaml;
end;

// ═════════════════════════════════════════════
// 코드 파일에 이벤트 핸들러 추가
procedure Form1.AddEventHandlerToCode(handlerName: string);
var
  code   : string;
  marker : string;
  handler: string;
  sb     : System.Text.StringBuilder;
begin
  code := fCodeEditor.Text;
  marker := '// ─── 이벤트 핸들러 ───────────────────────────';

  // 이미 핸들러가 있으면 추가하지 않음
  if code.Contains('procedure MainWindow.' + handlerName) then exit;

  // 핸들러 코드 생성
  sb := new System.Text.StringBuilder();
  sb.AppendLine('procedure MainWindow.' + handlerName +
    '(sender: System.Object; e: System.Windows.RoutedEventArgs);');
  sb.AppendLine('begin');
  sb.AppendLine('  // TODO: ' + handlerName + ' 구현');
  sb.AppendLine('end;');
  sb.AppendLine('');
  handler := sb.ToString();

  // 선언부에 추가 (type 블록 안)
  var typeMarker := '    constructor Create;';
  if code.Contains(typeMarker) then
  begin
    var decl := '    procedure ' + handlerName +
      '(sender: System.Object; e: System.Windows.RoutedEventArgs);';
    code := code.Replace(typeMarker,
      typeMarker + System.Environment.NewLine + decl);
  end;

  // 구현부 마커 뒤에 핸들러 삽입
  if code.Contains(marker) then
    code := code.Replace(marker, marker +
      System.Environment.NewLine + System.Environment.NewLine + handler)
  else
    // 마커 없으면 begin 앞에 삽입
    code := code.Replace(#13#10 + 'begin' + #13#10,
      #13#10 + handler + 'begin' + #13#10);

  fCodeEditor.Text := code;
end;

// ═════════════════════════════════════════════
// pabcnetc.exe 경로 탐색
function Form1.FindPabcCompiler: string;
var
  candidates: array of string;
  path      : string;
  regPath   : string;
begin
  Result := '';

  // 1) 레지스트리에서 설치 경로 확인
  try
    regPath := System.Convert.ToString(
      Microsoft.Win32.Registry.GetValue(
        'HKEY_LOCAL_MACHINE\SOFTWARE\PascalABC.NET',
        'InstallDir', ''));
    if (regPath <> '') and
       System.IO.File.Exists(regPath + '\pabcnetc.exe') then
    begin
      Result := regPath + '\pabcnetc.exe';
      exit;
    end;
  except
  end;

  // 2) 일반적인 설치 경로들 확인
  candidates := [
    'C:\Program Files\PascalABC.NET\pabcnetc.exe',
    'C:\Program Files (x86)\PascalABC.NET\pabcnetc.exe',
    System.Environment.GetFolderPath(
      System.Environment.SpecialFolder.LocalApplicationData) +
      '\PascalABC.NET\pabcnetc.exe',
    System.AppDomain.CurrentDomain.BaseDirectory + 'pabcnetc.exe'
  ];

  foreach path in candidates do
  begin
    if System.IO.File.Exists(path) then
    begin
      Result := path;
      exit;
    end;
  end;

  // 3) PATH 환경변수에서 찾기 (where 명령 사용)
  try
    var psi := new System.Diagnostics.ProcessStartInfo();
    psi.FileName               := 'where';
    psi.Arguments              := 'pabcnetc.exe';
    psi.UseShellExecute        := false;
    psi.RedirectStandardOutput := true;
    psi.CreateNoWindow         := true;
    var proc := System.Diagnostics.Process.Start(psi);
    var output := proc.StandardOutput.ReadToEnd().Trim();
    proc.WaitForExit();
    if (output <> '') and System.IO.File.Exists(output.Split([#13, #10])[0]) then
      Result := output.Split([#13, #10])[0];
  except
  end;
end;

// ═════════════════════════════════════════════
// 빌드: bat 파일 경유, 단계별로 try/except를 분리해서
// 예외 발생 시 즉시 ex.Message를 문자열로 캡처 → 이후 ex 객체를 다시 참조하지 않음
// (ToString() 실패는 보통 예외 객체가 finally 블록 등에서 재사용/지연 평가될 때 발생)
procedure Form1.OnBuild(sender: System.Object; e: System.EventArgs);
var
  xamlPath: string;
  pasPath : string;
  outputFile: string;
  compilerPath: string;
  tempBat : string;
  output      : string;
  exitCode    : integer;
  hadError    : boolean;
  errMsg      : string;
begin
  hadError := false;
  errMsg   := '';
  output   := '';
  exitCode := -1;

  xamlPath := fProjectPath + fXamlFileName;
  pasPath  := fProjectPath + fPasFileName;
  tempBat    := fProjectPath + 'build.bat';
  outputFile := fProjectPath + 'build_output.txt';

  
  try
    // 1) XAML파일 저장
    System.IO.File.WriteAllText(xamlPath, fXamlEditor.Text, System.Text.Encoding.UTF8);
    // 2) PAS 저장
    System.IO.File.WriteAllText(pasPath,  fCodeEditor.Text, System.Text.Encoding.UTF8);
  except
    on ex: System.Exception do
    begin
      errMsg   := ex.Message;
      hadError := true;
    end;
  end;

  if hadError then
  begin
    System.Windows.Forms.MessageBox.Show('파일 저장 오류: ' + errMsg);
    exit;
  end;

  // 2) 컴파일러 경로 탐색
  compilerPath := FindPabcCompiler();
  System.Windows.Forms.MessageBox.Show('컴파일러 위치: ' + compilerPath);
  if compilerPath = '' then
  begin
    System.Windows.Forms.MessageBox.Show(
      'pabcnetc.exe를 찾을 수 없습니다.' + #13#10 +
      'PascalABC.NET 설치 경로를 확인하세요.',
      '컴파일러를 찾을 수 없음',
      System.Windows.Forms.MessageBoxButtons.OK,
      System.Windows.Forms.MessageBoxIcon.Warning);
    exit;
  end;

// 3) bat 파일 생성 - 리디렉션 없이
  try
    var batContent := new System.Text.StringBuilder();
    batContent.AppendLine('@echo off');
    // > 리디렉션 완전 제거, 그냥 실행만
    batContent.AppendLine('"' + compilerPath + '" "' + pasPath + '"');
    batContent.AppendLine('exit %ERRORLEVEL%');
    System.IO.File.WriteAllText(tempBat, batContent.ToString(),
      System.Text.Encoding.Default);
  except
    on ex: System.Exception do
    begin
      errMsg   := ex.Message;
      hadError := true;
    end;
  end;
  if hadError then
  begin
    System.Windows.Forms.MessageBox.Show('빌드 스크립트 생성 오류: ' + errMsg);
    exit;
  end;

  // 4) 빌드 프로세스 실행
  try
    var psi := new System.Diagnostics.ProcessStartInfo();
    psi.FileName         := 'cmd.exe';
    psi.Arguments        := '/c "' + tempBat + '"';
    psi.WorkingDirectory := fProjectPath;
    psi.UseShellExecute  := true;
    psi.CreateNoWindow   := false;
    psi.WindowStyle      := System.Diagnostics.ProcessWindowStyle.Normal;

    var proc := new System.Diagnostics.Process();
    proc.StartInfo := psi;
    proc.Start();
    proc.WaitForExit(60000);

    if not proc.HasExited then
    begin
      try proc.Kill(); except end;
      errMsg   := '컴파일 시간 초과 (60초)';
      hadError := true;
    end
    else
      exitCode := proc.ExitCode;
  except
    on ex: System.Exception do
    begin
      errMsg   := ex.Message;
      hadError := true;
    end;
  end;

  // 5) 출력 파일 읽기 - exe 존재 여부로 성공 판단
  if not hadError then
  begin
    var exePath := fProjectPath +
      System.IO.Path.GetFileNameWithoutExtension(fPasFileName) + '.exe';
    if System.IO.File.Exists(exePath) then
      exitCode := 0
    else
      exitCode := 1;
    output := ''; // 출력을 캡처할 수 없으므로 비워둠
  end;

  // 6) 임시 파일 정리
  try
    if System.IO.File.Exists(tempBat) then System.IO.File.Delete(tempBat);
  except
  end;
  

  // 7) 결과 표시
  if hadError then
  begin
    lvErrors.Items.Clear();
    var item := new System.Windows.Forms.ListViewItem('빌드 실행 오류: ' + errMsg);
    item.ForeColor := System.Drawing.Color.Red;
    lvErrors.Items.Add(item);
    System.Windows.Forms.MessageBox.Show('빌드 실행 중 오류가 발생했습니다: ' + errMsg);
    exit;
  end;

  if exitCode = 0 then
  begin
    lvErrors.Items.Clear();
    var item := new System.Windows.Forms.ListViewItem('빌드 성공');
    item.SubItems.Add('');
    item.SubItems.Add('');
    item.ForeColor := System.Drawing.Color.Green;
    lvErrors.Items.Add(item);
    System.Windows.Forms.MessageBox.Show('빌드 성공!',
      '빌드', System.Windows.Forms.MessageBoxButtons.OK,
      System.Windows.Forms.MessageBoxIcon.Information);
  end
  else
    ShowBuildErrors(output);
end;

// ═════════════════════════════════════════════
// 실행: 빌드 후 EXE 실행
procedure Form1.OnRun(sender: System.Object; e: System.EventArgs);
var
  exePath: string;
begin
  OnBuild(sender, e);  // 먼저 빌드

  exePath := fProjectPath +
    System.IO.Path.GetFileNameWithoutExtension(fPasFileName) + '.exe';

  if System.IO.File.Exists(exePath) then
  begin
    try
      System.Diagnostics.Process.Start(exePath);
    except
      on ex: System.Exception do
        System.Windows.Forms.MessageBox.Show('실행 오류: ' + ex.Message);
    end;
  end
  else
    System.Windows.Forms.MessageBox.Show(
      '빌드된 실행 파일을 찾을 수 없습니다: ' + exePath,
      '실행 오류', System.Windows.Forms.MessageBoxButtons.OK,
      System.Windows.Forms.MessageBoxIcon.Error);
end;

// ═════════════════════════════════════════════
// 오류목록 선택 항목을 클립보드로 복사 (탭 구분, 한글 정상)
procedure Form1.OnErrorsCopy(sender: System.Object; e: System.EventArgs);
var
  sb  : System.Text.StringBuilder;
  item: System.Windows.Forms.ListViewItem;
begin
  if lvErrors.SelectedItems.Count = 0 then exit;
  sb := new System.Text.StringBuilder();
  foreach item in lvErrors.SelectedItems do
  begin
    sb.Append(item.Text);
    sb.Append(#9);
    if item.SubItems.Count > 1 then sb.Append(item.SubItems[1].Text); // 줄
    sb.Append(#9);
    if item.SubItems.Count > 2 then sb.Append(item.SubItems[2].Text); // 파일
    sb.AppendLine();
  end;
  System.Windows.Forms.Clipboard.SetText(sb.ToString());
end;

procedure Form1.OnErrorsKeyDown(sender: System.Object; e: System.Windows.Forms.KeyEventArgs);
begin
  if e.Control and (e.KeyCode = System.Windows.Forms.Keys.C) then
  begin
    OnErrorsCopy(sender, System.EventArgs.Empty);
    e.Handled := true;
  end
  else if e.Control and (e.KeyCode = System.Windows.Forms.Keys.A) then
  begin
    var i: integer;
    for i := 0 to lvErrors.Items.Count - 1 do
      lvErrors.Items[i].Selected := true;
    e.Handled := true;
  end;
end;

// ═════════════════════════════════════════════
// 빌드 오류 파싱 → 오류 목록에 표시
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
    item := new System.Windows.Forms.ListViewItem(
      '빌드가 실패했지만 출력 메시지가 없습니다. 컴파일러 경로/권한을 확인하세요.');
    item.SubItems.Add('');
    item.SubItems.Add('');
    item.ForeColor := System.Drawing.Color.Red;
    lvErrors.Items.Add(item);
  end
  else
  begin
    // PascalABC.NET 오류 형식: FileName(Line) : Error message
    re    := new System.Text.RegularExpressions.Regex(
      '([^(]+)\((\d+)\)\s*:\s*(.+)');
    lines := output.Split([#13, #10]);

    foreach line in lines do
    begin
      if line.Trim() = '' then continue;
      m := re.Match(line.Trim());
      if m.Success then
      begin
        item := new System.Windows.Forms.ListViewItem(m.Groups[3].Value); // 메시지
        item.SubItems.Add(m.Groups[2].Value);  // 줄번호
        item.SubItems.Add(m.Groups[1].Value);  // 파일명
        item.ForeColor := System.Drawing.Color.Red;
        lvErrors.Items.Add(item);
      end
      else
      begin
        item := new System.Windows.Forms.ListViewItem(line.Trim());
        item.SubItems.Add('');
        item.SubItems.Add('');
        lvErrors.Items.Add(item);
      end;
    end;
  end;

  System.Windows.Forms.MessageBox.Show('빌드 오류가 발생했습니다. 오류 목록을 확인하세요.',
    '빌드 실패', System.Windows.Forms.MessageBoxButtons.OK,
    System.Windows.Forms.MessageBoxIcon.Error);
end;

// ═════════════════════════════════════════════
// 새 프로젝트
procedure Form1.OnNewProject(sender: System.Object; e: System.EventArgs);
var
  dlg: System.Windows.Forms.FolderBrowserDialog;
begin
  dlg             := new System.Windows.Forms.FolderBrowserDialog();
  dlg.Description := '프로젝트 폴더를 선택하세요';
  if dlg.ShowDialog() = System.Windows.Forms.DialogResult.OK then
  begin
    fProjectPath := dlg.SelectedPath + '\';
    LoadXaml(
      '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
      '      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"' +
      '      Background="White" Width="600" Height="400">' +
      '</Grid>'
    );
    fCodeEditor.Text := GeneratePasCode(fXamlFileName);
    Self.Text := 'PascalABC WPF XAML Designer - ' + fProjectPath;
  end;
end;

// ═════════════════════════════════════════════
function Form1.SaveDesignerToString: string;
var
  sw        : System.IO.StringWriter;
  xwSettings: System.Xml.XmlWriterSettings;
  xw        : System.Xml.XmlWriter;
begin
  if fSurface.DesignContext = nil then
  begin
    Result := '';
    exit;
  end;
  sw            := new System.IO.StringWriter();
  xwSettings    := new System.Xml.XmlWriterSettings();
  xwSettings.Indent      := true;
  xwSettings.IndentChars := '  ';
  xw := System.Xml.XmlWriter.Create(sw, xwSettings);
  fSurface.SaveDesigner(xw);
  xw.Flush();
  Result := sw.ToString();
end;

// ═════════════════════════════════════════════
// 하단 XAML 에디터를 디자이너 현재 상태로 동기화
procedure Form1.SyncXamlEditor;
var
  s: string;
begin
  if fLoadingXaml then exit;
  s := SaveDesignerToString();
  if s <> '' then
  begin
    fOriginalXaml    := s;
    fXamlEditor.Text := s;
    if (fFoldingManager <> nil) and menuItemFolding.Checked then
      UpdateFolding();
  end;
end;

// ═════════════════════════════════════════════
procedure Form1.UpdateFolding;
begin
  if (fFoldingManager = nil) or (fFoldingStrategy = nil) then exit;
  try
    fFoldingStrategy.UpdateFoldings(fFoldingManager, fXamlEditor.Document);
  except
  end;
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
    fFoldingManager  := ICSharpCode.AvalonEdit.Folding.FoldingManager.Install(
                          fXamlEditor.TextArea);
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

// ═════════════════════════════════════════════
function Form1.StripCustomNamespaces(xaml: string): string;
var
  prefixes : System.Collections.Generic.List<string>;
  m        : System.Text.RegularExpressions.Match;
  re       : System.Text.RegularExpressions.Regex;
  prefix   : string;
  pattern  : string;
  s        : string;
begin
  s        := xaml;
  prefixes := new System.Collections.Generic.List<string>();

  // ① clr-namespace xmlns 선언에서 prefix 목록 수집
  re := new System.Text.RegularExpressions.Regex(
    'xmlns:(\w+)="clr-namespace:[^"]*"');
  m := re.Match(s);
  while m.Success do
  begin
    prefixes.Add(m.Groups[1].Value);
    m := m.NextMatch();
  end;

  // ② 각 prefix에 대해 본문 사용 제거
  foreach prefix in prefixes do
  begin
    // 2-a) 자기완결 엘리먼트 제거: <prefix:Foo ... />
    s := System.Text.RegularExpressions.Regex.Replace(s,
      '<' + prefix + ':[^>]*/>', '');

    // 2-b) 시작+끝 태그 쌍 제거: <prefix:Foo ...>...</prefix:Foo>
    s := System.Text.RegularExpressions.Regex.Replace(s,
      '<' + prefix + ':[^>]*>[\s\S]*?</' + prefix + ':[^>]*>', '');

    // 2-c) 속성값에 사용된 커스텀 타입 참조 제거
    //      예) Converter={StaticResource FileSizeConverter}  → 속성 전체 제거
    //          {x:Type prefix:Foo}  → 빈 문자열
    s := System.Text.RegularExpressions.Regex.Replace(s,
      '\s+\w[\w.]*="\{[^"]*' + prefix + ':[^"]*\}"', '');

    // 2-d) xmlns 선언 제거
    s := System.Text.RegularExpressions.Regex.Replace(s,
      '\s+xmlns:' + prefix + '="clr-namespace:[^"]*"', '');
  end;
  Result := s;
end;

// ═════════════════════════════════════════════
function Form1.PreprocessXaml(xaml: string): string;
var
  cleanedXaml  : string;
  doc          : System.Xml.XmlDocument;
  root         : System.Xml.XmlElement;
  nsMgr        : System.Xml.XmlNamespaceManager;
  resNode      : System.Xml.XmlNode;
  node         : System.Xml.XmlNode;
  safeInner    : System.Text.StringBuilder;
  resourcesXml : string;
  inner        : string;
  nodesToRemove: System.Collections.Generic.List<System.Xml.XmlNode>;
  winWidth     : string;
  winHeight    : string;
  sizeAttrs    : string;
begin
  Result := xaml;
  if not (xaml.Contains('<Window ') or xaml.Contains('<UserControl ')) then
    exit;

  cleanedXaml := StripCustomNamespaces(xaml);
  doc := new System.Xml.XmlDocument();
  doc.LoadXml(cleanedXaml);
  root := doc.DocumentElement;

  nsMgr := new System.Xml.XmlNamespaceManager(doc.NameTable);
  nsMgr.AddNamespace('wpf',
    'http://schemas.microsoft.com/winfx/2006/xaml/presentation');

  resNode := root.SelectSingleNode('wpf:Window.Resources', nsMgr);
  if resNode = nil then
    resNode := root.SelectSingleNode('wpf:UserControl.Resources', nsMgr);
  resourcesXml := '';
  if resNode <> nil then
  begin
    safeInner := new System.Text.StringBuilder();
    foreach node in resNode.ChildNodes do
    begin
      if node.Prefix <> '' then continue;
      safeInner.Append(node.OuterXml);
    end;
    if safeInner.Length > 0 then
      resourcesXml := '<Grid.Resources>' + safeInner.ToString() + '</Grid.Resources>';
  end;

  nodesToRemove := new System.Collections.Generic.List<System.Xml.XmlNode>();
  foreach node in root.ChildNodes do
    if node.LocalName.Contains('.') then
      nodesToRemove.Add(node);
  foreach node in nodesToRemove do
    root.RemoveChild(node);

  inner     := root.InnerXml;
  winWidth  := root.GetAttribute('Width');
  winHeight := root.GetAttribute('Height');
  sizeAttrs := '';
  if winWidth  <> '' then sizeAttrs += ' Width="'  + winWidth  + '"';
  if winHeight <> '' then sizeAttrs += ' Height="' + winHeight + '"';

  Result :=
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
    '      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"' +
    sizeAttrs + '>' +
    resourcesXml + inner + '</Grid>';
end;

// ═════════════════════════════════════════════
procedure Form1.BuildMenu;
var
  fileMenu : System.Windows.Forms.ToolStripMenuItem;
  viewMenu: System.Windows.Forms.ToolStripMenuItem;
  buildMenu: System.Windows.Forms.ToolStripMenuItem;
  newItem, openItem, saveItem, syncItem, applyItem: System.Windows.Forms.ToolStripMenuItem;
  buildItem, runItem: System.Windows.Forms.ToolStripMenuItem;
  helpMenu, aboutItem: System.Windows.Forms.ToolStripMenuItem;
begin
  menuStrip := new System.Windows.Forms.MenuStrip();

  // ── 파일 메뉴 ──
  fileMenu := new System.Windows.Forms.ToolStripMenuItem('파일(&F)');
  newItem  := new System.Windows.Forms.ToolStripMenuItem('새 프로젝트(&N)');
  openItem := new System.Windows.Forms.ToolStripMenuItem('열기(&O)');
  saveItem := new System.Windows.Forms.ToolStripMenuItem('저장(&S)');
  newItem.Click  += OnNewProject;
  openItem.Click += OnOpen;
  saveItem.Click += OnSave;
  fileMenu.DropDownItems.Add(newItem);
  fileMenu.DropDownItems.Add(openItem);
  fileMenu.DropDownItems.Add(saveItem);

  // ── 보기 메뉴 ──
  viewMenu              := new System.Windows.Forms.ToolStripMenuItem('보기(&V)');
  applyItem := new System.Windows.Forms.ToolStripMenuItem('XAML 적용(&A)');
  syncItem  := new System.Windows.Forms.ToolStripMenuItem('XAML 동기화(&X)');
  applyItem.Click += OnApplyXamlMenu;
  syncItem.Click  += OnSyncXamlMenu;
  viewMenu.DropDownItems.Add(applyItem);
  viewMenu.DropDownItems.Add(syncItem);
  viewMenu.DropDownItems.Add(new System.Windows.Forms.ToolStripSeparator());

  menuItemLineNum       := new System.Windows.Forms.ToolStripMenuItem('라인 번호 표시(&L)');
  menuItemLineNum.CheckOnClick := true;
  menuItemLineNum.Checked      := true;
  menuItemLineNum.Click        += OnToggleLineNumbers;
  viewMenu.DropDownItems.Add(menuItemLineNum);

  menuItemHighlight     := new System.Windows.Forms.ToolStripMenuItem('구문 강조 표시(&I)');
  menuItemHighlight.CheckOnClick := true;
  menuItemHighlight.Checked      := true;   // 기본값: 활성
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

  // ── 빌드 ──
  buildMenu := new System.Windows.Forms.ToolStripMenuItem('빌드(&B)');
  buildItem := new System.Windows.Forms.ToolStripMenuItem('빌드(&B)    F6');
  runItem   := new System.Windows.Forms.ToolStripMenuItem('실행(&R)    F5');
  buildItem.Click += OnBuild;
  runItem.Click   += OnRun;
  buildMenu.DropDownItems.Add(buildItem);
  buildMenu.DropDownItems.Add(runItem);

  // Help 메뉴
  helpMenu          := new System.Windows.Forms.ToolStripMenuItem('도움말(&H)');
  aboutItem         := new System.Windows.Forms.ToolStripMenuItem('정보(&A)...');
  aboutItem.Click  += OnAbout;
  helpMenu.DropDownItems.Add(aboutItem);

  menuStrip.Items.Add(fileMenu);
  menuStrip.Items.Add(viewMenu);
  menuStrip.Items.Add(buildMenu);
  menuStrip.Items.Add(helpMenu);
  Self.Controls.Add(menuStrip);
  Self.MainMenuStrip := menuStrip;

  // F5/F6 단축키
  Self.KeyPreview := true;
  Self.KeyDown += FormKeyDown;
end;

// ═════════════════════════════════════════════
// 왼쪽 Toolbox (Expander 버전)
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
      'Button'      : icon.Text := '⬜';
      'TextBox'     : icon.Text := '▤';
      'Label'       : icon.Text := 'A';
      'CheckBox'    : icon.Text := '☑';
      'ComboBox'    : icon.Text := '⊟';
      'ListBox'     : icon.Text := '≡';
      'Image'       : icon.Text := '▨';
      'TextBlock'   : icon.Text := 'T';
      'Slider'      : icon.Text := '⊸';
      'ProgressBar' : icon.Text := '▬';
      'RadioButton' : icon.Text := '◎';
      'Border'      : icon.Text := '▢';
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
    hdr.Foreground := new System.Windows.Media.SolidColorBrush(
      System.Windows.Media.Color.FromRgb(30, 30, 30));

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
  AddBtn(panelLayout, 'Grid',       'System.Windows.Controls.Grid');
  AddBtn(panelLayout, 'StackPanel', 'System.Windows.Controls.StackPanel');
  AddBtn(panelLayout, 'Canvas',     'System.Windows.Controls.Canvas');
  AddBtn(panelLayout, 'DockPanel',  'System.Windows.Controls.DockPanel');

  expLayout         := MakeExpander('레이아웃');
  expLayout.Content := panelLayout;
  fToolboxPanel.Children.Add(expLayout);

  panelCommon        := new System.Windows.Controls.StackPanel();
  panelCommon.Margin := new System.Windows.Thickness(8, 2, 0, 2);
  AddBtn(panelCommon, 'Button',      'System.Windows.Controls.Button');
  AddBtn(panelCommon, 'TextBox',     'System.Windows.Controls.TextBox');
  AddBtn(panelCommon, 'Label',       'System.Windows.Controls.Label');
  AddBtn(panelCommon, 'CheckBox',    'System.Windows.Controls.CheckBox');
  AddBtn(panelCommon, 'ComboBox',    'System.Windows.Controls.ComboBox');
  AddBtn(panelCommon, 'ListBox',     'System.Windows.Controls.ListBox');
  AddBtn(panelCommon, 'Image',       'System.Windows.Controls.Image');
  AddBtn(panelCommon, 'TextBlock',   'System.Windows.Controls.TextBlock');
  AddBtn(panelCommon, 'Slider',      'System.Windows.Controls.Slider');
  AddBtn(panelCommon, 'ProgressBar', 'System.Windows.Controls.ProgressBar');
  AddBtn(panelCommon, 'RadioButton', 'System.Windows.Controls.RadioButton');
  AddBtn(panelCommon, 'Border',      'System.Windows.Controls.Border');

  expCommon         := MakeExpander('공용 컨트롤');
  expCommon.Content := panelCommon;
  fToolboxPanel.Children.Add(expCommon);

  scroll         := new System.Windows.Controls.ScrollViewer();
  scroll.Content := fToolboxPanel;
  scroll.VerticalScrollBarVisibility :=
    System.Windows.Controls.ScrollBarVisibility.Auto;

  hostLeft       := new System.Windows.Forms.Integration.ElementHost();
  hostLeft.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostLeft.Child := scroll;
end;

// ═════════════════════════════════════════════
procedure Form1.BuildLayout;
var
  mainPanel     : System.Windows.Forms.Panel;
  toolboxPanel  : System.Windows.Forms.Panel;
  propPanel     : System.Windows.Forms.Panel;
  editorGrid    : System.Windows.Controls.Grid;
  editorRow0    : System.Windows.Controls.RowDefinition;
  editorRow1    : System.Windows.Controls.RowDefinition;
  applyBtn      : System.Windows.Controls.Button;
  errPanel      : System.Windows.Forms.Panel;
  errLabel      : System.Windows.Forms.Label;
  colMsg        : System.Windows.Forms.ColumnHeader;
  colLine       : System.Windows.Forms.ColumnHeader;
  colFile       : System.Windows.Forms.ColumnHeader;
begin
  // ── PropertyGrid (우측) ──
  fPropView       := new ICSharpCode.WpfDesign.Designer.PropertyGrid.PropertyGridView();
  hostRight       := new System.Windows.Forms.Integration.ElementHost();
  hostRight.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostRight.Child := fPropView;
  propPanel       := new System.Windows.Forms.Panel();
  propPanel.Dock  := System.Windows.Forms.DockStyle.Fill;
  propPanel.Controls.Add(hostRight);

  // ── DesignSurface 호스트 ──
  hostDesign      := new System.Windows.Forms.Integration.ElementHost();
  hostDesign.Dock := System.Windows.Forms.DockStyle.Fill;

  // ── XAML 에디터 (AvalonEdit) ──
  fXamlEditor                    := new ICSharpCode.AvalonEdit.TextEditor();
  fXamlEditor.FontFamily         := new System.Windows.Media.FontFamily('Consolas');
  fXamlEditor.FontSize           := 13;
  fXamlEditor.ShowLineNumbers    := true;
  fXamlEditor.SyntaxHighlighting :=
    ICSharpCode.AvalonEdit.Highlighting.HighlightingManager.Instance
      .GetDefinition('XML');
  fXamlEditor.WordWrap           := false;
  fXamlEditor.IsReadOnly         := false;
  fXamlEditor.HorizontalScrollBarVisibility :=
    System.Windows.Controls.ScrollBarVisibility.Auto;
  fXamlEditor.VerticalScrollBarVisibility :=
    System.Windows.Controls.ScrollBarVisibility.Auto;

  // XAML 에디터 + 적용버튼 WPF Grid
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

  // ── 코드 에디터 (AvalonEdit - Pascal 구문강조) ──
  fCodeEditor                    := new ICSharpCode.AvalonEdit.TextEditor();
  fCodeEditor.FontFamily         := new System.Windows.Media.FontFamily('Consolas');
  fCodeEditor.FontSize           := 13;
  fCodeEditor.ShowLineNumbers    := true;
  fCodeEditor.WordWrap           := false;
  fCodeEditor.IsReadOnly         := false;
  fCodeEditor.HorizontalScrollBarVisibility :=
    System.Windows.Controls.ScrollBarVisibility.Auto;
  fCodeEditor.VerticalScrollBarVisibility :=
    System.Windows.Controls.ScrollBarVisibility.Auto;
  hostCode       := new System.Windows.Forms.Integration.ElementHost();
  hostCode.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostCode.Child := fCodeEditor;

  // ── 탭 컨트롤 (디자인 / XAML / 코드) ──
  tabControl      := new System.Windows.Forms.TabControl();
  tabControl.Dock := System.Windows.Forms.DockStyle.Fill;
  tabControl.SelectedIndexChanged += OnTabChanged;

  tabDesign      := new System.Windows.Forms.TabPage('🎨 디자인');
  tabDesign.Controls.Add(hostDesign);

  tabXaml        := new System.Windows.Forms.TabPage('📄 XAML');
  tabXaml.Controls.Add(hostXaml);

  tabCode        := new System.Windows.Forms.TabPage('💻 코드');
  tabCode.Controls.Add(hostCode);

  tabControl.TabPages.Add(tabDesign);
  tabControl.TabPages.Add(tabXaml);
  tabControl.TabPages.Add(tabCode);

  // ── 오류 목록 패널 (하단) ──
  errLabel           := new System.Windows.Forms.Label();
  errLabel.Text      := '오류 목록';
  errLabel.Dock      := System.Windows.Forms.DockStyle.Top;
  errLabel.Font      := new System.Drawing.Font('Segoe UI', 9,
    System.Drawing.FontStyle.Bold);
  errLabel.BackColor := System.Drawing.Color.FromArgb(230, 230, 230);
  errLabel.Height    := 22;

  lvErrors                   := new System.Windows.Forms.ListView();
  lvErrors.Dock              := System.Windows.Forms.DockStyle.Fill;
  lvErrors.View              := System.Windows.Forms.View.Details;
  lvErrors.FullRowSelect     := true;
  lvErrors.GridLines         := true;
  lvErrors.MultiSelect       := true;
  lvErrors.Font              := new System.Drawing.Font('Consolas', 9);
  lvErrors.KeyDown           += OnErrorsKeyDown;

  // 우클릭 복사 메뉴
  var errMenu := new System.Windows.Forms.ContextMenuStrip();
  var copyItem := new System.Windows.Forms.ToolStripMenuItem('복사(&C)' + #9 + 'Ctrl+C');
  copyItem.Click += OnErrorsCopy;
  errMenu.Items.Add(copyItem);
  lvErrors.ContextMenuStrip := errMenu;
  colMsg  := new System.Windows.Forms.ColumnHeader();
  colMsg.Text  := '오류 메시지';
  colMsg.Width := 500;
  colLine := new System.Windows.Forms.ColumnHeader();
  colLine.Text  := '줄';
  colLine.Width := 60;
  colFile := new System.Windows.Forms.ColumnHeader();
  colFile.Text  := '파일';
  colFile.Width := 200;
  lvErrors.Columns.Add(colMsg);
  lvErrors.Columns.Add(colLine);
  lvErrors.Columns.Add(colFile);

  errPanel      := new System.Windows.Forms.Panel();
  errPanel.Dock := System.Windows.Forms.DockStyle.Fill;
  errPanel.Controls.Add(lvErrors);
  errPanel.Controls.Add(errLabel);

  // ── 우측 분할: 탭(디자인/XAML/코드) | 속성창 ──
  splitRight                  := new System.Windows.Forms.SplitContainer();
  splitRight.Dock             := System.Windows.Forms.DockStyle.Fill;
  splitRight.Orientation      := System.Windows.Forms.Orientation.Vertical;
  splitRight.SplitterDistance := 1100;
  splitRight.Panel1.Controls.Add(tabControl);
  splitRight.Panel2.Controls.Add(propPanel);

  // ── 좌우 분할: 툴박스 | 우측 분할 ──
  toolboxPanel      := new System.Windows.Forms.Panel();
  toolboxPanel.Dock := System.Windows.Forms.DockStyle.Fill;
  toolboxPanel.Controls.Add(hostLeft);

  splitDesign                  := new System.Windows.Forms.SplitContainer();
  splitDesign.Dock             := System.Windows.Forms.DockStyle.Fill;
  splitDesign.Orientation      := System.Windows.Forms.Orientation.Vertical;
  splitDesign.SplitterDistance := 5;//160;
  splitDesign.Panel1.Controls.Add(toolboxPanel);
  splitDesign.Panel2.Controls.Add(splitRight);

  // ── 상하 분할: 메인 | 오류목록 ──
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

  // 폴딩 타이머
  fFoldingTimer          := new System.Windows.Threading.DispatcherTimer();
  fFoldingTimer.Interval := System.TimeSpan.FromMilliseconds(500);
  fFoldingTimer.Tick     += OnFoldingTimerTick;
  fXamlEditor.TextChanged += OnXamlTextChanged;
end;

// ═════════════════════════════════════════════
// 탭 전환 시 처리
procedure Form1.OnTabChanged(sender: System.Object; e: System.EventArgs);
begin
  // 디자인 탭으로 돌아올 때 코드 에디터의 내용을 저장해두는 처리 등 가능
  if tabControl.SelectedTab = tabDesign then
  begin
    // 디자인 탭 전환 시 특별 처리 없음
  end;
end;

// ═════════════════════════════════════════════
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
  scroll.HorizontalScrollBarVisibility :=
    System.Windows.Controls.ScrollBarVisibility.Auto;
  scroll.VerticalScrollBarVisibility :=
    System.Windows.Controls.ScrollBarVisibility.Auto;
  scroll.Content   := fSurface;
  hostDesign.Child := scroll;

  ConnectEvents();

  if (menuItemFolding <> nil) and menuItemFolding.Checked then
    EnableFolding();
end;

// ═════════════════════════════════════════════
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

// ═════════════════════════════════════════════
// 이벤트 연결
procedure Form1.ConnectEvents;
var
  undoSvc: ICSharpCode.WpfDesign.Designer.Services.UndoService;
begin
  if fSurface.DesignContext = nil then exit;

  // 선택 변경 → PropertyGrid 갱신
  fSurface.DesignContext.Services.Selection.SelectionChanged += OnSelectionChanged;

  // UndoService 변경 → XAML 에디터 자동 동기화
  // 드래그/크기변경/속성변경 등 모든 디자인 변경을 감지함
  undoSvc := fSurface.DesignContext.Services.GetService(
    typeof(ICSharpCode.WpfDesign.Designer.Services.UndoService)
  ) as ICSharpCode.WpfDesign.Designer.Services.UndoService;

  if undoSvc <> nil then
    undoSvc.UndoStackChanged += OnUndoStackChanged;

  // 더블클릭 → 이벤트 핸들러 자동 생성
  fSurface.MouseDoubleClick += OnDesignerDoubleClick;
end;

// ═════════════════════════════════════════════
// 선택 변경 → PropertyGrid 업데이트
procedure Form1.OnSelectionChanged(sender: System.Object;
  e: ICSharpCode.WpfDesign.DesignItemCollectionEventArgs);
begin
  if fSurface.DesignContext = nil then exit;
  fPropView.SelectedItems :=
    fSurface.DesignContext.Services.Selection.SelectedItems;
end;

// ═════════════════════════════════════════════
// 디자인 변경(드래그/크기/속성) → XAML 자동 동기화
procedure Form1.OnUndoStackChanged(sender: System.Object; e: System.EventArgs);
begin
  SyncXamlEditor();
end;

// ═════════════════════════════════════════════
procedure Form1.OnSave(sender: System.Object; e: System.EventArgs);
var
  dlg : System.Windows.Forms.SaveFileDialog;
begin
  dlg          := new System.Windows.Forms.SaveFileDialog();
  dlg.Filter   := 'XAML 파일|*.xaml|모든 파일|*.*';
  dlg.FileName := fXamlFileName;
  dlg.InitialDirectory := fProjectPath;
  if dlg.ShowDialog() = System.Windows.Forms.DialogResult.OK then
  begin
    // XAML 저장
    System.IO.File.WriteAllText(dlg.FileName, fXamlEditor.Text,
      System.Text.Encoding.UTF8);
    // PAS 저장 (같은 폴더, 같은 이름)
    var pasPath := System.IO.Path.ChangeExtension(dlg.FileName, '.pas');
    System.IO.File.WriteAllText(pasPath, fCodeEditor.Text,
      System.Text.Encoding.UTF8);
    fProjectPath  := System.IO.Path.GetDirectoryName(dlg.FileName) + '\';
    fXamlFileName := System.IO.Path.GetFileName(dlg.FileName);
    fPasFileName  := System.IO.Path.GetFileName(pasPath);
    System.Windows.Forms.MessageBox.Show(
      'XAML: ' + dlg.FileName + #13#10 + 'PAS: ' + pasPath + #13#10 + '저장 완료!');
  end;
end;

// ═════════════════════════════════════════════
procedure Form1.OnOpen(sender: System.Object; e: System.EventArgs);
var
  dlg : System.Windows.Forms.OpenFileDialog;
  xaml: string;
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
      System.Windows.Forms.MessageBox.Show('파일 읽기 오류: ' + ex.Message);
      exit;
    end;
  end;

  fProjectPath  := System.IO.Path.GetDirectoryName(dlg.FileName) + '\';
  fXamlFileName := System.IO.Path.GetFileName(dlg.FileName);
  fPasFileName  := System.IO.Path.ChangeExtension(fXamlFileName, '.pas');
  Self.Text     := 'PascalABC WPF XAML Designer - ' + fProjectPath;

  LoadXaml(xaml);

  // 같은 폴더에 .pas 파일이 있으면 코드 에디터에 로드
  pasPath := fProjectPath + fPasFileName;
  if System.IO.File.Exists(pasPath) then
    fCodeEditor.Text := System.IO.File.ReadAllText(pasPath)
  else
    fCodeEditor.Text := GeneratePasCode(fXamlFileName);
end;

// ═════════════════════════════════════════════
// 하단 XAML → 디자이너 적용
// XAML 에디터에서 붙여넣기 후 적용
// Window/UserControl 루트도 자동 전처리하여 디자이너에 반영
procedure Form1.OnApplyXaml(sender: System.Object; e: System.Windows.RoutedEventArgs);
var
  xaml: string;
begin
  xaml := fXamlEditor.Text.Trim();
  if xaml = '' then exit;
  LoadXaml(xaml);
end;

procedure Form1.OnApplyXamlMenu(sender: System.Object; e: System.EventArgs);
var
  xaml: string;
begin
  xaml := fXamlEditor.Text.Trim();
  if xaml = '' then exit;
  LoadXaml(xaml);
end;

// ═════════════════════════════════════════════
// 메뉴: 수동 동기화
procedure Form1.OnSyncXamlMenu(sender: System.Object; e: System.EventArgs);
begin
  SyncXamlEditor();
end;

// ═════════════════════════════════════════════
procedure Form1.OnToggleLineNumbers(sender: System.Object; e: System.EventArgs);
begin
  fXamlEditor.ShowLineNumbers := menuItemLineNum.Checked;
  fCodeEditor.ShowLineNumbers := menuItemLineNum.Checked;
end;

// ═════════════════════════════════════════════
// 구문 강조 ON/OFF 토글
procedure Form1.OnToggleHighlight(sender: System.Object; e: System.EventArgs);
begin
  if menuItemHighlight.Checked then
    fXamlEditor.SyntaxHighlighting :=
      ICSharpCode.AvalonEdit.Highlighting.HighlightingManager.Instance
        .GetDefinition('XML')
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
  if menuItemFolding.Checked then
    EnableFolding()
  else
    DisableFolding();
end;

// ═════════════════════════════════════════════
procedure Form1.OnToolboxClick(sender: System.Object; e: System.Windows.RoutedEventArgs);
var
  tname    : string;
  t        : System.Type;
  inst     : System.Object;
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
    System.Windows.Forms.MessageBox.Show('타입을 찾을 수 없습니다: ' + tname);
    exit;
  end;
  try
    inst := System.Activator.CreateInstance(t);
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

// ═════════════════════════════════════════════
procedure Form1.FormKeyDown(sender: System.Object; ke: System.Windows.Forms.KeyEventArgs);
begin
  if ke.KeyCode = System.Windows.Forms.Keys.F5 then
    OnRun(sender, System.EventArgs.Empty)
  else if ke.KeyCode = System.Windows.Forms.Keys.F6 then
    OnBuild(sender, System.EventArgs.Empty);
end;


// Help > About
procedure Form1.OnAbout(sender: System.Object; e: System.EventArgs);
begin
  System.Windows.Forms.MessageBox.Show(
    'PascalABC-WPF-Xaml-Designer' + System.Environment.NewLine +
    'Ver 1.2.4' + System.Environment.NewLine + System.Environment.NewLine +
    'ICSharpCode.WpfDesign.Designer' + System.Environment.NewLine +
    'ICSharpCode.WpfDesign' + System.Environment.NewLine +
    'ICSharpCode.WpfDesign.XamlDom' + System.Environment.NewLine +
    'ICSharpCode.AvalonEdit' + System.Environment.NewLine +
    'avalonedit.6.3.1.120' + System.Environment.NewLine +
    ' 기반 WPF XAML 디자이너' + System.Environment.NewLine + System.Environment.NewLine +
    'Built with PascalABC.NET 3.11.1.3833' + System.Environment.NewLine + System.Environment.NewLine +
    'made by sigmak (dwfree74@gmail.com)',
    '프로그램 정보',
    System.Windows.Forms.MessageBoxButtons.OK,
    System.Windows.Forms.MessageBoxIcon.Information
  );
end;

// ═════════════════════════════════════════════
begin
  System.Threading.Thread.CurrentThread.SetApartmentState(
    System.Threading.ApartmentState.STA
  );
  System.Windows.Forms.Application.EnableVisualStyles();
  System.Windows.Forms.Application.Run(new Form1());
end.