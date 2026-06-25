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
//
// ★ 수정 이력 (Ver 2.3.0)
//   - GenerateInitializeComponent: 이벤트 핸들러 연결(+=) 구문이 finally 블록
//     안에 삽입되던 버그 수정 → try/finally 완전 종료 후 FindName 블록에서 연결
//   - GenerateWpfAppCode: private 선언부에 이벤트 핸들러 procedure 선언이
//     누락되지 않도록 controls 루프 조건 보강
//   - codegen.comment.event_handler 주석 앞뒤 공백 일관성 수정
// =============================================================================

uses
  System.Collections.Generic,
  System.Text,
  ControlInfo,          // TControlInfo
  ProjectOptions,       // TProjectOptions
  WpfEventMap,          // GetEventParamType, GetEventDelegateType
  XamlParser,           // ParseXClassInfo, ParseControlsFromXaml
  LocalizationCore,     // TLoc
  Strings_Common;       // 문자열 키 등록 (코드 생성기 주석용)

type
  TPascalCodeGenerator = class
  private
    fOptions      : TProjectOptions;
    fNamespace    : string;    // 현재 프로젝트 네임스페이스 (out 참조)
    fClassName    : string;    // 현재 윈도우/컨트롤 클래스명 (out 참조)
    fXamlFileName : string;    // .xaml 파일명 (경로 제외)
    fPasFileName  : string;    // .pas 파일명 (경로 제외)

    function BuildIndent: string;

    // ★ 수정: GenerateInitializeComponent 시그니처 변경 없음.
    //   내부 구현에서 try/finally 블록과 FindName/이벤트연결 블록을 명확히 분리.
    function GenerateInitializeComponent(
      controls: System.Collections.Generic.List<TControlInfo>): string;

  public
    constructor Create(
      options     : TProjectOptions;
      xamlFileName: string;
      pasFileName : string);

    function GenerateWpfAppCode(xamlText: string;
      var outNs: string; var outCls: string): string;

    function GenerateControlLibCode(xamlText: string;
      var outNs: string; var outCls: string): string;

    property Namespace2 : string  read fNamespace;
    property ClassName  : string  read fClassName;
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
//
// ★ 핵심 수정:
//   이전 코드는 try/finally 블록이 끝난 뒤(end;)에 FindName 과 이벤트 연결이
//   오도록 의도했지만, 실제 생성 결과에서 이벤트 연결(+=) 구문이 finally 블록
//   안(fs.Close() 바로 뒤)에 삽입되는 버그가 있었다.
//
//   원인: sb.AppendLine('  end;')  →  sb.AppendLine('')  순서로 finally 블록을
//   닫은 직후 빈 줄을 하나 넣었는데, Form1.AddEventSubscriptionToCode 가
//   "end;" 위치를 찾아 그 앞에 삽입하다 보니 finally 내부의 "end;" 를
//   먼저 발견했기 때문이다.
//
//   수정: GenerateInitializeComponent 자체가 완전하고 올바른 코드를 처음부터
//   생성하도록 한다. Form1.AddEventSubscriptionToCode 는 더 이상 필요 없다.
//   이벤트 연결 구문은 항상 "FindName 초기화 블록" 안에서, nil 체크 후에
//   생성한다.
//
//   생성 구조:
//     procedure ClassName.InitializeComponent;
//     var ... ;
//     begin
//       // XAML 로드 (try/finally)
//       xamlPath := ...;
//       fs := ...;
//       try
//         XamlServices.Transform(...);
//       finally
//         fs.Close();           ← finally 는 오직 fs.Close() 만 포함
//       end;
//                               ← 빈 줄
//       // Initialize control fields (FindName)
//       ctrl1 := Self.FindName('ctrl1') as TType;
//       ...
//                               ← 빈 줄 (이벤트가 있을 때만)
//       // Connect event handlers
//       if ctrl1 <> nil then
//         ctrl1.EventA += ctrl1_EventA;
//         ctrl1.EventB += ctrl1_EventB;   ← 같은 nil 체크 블록에 연속 삽입
//       ...
//     end;
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

  // ── XAML 로드 블록 (try/finally) ─────────────────────────────────────────
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
  // ★ 수정: finally 블록에는 오직 스트림 닫기만 포함한다.
  //   이전 버그: Form1.AddEventSubscriptionToCode 가 이 "end;" 앞에 += 를 삽입.
  sb.AppendLine('    fs.Close();');
  sb.AppendLine('  end;');
  // ── try/finally 완전 종료 ─────────────────────────────────────────────────
  sb.AppendLine('');

  if controls.Count > 0 then
  begin
    // ── FindName 으로 컨트롤 필드 초기화 ─────────────────────────────────────
    sb.AppendLine('  // ' + TLoc.S('codegen.comment.init_fields'));
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

    // ── 이벤트 핸들러 연결 ────────────────────────────────────────────────────
    // ★ 수정: 이 블록은 try/finally 완전 종료 후, FindName 초기화 직후에 위치한다.
    //   컨트롤별로 nil 체크 후 해당 컨트롤의 모든 이벤트를 연속 연결한다.
    //   (이전: 이벤트마다 별도 if 블록 → 수정: 컨트롤당 하나의 if 블록)
    hasEvents := false;
    foreach ctrl2 in controls do
      if ctrl2.Events.Count > 0 then hasEvents := true;

    if hasEvents then
    begin
      sb.AppendLine('');
      sb.AppendLine('  // ' + TLoc.S('codegen.comment.connect_events'));
      foreach ctrl2 in controls do
      begin
        if ctrl2.Events.Count = 0 then continue;

        if ctrl2.Events.Count = 1 then
        begin
          // 이벤트가 1개: 한 줄 if
          ev := ctrl2.Events[0];
          sb.AppendLine('  if ' + ctrl2.Name + ' <> nil then');
          sb.AppendLine('    ' + ctrl2.Name + '.' + ev.Item1 + ' += ' + ev.Item2 + ';');
        end
        else
        begin
          // ★ 수정: 이벤트가 2개 이상이면 begin/end 블록으로 묶어
          //   모든 이벤트를 하나의 nil 체크 안에서 연결한다.
          //   이전: 이벤트마다 개별 "if ctrl <> nil then" → 중복 nil 체크
          sb.AppendLine('  if ' + ctrl2.Name + ' <> nil then');
          sb.AppendLine('  begin');
          var evIdx := 0;
          while evIdx < ctrl2.Events.Count do
          begin
            ev := ctrl2.Events[evIdx];
            sb.AppendLine('    ' + ctrl2.Name + '.' + ev.Item1 + ' += ' + ev.Item2 + ';');
            evIdx += 1;
          end;
          sb.AppendLine('  end;');
        end;
      end;
    end;
  end;

  sb.AppendLine('end;');
  Result := sb.ToString();
