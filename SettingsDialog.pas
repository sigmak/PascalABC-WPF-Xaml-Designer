unit SettingsDialog;

// =============================================================================
// SettingsDialog.pas — "설정(Настройки)" 다이얼로그
//
// PascalABC.NET 해결 전략:
//   중첩 프로시저 간 호출, var 캡처 문제를 피하기 위해
//   상태를 TSettingsState 레코드에 담고,
//   이벤트 핸들러를 TSettingsDialog 클래스 메서드로 승격.
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
    NavList         : System.Windows.Forms.ListBox;
    Panels          : array[0..3] of System.Windows.Forms.Panel;
    BtnBar          : System.Windows.Forms.Panel;
    BtnOk           : System.Windows.Forms.Button;
    BtnCancel       : System.Windows.Forms.Button;
    BtnApply        : System.Windows.Forms.Button;
    CboLanguage     : System.Windows.Forms.ComboBox;
    ChkPauseConsole : System.Windows.Forms.CheckBox;
    ChkSaveOnSuccess: System.Windows.Forms.CheckBox;
    ChkAutoComplete : System.Windows.Forms.CheckBox;
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
    class function  MakeCheckRow(key: string; isChecked: boolean;
                                 var cb: System.Windows.Forms.CheckBox): System.Windows.Forms.Panel;
    // 페이지 빌더
    class procedure BuildPageGeneral;
    class procedure BuildPlaceholderPage(p: System.Windows.Forms.Panel; titleKey: string);
    // 이벤트 핸들러
    class procedure OnLanguageChanged(sender: System.Object; e: System.EventArgs);
    class procedure OnNavChanged(sender: System.Object; e: System.EventArgs);
    class procedure CommitCheckboxSettings;
    class procedure OnOkClick(sender: System.Object; e: System.EventArgs);
    class procedure OnApplyClick(sender: System.Object; e: System.EventArgs);
    class procedure OnCancelClick(sender: System.Object; e: System.EventArgs);
    class procedure OnBtnBarResize(sender: System.Object; e: System.EventArgs);
    class procedure RefreshNavList;       // ← 추가
    class procedure RefreshGeneralPage;   // ← 추가

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
begin
  Result := new System.Windows.Forms.Panel();
  Result.Height := 34;
  Result.Dock   := System.Windows.Forms.DockStyle.Top;
  lbl.Top  := 6;  lbl.Left := 16;
  ctl.Top  := 3;  ctl.Left := 176;
  Result.Controls.Add(lbl);
  Result.Controls.Add(ctl);
end;

// ── 헬퍼: 체크박스 행 ────────────────────────────────────────────────────────
class function TSettingsDialog.MakeCheckRow(key: string; isChecked: boolean;
                                            var cb: System.Windows.Forms.CheckBox): System.Windows.Forms.Panel;
begin
  Result := new System.Windows.Forms.Panel();
  Result.Height := 30;
  Result.Dock   := System.Windows.Forms.DockStyle.Top;
  cb := new System.Windows.Forms.CheckBox();
  TLoc.Bind(cb, key);
  cb.AutoSize := true;
  cb.Checked  := isChecked;
  cb.Top  := 5;
  cb.Left := 16;
  cb.Font := new System.Drawing.Font('Segoe UI', 9);
  Result.Controls.Add(cb);
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
  RefreshNavList;      // ← 추가
  RefreshGeneralPage;  // ← 추가
  if FState.OnLangChanged <> nil then FState.OnLangChanged();
end;

// ── 이벤트: 내비게이션 선택 변경 ─────────────────────────────────────────────
class procedure TSettingsDialog.OnNavChanged(sender: System.Object; e: System.EventArgs);
var
  idx, j: integer;
begin
  idx := FState.NavList.SelectedIndex;
  for j := 0 to 3 do
    FState.Panels[j].Visible := (j = idx);
end;

// ── 공통: 체크박스 값 저장 ───────────────────────────────────────────────────
class procedure TSettingsDialog.CommitCheckboxSettings;
begin
  AppSettings.TAppSettings.SavePauseAfterConsole(FState.ChkPauseConsole.Checked);
  AppSettings.TAppSettings.SaveSaveOnSuccess(FState.ChkSaveOnSuccess.Checked);
  AppSettings.TAppSettings.SaveAutoCompleteOnStartup(FState.ChkAutoComplete.Checked);
end;

// ── 이벤트: OK ───────────────────────────────────────────────────────────────
class procedure TSettingsDialog.OnOkClick(sender: System.Object; e: System.EventArgs);
begin
  CommitCheckboxSettings();
end;

