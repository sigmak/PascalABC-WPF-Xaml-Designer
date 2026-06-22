unit XamlPreprocessor;

// =============================================================================
// XamlPreprocessor.pas
//   StripCustomNamespaces   — clr-namespace 커스텀 네임스페이스 요소/속성 제거
//   PrepareXamlForBuild     — 빌드용 XAML 정리
//                             (XML 선언·이벤트·mc:Ignorable·d: 속성 제거)
//   PreprocessXaml          — 디자이너 로드용 XAML 변환
//                             (Window/UserControl → Grid 래퍼로 변환)
// =============================================================================

uses
  System.Text.RegularExpressions,
  XamlParser;   // StripEventAttributesForRuntime

// -----------------------------------------------------------------------------
// StripCustomNamespaces
// -----------------------------------------------------------------------------
function StripCustomNamespaces(xaml: string): string;
var
  prefixes : System.Collections.Generic.List<string>;
  m        : System.Text.RegularExpressions.Match;
  re       : System.Text.RegularExpressions.Regex;
  prefix   : string;
  s        : string;
begin
  s        := xaml;
  prefixes := new System.Collections.Generic.List<string>();

  re := new System.Text.RegularExpressions.Regex('xmlns:(\w+)="clr-namespace:[^"]*"');
  m  := re.Match(s);
  while m.Success do
  begin
    prefixes.Add(m.Groups[1].Value);
    m := m.NextMatch();
  end;

  foreach prefix in prefixes do
  begin
    // 셀프 클로징 요소 제거
    s := System.Text.RegularExpressions.Regex.Replace(s, '<' + prefix + ':[^>]*/>', '');
    // 열기·닫기 요소 제거
    s := System.Text.RegularExpressions.Regex.Replace(s,
      '<' + prefix + ':[^>]*>[\s\S]*?</' + prefix + ':[^>]*>', '');
    // 해당 접두사를 사용하는 속성 바인딩 제거
    s := System.Text.RegularExpressions.Regex.Replace(s,
      '\s+\w[\w.]*="\{[^"]*' + prefix + ':[^"]*\}"', '');
    // xmlns 선언 제거
    s := System.Text.RegularExpressions.Regex.Replace(s,
      '\s+xmlns:' + prefix + '="clr-namespace:[^"]*"', '');
  end;

  Result := s;
end;

// -----------------------------------------------------------------------------
// PrepareXamlForBuild
//   빌드 시 XAML 파일에 저장하는 내용을 정리한다.
//   · XML 선언(<?xml ...?>) 제거
//   · 이벤트 속성 제거 (런타임 로더가 처리할 수 없음)
//   · mc:Ignorable, xmlns:mc, d:* 속성, xmlns:d 제거
// -----------------------------------------------------------------------------
function PrepareXamlForBuild(xaml: string): string;
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

  s := StripEventAttributesForRuntime(s);

  re := new System.Text.RegularExpressions.Regex('\s+mc:Ignorable\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');
  re := new System.Text.RegularExpressions.Regex('\s+xmlns:mc\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');
  re := new System.Text.RegularExpressions.Regex('\s+d:\w+\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');
  re := new System.Text.RegularExpressions.Regex('\s+xmlns:d\s*=\s*"[^"]*"');
  s  := re.Replace(s, '');

  Result := s;
end;

// -----------------------------------------------------------------------------
// PreprocessXaml
//   WpfDesign 디자이너 로드용으로 XAML 을 변환한다.
//   · Window / UserControl 루트 → Grid 래퍼로 교체
//     (WpfDesign 은 Grid 를 루트로 선호)
//   · x:Class, mc:Ignorable, d:* 등 불필요 속성 제거
//   · Resources / Background 자식 요소는 Grid.Resources / Grid.Background 로 이동
// -----------------------------------------------------------------------------
function PreprocessXaml(xaml: string): string;
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

  // 이벤트 속성 제거
  s := StripEventAttributesForRuntime(s);

  // 디자이너 불필요 속성 제거
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

      // 크기 읽기 (없으면 기본값)
      w := root.GetAttribute('Width');
      h := root.GetAttribute('Height');
      if w = '' then w := root.GetAttribute('d:DesignWidth');
      if h = '' then h := root.GetAttribute('d:DesignHeight');
      if w = '' then w := '800';
      if h = '' then h := '450';
      sizeStr := ' Width="' + w + '" Height="' + h + '"';

      // 자식 노드 분류
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
      end;
    except
      inner    := '';
      resInner := '';
      bgInner  := '';
      sizeStr  := ' Width="800" Height="450"';
    end;

    var resBlock := '';
    if resInner <> '' then
      resBlock := '<Grid.Resources>' + resInner + '</Grid.Resources>';
    var bgBlock := '';
    if bgInner <> '' then
      bgBlock := '<Grid.Background>' + bgInner + '</Grid.Background>';

    Result :=
      '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
      '      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"' +
      sizeStr + '>' +
      resBlock + bgBlock + inner + '</Grid>';
    exit;
  end;

  Result := StripCustomNamespaces(s);
end;

end.