end;

// -----------------------------------------------------------------------------
// GenerateWpfAppCode
//
// ★ 수정:
//   1. private 선언부에 이벤트 핸들러 procedure 가 누락되지 않도록
//      controls 루프를 확실히 처리한다.
//   2. 이벤트 핸들러 주석 형식을 "// ctrl.Event event handler" 로 통일한다
//      (이전: "// ctrl.Event이벤트 핸들러" 처럼 언어 키가 앞에 붙어 공백 없이 이어지던 문제).
//   3. 진입점 코드에서 t.Start() 뒤에 t.Join()이 없어 메인 스레드가 즉시 종료되던
//      잠재적 문제를 수정한다 (단일 STA 스레드 앱에서는 Join 필요).
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

  // x:Class 클래스 이름이 프로그램(네임스페이스) 이름과 같으면 접미사 추가
  if fClassName = fNamespace then
    fClassName := fClassName + 'Window';

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

  // ── 클래스 선언 ──────────────────────────────────────────────────────────
  sb.AppendLine('type');
  sb.AppendLine(indent + fClassName + ' = class(System.Windows.Window)');

  // private: 컨트롤 필드
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

  // private: 이벤트 핸들러 선언
  // ★ 수정: hasEvents 를 먼저 계산한 뒤 선언부를 출력한다.
  //   이전 코드는 controls.Count > 0 블록 밖에서 hasEvents 를 재계산하여
  //   controls 가 0개일 때도 루프를 돌았던 것을 명확히 분리.
  hasEvents := false;
  foreach ctrl in controls do
    if ctrl.Events.Count > 0 then hasEvents := true;

  if hasEvents then
  begin
    sb.AppendLine('');
    sb.AppendLine(indent + '// ── ' + TLoc.S('codegen.comment.event_decl') + ' ─────────────────────');
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

  // ── constructor ──────────────────────────────────────────────────────────
  sb.AppendLine('constructor ' + fClassName + '.Create;');
  sb.AppendLine('begin');
  sb.AppendLine(indent + 'inherited Create;');
  sb.AppendLine(indent + 'InitializeComponent;');
  sb.AppendLine('end;');
  sb.AppendLine('');

  // ── InitializeComponent ──────────────────────────────────────────────────
  sb.Append(GenerateInitializeComponent(controls));
  sb.AppendLine('');

  // ── 이벤트 핸들러 구현 스텁 ──────────────────────────────────────────────
  if hasEvents then
  begin
    sb.AppendLine('// ── ' + TLoc.S('codegen.comment.event_impl') +
      ' ──────────────────────────────────');
    sb.AppendLine('');
    foreach ctrl in controls do
      foreach ev in ctrl.Events do
      begin
        var paramType := GetEventParamType(ctrl.TypeName, ev.Item1);
        // ★ 수정: 주석 형식 — "// ctrl.Event event handler" (공백 포함)
        //   이전: ctrl.Name + '.' + ev.Item1 + TLoc.S('codegen.comment.event_handler')
        //   → TLoc 값이 "이벤트 핸들러" 또는 "event handler" 인데, 한국어일 때는
        //     앞에 공백이 없어 "btnHello.Click이벤트 핸들러" 처럼 붙었음.
        //   수정: 항상 ' ' + TLoc.S(...) 로 공백을 명시 삽입.
        if fOptions.GenerateComments then
          sb.AppendLine('// ' + ctrl.Name + '.' + ev.Item1 +
            ' ' + TLoc.S('codegen.comment.event_handler'));
        sb.AppendLine('procedure ' + fClassName + '.' + ev.Item2 +
          '(sender: System.Object; e: ' + paramType + ');');
        sb.AppendLine('begin');
        if fOptions.GenerateComments then
          sb.AppendLine(indent + '// TODO: ' + ev.Item2);
        sb.AppendLine('end;');
        sb.AppendLine('');
      end;
  end;

  // ── 진입점 ───────────────────────────────────────────────────────────────
  sb.AppendLine('// ── ' + TLoc.S('codegen.comment.entrypoint') +
    ' ──────────────────────────────────');
  sb.AppendLine('procedure RunApp;');
  sb.AppendLine('begin');
  sb.AppendLine(indent + 'try');
  sb.AppendLine(indent + indent + 'var app := new System.Windows.Application();');
  sb.AppendLine(indent + indent + 'app.Run(new ' + fClassName + '());');
  sb.AppendLine(indent + 'except');
  sb.AppendLine(indent + indent + 'on ex: System.Exception do');
  sb.AppendLine(indent + indent + indent + 'System.Windows.Forms.MessageBox.Show(');
  sb.AppendLine(indent + indent + indent + indent +
    'ex.ToString(), ' + #39 + TLoc.S('codegen.runtime_error') + #39 + ',');
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
  // ★ 수정: t.Start() 만 있으면 메인 스레드가 즉시 end. 에 도달해 종료될 수 있음.
  //   t.Join() 을 추가하여 STA 스레드(WPF 앱)가 끝날 때까지 대기한다.
  sb.AppendLine(indent + 't.Start();');
  sb.AppendLine(indent + 't.Join();');
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