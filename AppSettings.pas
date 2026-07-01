unit AppSettings;

// =============================================================================
// AppSettings.pas — 앱 전역 설정 저장/로드 (프로젝트와 무관, 1회 설정 후 유지)
//
// TProjectOptions(.pwproj.user, 프로젝트별)와는 별개로, 언어처럼 "이 PC에서
// 이 IDE를 쓰는 사람"에 귀속되는 설정을 다룬다.
//
// 저장 위치: %AppData%\PascalABC-WPF-Designer\settings.ini
// 형식: 단순 key=value (한 줄씩) — 외부 라이브러리 의존성 없음.
//
// ★ 변경 이력: 한때 "일반"(콘솔 일시정지/성공시 저장/시작시 자동완성) 및
//   "에디터"(폰트/줄번호/하이라이트 등 13개) 설정도 여기서 관리했으나,
//   이 IDE가 1인 개발자용 단일 사용자 도구라는 점을 고려해 모두
//   Project Options(ProjectOptions.pas, .pwproj.user)로 되돌렸습니다.
//   이제 AppSettings는 "언어"처럼 정말 프로젝트와 무관한 값만 다룹니다.
//
// 새 전역 설정 항목을 추가할 때:
//   1) Load 함수와 Save 프로시저를 LoadLanguage/SaveLanguage 패턴대로 추가
//   2) LoadAll/SaveAll 의 범용 Dictionary를 그대로 재사용
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
    else if raw = TLanguage.Russian.ToString() then Result := TLanguage.Russian;
  end;
end; 

end.