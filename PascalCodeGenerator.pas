unit PascalCodeGenerator;

// =============================================================================
// PascalCodeGenerator.pas
//   TPascalCodeGenerator
//     XAML 정보와 TProjectOptions 를 받아 PascalABC.NET 소스 코드를 생성한다.
//
//   공개 메서드:
//     GenerateWpfAppCode(xamlFileName)       — program ... end. 형식 앱 코드
//     GenerateControlLibCode(xamlFileName)   — library ... end. 형식 라이브러리 코드
//     GenerateInitializeComponent(controls)  — InitializeComponent 프로시저 본문
// =============================================================================

uses
  System.Collections.Generic,
  System.Text,
  ControlInfo,          // TControlInfo
  ProjectOptions,       // TProjectOptions
  WpfEventMap,          // GetEventParamType, GetEventDelegateType
  XamlParser,           // ParseXClassInfo, ParseControlsFromXaml
  LocalizationCore,   // ← 추가
  Strings_Common;     // ← 추가  

type
  TPascalCodeGenerator = class
  private
    fOptions      : TProjectOptions;
    fNamespace    : string;    // 현재 프로젝트 네임스페이스 (out 참조)
    fClassName    : string;    // 현재 윈도우/컨트롤 클래스명 (out 참조)
    fXamlFileName : string;    // .xaml 파일명 (경로 제외)
    fPasFileName  : string;    // .pas 파일명 (경로 제외)

    function BuildIndent: string;
    function GenerateInitializeComponent(
      controls: System.Collections.Generic.List<TControlInfo>): string;

  public
    // 생성자: 의존 정보를 주입받는다.
    constructor Create(
      options     : TProjectOptions;
      xamlFileName: string;
      pasFileName : string);

    // XAML 을 분석한 뒤 완성된 PascalABC.NET 소스를 반환한다.
    // xamlText: fXamlEditor.Text 에 해당하는 원본 XAML 문자열
    // 부수 효과: fNamespace / fClassName 갱신
    function GenerateWpfAppCode(xamlText: string;
      var outNs: string; var outCls: string): string;

    function GenerateControlLibCode(xamlText: string;
      var outNs: string; var outCls: string): string;

    // 읽기 전용 프로퍼티
    property Namespace2 : string  read fNamespace; // Namespace 오류나서 수정함.
    property ClassName : string  read fClassName;
  end;

// =============================================================================
// 구현
// =============================================================================

constructor TPascalCodeGenerator.Create(
  options     : TProjectOptions;
  xamlFileName: string;
  pasFileName : string);
begin
  fOptions      := options;
  fXamlFileName := xamlFileName;
  fPasFileName  := pasFileName;
  fNamespace    := options.RootNamespace;
  fClassName    := options.ClassName;
end;

// -----------------------------------------------------------------------------
// BuildIndent — 옵션에 따른 들여쓰기 단위 문자열 반환
// -----------------------------------------------------------------------------
function TPascalCodeGenerator.BuildIndent: string;
var
  s  : string;
  ii : integer;
