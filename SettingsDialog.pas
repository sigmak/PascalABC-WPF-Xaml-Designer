unit SettingsDialog;

// =============================================================================
// SettingsDialog.pas — "언어 설정" 다이얼로그
//
//   ★ 변경 이력: 원래 일반/에디터/컴파일/IntelliSense 4개 탭을 가진 "환경설정"
//   다이얼로그로 설계했으나, 다음 이유로 언어 전환 전용 단일 페이지로 단순화했습니다.
//     - 이 IDE는 1인 개발자가 쓰는 단일 사용자 도구라서, "여러 사용자가 같은
//       프로젝트를 공유하므로 IDE 전역 설정과 프로젝트별 설정을 분리해야 한다"는
//       VS류의 전제가 적용되지 않습니다.
//     - "에디터" 탭(폰트/줄번호/하이라이트 등)은 Project Options로 되돌렸고,
//       "일반" 탭의 3항목(콘솔 일시정지/성공시 저장/시작시 자동완성)도 같은 이유로
//       Project Options의 "디버그/실행" 탭에 합류했습니다.
//     - 컴파일/IntelliSense 탭은 처음부터 빈 placeholder였고 실제 내용이 없었습니다.
//   결과적으로 이 다이얼로그에 실질적으로 남는 항목은 "언어 선택" 하나뿐이므로,
//   메뉴에서는 여전히 Tools → Settings... 로 부르되 내용은 언어 전환 단일 페이지로
//   유지합니다 (추후 IDE 전역 설정이 더 필요해지면 이 구조를 다시 확장하면 됩니다).
//
// PascalABC.NET 해결 전략:
//   상태를 TSettingsState 레코드에 담고, 이벤트 핸들러를 TSettingsDialog
//   클래스 메서드로 승격해 중첩 프로시저 var 캡처 문제를 피합니다.
// =============================================================================

interface

uses
  System.Windows.Forms,
  System.Drawing,
  LocalizationCore,
  Strings_Common,
  AppSettings;

// ── 다이얼로그 내부 상태를 담는 레코드 ──────────────────────────────────────
type
  TSettingsState = record
    Dlg             : System.Windows.Forms.Form;
    ContentPanel    : System.Windows.Forms.Panel;
    BtnBar          : System.Windows.Forms.Panel;
    BtnOk           : System.Windows.Forms.Button;
    BtnCancel       : System.Windows.Forms.Button;
    CboLanguage     : System.Windows.Forms.ComboBox;
    InitialLanguage : TLanguage;
    OnLangChanged   : System.Action;
  end;

// ── 메인 클래스 ──────────────────────────────────────────────────────────────
type
  TSettingsDialog = static class
  private
    class FState: TSettingsState; // var

    // 헬퍼
    class function  MakeSectionLabel(key: string): System.Windows.Forms.Panel;
    class function  MakeLabel(key: string): System.Windows.Forms.Label;
    class function  MakeRow(lbl: System.Windows.Forms.Label;
                            ctl: System.Windows.Forms.Control): System.Windows.Forms.Panel;
    // 페이지 빌더
    class procedure BuildPageLanguage;
    // 이벤트 핸들러
    class procedure OnLanguageChanged(sender: System.Object; e: System.EventArgs);
    class procedure OnOkClick(sender: System.Object; e: System.EventArgs);
    class procedure OnCancelClick(sender: System.Object; e: System.EventArgs);
    class procedure OnBtnBarResize(sender: System.Object; e: System.EventArgs);
    class procedure RefreshLanguagePage; // 언어 전환 시 라벨 다시 그림

  public
    class procedure Show(owner: System.Windows.Forms.IWin32Window;
                         onLanguageChanged: System.Action);
  end;

implementation

// ── 헬퍼: 섹션 타이틀 패널 ───────────────────────────────────────────────────
class function TSettingsDialog.MakeSectionLabel(key: string): System.Windows.Forms.Panel;
var
  lbl: System.Windows.Forms.Label;
begin
  Result := new System.Windows.Forms.Panel();
  Result.Height := 36;
  Result.Dock   := System.Windows.Forms.DockStyle.Top;
  lbl := new System.Windows.Forms.Label();
  TLoc.Bind(lbl, key);
  lbl.AutoSize := true;
  lbl.Left := 0;
  lbl.Top  := 8;
  lbl.Font := new System.Drawing.Font('Segoe UI', 11, System.Drawing.FontStyle.Bold);
  Result.Controls.Add(lbl);
end;

// ── 헬퍼: 라벨 ───────────────────────────────────────────────────────────────
class function TSettingsDialog.MakeLabel(key: string): System.Windows.Forms.Label;
begin
  Result := new System.Windows.Forms.Label();
  TLoc.Bind(Result, key);
  Result.Width     := 160;
  Result.Height    := 23;
  Result.TextAlign := System.Drawing.ContentAlignment.MiddleLeft;
  Result.Font      := new System.Drawing.Font('Segoe UI', 9);
