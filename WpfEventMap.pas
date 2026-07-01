unit WpfEventMap;

// =============================================================================
// WpfEventMap.pas
//   WPF_EVENTS 상수 배열
//   GetEventDelegateType  — 이벤트명 → 델리게이트 타입 문자열
//   GetEventParamType     — 이벤트명 → EventArgs 파생 타입 문자열
//   IsWpfEvent            — 주어진 속성명이 WPF 이벤트인지 검사
//   GetApplicableEvents   — 컨트롤 타입별로 의미 있는 이벤트 목록
//
// ★ 리팩토링 (구조 정리):
//   기존에는 GetEventDelegateType / GetEventParamType 가 같은 이벤트명을 키로
//   쓰는 두 개의 독립된 case 문이었다. 이벤트를 하나 추가할 때 두 case 문을
//   전부 고쳐야 했고, 실제로 Window 전용 이벤트(Closing 등)를 WPF_EVENTS 에는
//   추가했지만 델리게이트/파라미터 타입 쪽을 깜빡하는 식의 실수가 나기 쉬운
//   구조였다 (아래 WPF_EVENTS 의 "Closing 누락" 이력 참고).
//
//   그래서 이벤트명 → (델리게이트 타입, 파라미터 타입) 을 WPF_EVENT_TYPES 라는
//   단일 테이블로 합쳤다. GetEventDelegateType/GetEventParamType 은 이 테이블을
//   조회하는 얇은 래퍼로 남겨 기존 호출부(PascalCodeGenerator.pas 등)는 전혀
//   수정할 필요가 없다.
//
//   테이블에는 "기본값(System.EventHandler / System.EventArgs)과 다른 타입을
//   쓰는 이벤트"만 등록한다. 테이블에 없는 이벤트는 자동으로 기본값을 받으므로,
//   원래 두 case 문의 else 절과 동일한 동작이다 (아래 각주에 어떤 이벤트가
//   비대칭적으로 파라미터 타입만 갖는지 설명).
// =============================================================================

const
  WPF_EVENTS: array of string = [
    'Click', 'DoubleClick', 'MouseDown', 'MouseUp', 'MouseMove',
    'MouseEnter', 'MouseLeave', 'MouseWheel', 'KeyDown', 'KeyUp',
    'KeyPress', 'TextChanged', 'TextInput', 'SelectionChanged',
    'Checked', 'Unchecked', 'ValueChanged', 'Loaded', 'Unloaded',
    'GotFocus', 'LostFocus', 'SizeChanged', 'LayoutUpdated',
    'SourceUpdated', 'TargetUpdated', 'DataContextChanged',
    'IsVisibleChanged', 'IsEnabledChanged',
    'PreviewMouseDown', 'PreviewMouseUp', 'PreviewKeyDown', 'PreviewKeyUp',
    'DragEnter', 'DragLeave', 'DragOver', 'Drop',
    'ScrollChanged', 'ContextMenuOpening', 'ContextMenuClosing',
    'ToolTipOpening', 'ToolTipClosing',
    'RequestBringIntoView', 'ManipulationStarted', 'ManipulationDelta',
    'ManipulationCompleted', 'Expanded', 'Collapsed',
    'SelectedItemChanged', 'NodeExpanded', 'NodeCollapsed',
    // ★ 추가: Window 전용 이벤트
    //   누락으로 인해 IsWpfEvent('Closing') = false → ParseRootControlInfo가
    //   XAML 속성을 이벤트로 인식하지 못해 rootCtrl.Events가 비어 코드 생성 제외
    'Closing', 'Closed', 'ContentRendered', 'StateChanged',
    'LocationChanged', 'Activated', 'Deactivated',
    // ★ 추가: UserControl / Page 전용
    'Initialized'
  ];