begin
  s  := '';
  ii := 0;
  while ii < fOptions.IndentSize do
  begin
    s  += (if fOptions.UseTabs then #9 else ' ');
    ii += 1;
  end;
  Result := s;
end;

// -----------------------------------------------------------------------------
// GenerateInitializeComponent
// -----------------------------------------------------------------------------
function TPascalCodeGenerator.GenerateInitializeComponent(
  controls: System.Collections.Generic.List<TControlInfo>): string;
var
  sb        : System.Text.StringBuilder;
  ctrl      : TControlInfo;
  ctrl2     : TControlInfo;
  ev        : System.Tuple<string, string>;
  hasEvents : boolean;
  indent    : string;
begin
  indent := BuildIndent();
  sb     := new System.Text.StringBuilder();

  sb.AppendLine('procedure ' + fClassName + '.InitializeComponent;');
  sb.AppendLine('var');
  sb.AppendLine('  xamlPath   : string;');
  sb.AppendLine('  fs         : System.IO.FileStream;');
  sb.AppendLine('  xrSettings : System.Xaml.XamlXmlReaderSettings;');
  sb.AppendLine('  xamlReader : System.Xaml.XamlXmlReader;');
  sb.AppendLine('  objSettings: System.Xaml.XamlObjectWriterSettings;');
  sb.AppendLine('  objWriter  : System.Xaml.XamlObjectWriter;');
  sb.AppendLine('begin');

  sb.AppendLine('  xamlPath := System.IO.Path.Combine(');
  sb.AppendLine('    System.AppDomain.CurrentDomain.BaseDirectory,');
  sb.AppendLine('    ' + #39 + fXamlFileName + #39 + ');');
  sb.AppendLine('');
  sb.AppendLine('  fs := new System.IO.FileStream(xamlPath,');
  sb.AppendLine('          System.IO.FileMode.Open, System.IO.FileAccess.Read);');
  sb.AppendLine('  try');
  sb.AppendLine('    xrSettings := new System.Xaml.XamlXmlReaderSettings();');
  sb.AppendLine('    xrSettings.LocalAssembly :=');
  sb.AppendLine('      System.Reflection.Assembly.GetExecutingAssembly();');
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

  // FindName 으로 컨트롤 필드 초기화
  if controls.Count > 0 then
  begin
    sb.AppendLine('  // ' + TLoc.S('codegen.comment.init_fields')); // '  // 컨트롤 필드 초기화 (FindName)'
    foreach ctrl in controls do
    begin
      var wpfType := 'System.Windows.Controls.' + ctrl.TypeName;
      case ctrl.TypeName of
        'Window', 'UserControl', 'Page':
          wpfType := 'System.Windows.' + ctrl.TypeName;
        'TextBlock', 'Image':
          wpfType := 'System.Windows.Controls.' + ctrl.TypeName;
      end;
      sb.AppendLine('  ' + ctrl.Name + ' := Self.FindName(' +
        #39 + ctrl.Name + #39 + ') as ' + wpfType + ';');
    end;
    sb.AppendLine('');

    // 이벤트 핸들러 연결
    hasEvents := false;
    foreach ctrl2 in controls do
      if ctrl2.Events.Count > 0 then hasEvents := true;

    if hasEvents then
    begin
      sb.AppendLine('  // ' + TLoc.S('codegen.comment.connect_events')); // '  // 이벤트 핸들러 연결'
      foreach ctrl2 in controls do
        foreach ev in ctrl2.Events do
        begin
          sb.AppendLine('  if ' + ctrl2.Name + ' <> nil then');
          sb.AppendLine('    ' + ctrl2.Name + '.' + ev.Item1 + ' += ' + ev.Item2 + ';');
        end;
    end;
  end;

  sb.AppendLine('end;');
  Result := sb.ToString();
end;

// -----------------------------------------------------------------------------
// GenerateWpfAppCode
// -----------------------------------------------------------------------------
function TPascalCodeGenerator.GenerateWpfAppCode(
  xamlText: string;
  var outNs: string; var outCls: string): string;
var
  sb          : System.Text.StringBuilder;
  controls    : System.Collections.Generic.List<TControlInfo>;
  ctrl        : TControlInfo;
  ev          : System.Tuple<string, string>;
  programName : string;
  hasEvents   : boolean;
  indent      : string;
begin
  ParseXClassInfo(xamlText, fNamespace, fClassName);

  // x:Class 클래스 이름이 프로그램 이름과 겹치는 경우 접미사 추가
  if fClassName = fNamespace then
  begin
    var newCls    := fClassName + 'Window';
    var oldXClass := fNamespace + '.' + fClassName;
    var newXClass := fNamespace + '.' + newCls;
    // 호출자가 xamlText를 업데이트 할 수 있도록 변환 된 문자열을 반환해야하지만,
    // 여기서는 outNs / outCls 만 업데이트합니다 (XAML 업데이트는 Form1 측의 책임임)
    fClassName := newCls;
  end;

  outNs  := fNamespace;
  outCls := fClassName;

  controls    := ParseControlsFromXaml(xamlText);
  programName := fNamespace;
  indent      := BuildIndent();

  sb := new System.Text.StringBuilder();

  // ── 프로그램 헤더 ────────────────────────────────────────────────────────
  sb.AppendLine('program ' + programName + ';');
  sb.AppendLine('');
  sb.AppendLine('{$apptype windows}');
  sb.AppendLine('{$reference PresentationFramework.dll}');
  sb.AppendLine('{$reference PresentationCore.dll}');
  sb.AppendLine('{$reference WindowsBase.dll}');
  sb.AppendLine('{$reference System.Windows.Forms.dll}');
  sb.AppendLine('{$reference System.Xaml.dll}');
  sb.AppendLine('');
  sb.AppendLine('uses');
  sb.AppendLine(indent + 'System.Windows,');
  sb.AppendLine(indent + 'System.Windows.Controls,');
  sb.AppendLine(indent + 'System.Windows.Markup,');
  sb.AppendLine(indent + 'System.Xaml,');
  sb.AppendLine(indent + 'System.IO,');
  sb.AppendLine(indent + 'System.Threading;');
  sb.AppendLine('');

  // ── 클래스 선언 ────────────────────────────────────────────────────────────
  sb.AppendLine('type');
  sb.AppendLine(indent + fClassName + ' = class(System.Windows.Window)');

  if controls.Count > 0 then
  begin
    sb.AppendLine(indent + 'private');
    foreach ctrl in controls do
    begin
      var wpfType := 'System.Windows.Controls.' + ctrl.TypeName;
      case ctrl.TypeName of
        'Window', 'UserControl': wpfType := 'System.Windows.' + ctrl.TypeName;
      end;
      sb.AppendLine(indent + indent + ctrl.Name + ' : ' + wpfType + ';');
    end;
  end;

  hasEvents := false;
  foreach ctrl in controls do
    if ctrl.Events.Count > 0 then hasEvents := true;

  if hasEvents then
  begin
    sb.AppendLine(indent + '// ── ' + TLoc.S('codegen.comment.event_decl') + ' ─────────────────────'); //'// ── 이벤트 핸들러 선언 ─────────────────────'
    foreach ctrl in controls do
      foreach ev in ctrl.Events do
      begin
        var paramType := GetEventParamType(ctrl.TypeName, ev.Item1);
        sb.AppendLine(indent + indent + 'procedure ' + ev.Item2 +
          '(sender: System.Object; e: ' + paramType + ');');
      end;
  end;

  sb.AppendLine(indent + 'public');
  sb.AppendLine(indent + indent + 'constructor Create;');
  sb.AppendLine(indent + indent + 'procedure InitializeComponent;');
  sb.AppendLine(indent + 'end;');
  sb.AppendLine('');

  // ── constructor ────────────────────────────────────────────────────────────
  sb.AppendLine('constructor ' + fClassName + '.Create;');
  sb.AppendLine('begin');
  sb.AppendLine(indent + 'inherited Create;');
  sb.AppendLine(indent + 'InitializeComponent;');
  sb.AppendLine('end;');
  sb.AppendLine('');

  sb.Append(GenerateInitializeComponent(controls));
  sb.AppendLine('');

  // ── 이벤트 핸들러 구현 스텁 ────────────────────────────────────────────────
  if hasEvents then
  begin
    sb.AppendLine('// ── ' + TLoc.S('codegen.comment.event_impl') + ' ──────────────────────────────────'); //'// ── 이벤트 핸들러 구현 ──────────────────────────────────'
    sb.AppendLine('');
    foreach ctrl in controls do
      foreach ev in ctrl.Events do
      begin
        var paramType := GetEventParamType(ctrl.TypeName, ev.Item1);
        if fOptions.GenerateComments then
          sb.AppendLine('// ' + ctrl.Name + '.' + ev.Item1 + TLoc.S('codegen.comment.event_handler')); // ' 이벤트 핸들러'
        sb.AppendLine('procedure ' + fClassName + '.' + ev.Item2 +
          '(sender: System.Object; e: ' + paramType + ');');
        sb.AppendLine('begin');
        if fOptions.GenerateComments then
          sb.AppendLine(indent + '// TODO: ' + ev.Item2 + TLoc.S('codegen.comment.impl')); // ' 구현'
        sb.AppendLine('end;');
        sb.AppendLine('');
      end;
  end;

  // ── 진입점 ─────────────────────────────────────────────────────────────────
  sb.AppendLine('// ── ' + TLoc.S('codegen.comment.entrypoint') + ' ──────────────────────────────────'); // '// ── 애플리케이션 진입점 ──────────────────────────────────'
  sb.AppendLine('procedure RunApp;');
  sb.AppendLine('begin');
  sb.AppendLine(indent + 'try');
  sb.AppendLine(indent + indent + 'var app := new System.Windows.Application();');
  sb.AppendLine(indent + indent + 'app.Run(new ' + fClassName + '());');
  sb.AppendLine(indent + 'except');
  sb.AppendLine(indent + indent + 'on ex: System.Exception do');
  sb.AppendLine(indent + indent + indent + 'System.Windows.Forms.MessageBox.Show(');
  sb.AppendLine(indent + indent + indent + indent +
    'ex.ToString(), ' + #39 + TLoc.S('codegen.runtime_error') + #39 + ','); // '실행 오류'
  sb.AppendLine(indent + indent + indent + indent +
    'System.Windows.Forms.MessageBoxButtons.OK,');
  sb.AppendLine(indent + indent + indent + indent +
    'System.Windows.Forms.MessageBoxIcon.Error);');
  sb.AppendLine(indent + 'end;');
  sb.AppendLine('end;');
  sb.AppendLine('');
  sb.AppendLine('begin');
  sb.AppendLine(indent + 'var t := new System.Threading.Thread(RunApp);');
  sb.AppendLine(indent + 't.SetApartmentState(System.Threading.ApartmentState.STA);');
  sb.AppendLine(indent + 't.IsBackground := false;');
  sb.AppendLine(indent + 't.Start();');
  sb.AppendLine('end.');

  Result := sb.ToString();
end;

// -----------------------------------------------------------------------------
// GenerateControlLibCode
// -----------------------------------------------------------------------------
function TPascalCodeGenerator.GenerateControlLibCode(
  xamlText: string;
  var outNs: string; var outCls: string): string;
var
  sb       : System.Text.StringBuilder;
  controls : System.Collections.Generic.List<TControlInfo>;
  ctrl     : TControlInfo;
  unitName : string;
  indent   : string;
begin
  ParseXClassInfo(xamlText, fNamespace, fClassName);

  var baseUnitName := System.IO.Path.GetFileNameWithoutExtension(fPasFileName);
  if fClassName = baseUnitName then
    fClassName := fClassName + 'Control';

  outNs  := fNamespace;
  outCls := fClassName;

  controls := ParseControlsFromXaml(xamlText);
  unitName := baseUnitName;
  indent   := BuildIndent();

  sb := new System.Text.StringBuilder();
  sb.AppendLine('library ' + unitName + ';');
  sb.AppendLine('');
  sb.AppendLine('{$reference PresentationFramework.dll}');
  sb.AppendLine('{$reference PresentationCore.dll}');
  sb.AppendLine('{$reference WindowsBase.dll}');
  sb.AppendLine('{$reference System.Xaml.dll}');
  sb.AppendLine('');
  sb.AppendLine('uses');
  sb.AppendLine(indent + 'System.Windows,');
  sb.AppendLine(indent + 'System.Windows.Controls,');
  sb.AppendLine(indent + 'System.Windows.Markup,');
  sb.AppendLine(indent + 'System.Xaml,');
  sb.AppendLine(indent + 'System.IO;');
  sb.AppendLine('');
  sb.AppendLine('type');
  sb.AppendLine(indent + fClassName + ' = class(System.Windows.Controls.UserControl)');
  sb.AppendLine(indent + 'private');

  foreach ctrl in controls do
  begin
    var wpfType := 'System.Windows.Controls.' + ctrl.TypeName;
    sb.AppendLine(indent + indent + ctrl.Name + ' : ' + wpfType + ';');
  end;

  sb.AppendLine(indent + 'public');
  sb.AppendLine(indent + indent + 'constructor Create;');
  sb.AppendLine(indent + indent + 'procedure InitializeComponent;');
  sb.AppendLine(indent + 'end;');
  sb.AppendLine('');
  sb.AppendLine('constructor ' + fClassName + '.Create;');
  sb.AppendLine('begin');
  sb.AppendLine(indent + 'inherited Create;');
  sb.AppendLine(indent + 'InitializeComponent;');
  sb.AppendLine('end;');
  sb.AppendLine('');
  sb.Append(GenerateInitializeComponent(controls));
  sb.AppendLine('');
  sb.AppendLine('end.');

  Result := sb.ToString();
end;

end.