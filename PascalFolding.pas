unit PascalFolding;

// =============================================================================
// PascalFolding.pas
//   TPascalFoldingStrategy
//     AvalonEdit FoldingManager 에 Pascal begin/end 블록 폴딩 정보를 갱신한다.
//     정규식으로 begin·end·type·interface·implementation 키워드를 인식하고
//     스택 방식으로 중첩 블록을 처리한다.
// =============================================================================

{$reference AvalonEdit.6.3.1.120\lib\net462\ICSharpCode.AvalonEdit.dll}

uses
  System.Collections.Generic,
  System.Text.RegularExpressions;

type
  TPascalFoldingStrategy = class
  public
    procedure UpdateFoldings(
      manager  : ICSharpCode.AvalonEdit.Folding.FoldingManager;
      document : ICSharpCode.AvalonEdit.Document.TextDocument);
  end;

procedure TPascalFoldingStrategy.UpdateFoldings(
  manager  : ICSharpCode.AvalonEdit.Folding.FoldingManager;
  document : ICSharpCode.AvalonEdit.Document.TextDocument);
var
  newFoldings : System.Collections.Generic.List<ICSharpCode.AvalonEdit.Folding.NewFolding>;
  stack       : System.Collections.Generic.Stack<System.Tuple<integer, string>>;
  text        : string;
  re          : System.Text.RegularExpressions.Regex;
  m           : System.Text.RegularExpressions.Match;
  kw          : string;
  startOffset : integer;
  f           : ICSharpCode.AvalonEdit.Folding.NewFolding;
begin
  newFoldings := new System.Collections.Generic.List<ICSharpCode.AvalonEdit.Folding.NewFolding>();
  stack       := new System.Collections.Generic.Stack<System.Tuple<integer, string>>();
  text        := document.Text;

  // begin/end, type, interface/implementation 블록 인식
  // 간이 구현: 정규식으로 키워드 위치를 순서대로 추출한 뒤 스택으로 쌍을 맞춘다.
  re := new System.Text.RegularExpressions.Regex(
    '\b(begin|end|type|interface|implementation|initialization|finalization)\b',
    System.Text.RegularExpressions.RegexOptions.IgnoreCase or
    System.Text.RegularExpressions.RegexOptions.Multiline);

  m := re.Match(text);
  while m.Success do
  begin
    kw := m.Value.ToLower();

    // 여는 키워드 → 스택 Push
    if (kw = 'begin') or (kw = 'type') or
       (kw = 'interface') or (kw = 'initialization') then
    begin
      stack.Push(System.Tuple.Create(m.Index, kw));
    end
    // 닫는 키워드 → 스택 Pop 후 Folding 생성
    else if (kw = 'end') or (kw = 'implementation') or
            (kw = 'finalization') then
    begin
      if stack.Count > 0 then
      begin
        var top     := stack.Pop();
        startOffset := top.Item1;
        var endOff  := m.Index + m.Length;

        // 너무 짧은 범위는 폴딩 제외 (최소 10자)
        if (endOff - startOffset) > 10 then
        begin
          f               := new ICSharpCode.AvalonEdit.Folding.NewFolding();
          f.StartOffset   := startOffset;
          f.EndOffset     := endOff;
          f.Name          := top.Item2 + ' ... end';
          f.DefaultClosed := false;
          newFoldings.Add(f);
        end;
      end;
    end;

    m := m.NextMatch();
  end;

  // UpdateFoldings 는 StartOffset 오름차순 정렬을 요구한다.
  // (Sort 람다 미지원 환경 대비: 단순 버블 정렬)
  var n := newFoldings.Count;
  var i, j: integer;
  for i := 0 to n - 2 do
    for j := 0 to n - 2 - i do
      if newFoldings[j].StartOffset > newFoldings[j + 1].StartOffset then
      begin
        var tmp         := newFoldings[j];
        newFoldings[j]  := newFoldings[j + 1];
        newFoldings[j + 1] := tmp;
      end;

  var firstErr := -1;
  manager.UpdateFoldings(newFoldings, firstErr);
end;


end.