end;

// ── 헬퍼: 라벨 + 컨트롤 한 행 ───────────────────────────────────────────────
class function TSettingsDialog.MakeRow(lbl: System.Windows.Forms.Label;
  ctl: System.Windows.Forms.Control): System.Windows.Forms.Panel;
var
  table: System.Windows.Forms.TableLayoutPanel;
begin
  Result        := new System.Windows.Forms.Panel();
  Result.Height := 34;
  Result.Dock   := System.Windows.Forms.DockStyle.Top;
  Result.Padding := new System.Windows.Forms.Padding(16, 0, 12, 0); // 좌우 패딩

  table := new System.Windows.Forms.TableLayoutPanel();
  table.Dock := System.Windows.Forms.DockStyle.Fill;
  table.ColumnCount := 2;
  table.RowCount := 1;
  
  // 컬럼0: 라벨 160px 고정, 컬럼1: 컨트롤 100% 채움
  table.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(
    System.Windows.Forms.SizeType.Absolute, 160));
  table.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(
    System.Windows.Forms.SizeType.Percent, 100));
  
  lbl.Margin := new System.Windows.Forms.Padding(0, 6, 5, 0);
  lbl.Anchor := System.Windows.Forms.AnchorStyles.Left or
                System.Windows.Forms.AnchorStyles.Top;
  
  ctl.Margin := new System.Windows.Forms.Padding(5, 3, 0, 3);
  ctl.Dock   := System.Windows.Forms.DockStyle.Fill; // ★ 남은 공간 정확히 채움
  
  table.Controls.Add(lbl, 0, 0);
  table.Controls.Add(ctl, 1, 0);
  Result.Controls.Add(table);
end;

// ── 이벤트: 언어 드롭다운 변경 ───────────────────────────────────────────────
class procedure TSettingsDialog.OnLanguageChanged(sender: System.Object; e: System.EventArgs);
var
  selected: TLanguage;
begin
  if FState.CboLanguage.SelectedItem = nil then exit;
  selected := TLoc.LanguageFromName(FState.CboLanguage.SelectedItem.ToString());
  if selected = TLoc.CurrentLanguage then exit;
  TLoc.SetLanguage(selected);
  AppSettings.TAppSettings.SaveLanguage(selected);
  RefreshLanguagePage;
  if FState.OnLangChanged <> nil then FState.OnLangChanged();
end;

// ── 이벤트: OK ───────────────────────────────────────────────────────────────
class procedure TSettingsDialog.OnOkClick(sender: System.Object; e: System.EventArgs);
begin
  // 언어는 OnLanguageChanged에서 이미 즉시 저장/반영되었으므로 OK는 단순히 닫기만 함.
end;

// ── 이벤트: 취소 — 언어 되돌리기 ────────────────────────────────────────────
class procedure TSettingsDialog.OnCancelClick(sender: System.Object; e: System.EventArgs);
begin
  if TLoc.CurrentLanguage <> FState.InitialLanguage then
  begin
    TLoc.SetLanguage(FState.InitialLanguage);
    AppSettings.TAppSettings.SaveLanguage(FState.InitialLanguage);
    RefreshLanguagePage;
    if FState.OnLangChanged <> nil then FState.OnLangChanged();
  end;
end;

// ── 이벤트: 버튼 바 리사이즈 ─────────────────────────────────────────────────
class procedure TSettingsDialog.OnBtnBarResize(sender: System.Object; e: System.EventArgs);
var
  bar: System.Windows.Forms.Panel;
begin
  bar := sender as System.Windows.Forms.Panel;
  FState.BtnOk.Left     := bar.ClientSize.Width - 12 - FState.BtnOk.Width;
  FState.BtnCancel.Left := FState.BtnOk.Left - 6 - FState.BtnCancel.Width;
end;

// ── 언어 페이지 재빌드 (언어 전환 시 라벨도 새로 그려야 함) ──────────────────
class procedure TSettingsDialog.RefreshLanguagePage;
begin
  FState.ContentPanel.Controls.Clear;
  BuildPageLanguage;
end;

// ── 페이지 빌더: 언어 선택 (이 다이얼로그의 유일한 콘텐츠) ───────────────────
class procedure TSettingsDialog.BuildPageLanguage;
var
  p       : System.Windows.Forms.Panel;
  lblLang : System.Windows.Forms.Label;
  lang    : TLanguage;
  rowLang : System.Windows.Forms.Panel;
