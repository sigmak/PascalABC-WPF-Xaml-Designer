unit PascalHighlighting;

// =============================================================================
// PascalHighlighting.pas
//   CreatePascalHighlighting
//     AvalonEdit 용 Pascal/PascalABC.NET 구문 강조 정의를
//     XSHD XML 문자열로 작성한 뒤 동적으로 로드해 반환한다.
//     실패 시 nil 반환.
// =============================================================================

{$reference AvalonEdit.6.3.1.120\lib\net462\ICSharpCode.AvalonEdit.dll}

// -----------------------------------------------------------------------------
// CreatePascalHighlighting
// -----------------------------------------------------------------------------
function CreatePascalHighlighting: ICSharpCode.AvalonEdit.Highlighting.IHighlightingDefinition;
const
  PASCAL_XSHD =
    '<?xml version="1.0"?>' +
    '<SyntaxDefinition name="PascalABC" xmlns="http://icsharpcode.net/sharpdevelop/syntaxdefinition/2008">' +

    // ── 색상 정의 ─────────────────────────────────────────────────────────────
    '<Color name="Comment"      foreground="#608B4E" fontStyle="italic"/>' +
    '<Color name="String"       foreground="#CE9178"/>' +
    '<Color name="Keyword"      foreground="#569CD6" fontWeight="bold"/>' +
    '<Color name="TypeKeyword"  foreground="#4EC9B0" fontWeight="bold"/>' +
    '<Color name="Number"       foreground="#B5CEA8"/>' +
    '<Color name="Directive"    foreground="#9B9B9B" fontStyle="italic"/>' +
    '<Color name="Attribute"    foreground="#C8C8C8"/>' +
    '<Color name="ClassDecl"    foreground="#4EC9B0" fontWeight="bold"/>' +
    '<Color name="ProcDecl"     foreground="#DCDCAA"/>' +

    // ── 메인 룰셋 ─────────────────────────────────────────────────────────────
    '<RuleSet>' +

    // 블록 주석  { ... }  (컴파일러 지시자 {$ 제외)
    '<Span color="Comment" multiline="true">' +
      '<Begin>\{(?!\$)</Begin>' +
      '<End>\}</End>' +
    '</Span>' +

    // 컴파일러 지시자  {$...}
    '<Span color="Directive">' +
      '<Begin>\{\$</Begin>' +
      '<End>\}</End>' +
    '</Span>' +

    // 블록 주석  (* ... *)
    '<Span color="Comment" multiline="true">' +
      '<Begin>\(\*</Begin>' +
      '<End>\*\)</End>' +
    '</Span>' +

    // 줄 주석  //
    '<Span color="Comment">' +
      '<Begin>//</Begin>' +
    '</Span>' +

    // 문자열  ' ... '
    '<Span color="String">' +
      '<Begin>&apos;</Begin>' +
      '<End>&apos;</End>' +
    '</Span>' +

    // 숫자  (0x hex, 정수, 실수)
    '<Rule color="Number">\b(0[xX][0-9a-fA-F]+|\d+(\.\d+)?([eE][+\-]?\d+)?)\b</Rule>' +

    // ── 기본 타입 키워드 ──────────────────────────────────────────────────────
    '<Keywords color="TypeKeyword">' +
      '<Word>integer</Word><Word>cardinal</Word><Word>int64</Word>' +
      '<Word>longint</Word><Word>shortint</Word><Word>byte</Word><Word>word</Word>' +
      '<Word>real</Word><Word>single</Word><Word>double</Word><Word>extended</Word>' +
      '<Word>boolean</Word><Word>char</Word><Word>string</Word>' +
      '<Word>pointer</Word><Word>variant</Word><Word>object</Word>' +
      '<Word>array</Word><Word>record</Word><Word>set</Word><Word>file</Word>' +
    '</Keywords>' +

    // ── 제어 흐름 / 선언 키워드 ───────────────────────────────────────────────
    '<Keywords color="Keyword">' +
      '<Word>program</Word><Word>unit</Word><Word>library</Word><Word>uses</Word>' +
      '<Word>type</Word><Word>var</Word><Word>const</Word><Word>label</Word>' +
      '<Word>begin</Word><Word>end</Word><Word>interface</Word><Word>implementation</Word>' +
      '<Word>initialization</Word><Word>finalization</Word>' +
      '<Word>procedure</Word><Word>function</Word><Word>constructor</Word><Word>destructor</Word>' +
      '<Word>class</Word><Word>inherited</Word><Word>override</Word><Word>virtual</Word>' +
      '<Word>abstract</Word><Word>sealed</Word><Word>static</Word>' +
      '<Word>property</Word><Word>read</Word><Word>write</Word>' +
      '<Word>public</Word><Word>private</Word><Word>protected</Word><Word>published</Word>' +
      '<Word>if</Word><Word>then</Word><Word>else</Word>' +
      '<Word>for</Word><Word>to</Word><Word>downto</Word><Word>do</Word>' +
      '<Word>while</Word><Word>repeat</Word><Word>until</Word>' +
      '<Word>case</Word><Word>of</Word><Word>with</Word>' +
      '<Word>try</Word><Word>except</Word><Word>finally</Word><Word>raise</Word>' +
      '<Word>on</Word><Word>at</Word>' +
      '<Word>and</Word><Word>or</Word><Word>not</Word><Word>xor</Word>' +
      '<Word>in</Word><Word>is</Word><Word>as</Word>' +
      '<Word>nil</Word><Word>true</Word><Word>false</Word>' +
      '<Word>Self</Word><Word>Result</Word>' +
      '<Word>exit</Word><Word>break</Word><Word>continue</Word><Word>halt</Word>' +
      '<Word>new</Word><Word>dispose</Word><Word>typeof</Word>' +
      '<Word>forward</Word><Word>external</Word><Word>overload</Word>' +
      '<Word>div</Word><Word>mod</Word><Word>shl</Word><Word>shr</Word>' +
      '<Word>foreach</Word><Word>yield</Word><Word>where</Word>' +
      '<Word>sequence</Word><Word>auto</Word><Word>event</Word>' +
    '</Keywords>' +

    '</RuleSet>' +
    '</SyntaxDefinition>';

begin
  try
    var xmlStream  := new System.IO.MemoryStream(
                        System.Text.Encoding.UTF8.GetBytes(PASCAL_XSHD));
    var reader     := new System.Xml.XmlTextReader(xmlStream);
    var xshd       := ICSharpCode.AvalonEdit.Highlighting.Xshd.HighlightingLoader.LoadXshd(reader);
    Result         := ICSharpCode.AvalonEdit.Highlighting.Xshd.HighlightingLoader.Load(
                        xshd,
                        ICSharpCode.AvalonEdit.Highlighting.HighlightingManager.Instance);
  except
    Result := nil;
  end;
end;
end.