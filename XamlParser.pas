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
// ROOT_TAG_NAMES
//   XAML 루트가 될 수 있는 최상위 타입 이름 목록.
//   ParseControlsFromXaml 에서 첫 번째 매칭 태그가 이 목록에 속하면
//   "루트" 로 판정하여 controls 리스트에서 제외한다.
//   대신 ParseRootControlInfo 로 별도 수집한다.
// -----------------------------------------------------------------------------
var ROOT_TAG_NAMES: array of string :=
  ('Window', 'UserControl', 'Page', 'NavigationWindow', 'Application');

function IsRootTagName(tagName: string): boolean;
var n: string;
begin
  foreach n in ROOT_TAG_NAMES do
    if string.Equals(n, tagName, System.StringComparison.OrdinalIgnoreCase) then
    begin Result := true; exit; end;
  Result := false;
end;

// -----------------------------------------------------------------------------
// ParseControlsFromXaml
//   XAML 에서 x:Name 속성을 가진 요소를 찾고,
//   해당 요소에 달린 WPF 이벤트 속성(핸들러명)을 함께 수집한다.
//
// ★ 수정: 첫 번째 태그(루트 Window/UserControl/Page 등)는 controls 리스트에
//   포함하지 않는다. 루트 이벤트(Loaded, Closing 등)는 InitializeComponent 에서
//   FindName 경로가 아니라 Self.EventName += Handler 로 직접 구독해야 하기
//   때문이다. FindName('window1')은 Window 자신에 대해 null 을 반환하므로
//   이벤트 구독이 누락되고, XAML 로더도 핸들러를 찾지 못해 런타임 예외가
//   발생하여 프로그램이 즉시 종료된다.
//   루트 이벤트/이름은 ParseRootControlInfo 로 따로 수집한다.
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
  isFirst : boolean;
begin
  Result := new System.Collections.Generic.List<TControlInfo>();

  reTag  := new System.Text.RegularExpressions.Regex(
    '<([A-Za-z][A-Za-z0-9]*)\s([^>]*?)(?:/>|>)',
    System.Text.RegularExpressions.RegexOptions.Singleline);
  reAttr := new System.Text.RegularExpressions.Regex('(\w[\w.]*)\s*=\s*"([^"]*)"');
  reName := new System.Text.RegularExpressions.Regex('x:Name\s*=\s*"([^"]+)"');

  isFirst := true;
  mTag := reTag.Match(xaml);
  while mTag.Success do
  begin
    tagName := mTag.Groups[1].Value;
    tagText := mTag.Value;

    // ★ 수정: 첫 번째 태그가 루트 타입이면 건너뛴다.
    //   (루트 이벤트는 ParseRootControlInfo → Self.Event += Handler 로 처리)
    if isFirst then
    begin
      isFirst := false;
      if IsRootTagName(tagName) then
      begin
        mTag := mTag.NextMatch();
        continue;
      end;
    end;

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
// ParseRootControlInfo
//   XAML 의 첫 번째 태그(루트 Window/UserControl/Page)에서
//   x:Name 과 WPF 이벤트 속성만 수집하여 TControlInfo 로 반환한다.
//   루트가 없거나 이벤트/이름이 없으면 nil 반환.
//
//   코드 생성기는 루트 이벤트를 Self.EventName += Handler 형식으로 구독한다
//   (FindName 은 루트 자신에 대해 null 을 반환하므로 사용 불가).
// -----------------------------------------------------------------------------
function ParseRootControlInfo(
  xaml: string
): TControlInfo;
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
  Result := nil;

  reTag  := new System.Text.RegularExpressions.Regex(
    '<([A-Za-z][A-Za-z0-9]*)\s([^>]*?)(?:/>|>)',
    System.Text.RegularExpressions.RegexOptions.Singleline);
  reAttr := new System.Text.RegularExpressions.Regex('(\w[\w.]*)\s*=\s*"([^"]*)"');
  reName := new System.Text.RegularExpressions.Regex('x:Name\s*=\s*"([^"]+)"');

  mTag := reTag.Match(xaml);
  if not mTag.Success then exit;

  tagName := mTag.Groups[1].Value;
  if not IsRootTagName(tagName) then exit;

  tagText  := mTag.Value;
  mName    := reName.Match(tagText);
  ctrlName := (if mName.Success then mName.Groups[1].Value else '');

  // 이벤트가 없으면 굳이 반환할 필요 없음
  var hasEvent := false;
  mAttr := reAttr.Match(tagText);
  while mAttr.Success do
  begin
    if IsWpfEvent(mAttr.Groups[1].Value) then begin hasEvent := true; break; end;
    mAttr := mAttr.NextMatch();
  end;
  if not hasEvent then exit;

  info := new TControlInfo(ctrlName, tagName);

  mAttr := reAttr.Match(tagText);
  while mAttr.Success do
  begin
    var attrName    := mAttr.Groups[1].Value;
    var handlerName := mAttr.Groups[2].Value;
    if IsWpfEvent(attrName) then
      info.Events.Add(System.Tuple.Create(attrName, handlerName));
    mAttr := mAttr.NextMatch();
  end;

  Result := info;
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