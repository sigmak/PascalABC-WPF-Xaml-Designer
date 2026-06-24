unit AppSettings;

// =============================================================================
// AppSettings.pas — 앱 전역 설정 저장/로드 (프로젝트와 무관, 1회 설정 후 유지)
//
// TProjectOptions(.opts 파일, 프로젝트별)와는 별개로, 언어처럼 "이 PC에서
// 이 IDE를 쓰는 사람"에 귀속되는 설정을 다룬다.
//
// 저장 위치: %AppData%\PascalABC-WPF-Designer\settings.ini
// 형식: 단순 key=value (한 줄씩) — 외부 라이브러리 의존성 없음.
//
// 새 전역 설정 항목을 추가할 때:
//   1) TAppSettingsData 에 필드 추가
//   2) Load 의 케이스문에 키 매핑 추가
//   3) Save 에 한 줄 추가
// =============================================================================
interface

uses
  System.IO,
  System.Collections.Generic,
  LocalizationCore;

type
  TAppSettings = static class
  private
    class function SettingsFilePath: string;
  public
    // ── 언어 ─────────────────────────────────────────────────────────────
    class procedure SaveLanguage(lang: TLanguage);
    class function LoadLanguage: TLanguage;     // 저장된 값이 없으면 Korean 반환

    // ── 일반 IDE 동작 설정 (첨부 이미지의 "설정 > 일반" 패널) ───────────────
    class function LoadPauseAfterConsole: boolean;     // 기본값 true
    class procedure SavePauseAfterConsole(value: boolean);
    class function LoadSaveOnSuccess: boolean;          // 기본값 false
    class procedure SaveSaveOnSuccess(value: boolean);
    class function LoadAutoCompleteOnStartup: boolean;  // 기본값 true
    class procedure SaveAutoCompleteOnStartup(value: boolean);

    // ── 범용 key=value (향후 다른 전역 설정 추가 시 재사용) ────────────────
    class function LoadAll: Dictionary<string, string>;
    class procedure SaveAll(values: Dictionary<string, string>);
  end;

implementation

class function TAppSettings.SettingsFilePath: string;
var
  dir: string;
begin
  dir := Path.Combine(
    System.Environment.GetFolderPath(System.Environment.SpecialFolder.ApplicationData),
    'PascalABC-WPF-Designer');
  if not Directory.Exists(dir) then
    Directory.CreateDirectory(dir);
  Result := Path.Combine(dir, 'settings.ini');
end;

class function TAppSettings.LoadAll: Dictionary<string, string>;
var
  path: string;
  line: string;
  idx: integer;
  key, val: string;
begin
  Result := new Dictionary<string, string>;
  path := SettingsFilePath;
  if not System.IO.File.Exists(path) then exit;
  try
    foreach line in System.IO.File.ReadAllLines(path) do
    begin
      if (line.Trim() = '') or line.TrimStart().StartsWith('#') then continue;
      idx := line.IndexOf('=');
      if idx <= 0 then continue;
      key := line.Substring(0, idx).Trim();
      val := line.Substring(idx + 1).Trim();
      Result[key] := val;
    end;
  except
    on ex: System.Exception do
    begin
      // 설정 파일이 손상되어도 앱 시작은 막지 않음 — 기본값으로 동작
    end;
  end;
end;

class procedure TAppSettings.SaveAll(values: Dictionary<string, string>);
var
  sb: System.Text.StringBuilder;
  kv: KeyValuePair<string, string>;
begin
  sb := new System.Text.StringBuilder;
  sb.AppendLine('# PascalABC-WPF-Designer settings — 자동 생성 파일');
  foreach kv in values do
    sb.AppendLine(kv.Key + '=' + kv.Value);
  try
    System.IO.File.WriteAllText(SettingsFilePath, sb.ToString());
  except
    on ex: System.Exception do
    begin
      // 저장 실패해도 (예: 권한 문제) 앱 동작에 영향 없도록 무시
    end;
  end;
end;

class procedure TAppSettings.SaveLanguage(lang: TLanguage);
var
  values: Dictionary<string, string>;
begin
  values := LoadAll;   // 다른 설정 값을 보존하기 위해 먼저 전체를 읽음
  values['Language'] := lang.ToString();
  SaveAll(values);
end;

class function TAppSettings.LoadLanguage: TLanguage;
var
  values: Dictionary<string, string>;
  raw: string;
begin
  Result := TLanguage.Korean;   // 기본값
  values := LoadAll;
  if values.ContainsKey('Language') then
  begin
    raw := values['Language'];
    if raw = TLanguage.Korean.ToString() then Result := TLanguage.Korean
    else if raw = TLanguage.English.ToString() then Result := TLanguage.English
    else if raw = TLanguage.Ukrainian.ToString() then Result := TLanguage.Ukrainian;
  end;
end;

// ── 일반 IDE 동작 설정 ───────────────────────────────────────────────────────
// 패턴이 모두 동일: LoadAll → 키 있으면 파싱, 없으면 기본값 → SaveAll 시 다른 값 보존

class function TAppSettings.LoadPauseAfterConsole: boolean;
var values: Dictionary<string, string>;
begin
  values := LoadAll;
  if values.ContainsKey('PauseAfterConsole') then
    Result := values['PauseAfterConsole'] = 'true'
  else
    Result := true;   // 기본값: 이미지에서 체크되어 있던 상태와 동일
end;

class procedure TAppSettings.SavePauseAfterConsole(value: boolean);
var values: Dictionary<string, string>;
begin
  values := LoadAll;
  values['PauseAfterConsole'] := (if value then 'true' else 'false');
  SaveAll(values);
end;

class function TAppSettings.LoadSaveOnSuccess: boolean;
var values: Dictionary<string, string>;
begin
  values := LoadAll;
  if values.ContainsKey('SaveOnSuccess') then
    Result := values['SaveOnSuccess'] = 'true'
  else
    Result := false;  // 기본값: 이미지에서 체크 해제 상태와 동일
end;

class procedure TAppSettings.SaveSaveOnSuccess(value: boolean);
var values: Dictionary<string, string>;
begin
  values := LoadAll;
  values['SaveOnSuccess'] := (if value then 'true' else 'false');
  SaveAll(values);
end;

class function TAppSettings.LoadAutoCompleteOnStartup: boolean;
var values: Dictionary<string, string>;
begin
  values := LoadAll;
  if values.ContainsKey('AutoCompleteOnStartup') then
    Result := values['AutoCompleteOnStartup'] = 'true'
  else
    Result := true;   // 기본값: 이미지에서 체크되어 있던 상태와 동일
end;

class procedure TAppSettings.SaveAutoCompleteOnStartup(value: boolean);
var values: Dictionary<string, string>;
begin
  values := LoadAll;
  values['AutoCompleteOnStartup'] := (if value then 'true' else 'false');
  SaveAll(values);
end;

end.