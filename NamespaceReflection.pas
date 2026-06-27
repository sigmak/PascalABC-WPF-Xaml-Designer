unit NamespaceReflection;

// =============================================================================
// NamespaceReflection.pas
//
// .NET 리플렉션 기반 네임스페이스/타입 인텔리센스 인덱스.
//
//   System.        →  Windows, Collections, Text, IO, ... (네임스페이스 자식)
//   System.Windows.        →  Application, Controls, MessageBox, ... (네임스페이스+타입 혼합)
//   System.Windows.Application.   →  Run, Current, Exit, ... (타입의 실제 멤버)
//
// 기본으로 잡는 어셈블리(고정 목록):
//   - mscorlib (.NET Framework) 또는 System.Private.CoreLib (.NET Core/5+)
//   - System.Runtime (있는 경우, CoreLib 분리형 BCL 대응)
//   - WindowsBase, PresentationCore, PresentationFramework (WPF 핵심 3종)
//
// 추후 IDE가 프로젝트의 실제 참조 어셈블리 목록을 넘겨주면
// TReflectionIndex.AddAssembly() / RegisterAssemblyByPath() 로 확장 가능.
// =============================================================================

interface

uses
  System.Collections.Generic,
  System.Reflection;

type
  // 네임스페이스 트리의 한 노드. 네임스페이스 또는 타입(들)을 가질 수 있음.
  TNamespaceNode = class
  public
    Name     : string;                                    // 이 노드의 이름 (마지막 세그먼트)
    FullPath : string;                                     // 'System.Windows' 같은 전체 경로
    Children : System.Collections.Generic.Dictionary<string, TNamespaceNode>;
    Types    : System.Collections.Generic.List<System.Type>; // 이 네임스페이스에 직접 속한 타입들

    constructor Create(name, fullPath: string);
  end;

  // 경로 하나를 ResolvePath 했을 때의 결과 종류
  TResolveKind = (rkNone, rkNamespace, rkType);

  // ResolvePath의 결과
  TResolveResult = class
  public
    Kind          : TResolveKind;
    NamespaceNode : TNamespaceNode;   // Kind = rkNamespace 일 때
    ResolvedType  : System.Type;      // Kind = rkType 일 때
  end;

  // 멤버 한 개에 대한 가벼운 설명 (메서드/속성/필드/이벤트 통합)
  TReflectedMember = class
  public
    Name        : string;
    Kind        : string;   // 'Method' | 'Property' | 'Field' | 'Event' | 'Constructor'
    Signature   : string;   // 자동완성 목록에 보여줄 설명 문자열
    IsStatic    : boolean;

    constructor Create(name, kind, signature: string; isStatic: boolean);
  end;

  // 전체 인덱스: 트리 빌드, 캐시, 조회를 전담
  TReflectionIndex = class
  private
    fRoot   : TNamespaceNode;
    fBuilt  : boolean;
    fLoadedAssemblies: System.Collections.Generic.List<Assembly>;

    procedure EnsureBuilt;
    procedure IndexAssembly(asm: Assembly);
    function  GetOrCreateChild(parent: TNamespaceNode; segment, fullPath: string): TNamespaceNode;
    procedure InsertType(t: System.Type);
    function  TryLoadCoreAssemblies: System.Collections.Generic.List<Assembly>;
    function  TryLoadByName(name: string): Assembly;
  public
    constructor Create;

    // 명시적으로 어셈블리 하나를 인덱스에 추가 (프로젝트 참조 어셈블리 확장용)
    procedure AddAssembly(asm: Assembly);
    procedure RegisterAssemblyByPath(dllPath: string);

    // 'System.Windows.Application' 같은 점(.)-구분 경로를 해석.
    // 경로가 비어 있으면 루트(최상위 네임스페이스 목록) 반환.
    function ResolvePath(path: string): TResolveResult;

    // 네임스페이스 노드 하나의 자식들을 (네임스페이스+타입 혼합) 이름 목록으로
    function GetChildNames(node: TNamespaceNode): System.Collections.Generic.List<string>;

    // 타입의 멤버 목록 (Public, Static+Instance, 중복 오버로드 제거)
    function GetTypeMembers(t: System.Type): System.Collections.Generic.List<TReflectedMember>;

    // 강제 재빌드 (새 어셈블리 참조 추가 후 호출)
    procedure Invalidate;
  end;

