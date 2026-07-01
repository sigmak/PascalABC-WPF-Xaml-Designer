unit ProjectFile;

// =============================================================================
// ProjectFile.pas
//
//   PascalABC-WPF-Designer 의 "프로젝트 파일(.pwproj)" / "솔루션 파일(.pwsln)"
//   직렬화를 담당하는 유닛. Visual Studio 의 .csproj / .sln 구조를 단순화하여
//   2단계(솔루션 → 프로젝트)로 구성한다.
//
//   ※ 사용자별 로컬 설정(컴파일러 경로·에디터 폰트 등)은 이 유닛이 아니라
//      기존 TProjectOptions.SaveToFile/LoadFromFile (→ .pwproj.user) 이 담당한다.
//      VS 비유: .pwproj = .csproj,  .pwproj.user = .csproj.user,  .pwsln = .sln
//
//   파일 구조 예:
//     MySolution.pwsln
//     WpfApp1\WpfApp1.pwproj
//     WpfApp1\WpfApp1.pwproj.user
//     WpfApp1\WpfApp1.xaml
//     WpfApp1\WpfApp1.pas
// =============================================================================

interface

uses
  System.IO,
  System.Text,
  System.Xml,
  ProjectOptions; // TProjectType

const
  PROJECT_FILE_EXT      = '.pwproj';
  PROJECT_USER_FILE_EXT = '.pwproj.user';
  SOLUTION_FILE_EXT     = '.pwsln';
  PROJECT_FILE_VERSION  = '1';
  SOLUTION_FILE_VERSION = '1';

// TProjectFile.SaveToFile / TSolutionFile.SaveToFile 공통 — 들여쓰기·UTF8 설정으로
// XmlDocument를 지정 경로에 저장한다.
procedure SaveXmlDocument(doc: System.Xml.XmlDocument; path: string);