// -----------------------------------------------------------------------------
// 이벤트명 → (델리게이트 타입, 파라미터 타입) 단일 테이블
//   각 행 = [EventName, DelegateType, ParamType]
//   ★ PascalABC.NET 은 배열 리터럴 안에서 "(Field: Value; ...)" 레코드 생성자
//     문법을 지원하지 않아 컴파일 오류(Found ';' but expected ')')가 났었다.
//     레코드 타입 대신, 이미 이 파일에서 쓰던 array-literal([...]) 문법만으로
//     구성되는 array of array of string 으로 표현한다.
// -----------------------------------------------------------------------------
const
  DEFAULT_DELEGATE_TYPE = 'System.EventHandler';
  DEFAULT_PARAM_TYPE    = 'System.EventArgs';

  // 여기 없는 이벤트는 DEFAULT_DELEGATE_TYPE / DEFAULT_PARAM_TYPE 을 받는다.
  WPF_EVENT_TYPES: array of array of string = [
    ['Click',     'System.Windows.RoutedEventHandler', 'System.Windows.RoutedEventArgs'],
    ['Checked',   'System.Windows.RoutedEventHandler', 'System.Windows.RoutedEventArgs'],
    ['Unchecked', 'System.Windows.RoutedEventHandler', 'System.Windows.RoutedEventArgs'],
    ['Loaded',    'System.Windows.RoutedEventHandler', 'System.Windows.RoutedEventArgs'],
    ['Unloaded',  'System.Windows.RoutedEventHandler', 'System.Windows.RoutedEventArgs'],
    ['GotFocus',  'System.Windows.RoutedEventHandler', 'System.Windows.RoutedEventArgs'],
    ['LostFocus', 'System.Windows.RoutedEventHandler', 'System.Windows.RoutedEventArgs'],

    ['MouseDown',        'System.Windows.Input.MouseButtonEventHandler', 'System.Windows.Input.MouseButtonEventArgs'],
    ['MouseUp',          'System.Windows.Input.MouseButtonEventHandler', 'System.Windows.Input.MouseButtonEventArgs'],
    ['PreviewMouseDown', 'System.Windows.Input.MouseButtonEventHandler', 'System.Windows.Input.MouseButtonEventArgs'],
    ['PreviewMouseUp',   'System.Windows.Input.MouseButtonEventHandler', 'System.Windows.Input.MouseButtonEventArgs'],

    ['MouseMove',  'System.Windows.Input.MouseEventHandler', 'System.Windows.Input.MouseEventArgs'],
    ['MouseEnter', 'System.Windows.Input.MouseEventHandler', 'System.Windows.Input.MouseEventArgs'],
    ['MouseLeave', 'System.Windows.Input.MouseEventHandler', 'System.Windows.Input.MouseEventArgs'],

    ['KeyDown',        'System.Windows.Input.KeyEventHandler', 'System.Windows.Input.KeyEventArgs'],
    ['KeyUp',          'System.Windows.Input.KeyEventHandler', 'System.Windows.Input.KeyEventArgs'],
    ['PreviewKeyDown', 'System.Windows.Input.KeyEventHandler', 'System.Windows.Input.KeyEventArgs'],
    ['PreviewKeyUp',   'System.Windows.Input.KeyEventHandler', 'System.Windows.Input.KeyEventArgs'],

    ['TextChanged',      'System.Windows.Controls.TextChangedEventHandler',      'System.Windows.Controls.TextChangedEventArgs'],
    ['SelectionChanged', 'System.Windows.Controls.SelectionChangedEventHandler', 'System.Windows.Controls.SelectionChangedEventArgs'],
    ['ValueChanged',     'System.Windows.RoutedPropertyChangedEventHandler<double>', 'System.Windows.RoutedPropertyChangedEventArgs<double>'],

    // Window 전용: Closing 은 e.Cancel := true 로 닫기를 취소할 수 있어야 하므로 CancelEventHandler/Args.
    // Closed/ContentRendered/Activated/Deactivated/StateChanged/LocationChanged/Initialized 는
    // 테이블에 없어도 DEFAULT_DELEGATE_TYPE/DEFAULT_PARAM_TYPE(EventHandler/EventArgs)을 그대로 받는다.
    ['Closing', 'System.ComponentModel.CancelEventHandler', 'System.ComponentModel.CancelEventArgs'],

    // ── 아래는 "델리게이트는 기본값(EventHandler), 파라미터 타입만 특정 타입"인
    //    비대칭 항목들 (원래 GetEventDelegateType 의 case 에는 없고
    //    GetEventParamType 의 case 에만 있던 이벤트들 — 기존 동작 그대로 보존) ──
    ['LayoutUpdated', DEFAULT_DELEGATE_TYPE, 'System.Windows.RoutedEventArgs'],
    ['DoubleClick',   DEFAULT_DELEGATE_TYPE, 'System.Windows.Input.MouseButtonEventArgs'],
    ['MouseWheel',    DEFAULT_DELEGATE_TYPE, 'System.Windows.Input.MouseWheelEventArgs'],
    ['SizeChanged',   DEFAULT_DELEGATE_TYPE, 'System.Windows.SizeChangedEventArgs'],
    ['ScrollChanged', DEFAULT_DELEGATE_TYPE, 'System.Windows.Controls.ScrollChangedEventArgs'],
    ['DragEnter',     DEFAULT_DELEGATE_TYPE, 'System.Windows.DragEventArgs'],
    ['DragLeave',     DEFAULT_DELEGATE_TYPE, 'System.Windows.DragEventArgs'],
    ['DragOver',      DEFAULT_DELEGATE_TYPE, 'System.Windows.DragEventArgs'],
    ['Drop',          DEFAULT_DELEGATE_TYPE, 'System.Windows.DragEventArgs']
  ];

// -----------------------------------------------------------------------------
// TryFindEventTypeInfo
//   WPF_EVENT_TYPES 에서 evName 을 찾는다. 못 찾으면 false.
// -----------------------------------------------------------------------------
function TryFindEventTypeInfo(evName: string; var delegateType, paramType: string): boolean;
var
  row: array of string;
begin
  foreach row in WPF_EVENT_TYPES do
    if row[0] = evName then
    begin
      delegateType := row[1];
      paramType    := row[2];
      Result := true;
      exit;
    end;
  Result := false;
