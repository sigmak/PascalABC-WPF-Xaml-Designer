unit ProjectOptions;

// =============================================================================
// ProjectOptions.pas
//   TProjectType 열거형과 TProjectOptions 클래스 정의
// =============================================================================
interface

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
    // ★ 추가
    procedure SaveToFile(const path: string);
    procedure LoadFromFile(const path: string);
  end;
  
implementation  

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

// -----------------------------------------------------------------------
// SaveToFile : key=value 텍스트 형식으로 저장
// -----------------------------------------------------------------------
procedure TProjectOptions.SaveToFile(const path: string);
var
  sw: System.IO.StreamWriter;
begin
  sw := new System.IO.StreamWriter(path, false, System.Text.Encoding.UTF8);
  try
    sw.WriteLine('ProjectName='       + ProjectName);
    sw.WriteLine('RootNamespace='     + RootNamespace);
    sw.WriteLine('ClassName='         + ClassName);
    sw.WriteLine('ProjectType='       + integer(ProjectType).ToString());
    sw.WriteLine('ProjectPath='       + ProjectPath);
    sw.WriteLine('CompilerPath='      + CompilerPath);
    sw.WriteLine('AdditionalArgs='    + AdditionalArgs);
    sw.WriteLine('NoConsole='         + NoConsole.ToString());
    sw.WriteLine('DebugInfo='         + DebugInfo.ToString());
    sw.WriteLine('WarningsAsErrors='  + WarningsAsErrors.ToString());
    sw.WriteLine('AutoClean='         + AutoClean.ToString());
    sw.WriteLine('OutputFileName='    + OutputFileName);
    sw.WriteLine('OutputDirectory='   + OutputDirectory);
    sw.WriteLine('CopyXamlToOutput='  + CopyXamlToOutput.ToString());
    sw.WriteLine('EmbedAssemblyInfo=' + EmbedAssemblyInfo.ToString());
    sw.WriteLine('AssemblyVersion='   + AssemblyVersion);
    sw.WriteLine('AssemblyTitle='     + AssemblyTitle);
    sw.WriteLine('AssemblyCompany='   + AssemblyCompany);
    sw.WriteLine('AssemblyCopyright=' + AssemblyCopyright);
    sw.WriteLine('OptimizeCode='      + OptimizeCode.ToString());
    sw.WriteLine('InlineExpansion='   + InlineExpansion.ToString());
    sw.WriteLine('TargetPlatform='    + TargetPlatform);
    sw.WriteLine('IndentSize='        + IndentSize.ToString());
    sw.WriteLine('UseTabs='           + UseTabs.ToString());
    sw.WriteLine('BraceStyle='        + BraceStyle);
    sw.WriteLine('AutoInsertBegin='   + AutoInsertBegin.ToString());
    sw.WriteLine('AutoInsertEnd='     + AutoInsertEnd.ToString());
    sw.WriteLine('GenerateComments='  + GenerateComments.ToString());
    sw.WriteLine('CommentStyle='      + CommentStyle);
    sw.WriteLine('FontName='          + FontName);
    sw.WriteLine('FontSize='          + FontSize.ToString());
    sw.WriteLine('XamlShowLineNum='   + XamlShowLineNum.ToString());
    sw.WriteLine('CodeShowLineNum='   + CodeShowLineNum.ToString());
    sw.WriteLine('XamlHighlight='     + XamlHighlight.ToString());
    sw.WriteLine('CodeHighlight='     + CodeHighlight.ToString());
    sw.WriteLine('WordWrap='          + WordWrap.ToString());
    sw.WriteLine('XamlFolding='       + XamlFolding.ToString());
    sw.WriteLine('CodeFolding='       + CodeFolding.ToString());
    sw.WriteLine('TabSize='           + TabSize.ToString());
    sw.WriteLine('ShowWhitespace='    + ShowWhitespace.ToString());
    sw.WriteLine('HighlightCurrLine=' + HighlightCurrLine.ToString());
    sw.WriteLine('AutoComplete='      + AutoComplete.ToString());
    sw.WriteLine('StartAction='       + StartAction);
    sw.WriteLine('ExternalProgram='   + ExternalProgram);
    sw.WriteLine('StartArgs='         + StartArgs);
    sw.WriteLine('WorkingDir='        + WorkingDir);
    sw.WriteLine('UseEnvVars='        + UseEnvVars.ToString());
    sw.WriteLine('RunBeforeBuild='    + RunBeforeBuild.ToString());
  finally
    sw.Close();
  end;