// ── 이벤트: 적용 ─────────────────────────────────────────────────────────────
class procedure TSettingsDialog.OnApplyClick(sender: System.Object; e: System.EventArgs);
begin
  CommitCheckboxSettings();
end;

// ── 이벤트: 취소 — 언어 되돌리기 ────────────────────────────────────────────
class procedure TSettingsDialog.OnCancelClick(sender: System.Object; e: System.EventArgs);
begin
  if TLoc.CurrentLanguage <> FState.InitialLanguage then
  begin
    TLoc.SetLanguage(FState.InitialLanguage);
    AppSettings.TAppSettings.SaveLanguage(FState.InitialLanguage);
    RefreshNavList;      // ← 추가
    RefreshGeneralPage;  // ← 추가
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
  FState.BtnApply.Left  := FState.BtnCancel.Left - 6 - FState.BtnApply.Width;
end;


// ── NavList 아이템 텍스트 갱신 ────────────────────────────────────────────
class procedure TSettingsDialog.RefreshNavList;
var
  savedIdx: integer;
begin
  savedIdx := FState.NavList.SelectedIndex;
  FState.NavList.BeginUpdate;
  FState.NavList.Items.Clear;
  FState.NavList.Items.Add(TLoc.S('dlg.settings.nav.general'));
  FState.NavList.Items.Add(TLoc.S('dlg.settings.nav.editor'));
  FState.NavList.Items.Add(TLoc.S('dlg.settings.nav.compile'));
  FState.NavList.Items.Add(TLoc.S('dlg.settings.nav.intellisense'));
  FState.NavList.EndUpdate;
  FState.NavList.SelectedIndex := savedIdx;
end;

// ── General 페이지 재빌드 ─────────────────────────────────────────────────
class procedure TSettingsDialog.RefreshGeneralPage;
begin
  FState.Panels[0].Controls.Clear;
  BuildPageGeneral;
end;

// ── 페이지 빌더: 일반 ────────────────────────────────────────────────────────
class procedure TSettingsDialog.BuildPageGeneral;
var
  p       : System.Windows.Forms.Panel;
  lblLang : System.Windows.Forms.Label;
  lang    : TLanguage;
  rowLang : System.Windows.Forms.Panel;
begin
  p := FState.Panels[0];
  p.Controls.Add(MakeSectionLabel('dlg.settings.general.header'));

  FState.CboLanguage := new System.Windows.Forms.ComboBox();
  FState.CboLanguage.DropDownStyle := System.Windows.Forms.ComboBoxStyle.DropDownList;
  FState.CboLanguage.Width := 220;
  FState.CboLanguage.Font  := new System.Drawing.Font('Segoe UI', 9);
  foreach lang in TLoc.AllLanguages do
    FState.CboLanguage.Items.Add(TLoc.LanguageName(lang));
  FState.CboLanguage.SelectedItem := TLoc.LanguageName(TLoc.CurrentLanguage);
  FState.CboLanguage.SelectedIndexChanged += OnLanguageChanged;

  lblLang := MakeLabel('dlg.settings.general.lang_label');
  rowLang := MakeRow(lblLang, FState.CboLanguage);
  rowLang.Height := 40;
  p.Controls.Add(rowLang);

  p.Controls.Add(MakeCheckRow('dlg.settings.general.pause_console',
    AppSettings.TAppSettings.LoadPauseAfterConsole, FState.ChkPauseConsole));
  p.Controls.Add(MakeCheckRow('dlg.settings.general.save_on_success',
    AppSettings.TAppSettings.LoadSaveOnSuccess, FState.ChkSaveOnSuccess));
  p.Controls.Add(MakeCheckRow('dlg.settings.general.autocomplete',
    AppSettings.TAppSettings.LoadAutoCompleteOnStartup, FState.ChkAutoComplete));
end;

// ── 페이지 빌더: 빈 플레이스홀더 ────────────────────────────────────────────
class procedure TSettingsDialog.BuildPlaceholderPage(p: System.Windows.Forms.Panel; titleKey: string);
begin
  p.Controls.Add(MakeSectionLabel(titleKey));
end;

// ── 메인 진입점 ──────────────────────────────────────────────────────────────
class procedure TSettingsDialog.Show(owner: System.Windows.Forms.IWin32Window;
                                     onLanguageChanged: System.Action);
var
  splitDlg    : System.Windows.Forms.SplitContainer;
  contentPanel: System.Windows.Forms.Panel;
  i           : integer;
