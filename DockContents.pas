unit DockContents;

{$reference dockpanelsuite.3.1.0\lib\net40\WeifenLuo.WinFormsUI.Docking.dll}
{$reference System.Windows.Forms.dll}

uses
  System.Windows.Forms,
  WeifenLuo.WinFormsUI.Docking;

// =============================================================================
// 헬퍼: DockAreas 플래그 상수
// PascalABC.NET 에서 [Flags] 열거형을 or 로 조합하면
// "Static field cannot be accessed with an instance reference" 오류가 발생하므로
// 정수 상수로 미리 정의해 둔다.
// WeifenLuo DockAreas 값:
//   None=0, Float=1, DockLeft=2, DockRight=4, DockTop=8, DockBottom=16, Document=32
// =============================================================================
const
  DA_Float    = 1;
  DA_Left     = 2;
  DA_Right    = 4;
  DA_Top      = 8;
  DA_Bottom   = 16;
  DA_Document = 32;

// =============================================================================
// TToolboxDock
// =============================================================================
type
  TToolboxDock = class(WeifenLuo.WinFormsUI.Docking.DockContent)
  public
    constructor Create(host: System.Windows.Forms.Control);
  end;

constructor TToolboxDock.Create(host: System.Windows.Forms.Control);
begin
  inherited Create;
  Self.Text               := '도구 상자';
  Self.CloseButtonVisible := true;
  Self.CloseButton        := true;
  Self.DockAreas          := WeifenLuo.WinFormsUI.Docking.DockAreas(DA_Left or DA_Right or DA_Float);
  if host <> nil then
  begin
    host.Dock := System.Windows.Forms.DockStyle.Fill;
    Self.Controls.Add(host);
  end;
end;

// =============================================================================
// TSolutionExplorerDock
// =============================================================================
type
  TSolutionExplorerDock = class(WeifenLuo.WinFormsUI.Docking.DockContent)
  public
    constructor Create(trv: System.Windows.Forms.Control);
  end;

constructor TSolutionExplorerDock.Create(trv: System.Windows.Forms.Control);
begin
  inherited Create;
  Self.Text               := '솔루션 탐색기';
  Self.CloseButtonVisible := true;
  Self.CloseButton        := true;
  Self.DockAreas          := WeifenLuo.WinFormsUI.Docking.DockAreas(DA_Left or DA_Right or DA_Float);
  if trv <> nil then
  begin
    trv.Dock := System.Windows.Forms.DockStyle.Fill;
    Self.Controls.Add(trv);
  end;
end;

// =============================================================================
// TPropertyGridDock
// =============================================================================
type
  TPropertyGridDock = class(WeifenLuo.WinFormsUI.Docking.DockContent)
  public
    constructor Create(host: System.Windows.Forms.Control);
  end;

constructor TPropertyGridDock.Create(host: System.Windows.Forms.Control);
begin
  inherited Create;
  Self.Text               := '속성';
  Self.CloseButtonVisible := true;
  Self.CloseButton        := true;
  Self.DockAreas          := WeifenLuo.WinFormsUI.Docking.DockAreas(DA_Left or DA_Right or DA_Float);
  if host <> nil then
  begin
    host.Dock := System.Windows.Forms.DockStyle.Fill;
    Self.Controls.Add(host);
  end;
end;

// =============================================================================
// TOutputDock
// =============================================================================
type
  TOutputDock = class(WeifenLuo.WinFormsUI.Docking.DockContent)
  public
    constructor Create(txt: System.Windows.Forms.Control);
  end;

constructor TOutputDock.Create(txt: System.Windows.Forms.Control);
begin
  inherited Create;
  Self.Text               := '출력';
  Self.CloseButtonVisible := true;
  Self.CloseButton        := true;
  Self.DockAreas          := WeifenLuo.WinFormsUI.Docking.DockAreas(DA_Bottom or DA_Top or DA_Float);
  if txt <> nil then
  begin
    txt.Dock := System.Windows.Forms.DockStyle.Fill;
    Self.Controls.Add(txt);
  end;
end;

// =============================================================================
// TErrorListDock
// =============================================================================
type
  TErrorListDock = class(WeifenLuo.WinFormsUI.Docking.DockContent)
  public
    constructor Create(lv: System.Windows.Forms.Control);
  end;

constructor TErrorListDock.Create(lv: System.Windows.Forms.Control);
begin
  inherited Create;
  Self.Text               := '오류 목록';
  Self.CloseButtonVisible := true;
  Self.CloseButton        := true;
  Self.DockAreas          := WeifenLuo.WinFormsUI.Docking.DockAreas(DA_Bottom or DA_Top or DA_Float);
  if lv <> nil then
  begin
    lv.Dock := System.Windows.Forms.DockStyle.Fill;
    Self.Controls.Add(lv);
  end;
end;

// =============================================================================
// TMainDocumentDock  —  중앙 고정 문서 영역 (닫기/이동 불가)
// =============================================================================
type
  TMainDocumentDock = class(WeifenLuo.WinFormsUI.Docking.DockContent)
  public
    constructor Create(tab: System.Windows.Forms.Control);
  end;

constructor TMainDocumentDock.Create(tab: System.Windows.Forms.Control);
begin
  inherited Create;
  Self.Text               := '편집기';
  Self.CloseButtonVisible := false;
  Self.CloseButton        := false;
  Self.DockAreas          := WeifenLuo.WinFormsUI.Docking.DockAreas(DA_Document);
  if tab <> nil then
  begin
    tab.Dock := System.Windows.Forms.DockStyle.Fill;
    Self.Controls.Add(tab);
  end;
end;

end.