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
    'SelectedItemChanged', 'NodeExpanded', 'NodeCollapsed'
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

end.