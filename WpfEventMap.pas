unit WpfEventMap;

// =============================================================================
// WpfEventMap.pas
//   WPF_EVENTS 상수 배열
//   GetEventDelegateType  — 이벤트명 → 델리게이트 타입 문자열
//   GetEventParamType     — 이벤트명 → EventArgs 파생 타입 문자열
//   IsWpfEvent            — 주어진 속성명이 WPF 이벤트인지 검사
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
// GetEventDelegateType
//   컨트롤 타입명(ctrlType)과 이벤트명(evName)을 받아
//   해당 이벤트의 .NET 델리게이트 완전 타입명을 반환한다.
// -----------------------------------------------------------------------------
function GetEventDelegateType(ctrlType: string; evName: string): string;
begin
  case evName of
    'Click', 'Checked', 'Unchecked', 'Loaded', 'Unloaded',
    'GotFocus', 'LostFocus':
      Result := 'System.Windows.RoutedEventHandler';

    'MouseDown', 'MouseUp', 'PreviewMouseDown', 'PreviewMouseUp':
      Result := 'System.Windows.Input.MouseButtonEventHandler';

    'MouseMove', 'MouseEnter', 'MouseLeave':
      Result := 'System.Windows.Input.MouseEventHandler';

    'KeyDown', 'KeyUp', 'PreviewKeyDown', 'PreviewKeyUp':
      Result := 'System.Windows.Input.KeyEventHandler';

    'TextChanged':
      Result := 'System.Windows.Controls.TextChangedEventHandler';

    'SelectionChanged':
      Result := 'System.Windows.Controls.SelectionChangedEventHandler';

    'ValueChanged':
      Result := 'System.Windows.RoutedPropertyChangedEventHandler<double>';

    // ★ 추가: Window 전용 이벤트 델리게이트
    'Closing':
      Result := 'System.ComponentModel.CancelEventHandler';

    'Closed', 'ContentRendered', 'Activated', 'Deactivated',
    'StateChanged', 'LocationChanged', 'Initialized':
      Result := 'System.EventHandler';
  else
    Result := 'System.EventHandler';
  end;
end;

// -----------------------------------------------------------------------------
// GetEventParamType
//   이벤트 핸들러의 두 번째 파라미터(e) 타입을 반환한다.
// -----------------------------------------------------------------------------
function GetEventParamType(ctrlType: string; evName: string): string;
begin
  case evName of
    'Click', 'Checked', 'Unchecked', 'Loaded', 'Unloaded',
    'GotFocus', 'LostFocus', 'LayoutUpdated':
      Result := 'System.Windows.RoutedEventArgs';

    'MouseDown', 'MouseUp', 'PreviewMouseDown', 'PreviewMouseUp',
    'DoubleClick':
      Result := 'System.Windows.Input.MouseButtonEventArgs';

    'MouseMove', 'MouseEnter', 'MouseLeave':
      Result := 'System.Windows.Input.MouseEventArgs';

    'MouseWheel':
      Result := 'System.Windows.Input.MouseWheelEventArgs';

    'KeyDown', 'KeyUp', 'PreviewKeyDown', 'PreviewKeyUp':
      Result := 'System.Windows.Input.KeyEventArgs';

    'TextChanged':
      Result := 'System.Windows.Controls.TextChangedEventArgs';

    'SelectionChanged':
      Result := 'System.Windows.Controls.SelectionChangedEventArgs';

    'ValueChanged':
      Result := 'System.Windows.RoutedPropertyChangedEventArgs<double>';

    'SizeChanged':
      Result := 'System.Windows.SizeChangedEventArgs';

    'ScrollChanged':
      Result := 'System.Windows.Controls.ScrollChangedEventArgs';

    'DragEnter', 'DragLeave', 'DragOver', 'Drop':
      Result := 'System.Windows.DragEventArgs';

    // ★ 추가: Window 전용 이벤트 파라미터 타입
    //   Closing → CancelEventArgs  (e.Cancel := true 로 닫기 취소 가능)
    //   나머지  → EventArgs
    'Closing':
      Result := 'System.ComponentModel.CancelEventArgs';

    'Closed', 'ContentRendered', 'Activated', 'Deactivated',
    'StateChanged', 'LocationChanged', 'Initialized':
      Result := 'System.EventArgs';
  else
    Result := 'System.EventArgs';
  end;
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