// 프로세스 전역 싱글턴 — 매번 새로 만들 필요 없이 캐시된 인스턴스 재사용
function GlobalReflectionIndex: TReflectionIndex;

implementation

var
  _globalIndex: TReflectionIndex := nil;

function GlobalReflectionIndex: TReflectionIndex;
begin
  if _globalIndex = nil then
    _globalIndex := new TReflectionIndex();
  Result := _globalIndex;
end;

// =============================================================================
// TNamespaceNode
// =============================================================================

constructor TNamespaceNode.Create(name, fullPath: string);
begin
  Name     := name;
  FullPath := fullPath;
  Children := new System.Collections.Generic.Dictionary<string, TNamespaceNode>(
    System.StringComparer.OrdinalIgnoreCase);
  Types    := new System.Collections.Generic.List<System.Type>();
end;

// =============================================================================
// TReflectedMember
// =============================================================================

constructor TReflectedMember.Create(name, kind, signature: string; isStatic: boolean);
begin
  Name      := name;
  Kind      := kind;
  Signature := signature;
  IsStatic  := isStatic;
end;

// =============================================================================
// TReflectionIndex
// =============================================================================

constructor TReflectionIndex.Create;
begin
  fRoot  := new TNamespaceNode('', '');
  fBuilt := false;
  fLoadedAssemblies := new System.Collections.Generic.List<Assembly>();
end;

// 이름으로 어셈블리 로드를 시도. 실패하면 nil 반환 (예외를 위로 던지지 않음).
function TReflectionIndex.TryLoadByName(name: string): Assembly;
begin
  Result := nil;
  try
    Result := Assembly.Load(name);
  except
    on e: System.Exception do
      Result := nil;
  end;
end;

// 기본 고정 어셈블리들을 모은다. .NET Framework / .NET Core 양쪽 이름을 모두 시도.
function TReflectionIndex.TryLoadCoreAssemblies: System.Collections.Generic.List<Assembly>;
var
  list: System.Collections.Generic.List<Assembly>;
  candidateNames: array of string;
  n: string;
  asm: Assembly;
  seen: System.Collections.Generic.HashSet<string>;
begin
  list := new System.Collections.Generic.List<Assembly>();
  seen := new System.Collections.Generic.HashSet<string>();

  // BCL 핵심: .NET Framework는 mscorlib, .NET Core/5+ 는 System.Private.CoreLib + System.Runtime
  // WPF 핵심 3종: WindowsBase, PresentationCore, PresentationFramework
  candidateNames := [
    'mscorlib',
    'System.Private.CoreLib',
    'System.Runtime',
    'System',
    'WindowsBase',
    'PresentationCore',
    'PresentationFramework'
  ];

  // 1) 이미 현재 AppDomain에 로드돼 있는 어셈블리 중 후보와 이름이 일치하는 것 우선 사용
  foreach var loaded in System.AppDomain.CurrentDomain.GetAssemblies() do
  begin
    var shortName := loaded.GetName().Name;
    foreach n in candidateNames do
      if string.Equals(shortName, n, System.StringComparison.OrdinalIgnoreCase) then
        if not seen.Contains(shortName) then
        begin
          list.Add(loaded);
          seen.Add(shortName);
        end;
  end;

  // 2) 아직 로드되지 않은 후보는 이름으로 직접 로드 시도
  foreach n in candidateNames do
    if not seen.Contains(n) then
    begin
      asm := TryLoadByName(n);
      if asm <> nil then
      begin
        list.Add(asm);
        seen.Add(n);
      end;
    end;

  // 3) object/string 등 가장 기초적인 타입이 속한 어셈블리는 항상 확보
  asm := typeof(System.Object).Assembly;
  if not seen.Contains(asm.GetName().Name) then
  begin
    list.Add(asm);
    seen.Add(asm.GetName().Name);
  end;

  Result := list;
end;

procedure TReflectionIndex.AddAssembly(asm: Assembly);
begin
  if asm = nil then exit;
  if fLoadedAssemblies.Contains(asm) then exit;
  fLoadedAssemblies.Add(asm);
  IndexAssembly(asm);
