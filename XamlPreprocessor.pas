unit XamlPreprocessor;

// =============================================================================
// XamlPreprocessor.pas
//   StripCustomNamespaces   — clr-namespace 커스텀 네임스페이스 요소/속성 제거
//   PrepareXamlForBuild     — 빌드용 XAML 정리
//                             (XML 선언·이벤트·mc:Ignorable·d: 속성 제거)
//   PreprocessXaml          — 디자이너 로드용 XAML 변환
//                             (Window/UserControl → Grid 래퍼로 변환)
//
// ★ 리팩토링 (구조 정리):
//   - "new Regex(패턴); s := re.Replace(s, '');" 2줄짜리 패턴이 PrepareXamlForBuild
//     에 4번, PreprocessXaml 에 5번, StripCustomNamespaces 에 4번 — 총 13번
//     반복되고 있었다. StripByRegex 헬퍼로 한 줄 호출로 줄였다.
//   - mc:Ignorable / xmlns:mc / d:* / xmlns:d 4개 속성 제거는 PrepareXamlForBuild
//     와 PreprocessXaml 양쪽에 동일한 정규식이 그대로 복붙되어 있었다.
//     패턴을 한쪽만 고치고 다른 쪽을 깜빡할 위험이 있어 StripDesignerOnlyAttributes
//     하나로 합쳤다 (두 함수가 이 하나의 정의를 공유).
//   - Width/Height 를 읽고 없으면 d:DesignWidth/DesignHeight, 그것도 없으면
//     기본값으로 대체하는 3단 폴백 로직을 GetXmlAttrWithFallback 으로 추출.
//   - Grid.Resources / Grid.Background 블록을 "내용 있으면 태그로 감싸고,
//     없으면 빈 문자열" 처리하던 반복 코드를 WrapIfNotEmpty 로 추출.
// =============================================================================

uses
  System.Text.RegularExpressions,
  XamlParser;   // StripEventAttributesForRuntime

// -----------------------------------------------------------------------------
// StripByRegex
//   s 에서 pattern 에 매치되는 부분을 전부 제거(빈 문자열로 치환)한다.
//   "new Regex(...); re.Replace(...)" 두 줄짜리 반복을 한 줄 호출로 줄이기 위한 헬퍼.
// -----------------------------------------------------------------------------
function StripByRegex(s: string; pattern: string): string;
begin
  Result := System.Text.RegularExpressions.Regex.Replace(s, pattern, '');
end;

// -----------------------------------------------------------------------------
// StripDesignerOnlyAttributes
//   mc:Ignorable, xmlns:mc, d:* (Blend 디자인타임 속성), xmlns:d 를 제거한다.
//   PrepareXamlForBuild 와 PreprocessXaml 이 동일하게 필요로 하는 정리이므로
//   패턴을 이 한 곳에서만 관리한다.
// -----------------------------------------------------------------------------
function StripDesignerOnlyAttributes(s: string): string;
const
  PATTERNS: array of string = [
    '\s+mc:Ignorable\s*=\s*"[^"]*"',
    '\s+xmlns:mc\s*=\s*"[^"]*"',
    '\s+d:\w+\s*=\s*"[^"]*"',
    '\s+xmlns:d\s*=\s*"[^"]*"'
  ];
var
  pattern: string;
begin
  Result := s;
  foreach pattern in PATTERNS do
    Result := StripByRegex(Result, pattern);
end;

// -----------------------------------------------------------------------------
// StripXmlDeclaration
//   문자열 맨 앞의 <?xml ... ?> 선언을 제거한다. 없으면 그대로 반환.
// -----------------------------------------------------------------------------
function StripXmlDeclaration(s: string): string;
var
  trimmed : string;
  declEnd : integer;
begin
  Result  := s;
  trimmed := s.TrimStart();
  if not trimmed.StartsWith('<?xml') then exit;

  declEnd := trimmed.IndexOf('?>');
  if declEnd >= 0 then
    Result := trimmed.Substring(declEnd + 2).TrimStart();
end;

// -----------------------------------------------------------------------------
// GetXmlAttrWithFallback
//   root 에서 primaryAttr 값을 읽고, 비어 있으면 fallbackAttr, 그마저 비어
//   있으면 defaultVal 을 반환한다.
//   (Width 없으면 d:DesignWidth, 그것도 없으면 "800" 같은 3단 폴백에 사용)
// -----------------------------------------------------------------------------
function GetXmlAttrWithFallback(root: System.Xml.XmlElement;
  primaryAttr, fallbackAttr, defaultVal: string): string;
begin
  Result := root.GetAttribute(primaryAttr);
  if Result = '' then
    Result := root.GetAttribute(fallbackAttr);
  if Result = '' then
    Result := defaultVal;
end;

// -----------------------------------------------------------------------------
// WrapIfNotEmpty
//   inner 가 비어 있지 않으면 <tagName>inner</tagName> 로 감싸고,
//   비어 있으면 빈 문자열을 반환한다.
// -----------------------------------------------------------------------------
function WrapIfNotEmpty(inner, tagName: string): string;
begin
  if inner = '' then
    Result := ''
  else
    Result := '<' + tagName + '>' + inner + '</' + tagName + '>';
end;

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
    s := StripByRegex(s, '<' + prefix + ':[^>]*/>');
    // 열기·닫기 요소 제거
    s := StripByRegex(s, '<' + prefix + ':[^>]*>[\s\S]*?</' + prefix + ':[^>]*>');
    // 해당 접두사를 사용하는 속성 바인딩 제거
    s := StripByRegex(s, '\s+\w[\w.]*="\{[^"]*' + prefix + ':[^"]*\}"');
    // xmlns 선언 제거
    s := StripByRegex(s, '\s+xmlns:' + prefix + '="clr-namespace:[^"]*"');
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
  s : string;
begin
  s := StripXmlDeclaration(xaml);
  s := StripEventAttributesForRuntime(s);
  s := StripDesignerOnlyAttributes(s);
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
  s := StripByRegex(s, '\s+x:Class\s*=\s*"[^"]*"');
  s := StripDesignerOnlyAttributes(s);

  var trimmed := s.TrimStart();
  if trimmed.StartsWith('<Window') or trimmed.StartsWith('<UserControl') then
  begin
    s := StripCustomNamespaces(s);
    try
      doc  := new System.Xml.XmlDocument();
      doc.LoadXml(s);
      root := doc.DocumentElement;

      // 크기 읽기 (없으면 d:DesignWidth/Height, 그마저 없으면 기본값)
      w := GetXmlAttrWithFallback(root, 'Width',  'd:DesignWidth',  '800');
      h := GetXmlAttrWithFallback(root, 'Height', 'd:DesignHeight', '450');
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

    Result :=
      '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
      '      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"' +
      sizeStr + '>' +
      WrapIfNotEmpty(resInner, 'Grid.Resources') +
      WrapIfNotEmpty(bgInner, 'Grid.Background') +
      inner + '</Grid>';
    exit;
  end;

  Result := StripCustomNamespaces(s);
end;

end.