type
  // ───────────────────────────────────────────────────────────────────────
  // TProjectFile — 단일 프로젝트(.pwproj)의 내용
  //   VS의 .csproj 에서 우리에게 필요한 최소 정보만 옮긴 것:
  //   프로젝트 식별 정보 + 소스 파일 목록(상대 경로).
  // ───────────────────────────────────────────────────────────────────────
  TProjectFile = class
  public
    ProjectName   : string;
    RootNamespace : string;
    ClassName     : string;
    ProjectType   : TProjectType;
    XamlFileName  : string; // 프로젝트 폴더 기준 상대 파일명
    PasFileName   : string; // 프로젝트 폴더 기준 상대 파일명

    constructor Create;
    begin
      ProjectName   := '';
      RootNamespace := '';
      ClassName     := '';
      ProjectType   := ptWpfApp;
      XamlFileName  := '';
      PasFileName   := '';
    end;

    // XML 엘리먼트 하나를 만들어 parent에 붙이는 헬퍼.
    // ★ 수정: SaveToFile 내부의 중첩 procedure였으나 PascalABC.NET이
    //   클래스 인라인 메서드 본문 안의 중첩 서브루틴 선언을 지원하지 않아
    //   (var절 뒤에 중첩 procedure가 오면 파서 오류) 별도 메서드로 분리함.
    procedure AddElem(doc: System.Xml.XmlDocument; parent: System.Xml.XmlElement;
      name, value: string);
    var e: System.Xml.XmlElement;
    begin
      e := doc.CreateElement(name);
      e.InnerText := value;
      parent.AppendChild(e);
    end;

    // 지정 경로(예: C:\Sol\WpfApp1\WpfApp1.pwproj)에 XML로 저장
    procedure SaveToFile(path: string);
    var
      doc   : System.Xml.XmlDocument;
      root  : System.Xml.XmlElement;
    begin
      doc  := new System.Xml.XmlDocument();
      root := doc.CreateElement('PwProject');
      root.SetAttribute('Version', PROJECT_FILE_VERSION);
      doc.AppendChild(root);

      AddElem(doc, root, 'ProjectName',   ProjectName);
      AddElem(doc, root, 'RootNamespace', RootNamespace);
      AddElem(doc, root, 'ClassName',     ClassName);
      AddElem(doc, root, 'ProjectType',
        (if ProjectType = ptWpfControlLibrary then 'WpfControlLibrary' else 'WpfApplication'));
      AddElem(doc, root, 'XamlFile', XamlFileName);
      AddElem(doc, root, 'PasFile',  PasFileName);

      SaveXmlDocument(doc, path);
    end;

    // root 엘리먼트의 자식 노드 텍스트를 읽는 헬퍼 (없으면 fallback 반환).
    // ★ 수정: LoadFromFile 내부의 중첩 function이었으나 위와 동일한 이유로 분리함.
    function GetChildText(root: System.Xml.XmlElement; name, fallback: string): string;
    var node: System.Xml.XmlNode;
    begin
      node := root.SelectSingleNode(name);
      Result := (if node <> nil then node.InnerText else fallback);
    end;

    // 지정 경로의 .pwproj XML을 읽어 필드에 채운다
    procedure LoadFromFile(path: string);
    var
      doc  : System.Xml.XmlDocument;
      root : System.Xml.XmlElement;
    begin
      doc := new System.Xml.XmlDocument();
      doc.Load(path);
      root := doc.DocumentElement;

      ProjectName   := GetChildText(root, 'ProjectName',   System.IO.Path.GetFileNameWithoutExtension(path));
      RootNamespace := GetChildText(root, 'RootNamespace', ProjectName);
      ClassName     := GetChildText(root, 'ClassName',     ProjectName);
      ProjectType   := (if GetChildText(root, 'ProjectType', 'WpfApplication') = 'WpfControlLibrary'
                         then ptWpfControlLibrary else ptWpfApp);
      XamlFileName  := GetChildText(root, 'XamlFile', ProjectName + '.xaml');
      PasFileName   := GetChildText(root, 'PasFile',  ProjectName + '.pas');
    end;
  end;

  // ───────────────────────────────────────────────────────────────────────
  // TSolutionFile — 솔루션(.pwsln)의 내용
  //   현재는 "프로젝트 1개"만 지원(향후 다중 프로젝트 확장을 고려해 목록으로 유지).
  //   VS의 .sln 처럼, 솔루션 파일 기준 "상대 경로"로 프로젝트를 참조한다.
  // ───────────────────────────────────────────────────────────────────────
  TSolutionFile = class
  public
    SolutionName    : string;
    ProjectRelPaths : System.Collections.Generic.List<string>; // .pwproj 의 상대 경로들

    constructor Create;
    begin
      SolutionName    := '';
      ProjectRelPaths := new System.Collections.Generic.List<string>();
    end;

    procedure SaveToFile(path: string);
    var
      doc  : System.Xml.XmlDocument;
      root : System.Xml.XmlElement;
      projsElem, pElem : System.Xml.XmlElement;
      relPath: string;
    begin
      doc  := new System.Xml.XmlDocument();
      root := doc.CreateElement('PwSolution');
      root.SetAttribute('Version', SOLUTION_FILE_VERSION);
      doc.AppendChild(root);

      var nameElem := doc.CreateElement('SolutionName');
      nameElem.InnerText := SolutionName;
      root.AppendChild(nameElem);

      projsElem := doc.CreateElement('Projects');
      root.AppendChild(projsElem);
      foreach relPath in ProjectRelPaths do
      begin
        pElem := doc.CreateElement('Project');
        pElem.SetAttribute('Path', relPath);
        projsElem.AppendChild(pElem);
      end;

      SaveXmlDocument(doc, path);
    end;

    procedure LoadFromFile(path: string);
    var
      doc       : System.Xml.XmlDocument;
      root      : System.Xml.XmlElement;
      nameNode  : System.Xml.XmlNode;
      projNodes : System.Xml.XmlNodeList;
      n         : System.Xml.XmlNode;
      elem      : System.Xml.XmlElement;
    begin
      doc := new System.Xml.XmlDocument();
      doc.Load(path);
      root := doc.DocumentElement;

      nameNode := root.SelectSingleNode('SolutionName');
      SolutionName := (if nameNode <> nil then nameNode.InnerText
                        else System.IO.Path.GetFileNameWithoutExtension(path));

      ProjectRelPaths.Clear();
      projNodes := root.SelectNodes('Projects/Project');
      foreach n in projNodes do
      begin
        // ★ 수정: XmlNode.Attributes['Path']는 정수 인덱서만 지원해 타입 오류가 났음.
        //   XmlElement로 캐스팅하면 이름 기반 인덱서(GetAttribute)를 안전하게 쓸 수 있다.
        elem := n as System.Xml.XmlElement;
        if elem <> nil then
        begin
          var p := elem.GetAttribute('Path');
          if p <> '' then ProjectRelPaths.Add(p);
        end;
      end;
    end;

    // 첫 번째(=현재 유일하게 지원하는) 프로젝트의 절대 경로.
    // solutionFolder: 솔루션 파일이 들어있는 폴더(끝에 '\' 포함 권장)
    function FirstProjectAbsolutePath(solutionFolder: string): string;
    begin
      Result := '';
      if ProjectRelPaths.Count > 0 then
        Result := System.IO.Path.GetFullPath(
          System.IO.Path.Combine(solutionFolder, ProjectRelPaths[0]));
    end;
  end;

// 두 절대경로 중 fromPath가 위치한 폴더를 기준으로 toPath의 상대경로를 구한다.
// (VS가 .sln 안에 프로젝트를 상대경로로 적는 방식과 동일)
function MakeRelativePath(fromFolder, toPath: string): string;

implementation

procedure SaveXmlDocument(doc: System.Xml.XmlDocument; path: string);
var
  settings: System.Xml.XmlWriterSettings;
  writer  : System.Xml.XmlWriter;
begin
  settings := new System.Xml.XmlWriterSettings();
  settings.Indent := true;
  settings.IndentChars := '  ';
  settings.Encoding := System.Text.Encoding.UTF8;
  writer := System.Xml.XmlWriter.Create(path, settings);
  try
    doc.Save(writer);
  finally
    writer.Close();
  end;
end;

function MakeRelativePath(fromFolder, toPath: string): string;
var
  fromUri, toUri: System.Uri;
  relUri: System.Uri;
  rel: string;
begin
  if not fromFolder.EndsWith('\') then fromFolder := fromFolder + '\';
  fromUri := new System.Uri(fromFolder);
  toUri   := new System.Uri(toPath);
  relUri  := fromUri.MakeRelativeUri(toUri);
  rel     := System.Uri.UnescapeDataString(relUri.ToString());
  Result  := rel.Replace('/', '\');
end;

end.