begin
  p := FState.ContentPanel;
  p.Controls.Add(MakeSectionLabel('dlg.settings.general.header'));

  FState.CboLanguage := new System.Windows.Forms.ComboBox();
  FState.CboLanguage.DropDownStyle := System.Windows.Forms.ComboBoxStyle.DropDownList;
  //FState.CboLanguage.Width := 220;
  FState.CboLanguage.Font  := new System.Drawing.Font('Segoe UI', 9);
  foreach lang in TLoc.AllLanguages do
    FState.CboLanguage.Items.Add(TLoc.LanguageName(lang));
  FState.CboLanguage.SelectedItem := TLoc.LanguageName(TLoc.CurrentLanguage);
  FState.CboLanguage.SelectedIndexChanged += OnLanguageChanged;

  lblLang := MakeLabel('dlg.settings.general.lang_label');
  rowLang := MakeRow(lblLang, FState.CboLanguage);
  rowLang.Height := 40;
  p.Controls.Add(rowLang);
end;

// ── 메인 진입점 ──────────────────────────────────────────────────────────────
class procedure TSettingsDialog.Show(owner: System.Windows.Forms.IWin32Window;
                                     onLanguageChanged: System.Action);
begin
  // 상태 초기화
  FState.InitialLanguage := TLoc.CurrentLanguage;
  FState.OnLangChanged   := onLanguageChanged;

  // ── 다이얼로그 폼 ──────────────────────────────────────────────────────
  // ★ 수정: 네비게이션 리스트(탭 4개)가 사라지고 언어 선택 한 줄만 남으므로
  //   창 크기를 그에 맞춰 작게 줄였습니다.
  FState.Dlg := new System.Windows.Forms.Form();
  TLoc.Bind(FState.Dlg, 'dlg.settings.title');
  FState.Dlg.Width           := 420;
  FState.Dlg.Height          := 200;
  FState.Dlg.FormBorderStyle := System.Windows.Forms.FormBorderStyle.FixedDialog;
  FState.Dlg.StartPosition   := System.Windows.Forms.FormStartPosition.CenterParent;
  FState.Dlg.MaximizeBox     := false;
  FState.Dlg.MinimizeBox     := false;

  // ── 컨텐츠 영역 (네비게이션 없이 바로 내용) ───────────────────────────────
  FState.ContentPanel := new System.Windows.Forms.Panel();
  FState.ContentPanel.Dock    := System.Windows.Forms.DockStyle.Fill;
  FState.ContentPanel.Padding := new System.Windows.Forms.Padding(20, 12, 20, 12);

  BuildPageLanguage();

  // ── 하단 버튼 바 ───────────────────────────────────────────────────────
  // ★ 수정: 더 이상 별도 페이지가 없어 "적용" 버튼의 의미가 없으므로 제거하고
  //   확인/취소만 남겼습니다 (언어는 선택 즉시 반영되므로 적용이 따로 필요 없음).
  FState.BtnBar := new System.Windows.Forms.Panel();
  FState.BtnBar.Height := 48;
  FState.BtnBar.Dock   := System.Windows.Forms.DockStyle.Bottom;

  FState.BtnCancel := new System.Windows.Forms.Button();
  TLoc.Bind(FState.BtnCancel, 'btn.cancel');
  FState.BtnCancel.Width        := 88;
  FState.BtnCancel.Height       := 30;
  FState.BtnCancel.Top          := 9;
  FState.BtnCancel.Anchor       := System.Windows.Forms.AnchorStyles.Right
                                or System.Windows.Forms.AnchorStyles.Top;
  FState.BtnCancel.DialogResult := System.Windows.Forms.DialogResult.Cancel;
  FState.BtnCancel.Click        += OnCancelClick;

  FState.BtnOk := new System.Windows.Forms.Button();
  TLoc.Bind(FState.BtnOk, 'btn.ok');
  FState.BtnOk.Width        := 88;
  FState.BtnOk.Height       := 30;
  FState.BtnOk.Top          := 9;
  FState.BtnOk.Anchor       := System.Windows.Forms.AnchorStyles.Right
                            or System.Windows.Forms.AnchorStyles.Top;
  FState.BtnOk.DialogResult := System.Windows.Forms.DialogResult.OK;
  FState.BtnOk.Click        += OnOkClick;

  FState.BtnBar.Controls.Add(FState.BtnCancel);
  FState.BtnBar.Controls.Add(FState.BtnOk);
  FState.BtnBar.Resize += OnBtnBarResize;

  // 초기 버튼 위치
  FState.BtnOk.Left     := 420 - 12 - FState.BtnOk.Width;
  FState.BtnCancel.Left := FState.BtnOk.Left - 6 - FState.BtnCancel.Width;

  FState.Dlg.AcceptButton := FState.BtnOk;
  FState.Dlg.CancelButton := FState.BtnCancel;

  FState.Dlg.Controls.Add(FState.ContentPanel);
  FState.Dlg.Controls.Add(FState.BtnBar);

  FState.Dlg.ShowDialog(owner);
end; 

end.