begin
  // 상태 초기화
  FState.InitialLanguage := TLoc.CurrentLanguage;
  FState.OnLangChanged   := onLanguageChanged;

  // ── 다이얼로그 폼 ──────────────────────────────────────────────────────
  FState.Dlg := new System.Windows.Forms.Form();
  TLoc.Bind(FState.Dlg, 'dlg.settings.title');
  FState.Dlg.Width           := 620;
  FState.Dlg.Height          := 460;
  FState.Dlg.FormBorderStyle := System.Windows.Forms.FormBorderStyle.FixedDialog;
  FState.Dlg.StartPosition   := System.Windows.Forms.FormStartPosition.CenterParent;
  FState.Dlg.MaximizeBox     := false;
  FState.Dlg.MinimizeBox     := false;

  // ── SplitContainer ───────────────────────────────────────────────────
  splitDlg := new System.Windows.Forms.SplitContainer();
  splitDlg.Dock             := System.Windows.Forms.DockStyle.Fill;
  splitDlg.Orientation      := System.Windows.Forms.Orientation.Vertical;
  splitDlg.SplitterDistance := 5; //180;
  splitDlg.IsSplitterFixed  := true;

  // ── 좌측 내비게이션 ────────────────────────────────────────────────────
  FState.NavList := new System.Windows.Forms.ListBox();
  FState.NavList.Dock        := System.Windows.Forms.DockStyle.Fill;
  FState.NavList.Font        := new System.Drawing.Font('Segoe UI', 9);
  FState.NavList.BorderStyle := System.Windows.Forms.BorderStyle.None;
  FState.NavList.ItemHeight  := 28;
  FState.NavList.Items.Add(TLoc.S('dlg.settings.nav.general'));
  FState.NavList.Items.Add(TLoc.S('dlg.settings.nav.editor'));
  FState.NavList.Items.Add(TLoc.S('dlg.settings.nav.compile'));
  FState.NavList.Items.Add(TLoc.S('dlg.settings.nav.intellisense'));
  FState.NavList.SelectedIndex        := 0;
  FState.NavList.SelectedIndexChanged += OnNavChanged;
  splitDlg.Panel1.Controls.Add(FState.NavList);

  // ── 우측 컨텐츠 영역 ───────────────────────────────────────────────────
  contentPanel := new System.Windows.Forms.Panel();
  contentPanel.Dock    := System.Windows.Forms.DockStyle.Fill;
  contentPanel.Padding := new System.Windows.Forms.Padding(20, 12, 20, 12);
  splitDlg.Panel2.Controls.Add(contentPanel);

  for i := 0 to 3 do
  begin
    FState.Panels[i] := new System.Windows.Forms.Panel();
    FState.Panels[i].Dock    := System.Windows.Forms.DockStyle.Fill;
    FState.Panels[i].Visible := (i = 0);
    contentPanel.Controls.Add(FState.Panels[i]);
  end;

  BuildPageGeneral();
  BuildPlaceholderPage(FState.Panels[1], 'dlg.settings.nav.editor');
  BuildPlaceholderPage(FState.Panels[2], 'dlg.settings.nav.compile');
  BuildPlaceholderPage(FState.Panels[3], 'dlg.settings.nav.intellisense');

  // ── 하단 버튼 바 ───────────────────────────────────────────────────────
  FState.BtnBar := new System.Windows.Forms.Panel();
  FState.BtnBar.Height := 48;
  FState.BtnBar.Dock   := System.Windows.Forms.DockStyle.Bottom;

  FState.BtnApply := new System.Windows.Forms.Button();
  TLoc.Bind(FState.BtnApply, 'btn.apply');
  FState.BtnApply.Width  := 88;
  FState.BtnApply.Height := 30;
  FState.BtnApply.Top    := 9;
  FState.BtnApply.Anchor := System.Windows.Forms.AnchorStyles.Right
                         or System.Windows.Forms.AnchorStyles.Top;
  FState.BtnApply.Click  += OnApplyClick;

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

  FState.BtnBar.Controls.Add(FState.BtnApply);
  FState.BtnBar.Controls.Add(FState.BtnCancel);
  FState.BtnBar.Controls.Add(FState.BtnOk);
  FState.BtnBar.Resize += OnBtnBarResize;

  // 초기 버튼 위치
  FState.BtnOk.Left     := 620 - 12 - FState.BtnOk.Width;
  FState.BtnCancel.Left := FState.BtnOk.Left - 6 - FState.BtnCancel.Width;
  FState.BtnApply.Left  := FState.BtnCancel.Left - 6 - FState.BtnApply.Width;

  FState.Dlg.AcceptButton := FState.BtnOk;
  FState.Dlg.CancelButton := FState.BtnCancel;

  FState.Dlg.Controls.Add(splitDlg);
  FState.Dlg.Controls.Add(FState.BtnBar);

  FState.Dlg.ShowDialog(owner);
end;

end.