end;

// -----------------------------------------------------------------------
// LoadFromFile : key=value 텍스트에서 로드
// -----------------------------------------------------------------------
procedure TProjectOptions.LoadFromFile(const path: string);
var
  lines: array of string;
  line, key, val: string;
  eqPos: integer;
begin
  lines := System.IO.File.ReadAllLines(path, System.Text.Encoding.UTF8);
  foreach line in lines do
  begin
    eqPos := line.IndexOf('=');
    if eqPos < 1 then continue;
    key := line.Substring(0, eqPos).Trim();
    val := line.Substring(eqPos + 1);   // 값 쪽은 Trim 안 함 (경로에 공백 가능)

    case key of
      'ProjectName'       : ProjectName        := val;
      'RootNamespace'     : RootNamespace      := val;
      'ClassName'         : ClassName          := val;
      'ProjectType'       : ProjectType        := TProjectType(integer.Parse(val));
      'ProjectPath'       : ProjectPath        := val;
      'CompilerPath'      : CompilerPath       := val;
      'AdditionalArgs'    : AdditionalArgs     := val;
      'NoConsole'         : NoConsole          := boolean.Parse(val);
      'DebugInfo'         : DebugInfo          := boolean.Parse(val);
      'WarningsAsErrors'  : WarningsAsErrors   := boolean.Parse(val);
      'AutoClean'         : AutoClean          := boolean.Parse(val);
      'OutputFileName'    : OutputFileName     := val;
      'OutputDirectory'   : OutputDirectory    := val;
      'CopyXamlToOutput'  : CopyXamlToOutput  := boolean.Parse(val);
      'EmbedAssemblyInfo' : EmbedAssemblyInfo  := boolean.Parse(val);
      'AssemblyVersion'   : AssemblyVersion    := val;
      'AssemblyTitle'     : AssemblyTitle      := val;
      'AssemblyCompany'   : AssemblyCompany    := val;
      'AssemblyCopyright' : AssemblyCopyright  := val;
      'OptimizeCode'      : OptimizeCode       := boolean.Parse(val);
      'InlineExpansion'   : InlineExpansion    := boolean.Parse(val);
      'TargetPlatform'    : TargetPlatform     := val;
      'IndentSize'        : IndentSize         := integer.Parse(val);
      'UseTabs'           : UseTabs            := boolean.Parse(val);
      'BraceStyle'        : BraceStyle         := val;
      'AutoInsertBegin'   : AutoInsertBegin    := boolean.Parse(val);
      'AutoInsertEnd'     : AutoInsertEnd      := boolean.Parse(val);
      'GenerateComments'  : GenerateComments   := boolean.Parse(val);
      'CommentStyle'      : CommentStyle       := val;
      'FontName'          : FontName           := val;
      'FontSize'          : FontSize           := integer.Parse(val);
      'XamlShowLineNum'   : XamlShowLineNum    := boolean.Parse(val);
      'CodeShowLineNum'   : CodeShowLineNum    := boolean.Parse(val);
      'XamlHighlight'     : XamlHighlight      := boolean.Parse(val);
      'CodeHighlight'     : CodeHighlight      := boolean.Parse(val);
      'WordWrap'          : WordWrap           := boolean.Parse(val);
      'XamlFolding'       : XamlFolding        := boolean.Parse(val);
      'CodeFolding'       : CodeFolding        := boolean.Parse(val);
      'TabSize'           : TabSize            := integer.Parse(val);
      'ShowWhitespace'    : ShowWhitespace     := boolean.Parse(val);
      'HighlightCurrLine' : HighlightCurrLine  := boolean.Parse(val);
      'AutoComplete'      : AutoComplete       := boolean.Parse(val);
      'StartAction'       : StartAction        := val;
      'ExternalProgram'   : ExternalProgram    := val;
      'StartArgs'         : StartArgs          := val;
      'WorkingDir'        : WorkingDir         := val;
      'UseEnvVars'        : UseEnvVars         := boolean.Parse(val);
      'RunBeforeBuild'    : RunBeforeBuild     := boolean.Parse(val);
    end;
  end;
end;

end.