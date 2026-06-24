unit LocalizationCore;

// =============================================================================
// LocalizationCore.pas — 다국어 처리 핵심 엔진
// =============================================================================

interface

uses
  System.Collections.Generic,
  System.Windows.Forms;

type
  TLanguage = (Korean, English, Ukrainian);

  TBoundKind = (BoundMenuItem, BoundLabelControl, BoundButtonControl,
                BoundFormTitle, BoundColumnHeader, BoundToolTip);

  TBoundEntry = record
    Kind : TBoundKind;
    Key  : string;
    Obj  : System.Object;
  end;

  TLoc = static class
  private
    class fCurrent    : TLanguage;
    class fTable      : Dictionary<string, Dictionary<TLanguage, string>>;
    class fBound      : List<TBoundEntry>;
    class fInitialized: boolean;
    class fMissingLog : HashSet<string>;

    class procedure EnsureInit;
  public
    class property CurrentLanguage: TLanguage read fCurrent;
    class procedure Init;
    class procedure SetLanguage(lang: TLanguage);
    class function LanguageName(lang: TLanguage): string;
    class function LanguageFromName(name: string): TLanguage;
    class function AllLanguages: array of TLanguage;

    class procedure Register(key: string; values: array of string);

    class function S(key: string): string;

    // ── TLoc.F 오버로드 ──────────────────────────────────────────────────
    // PascalABC.NET 에서 배열 리터럴 [ex.Message] 을 array of object 로
    // 암묵 변환하지 못하는 문제를 오버로드로 완전히 우회한다.
    // 호출부에서 배열을 만들지 않고 인자를 직접 넘길 수 있어 코드도 간결해진다.
    class function F(key: string; args: array of System.Object): string; // 기존 — 직접 배열 필요 시
    class function F(key: string; arg0: string): string;                  // ★ 추가: 인자 1개
    class function F(key: string; arg0: string; arg1: string): string;    // ★ 추가: 인자 2개
    class function F(key: string; arg0: string; arg1: string; arg2: string): string; // ★ 추가: 인자 3개

    class procedure Bind(item: System.Windows.Forms.ToolStripMenuItem; key: string);
    class procedure Bind(ctrl: System.Windows.Forms.Control; key: string);
    class procedure Bind(frm: System.Windows.Forms.Form; key: string; prefix: string := ''; suffix: string := '');
    class procedure Bind(col: System.Windows.Forms.ColumnHeader; key: string);
    class procedure RefreshBound;

    class function MissingKeyCount: integer;
    class function MissingKeysReport: string;
  end;

implementation

class procedure TLoc.EnsureInit;
begin
  if fInitialized then exit;
  fTable       := new Dictionary<string, Dictionary<TLanguage, string>>;
  fBound       := new List<TBoundEntry>;
  fMissingLog  := new HashSet<string>;
  fCurrent     := TLanguage.Korean;
  fInitialized := true;
end;

class procedure TLoc.Init;
begin
  EnsureInit;
end;

class function TLoc.AllLanguages: array of TLanguage;
begin
  Result := new TLanguage[3];
  Result[0] := TLanguage.Korean;
  Result[1] := TLanguage.English;
  Result[2] := TLanguage.Ukrainian;
end;

class function TLoc.LanguageName(lang: TLanguage): string;
begin
  case lang of
    TLanguage.Korean    : Result := '한국어';
    TLanguage.English   : Result := 'English';
    TLanguage.Ukrainian : Result := 'Українська';
  else
    Result := lang.ToString();
  end;
end;

class function TLoc.LanguageFromName(name: string): TLanguage;
begin
  if name = '한국어' then Result := TLanguage.Korean
  else if name = 'English' then Result := TLanguage.English
  else if name = 'Українська' then Result := TLanguage.Ukrainian
  else Result := TLanguage.Korean;
end;

class procedure TLoc.Register(key: string; values: array of string);
var
  langs: array of TLanguage;
  m: Dictionary<TLanguage, string>;
  i: integer;
begin
  EnsureInit;
  langs := AllLanguages;
  m := new Dictionary<TLanguage, string>;
  i := 0;
  while (i < langs.Length) and (i < values.Length) do
  begin
    m[langs[i]] := values[i];
    i += 1;
  end;
  if fTable.ContainsKey(key) then
    fTable[key] := m
  else
    fTable.Add(key, m);
end;