end;

procedure TReflectionIndex.RegisterAssemblyByPath(dllPath: string);
var
  asm: Assembly;
begin
  try
    asm := Assembly.LoadFrom(dllPath);
    AddAssembly(asm);
  except
    on e: System.Exception do
      ; // 로드 실패한 DLL은 조용히 무시 (자동완성이 죽으면 안 됨)
  end;
end;

procedure TReflectionIndex.Invalidate;
begin
  fBuilt := false;
  fRoot  := new TNamespaceNode('', '');
  fLoadedAssemblies.Clear();
end;

procedure TReflectionIndex.EnsureBuilt;
var
  asm: Assembly;
begin
  if fBuilt then exit;

  foreach asm in TryLoadCoreAssemblies() do
    AddAssembly(asm);

  fBuilt := true;
end;

// parent 노드 밑에 segment 라는 자식 네임스페이스 노드를 찾거나 새로 만든다.
function TReflectionIndex.GetOrCreateChild(
  parent: TNamespaceNode; segment, fullPath: string): TNamespaceNode;
var
  child: TNamespaceNode;
begin
  if parent.Children.TryGetValue(segment, child) then
    Result := child
  else
  begin
    child := new TNamespaceNode(segment, fullPath);
    parent.Children[segment] := child;
    Result := child;
  end;
end;

// 타입 하나를 네임스페이스 경로를 따라 트리에 삽입.
procedure TReflectionIndex.InsertType(t: System.Type);
var
  ns      : string;
  segs    : array of string;
  node    : TNamespaceNode;
  pathSoFar: string;
  i       : integer;
begin
  ns := t.Namespace;
  if ns = nil then ns := '';

  // 컴파일러 생성 타입(<>, $ 포함)이나 비공개 중첩 타입 제외
  if t.Name.Contains('<') or t.Name.Contains('$') then exit;
  if t.IsNested then exit; // 중첩 타입은 부모 타입의 멤버로 별도 취급하지 않고 생략 (단순화)

  node := fRoot;
  if ns <> '' then
  begin
    segs := ns.Split('.');
    pathSoFar := '';
    for i := 0 to Length(segs) - 1 do
    begin
      var seg := segs[i];
      if pathSoFar = '' then pathSoFar := seg
      else pathSoFar := pathSoFar + '.' + seg;
      node := GetOrCreateChild(node, seg, pathSoFar);
    end;
  end;

  node.Types.Add(t);
end;

// 어셈블리 안의 공개 타입들을 모두 인덱싱
procedure TReflectionIndex.IndexAssembly(asm: Assembly);
var
  types: array of System.Type;
  t: System.Type;
begin
  try
    types := asm.GetExportedTypes();
  except
    on e: System.Exception do
      exit; // 일부 타입 로드 실패해도 전체가 죽지 않게
  end;

  foreach t in types do
  begin
    if not t.IsPublic then continue;
    InsertType(t);
  end;
end;

// 점(.)-구분 경로를 해석해서 네임스페이스 노드 또는 타입을 찾는다.
function TReflectionIndex.ResolvePath(path: string): TResolveResult;
var
  segs: array of string;
  node: TNamespaceNode;
  i   : integer;
  matchedType: System.Type;
  seg : string;
