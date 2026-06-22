unit ProjectOptions;

// =============================================================================
// ProjectOptions.pas
//   TProjectType 열거형과 TProjectOptions 클래스 정의
// =============================================================================

type
  TProjectType = (ptWpfApp, ptWpfControlLibrary);

type
  TProjectOptions = class
    // 프로젝트 정보
    ProjectName      : string;
    RootNamespace    : string;
    ClassName        : string;
    ProjectType      : TProjectType;
    ProjectPath      : string;

    // 컴파일러
    CompilerPath     : string;
    AdditionalArgs   : string;
    NoConsole        : boolean;
    DebugInfo        : boolean;
    WarningsAsErrors : boolean;
    AutoClean        : boolean;

    // 출력 설정
    OutputFileName   : string;
    OutputDirectory  : string;
    CopyXamlToOutput : boolean;
    EmbedAssemblyInfo: boolean;
    AssemblyVersion  : string;
    AssemblyTitle    : string;
    AssemblyCompany  : string;
    AssemblyCopyright: string;

    // 최적화
    OptimizeCode     : boolean;
    InlineExpansion  : boolean;
    TargetPlatform   : string;   // 'AnyCPU', 'x86', 'x64'

    // 코드 스타일
    IndentSize       : integer;
    UseTabs          : boolean;
    BraceStyle       : string;   // 'Pascal', 'Allman'
    AutoInsertBegin  : boolean;
    AutoInsertEnd    : boolean;
    GenerateComments : boolean;
    CommentStyle     : string;   // 'Line (//)','Block ({})','XML (///)'

    // 에디터
    FontName         : string;
    FontSize         : integer;
    XamlShowLineNum  : boolean;
    CodeShowLineNum  : boolean;
    XamlHighlight    : boolean;
    CodeHighlight    : boolean;
    WordWrap         : boolean;
    XamlFolding      : boolean;
    CodeFolding      : boolean;
    TabSize          : integer;
    ShowWhitespace   : boolean;
    HighlightCurrLine: boolean;
    AutoComplete     : boolean;

    // 디버그/실행
    StartAction      : string;   // 'Project','ExternalProgram','URL'
    ExternalProgram  : string;
    StartArgs        : string;
    WorkingDir       : string;
    UseEnvVars       : boolean;
    RunBeforeBuild   : boolean;

    constructor Create;
  end;

constructor TProjectOptions.Create;
begin
  ProjectName       := 'WpfApp1';
  RootNamespace     := 'WpfApp1';
  ClassName         := 'WpfApp1Window';
  ProjectType       := ptWpfApp;
  ProjectPath       := '';
  CompilerPath      := '';
  AdditionalArgs    := '';
  NoConsole         := true;
  DebugInfo         := false;
  WarningsAsErrors  := false;
  AutoClean         := true;
  OutputFileName    := '';
  OutputDirectory   := '';
  CopyXamlToOutput  := true;
  EmbedAssemblyInfo := false;
  AssemblyVersion   := '1.0.0.0';
  AssemblyTitle     := '';
  AssemblyCompany   := '';
  AssemblyCopyright := '';
  OptimizeCode      := false;
  InlineExpansion   := false;
  TargetPlatform    := 'AnyCPU';
  IndentSize        := 2;
  UseTabs           := false;
  BraceStyle        := 'Pascal';
  AutoInsertBegin   := true;
  AutoInsertEnd     := true;
  GenerateComments  := true;
  CommentStyle      := 'Line (//)';
  FontName          := 'Consolas';
  FontSize          := 13;
  XamlShowLineNum   := true;
  CodeShowLineNum   := true;
  XamlHighlight     := true;
  CodeHighlight     := true;
  WordWrap          := false;
  XamlFolding       := true;
  CodeFolding       := true;
  TabSize           := 2;
  ShowWhitespace    := false;
  HighlightCurrLine := true;
  AutoComplete      := true;
  StartAction       := 'Project';
  ExternalProgram   := '';
  StartArgs         := '';
  WorkingDir        := '';
  UseEnvVars        := false;
  RunBeforeBuild    := false;
end;

end.