class function TLoc.S(key: string): string;
begin
  EnsureInit;
  if fTable.ContainsKey(key) and fTable[key].ContainsKey(fCurrent) then
    Result := fTable[key][fCurrent]
  else
  begin
    if not fMissingLog.Contains(key) then
      fMissingLog.Add(key);
    Result := '[[' + key + ']]';
  end;
end;

// ── TLoc.F 구현 ─────────────────────────────────────────────────────────────

// 기존: array of object 직접 사용 (배열을 직접 넘길 때)
class function TLoc.F(key: string; args: array of System.Object): string;
begin
  Result := string.Format(S(key), args);
end;

// ★ 추가: 인자 1개 — TLoc.F('key', ex.Message)
// PascalABC.NET 에서 [ex.Message] → array of object 암묵 변환 불가 문제 해결
class function TLoc.F(key: string; arg0: string): string;
var args: array of System.Object;
begin
  args := new System.Object[1];
  args[0] := arg0;
  Result := string.Format(S(key), args);
end;

// ★ 추가: 인자 2개 — TLoc.F('key', val1, val2)
class function TLoc.F(key: string; arg0: string; arg1: string): string;
var args: array of System.Object;
begin
  args := new System.Object[2];
  args[0] := arg0;
  args[1] := arg1;
  Result := string.Format(S(key), args);
end;

// ★ 추가: 인자 3개 — TLoc.F('key', val1, val2, val3)
class function TLoc.F(key: string; arg0: string; arg1: string; arg2: string): string;
var args: array of System.Object;
begin
  args := new System.Object[3];
  args[0] := arg0;
  args[1] := arg1;
  args[2] := arg2;
  Result := string.Format(S(key), args);
end;

// ── Bind 구현 ────────────────────────────────────────────────────────────────

class procedure TLoc.Bind(item: System.Windows.Forms.ToolStripMenuItem; key: string);
var e: TBoundEntry;
begin
  EnsureInit;
  e.Kind := TBoundKind.BoundMenuItem;
  e.Key  := key;
  e.Obj  := item;
  fBound.Add(e);
  item.Text := S(key);
end;

class procedure TLoc.Bind(ctrl: System.Windows.Forms.Control; key: string);
var e: TBoundEntry;
begin
  EnsureInit;
  e.Kind := TBoundKind.BoundLabelControl;
  e.Key  := key;
  e.Obj  := ctrl;
  fBound.Add(e);
  ctrl.Text := S(key);
end;

class procedure TLoc.Bind(frm: System.Windows.Forms.Form; key: string; prefix: string; suffix: string);
var e: TBoundEntry;
begin
  EnsureInit;
  e.Kind := TBoundKind.BoundFormTitle;
  e.Key  := key;
  e.Obj  := frm;
  fBound.Add(e);
  frm.Text := prefix + S(key) + suffix;
end;

class procedure TLoc.Bind(col: System.Windows.Forms.ColumnHeader; key: string);
var e: TBoundEntry;
begin
  EnsureInit;
  e.Kind := TBoundKind.BoundColumnHeader;
  e.Key  := key;
  e.Obj  := col;
  fBound.Add(e);
  col.Text := S(key);
end;

class procedure TLoc.RefreshBound;
var
  e: TBoundEntry;
begin
  EnsureInit;
  foreach e in fBound do
  begin
    case e.Kind of
      TBoundKind.BoundMenuItem:
        (e.Obj as System.Windows.Forms.ToolStripMenuItem).Text := S(e.Key);
      TBoundKind.BoundLabelControl:
        (e.Obj as System.Windows.Forms.Control).Text := S(e.Key);
      TBoundKind.BoundColumnHeader:
        (e.Obj as System.Windows.Forms.ColumnHeader).Text := S(e.Key);
    end;
  end;
end;

class procedure TLoc.SetLanguage(lang: TLanguage);
begin
  EnsureInit;
  if lang = fCurrent then exit;
  fCurrent := lang;
  RefreshBound;
end;

class function TLoc.MissingKeyCount: integer;
begin
  EnsureInit;
  Result := fMissingLog.Count;
end;

class function TLoc.MissingKeysReport: string;
var
  sb: System.Text.StringBuilder;
  k: string;
begin
  EnsureInit;
  sb := new System.Text.StringBuilder;
  foreach k in fMissingLog do
    sb.AppendLine(k);
  Result := sb.ToString();
end;

end.