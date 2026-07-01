unit DockContents;

{$reference dockpanelsuite.3.1.0\lib\net40\WeifenLuo.WinFormsUI.Docking.dll}
{$reference System.Windows.Forms.dll}

uses
  System.Windows.Forms,
  WeifenLuo.WinFormsUI.Docking,
  LocalizationCore,
  Strings_Common;

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
// SetupDockContent — 6개 DockContent 자식 클래스 생성자의 공통 초기화 로직
//   (Text/닫기버튼/DockAreas 설정 + 내부 컨트롤 Dock=Fill 후 추가)
// =============================================================================
procedure SetupDockContent(content: WeifenLuo.WinFormsUI.Docking.DockContent;
  ctrl: System.Windows.Forms.Control; text: string; closable: boolean; areas: integer);
begin
  content.Text               := text;
  content.CloseButtonVisible := closable;
  content.CloseButton        := closable;
  content.DockAreas          := WeifenLuo.WinFormsUI.Docking.DockAreas(areas);
  if ctrl <> nil then
  begin
    ctrl.Dock := System.Windows.Forms.DockStyle.Fill;
    content.Controls.Add(ctrl);
  end;
end;

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
  SetupDockContent(Self, host, TLoc.S('dock.toolbox'), true, DA_Left or DA_Right or DA_Float); //'도구 상자'
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
  SetupDockContent(Self, trv, TLoc.S('dock.explorer'), true, DA_Left or DA_Right or DA_Float); //'솔루션 탐색기'
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
  SetupDockContent(Self, host, TLoc.S('dock.properties'), true, DA_Left or DA_Right or DA_Float); //'속성'
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
  SetupDockContent(Self, txt, TLoc.S('dock.output'), true, DA_Bottom or DA_Top or DA_Float); //'출력'
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
  SetupDockContent(Self, lv, TLoc.S('dock.errors'), true, DA_Bottom or DA_Top or DA_Float); //'오류 목록'
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
  SetupDockContent(Self, tab, TLoc.S('dock.editor'), false, DA_Document); //'편집기'
end;

end.