begin
  EnsureBuilt;

  var res := new TResolveResult();
  res.Kind := rkNone;

  if (path = nil) or (path = '') then
  begin
    res.Kind          := rkNamespace;
    res.NamespaceNode := fRoot;
    Result := res;
    exit;
  end;

  segs := path.Split('.');
  node := fRoot;

  for i := 0 to Length(segs) - 1 do
  begin
    seg := segs[i];

    // 1순위: 현재 노드 밑에 같은 이름의 네임스페이스가 있으면 그쪽으로 이동
    var childNs: TNamespaceNode;
    if node.Children.TryGetValue(seg, childNs) then
    begin
      node := childNs;
      continue;
    end;

    // 2순위: 현재 노드 밑에 이름이 일치하는 타입이 있으면, 거기서 경로 종료해야 함
    matchedType := nil;
    foreach var ty in node.Types do
      if string.Equals(ty.Name, seg, System.StringComparison.OrdinalIgnoreCase) then
      begin matchedType := ty; break; end;

    if matchedType <> nil then
    begin
      // 이게 경로의 마지막 세그먼트라면 타입으로 확정
      if i = Length(segs) - 1 then
      begin
        res.Kind := rkType;
        res.ResolvedType := matchedType;
        Result := res;
        exit;
      end
      else
      begin
        // 타입 뒤에 더 세그먼트가 남았는데 더 내려갈 네임스페이스가 없으면 실패
        res.Kind := rkNone;
        Result := res;
        exit;
      end;
    end;

    // 둘 다 못 찾음 → 해석 실패
    res.Kind := rkNone;
    Result := res;
    exit;
  end;

  // 루프를 끝까지 돌았다 = 마지막까지 네임스페이스로만 이동 성공
  res.Kind          := rkNamespace;
  res.NamespaceNode := node;
  Result := res;
end;

// 네임스페이스 노드의 자식들(하위 네임스페이스 + 타입)을 이름 목록으로 변환
function TReflectionIndex.GetChildNames(
  node: TNamespaceNode): System.Collections.Generic.List<string>;
var
  list: System.Collections.Generic.List<string>;
  seenNames: System.Collections.Generic.HashSet<string>;
begin
  list := new System.Collections.Generic.List<string>();
  seenNames := new System.Collections.Generic.HashSet<string>(
    System.StringComparer.OrdinalIgnoreCase);

  if node = nil then begin Result := list; exit; end;

  foreach var kv in node.Children do
    if seenNames.Add(kv.Key) then
      list.Add(kv.Key);

  foreach var t in node.Types do
    if seenNames.Add(t.Name) then
      list.Add(t.Name);

  Result := list;
end;

// 타입의 멤버를 자동완성용으로 추출 (Public, Static+Instance, 오버로드는 1개만)
function TReflectionIndex.GetTypeMembers(
  t: System.Type): System.Collections.Generic.List<TReflectedMember>;
var
  list   : System.Collections.Generic.List<TReflectedMember>;
  seen   : System.Collections.Generic.HashSet<string>;
  flags  : BindingFlags;
begin
  list := new System.Collections.Generic.List<TReflectedMember>();
  seen := new System.Collections.Generic.HashSet<string>(System.StringComparer.Ordinal);

  if t = nil then begin Result := list; exit; end;

  flags := BindingFlags.Public or BindingFlags.Static or
           BindingFlags.Instance or BindingFlags.FlattenHierarchy;

  // 메서드 (속성 접근자 get_/set_ 는 제외, 오버로드 중복 제거)
  foreach var mi in t.GetMethods(flags) do
  begin
    if mi.IsSpecialName then continue; // get_X / set_X / add_X 등 제외
    if not seen.Add('M:' + mi.Name) then continue;
    var sig := mi.Name + '(' + mi.GetParameters().Length.ToString() + ' args)';
    list.Add(new TReflectedMember(mi.Name, 'Method', t.Name + '.' + sig, mi.IsStatic));
  end;

  // 속성
  foreach var pi in t.GetProperties(flags) do
  begin
    if not seen.Add('P:' + pi.Name) then continue;
    var isStaticProp := (pi.GetMethod <> nil) and pi.GetMethod.IsStatic;
    list.Add(new TReflectedMember(pi.Name, 'Property',
      t.Name + '.' + pi.Name + ': ' + pi.PropertyType.Name, isStaticProp));
  end;

  // 필드
  foreach var fi in t.GetFields(flags) do
  begin
    if not seen.Add('F:' + fi.Name) then continue;
    list.Add(new TReflectedMember(fi.Name, 'Field',
      t.Name + '.' + fi.Name + ': ' + fi.FieldType.Name, fi.IsStatic));
  end;

  // 이벤트
  foreach var ei in t.GetEvents(flags) do
  begin
    if not seen.Add('E:' + ei.Name) then continue;
    var isStaticEvent := (ei.AddMethod <> nil) and ei.AddMethod.IsStatic;
    list.Add(new TReflectedMember(ei.Name, 'Event', t.Name + '.' + ei.Name, isStaticEvent));
  end;

  Result := list;
end;

end.