end;

// -----------------------------------------------------------------------------
// GetEventDelegateType
//   컨트롤 타입명(ctrlType)과 이벤트명(evName)을 받아
//   해당 이벤트의 .NET 델리게이트 완전 타입명을 반환한다.
//   (ctrlType 은 향후 컨트롤별 오버라이드를 위해 시그니처만 유지)
// -----------------------------------------------------------------------------
function GetEventDelegateType(ctrlType: string; evName: string): string;
var
  delegateType, paramType: string;
begin
  if TryFindEventTypeInfo(evName, delegateType, paramType) then
    Result := delegateType
  else
    Result := DEFAULT_DELEGATE_TYPE;
end;

// -----------------------------------------------------------------------------
// GetEventParamType
//   이벤트 핸들러의 두 번째 파라미터(e) 타입을 반환한다.
// -----------------------------------------------------------------------------
function GetEventParamType(ctrlType: string; evName: string): string;
var
  delegateType, paramType: string;
begin
  if TryFindEventTypeInfo(evName, delegateType, paramType) then
    Result := paramType
  else
    Result := DEFAULT_PARAM_TYPE;
end;

// -----------------------------------------------------------------------------
// IsWpfEvent
//   attrName 이 WPF_EVENTS 배열에 포함된 이벤트명이면 true를 반환한다.
// -----------------------------------------------------------------------------
function IsWpfEvent(attrName: string): boolean;
var
  ev: string;
begin
  foreach ev in WPF_EVENTS do
    if attrName = ev then
    begin
      Result := true;
      exit;
    end;
  Result := false;
end;

// -----------------------------------------------------------------------------
// 공통 이벤트 그룹 (모든 FrameworkElement / Control 계열이 공유)
// -----------------------------------------------------------------------------
const
  COMMON_EVENTS: array of string = [
    'Loaded', 'Unloaded', 'GotFocus', 'LostFocus',
    'MouseDown', 'MouseUp', 'MouseMove', 'MouseEnter', 'MouseLeave', 'MouseWheel',
    'PreviewMouseDown', 'PreviewMouseUp',
    'KeyDown', 'KeyUp', 'PreviewKeyDown', 'PreviewKeyUp',
    'SizeChanged', 'IsVisibleChanged', 'IsEnabledChanged', 'DataContextChanged',
    'DragEnter', 'DragLeave', 'DragOver', 'Drop',
    'ContextMenuOpening', 'ContextMenuClosing', 'ToolTipOpening', 'ToolTipClosing'
  ];

// -----------------------------------------------------------------------------
// GetApplicableEvents
//   컨트롤 타입명(ctrlType)을 받아, 해당 타입에서 실질적으로 의미 있는
//   이벤트 목록(타입 고유 이벤트 + 공통 이벤트)을 반환한다.
//   목록은 "주요 이벤트가 먼저" 오도록 정렬되어 있다 (Properties 창에서
//   가장 많이 쓰는 이벤트가 위쪽에 보이도록).
// -----------------------------------------------------------------------------
function GetApplicableEvents(ctrlType: string): array of string;
var
  specific: array of string;
  result_list: System.Collections.Generic.List<string>;
  ev: string;
begin
  case ctrlType of
    'Button', 'RepeatButton', 'ToggleButton':
      specific := ['Click'];

    'CheckBox', 'RadioButton':
      specific := ['Checked', 'Unchecked', 'Click'];

    'TextBox', 'PasswordBox', 'RichTextBox':
      specific := ['TextChanged', 'TextInput'];

    'ComboBox':
      specific := ['SelectionChanged', 'DropDownOpened', 'DropDownClosed'];

    'ListBox', 'ListView', 'DataGrid':
      specific := ['SelectionChanged'];

    'TreeView':
      specific := ['SelectedItemChanged', 'NodeExpanded', 'NodeCollapsed'];

    'Slider', 'ScrollBar', 'ProgressBar':
      specific := ['ValueChanged'];

    'ScrollViewer':
      specific := ['ScrollChanged'];

    'Expander':
      specific := ['Expanded', 'Collapsed'];

    'Window':
      specific := ['Loaded', 'Closing', 'Closed', 'ContentRendered',
                   'Activated', 'Deactivated', 'StateChanged', 'LocationChanged'];

    'Image':
      specific := [];

    'Canvas', 'Grid', 'StackPanel', 'WrapPanel', 'DockPanel', 'Border':
      specific := ['SizeChanged', 'LayoutUpdated'];
  else
    specific := ['Click'];   // 알려지지 않은 타입은 보수적으로 Click만 우선 표시
  end;

  result_list := new System.Collections.Generic.List<string>();
  // 1) 타입 고유 이벤트 먼저
  foreach ev in specific do
    if not result_list.Contains(ev) then
      result_list.Add(ev);
  // 2) 공통 이벤트 추가 (중복 제외)
  foreach ev in COMMON_EVENTS do
    if not result_list.Contains(ev) then
      result_list.Add(ev);

  Result := result_list.ToArray();
end;

end.