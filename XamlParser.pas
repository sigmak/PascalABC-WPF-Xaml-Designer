unit XamlParser;

// =============================================================================
// XamlParser.pas
//   ParseXClassInfo              — x:Class 속성에서 네임스페이스·클래스명 추출
//   ParseControlsFromXaml        — XAML 에서 x:Name + 이벤트 속성을 가진
//                                  컨트롤 목록(TControlInfo 리스트) 추출
//   StripEventAttributesForRuntime — 런타임 로드용으로 이벤트 속성 제거
// =============================================================================

uses
  System.Collections.Generic,
  System.Text.RegularExpressions,
  ControlInfo,      // TControlInfo
  WpfEventMap;     // WPF_EVENTS, IsWpfEvent

// -----------------------------------------------------------------------------
// ParseXClassInfo
//   xaml 문자열에서 x:Class="네임스페이스.클래스명" 를 분석한다.
//   성공 시 ns / cls 를 채우고 true 반환, 실패 시 기본값으로 false 반환.
// -----------------------------------------------------------------------------
function ParseXClassInfo(xaml: string; var ns: string; var cls: string): boolean;
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

// -----------------------------------------------------------------------------
// ParseControlsFromXaml
//   XAML 에서 x:Name 속성을 가진 요소를 찾고,
//   해당 요소에 달린 WPF 이벤트 속성(핸들러명)을 함께 수집한다.
// -----------------------------------------------------------------------------
function ParseControlsFromXaml(
  xaml: string
): System.Collections.Generic.List<TControlInfo>;
var
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
  Result := new System.Collections.Generic.List<TControlInfo>();

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

      Result.Add(info);
    end;

    mTag := mTag.NextMatch();
  end;
end;

// -----------------------------------------------------------------------------
// StripEventAttributesForRuntime
//   WPF 런타임 XamlXmlReader 는 이벤트 속성을 직접 처리할 수 없으므로
//   WPF_EVENTS 에 포함된 모든 이벤트 속성을 XAML 에서 제거한다.
// -----------------------------------------------------------------------------
function StripEventAttributesForRuntime(xaml: string): string;
var
  ev : string;
  re : System.Text.RegularExpressions.Regex;
  s  : string;
begin
  s := xaml;
  foreach ev in WPF_EVENTS do
  begin
    re := new System.Text.RegularExpressions.Regex('\s+' + ev + '\s*=\s*"[^"]*"');
    s  := re.Replace(s, '');
  end;
  Result := s;
end;

end.