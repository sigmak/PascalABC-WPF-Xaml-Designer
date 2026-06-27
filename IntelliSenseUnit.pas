unit IntelliSenseUnit;

// =============================================================================
// IntelliSenseUnit.pas  —  Pascal / XAML 에디터 인텔리센스
//
// AvalonEdit 내장 CodeCompletion API 사용 (별도 DLL 불필요):
//   ICSharpCode.AvalonEdit.CodeCompletion.CompletionWindow
//   ICSharpCode.AvalonEdit.CodeCompletion.ICompletionData
//
// 지원 기능:
//   [Pascal 에디터]
//     • '.' 입력  → 컨트롤명/Self/타입별 멤버 목록
//     • Ctrl+Space → 컨텍스트 자동완성 (키워드 + 컨트롤명)
//   [XAML 에디터]
//     • '<' 입력  → WPF 태그 목록
//     • ' ' 입력  → 현재 태그의 속성/이벤트 목록
//     • '="' 입력 → 이벤트면 기존 핸들러 목록
// =============================================================================

interface

{$reference AvalonEdit.6.3.1.120\lib\net462\ICSharpCode.AvalonEdit.dll}

uses
  System.Collections.Generic,
  ICSharpCode.AvalonEdit,
  ICSharpCode.AvalonEdit.CodeCompletion,
  ICSharpCode.AvalonEdit.Document,
  WpfEventMap,
  ControlInfo,
  NamespaceReflection;

// -----------------------------------------------------------------------------
// TCompletionItem  —  ICompletionData 구현체
// -----------------------------------------------------------------------------
type
  TCompletionItem = class(System.Object, ICompletionData)
  private
    fText        : string;
    fDescription : string;
    fIcon        : System.Windows.Media.ImageSource;
    fPriority    : double;
  public
    constructor Create(text, description: string); overload;
    constructor Create(text, description: string; priority: double); overload;

    function GetContent: System.Object;
    function GetDescription: System.Object;

    // ICompletionData
    property Image      : System.Windows.Media.ImageSource read fIcon;
    property Text       : string read fText;
    property Content    : System.Object read GetContent;
    property Description: System.Object read GetDescription;
    property Priority   : double read fPriority;
    procedure Complete(textArea: ICSharpCode.AvalonEdit.Editing.TextArea;
                       completionSegment: ISegment;
                       e: System.EventArgs);
  end;

// -----------------------------------------------------------------------------
// TPascalIntelliSense  —  Pascal 코드 에디터 인텔리센스 관리자
// -----------------------------------------------------------------------------
type
  TPascalIntelliSense = class
  private
    fEditor          : TextEditor;
    fCompletionWindow: CompletionWindow;
    fClassName       : string;          // 현재 생성된 클래스명 (예: MainWindow)
    fControls        : System.Collections.Generic.List<TControlInfo>; // 현재 컨트롤 목록

    procedure OnTextEntered(sender: System.Object;
                            e: System.Windows.Input.TextCompositionEventArgs);
    procedure OnTextEntering(sender: System.Object;
                             e: System.Windows.Input.TextCompositionEventArgs);
    procedure OnKeyDown(sender: System.Object;
                        e: System.Windows.Input.KeyEventArgs);
    procedure ShowDotCompletion(wordBefore: string);
    procedure ShowKeywordCompletion(prefix: string);
    procedure CloseCompletion;
    function  GetWordBeforeDot: string;
    function  GetWordBeforeCursor: string;
    function  BuildMemberList(typeName: string):
                System.Collections.Generic.List<ICompletionData>;
    function  BuildWindowMembers:
                System.Collections.Generic.List<ICompletionData>;
    function  BuildControlMembers(typeName: string):
                System.Collections.Generic.List<ICompletionData>;
    function  BuildReflectionMembers(path: string):
                System.Collections.Generic.List<ICompletionData>;
  public
    constructor Create(editor: TextEditor);
    procedure SetContext(className: string;
                         controls: System.Collections.Generic.List<TControlInfo>);
    procedure Detach;
  end;

// -----------------------------------------------------------------------------
// TXamlIntelliSense  —  XAML 에디터 인텔리센스 관리자
// -----------------------------------------------------------------------------
type
  TXamlIntelliSense = class
  private
    fEditor          : TextEditor;
    fCompletionWindow: CompletionWindow;
    fCodeText        : string;          // 현재 Pascal 코드 (핸들러명 추출용)

    procedure OnTextEntered(sender: System.Object;
                            e: System.Windows.Input.TextCompositionEventArgs);
    procedure OnTextEntering(sender: System.Object;
                             e: System.Windows.Input.TextCompositionEventArgs);
    procedure CloseCompletion;
    function  GetCurrentTagName: string;
    function  GetAlreadyUsedAttrs: System.Collections.Generic.List<string>;
    procedure ShowTagCompletion;
    procedure ShowAttributeCompletion(tagName: string);
    procedure ShowHandlerCompletion(eventName: string);
    function  ExtractHandlerNames(eventName: string):
                System.Collections.Generic.List<string>;
    function  BuildTagList:
                System.Collections.Generic.List<ICompletionData>;
    function  BuildAttributeList(tagName: string;
                                  usedAttrs: System.Collections.Generic.List<string>):
                System.Collections.Generic.List<ICompletionData>;
  public
    constructor Create(editor: TextEditor);
    procedure SetCodeText(code: string);
    procedure Detach;
  end;

implementation

// =============================================================================
// 공통 데이터 — WPF 타입별 멤버, 태그, 속성 테이블
// =============================================================================

// Pascal 키워드
const PASCAL_KEYWORDS: array of string = [
  'begin', 'end', 'if', 'then', 'else', 'for', 'to', 'downto', 'do',
  'while', 'repeat', 'until', 'case', 'of', 'var', 'const', 'type',
  'procedure', 'function', 'constructor', 'destructor', 'class', 'record',
  'array', 'string', 'integer', 'boolean', 'double', 'single', 'char',
  'nil', 'true', 'false', 'not', 'and', 'or', 'xor', 'mod', 'div',
  'inherited', 'override', 'virtual', 'abstract', 'sealed',
  'try', 'except', 'finally', 'raise', 'exit', 'result',
  'foreach', 'in', 'new', 'uses', 'unit', 'interface', 'implementation',
  'Self', 'System'
];

// WPF 태그 목록
const XAML_TAGS: array of string = [
  'Window', 'UserControl', 'Page', 'Grid', 'StackPanel', 'WrapPanel',
  'DockPanel', 'Canvas', 'Border', 'ScrollViewer', 'Expander', 'GroupBox',
  'Button', 'RepeatButton', 'ToggleButton', 'RadioButton', 'CheckBox',
  'Label', 'TextBlock', 'TextBox', 'PasswordBox', 'RichTextBox',
  'ComboBox', 'ComboBoxItem', 'ListBox', 'ListBoxItem',
  'ListView', 'ListViewItem', 'GridView', 'GridViewColumn',
  'DataGrid', 'DataGridTextColumn', 'DataGridCheckBoxColumn',
  'TreeView', 'TreeViewItem',
  'TabControl', 'TabItem',
  'Slider', 'ScrollBar', 'ProgressBar',
  'Image', 'Rectangle', 'Ellipse', 'Line', 'Path', 'Polygon', 'Polyline',
  'Menu', 'MenuItem', 'ContextMenu', 'Separator', 'ToolBar', 'StatusBar',
  'DatePicker', 'Calendar',
  'Frame', 'InkCanvas', 'Viewbox', 'UniformGrid',
  'Grid.RowDefinitions', 'Grid.ColumnDefinitions',
  'RowDefinition', 'ColumnDefinition',
  'Grid.Row', 'Grid.Column', 'Grid.RowSpan', 'Grid.ColumnSpan',
  'StackPanel.Orientation',
  'Window.Resources', 'UserControl.Resources', 'Grid.Resources',
  'Style', 'Setter', 'Trigger', 'DataTrigger',
  'SolidColorBrush', 'LinearGradientBrush', 'RadialGradientBrush',
  'GradientStop', 'BitmapImage', 'ImageBrush',
  'ControlTemplate', 'DataTemplate', 'ItemsPanelTemplate'
];

// 공통 속성 (모든 FrameworkElement)
const COMMON_ATTRS: array of string = [
  'x:Name', 'Width', 'Height', 'MinWidth', 'MinHeight', 'MaxWidth', 'MaxHeight',
  'Margin', 'Padding', 'HorizontalAlignment', 'VerticalAlignment',
  'HorizontalContentAlignment', 'VerticalContentAlignment',
  'Visibility', 'IsEnabled', 'Opacity', 'Background', 'Foreground',
  'FontFamily', 'FontSize', 'FontWeight', 'FontStyle',
  'Cursor', 'Tag', 'ToolTip',
  'Style', 'Template', 'Resources',
  'RenderTransform', 'RenderTransformOrigin', 'LayoutTransform',
  'Panel.ZIndex', 'Grid.Row', 'Grid.Column', 'Grid.RowSpan', 'Grid.ColumnSpan',
  'DockPanel.Dock', 'Canvas.Left', 'Canvas.Top', 'Canvas.Right', 'Canvas.Bottom'
];

// 공통 이벤트 (모든 FrameworkElement)
const COMMON_EVENT_ATTRS: array of string = [
  'Loaded', 'Unloaded', 'GotFocus', 'LostFocus', 'SizeChanged',
  'MouseDown', 'MouseUp', 'MouseMove', 'MouseEnter', 'MouseLeave',
  'MouseWheel', 'PreviewMouseDown', 'PreviewMouseUp',
  'KeyDown', 'KeyUp', 'PreviewKeyDown', 'PreviewKeyUp',
  'DragEnter', 'DragLeave', 'DragOver', 'Drop',
  'ContextMenuOpening', 'ToolTipOpening'
];

// 타입별 고유 속성
function GetTypeSpecificAttrs(tagName: string): array of string;
begin
  case tagName of
    'Button', 'RepeatButton':
      Result := ['Content', 'IsDefault', 'IsCancel', 'Click'];
    'ToggleButton', 'CheckBox', 'RadioButton':
      Result := ['Content', 'IsChecked', 'GroupName', 'Checked', 'Unchecked'];
    'TextBox', 'RichTextBox':
      Result := ['Text', 'IsReadOnly', 'MaxLength', 'TextWrapping',
                 'AcceptsReturn', 'AcceptsTab', 'TextAlignment',
                 'TextChanged', 'SelectionChanged'];
    'PasswordBox':
      Result := ['PasswordChar', 'MaxLength', 'PasswordChanged'];
    'Label':
      Result := ['Content', 'Target'];
    'TextBlock':
      Result := ['Text', 'TextWrapping', 'TextTrimming', 'TextDecorations',
                 'LineHeight', 'Inlines'];
    'ComboBox':
      Result := ['ItemsSource', 'SelectedItem', 'SelectedIndex', 'SelectedValue',
                 'DisplayMemberPath', 'IsEditable', 'IsReadOnly', 'Text',
                 'SelectionChanged', 'DropDownOpened', 'DropDownClosed'];
    'ListBox', 'ListView':
      Result := ['ItemsSource', 'SelectedItem', 'SelectedIndex', 'SelectedItems',
                 'SelectionMode', 'DisplayMemberPath',
                 'SelectionChanged'];
    'DataGrid':
      Result := ['ItemsSource', 'SelectedItem', 'AutoGenerateColumns',
                 'CanUserAddRows', 'CanUserDeleteRows', 'CanUserSortColumns',
                 'IsReadOnly', 'HeadersVisibility', 'GridLinesVisibility',
                 'SelectionMode', 'SelectionUnit',
                 'SelectionChanged', 'CellEditEnding', 'RowEditEnding'];
    'TreeView':
      Result := ['ItemsSource', 'SelectedItem', 'SelectedItemChanged'];
    'Slider':
      Result := ['Value', 'Minimum', 'Maximum', 'SmallChange', 'LargeChange',
                 'TickFrequency', 'TickPlacement', 'IsSnapToTickEnabled',
                 'Orientation', 'IsDirectionReversed', 'ValueChanged'];
    'ProgressBar':
      Result := ['Value', 'Minimum', 'Maximum', 'IsIndeterminate', 'Orientation'];
    'Image':
      Result := ['Source', 'Stretch', 'StretchDirection'];
    'ScrollViewer':
      Result := ['HorizontalScrollBarVisibility', 'VerticalScrollBarVisibility',
                 'CanContentScroll', 'PanningMode', 'ScrollChanged'];
    'Grid':
      Result := ['ShowGridLines'];
    'StackPanel':
      Result := ['Orientation'];
    'WrapPanel':
      Result := ['Orientation', 'ItemWidth', 'ItemHeight'];
    'DockPanel':
      Result := ['LastChildFill'];
    'Canvas':
      Result := ['ClipToBounds'];
    'Border':
      Result := ['BorderBrush', 'BorderThickness', 'CornerRadius', 'Child'];
    'Expander':
      Result := ['Header', 'IsExpanded', 'ExpandDirection',
                 'Expanded', 'Collapsed'];
    'GroupBox':
      Result := ['Header'];
    'TabControl':
      Result := ['SelectedIndex', 'SelectedItem', 'TabStripPlacement',
                 'SelectionChanged'];
    'TabItem':
      Result := ['Header', 'IsSelected'];
    'Window':
      Result := ['Title', 'Width', 'Height', 'Left', 'Top',
                 'WindowStyle', 'WindowState', 'ResizeMode',
                 'ShowInTaskbar', 'Topmost', 'Icon', 'Owner',
                 'SizeToContent', 'AllowsTransparency',
                 'Closing', 'Closed', 'Activated', 'Deactivated',
                 'ContentRendered', 'StateChanged', 'LocationChanged'];
    'UserControl':
      Result := [];
  else
    Result := [];
  end;
end;

// Window 멤버 (Self. 이후)
const WINDOW_MEMBERS: array of string = [
  // 속성
  'Title', 'Width', 'Height', 'Left', 'Top',
  'WindowStyle', 'WindowState', 'ResizeMode',
  'Background', 'Foreground', 'FontFamily', 'FontSize', 'FontWeight',
  'IsEnabled', 'Visibility', 'Opacity', 'ShowInTaskbar', 'Topmost',
  'Content', 'DataContext', 'Resources', 'Tag', 'Icon',
  'MinWidth', 'MinHeight', 'MaxWidth', 'MaxHeight',
  'ActualWidth', 'ActualHeight', 'SizeToContent',
  'AllowsTransparency', 'Owner',
  // 메서드
  'Show()', 'ShowDialog()', 'Close()', 'Hide()',
  'Activate()', 'Focus()',
  'DragMove()', 'InvalidateVisual()',
  'FindName()', 'RegisterName()',
  'BeginInit()', 'EndInit()',
  // 이벤트
  'Loaded +=', 'Closing +=', 'Closed +=',
  'Activated +=', 'Deactivated +=',
  'ContentRendered +=', 'StateChanged +=', 'LocationChanged +='
];

// Button/Control 공통 멤버
const CONTROL_MEMBERS_COMMON: array of string = [
  'Width', 'Height', 'MinWidth', 'MinHeight', 'MaxWidth', 'MaxHeight',
  'Margin', 'Padding', 'HorizontalAlignment', 'VerticalAlignment',
  'Background', 'Foreground', 'FontFamily', 'FontSize', 'FontWeight',
  'IsEnabled', 'Visibility', 'Opacity', 'Tag', 'ToolTip',
  'Focus()', 'InvalidateVisual()',
  'ActualWidth', 'ActualHeight', 'DataContext',
  'Loaded +=', 'GotFocus +=', 'LostFocus +='
];

// 타입별 고유 멤버
function GetTypeMembersSpecific(typeName: string): array of string;
begin
  case typeName of
    'Button', 'RepeatButton':
      Result := ['Content', 'IsDefault', 'IsCancel',
                 'Click +='];
    'CheckBox', 'RadioButton', 'ToggleButton':
      Result := ['Content', 'IsChecked', 'IsThreeState',
                 'Checked +=', 'Unchecked +=', 'Click +='];
    'TextBox':
      Result := ['Text', 'IsReadOnly', 'MaxLength', 'CaretIndex',
                 'SelectionStart', 'SelectionLength', 'SelectedText',
                 'TextWrapping', 'AcceptsReturn', 'AcceptsTab',
                 'Select()', 'SelectAll()', 'Clear()', 'AppendText()',
                 'TextChanged +=', 'SelectionChanged +='];
    'PasswordBox':
      Result := ['Password', 'MaxLength', 'PasswordChar',
                 'Clear()', 'SelectAll()',
                 'PasswordChanged +='];
    'Label', 'TextBlock':
      Result := ['Content', 'Text', 'TextWrapping', 'TextTrimming'];
    'ComboBox':
      Result := ['Items', 'ItemsSource', 'SelectedItem', 'SelectedIndex',
                 'SelectedValue', 'IsDropDownOpen', 'IsEditable', 'Text',
                 'SelectionChanged +=', 'DropDownOpened +=', 'DropDownClosed +='];
    'ListBox', 'ListView':
      Result := ['Items', 'ItemsSource', 'SelectedItem', 'SelectedIndex',
                 'SelectedItems', 'SelectionMode',
                 'ScrollIntoView()', 'UnselectAll()',
                 'SelectionChanged +='];
    'DataGrid':
      Result := ['Items', 'ItemsSource', 'SelectedItem', 'SelectedIndex',
                 'SelectedItems', 'Columns', 'CurrentItem',
                 'AutoGenerateColumns', 'IsReadOnly',
                 'CommitEdit()', 'CancelEdit()', 'BeginEdit()',
                 'SelectionChanged +=', 'CellEditEnding +='];
    'TreeView':
      Result := ['Items', 'ItemsSource', 'SelectedItem',
                 'SelectedItemChanged +='];
    'Slider':
      Result := ['Value', 'Minimum', 'Maximum', 'SmallChange', 'LargeChange',
                 'TickFrequency', 'IsSnapToTickEnabled',
                 'ValueChanged +='];
    'ProgressBar':
      Result := ['Value', 'Minimum', 'Maximum', 'IsIndeterminate'];
    'Image':
      Result := ['Source', 'Stretch'];
    'ScrollViewer':
      Result := ['HorizontalOffset', 'VerticalOffset',
                 'ScrollableWidth', 'ScrollableHeight',
                 'ScrollToTop()', 'ScrollToBottom()',
                 'ScrollToLeftEnd()', 'ScrollToRightEnd()',
                 'ScrollToHorizontalOffset()', 'ScrollToVerticalOffset()',
                 'ScrollChanged +='];
    'Grid', 'StackPanel', 'WrapPanel', 'DockPanel', 'Canvas':
      Result := ['Children'];
    'Border':
      Result := ['Child', 'BorderBrush', 'BorderThickness', 'CornerRadius'];
    'TabControl':
      Result := ['Items', 'SelectedItem', 'SelectedIndex', 'SelectedContent',
                 'SelectionChanged +='];
    'TabItem':
      Result := ['Header', 'Content', 'IsSelected'];
    'Expander':
      Result := ['Header', 'Content', 'IsExpanded',
                 'Expanded +=', 'Collapsed +='];
    'GroupBox':
      Result := ['Header', 'Content'];
    'Menu', 'ContextMenu':
      Result := ['Items'];
    'MenuItem':
      Result := ['Header', 'IsChecked', 'IsEnabled', 'Icon', 'InputGestureText',
                 'Click +='];
  else
    Result := [];
  end;
end;

// =============================================================================
// TCompletionItem 구현
// =============================================================================

constructor TCompletionItem.Create(text, description: string);
begin
  fText        := text;
  fDescription := description;
  fPriority    := 0.0;
end;

constructor TCompletionItem.Create(text, description: string; priority: double);
begin
  fText        := text;
  fDescription := description;
  fPriority    := priority;
end;

function TCompletionItem.GetContent: System.Object;
begin
  Result := fText;
end;

function TCompletionItem.GetDescription: System.Object;
begin
  Result := fDescription;
end;

procedure TCompletionItem.Complete(
  textArea: ICSharpCode.AvalonEdit.Editing.TextArea;
  completionSegment: ISegment;
  e: System.EventArgs);
var
  insertText: string;
begin
  insertText := fText;

  // "+=" 이벤트 구독 패턴: "Click +=" → 삽입 후 커서를 핸들러명 입력 위치로
  // "()" 메서드 패턴: 괄호 안에 커서
  textArea.Document.Replace(completionSegment, insertText);

  // "()" 인 경우 커서를 괄호 안으로 이동
  if insertText.EndsWith('()') then
    textArea.Caret.Offset := textArea.Caret.Offset - 1;
end;

// =============================================================================
// TPascalIntelliSense 구현
// =============================================================================

constructor TPascalIntelliSense.Create(editor: TextEditor);
begin
  fEditor   := editor;
  fControls := new System.Collections.Generic.List<TControlInfo>();
  fEditor.TextArea.TextEntered  += OnTextEntered;
  fEditor.TextArea.TextEntering += OnTextEntering;
  fEditor.TextArea.PreviewKeyDown += OnKeyDown;
end;

procedure TPascalIntelliSense.SetContext(
  className: string;
  controls: System.Collections.Generic.List<TControlInfo>);
begin
  fClassName := className;
  fControls  := controls;
end;

procedure TPascalIntelliSense.Detach;
begin
  fEditor.TextArea.TextEntered    -= OnTextEntered;
  fEditor.TextArea.TextEntering   -= OnTextEntering;
  fEditor.TextArea.PreviewKeyDown -= OnKeyDown;
end;

procedure TPascalIntelliSense.CloseCompletion;
begin
  if fCompletionWindow <> nil then
  begin
    fCompletionWindow.Close();
    fCompletionWindow := nil;
  end;
end;

// '.' 직전의 경로 전체를 추출 (예: "btnOk." → "btnOk", "System.Windows." → "System.Windows")
// 점으로 이어진 여러 세그먼트(식별자.식별자.식별자...)를 통째로 역방향 탐색한다.
function TPascalIntelliSense.GetWordBeforeDot: string;
var
  offset: integer;
  doc   : TextDocument;
  sb    : System.Text.StringBuilder;
  ch    : char;
begin
  Result := '';
  doc    := fEditor.Document;
  // 현재 캐럿 기준으로 '.' 바로 앞까지 역방향 탐색
  offset := fEditor.CaretOffset - 2; // -1 은 '.' 자체, -2 부터 단어 시작
  if offset < 0 then exit;

  sb := new System.Text.StringBuilder();
  while offset >= 0 do
  begin
    ch := doc.GetCharAt(offset);
    if System.Char.IsLetterOrDigit(ch) or (ch = '_') then
    begin
      sb.Insert(0, ch);
      offset -= 1;
    end
    else if (ch = '.') and (offset > 0) and
            (System.Char.IsLetterOrDigit(doc.GetCharAt(offset - 1)) or
             (doc.GetCharAt(offset - 1) = '_')) then
    begin
      // 세그먼트 경계의 '.' → 경로에 포함시키고 계속 역탐색
      sb.Insert(0, ch);
      offset -= 1;
    end
    else
      break;
  end;
  Result := sb.ToString();
end;

// 커서 바로 앞 단어 (자동완성 필터링용)
function TPascalIntelliSense.GetWordBeforeCursor: string;
var
  offset: integer;
  doc   : TextDocument;
  sb    : System.Text.StringBuilder;
  ch    : char;
begin
  Result := '';
  doc    := fEditor.Document;
  offset := fEditor.CaretOffset - 1;
  if offset < 0 then exit;

  sb := new System.Text.StringBuilder();
  while offset >= 0 do
  begin
    ch := doc.GetCharAt(offset);
    if System.Char.IsLetterOrDigit(ch) or (ch = '_') then
    begin
      sb.Insert(0, ch);
      offset -= 1;
    end
    else break;
  end;
  Result := sb.ToString();
end;

procedure TPascalIntelliSense.OnTextEntered(
  sender: System.Object;
  e: System.Windows.Input.TextCompositionEventArgs);
var
  wordBefore: string;
begin
  if e.Text = '.' then
  begin
    wordBefore := GetWordBeforeDot();
    if wordBefore <> '' then
      ShowDotCompletion(wordBefore);
  end;
end;

procedure TPascalIntelliSense.OnTextEntering(
  sender: System.Object;
  e: System.Windows.Input.TextCompositionEventArgs);
begin
  // 완성창이 열린 상태에서 공백/세미콜론이 입력되면 닫기
  if (fCompletionWindow <> nil) and (Length(e.Text) > 0) then
  begin
    var ch := e.Text[1];
    if not (System.Char.IsLetterOrDigit(ch) or (ch = '_') or (ch = '.')) then
      CloseCompletion();
  end;
end;

procedure TPascalIntelliSense.OnKeyDown(
  sender: System.Object;
  e: System.Windows.Input.KeyEventArgs);
begin
  // Ctrl+Space → 키워드/컨트롤명 자동완성
  if (e.Key = System.Windows.Input.Key.Space) and
     (System.Windows.Input.Keyboard.Modifiers =
      System.Windows.Input.ModifierKeys.Control) then
  begin
    e.Handled := true;
    ShowKeywordCompletion(GetWordBeforeCursor());
  end;

  // Escape → 닫기
  if e.Key = System.Windows.Input.Key.Escape then
    CloseCompletion();
end;

function TPascalIntelliSense.BuildWindowMembers:
  System.Collections.Generic.List<ICompletionData>;
var
  list: System.Collections.Generic.List<ICompletionData>;
begin
  list := new System.Collections.Generic.List<ICompletionData>();
  foreach var m in WINDOW_MEMBERS do
    list.Add(new TCompletionItem(m, 'Window.' + m));
  Result := list;
end;

function TPascalIntelliSense.BuildControlMembers(typeName: string):
  System.Collections.Generic.List<ICompletionData>;
var
  list: System.Collections.Generic.List<ICompletionData>;
begin
  list := new System.Collections.Generic.List<ICompletionData>();
  // 타입별 고유 멤버 먼저 (우선순위 높음)
  foreach var m in GetTypeMembersSpecific(typeName) do
    list.Add(new TCompletionItem(m, typeName + '.' + m, 1.0));
  // 공통 멤버
  foreach var m in CONTROL_MEMBERS_COMMON do
    list.Add(new TCompletionItem(m, 'Control.' + m));
  Result := list;
end;

// 경로(예: 'System', 'System.Windows', 'System.Windows.Application')를 리플렉션
// 인덱스로 해석해서, 네임스페이스면 하위 네임스페이스+타입 목록을,
// 타입이면 실제 멤버(메서드/속성/필드/이벤트) 목록을 자동완성 항목으로 변환.
// 해석에 실패하면(둘 다 아니면) nil 을 반환 — 호출자가 기존 로직으로 폴백하게.
function TPascalIntelliSense.BuildReflectionMembers(path: string):
  System.Collections.Generic.List<ICompletionData>;
var
  list  : System.Collections.Generic.List<ICompletionData>;
  res   : TResolveResult;
begin
  Result := nil;
  res := GlobalReflectionIndex().ResolvePath(path);

  case res.Kind of
    rkNamespace:
      begin
        list := new System.Collections.Generic.List<ICompletionData>();
        foreach var childName in GlobalReflectionIndex().GetChildNames(res.NamespaceNode) do
          list.Add(new TCompletionItem(childName, 'namespace/type: ' + path + '.' + childName));
        Result := list;
      end;

    rkType:
      begin
        list := new System.Collections.Generic.List<ICompletionData>();
        foreach var member in GlobalReflectionIndex().GetTypeMembers(res.ResolvedType) do
          list.Add(new TCompletionItem(member.Name, member.Signature,
            (if member.IsStatic then 1.0 else 0.8)));
        Result := list;
      end;

  else
    Result := nil; // rkNone → 해석 실패, 호출자가 폴백
  end;
end;

function TPascalIntelliSense.BuildMemberList(typeName: string):
  System.Collections.Generic.List<ICompletionData>;
begin
  // Self. 또는 클래스명. → Window 멤버
  if string.Equals(typeName, 'Self', System.StringComparison.OrdinalIgnoreCase) or
     string.Equals(typeName, fClassName, System.StringComparison.OrdinalIgnoreCase) then
    Result := BuildWindowMembers()
  else
    Result := BuildControlMembers(typeName);
end;

procedure TPascalIntelliSense.ShowDotCompletion(wordBefore: string);
var
  items   : System.Collections.Generic.List<ICompletionData>;
  ctrl    : TControlInfo;
  typeName: string;
  reflItems: System.Collections.Generic.List<ICompletionData>;
begin
  CloseCompletion();

  // Self / 클래스명은 항상 우선 — 리플렉션과 겹칠 일이 없음
  if string.Equals(wordBefore, 'Self', System.StringComparison.OrdinalIgnoreCase) or
     string.Equals(wordBefore, fClassName, System.StringComparison.OrdinalIgnoreCase) then
  begin
    items := BuildMemberList('Self');
    if (items = nil) or (items.Count = 0) then exit;
  end
  else
  begin
    // 컨트롤 목록에서 x:Name 매칭 먼저 시도 (btnOk. 처럼 단일 식별자인 경우만 해당)
    typeName := '';
    if (not wordBefore.Contains('.')) and (fControls <> nil) then
      foreach ctrl in fControls do
        if string.Equals(ctrl.Name, wordBefore, System.StringComparison.OrdinalIgnoreCase) then
        begin typeName := ctrl.TypeName; break; end;

    if typeName <> '' then
      items := BuildControlMembers(typeName)
    else
    begin
      // 컨트롤이 아니면 네임스페이스/타입 경로로 간주하고 리플렉션 인덱스에 질의
      // (예: 'System', 'System.Windows', 'System.Windows.Application')
      reflItems := BuildReflectionMembers(wordBefore);
      if reflItems <> nil then
        items := reflItems
      else
        // 리플렉션도 실패 → 기존 폴백(타입명 그대로 시도)
        items := BuildMemberList(wordBefore);
    end;
  end;

  if (items = nil) or (items.Count = 0) then exit;

  fCompletionWindow := new CompletionWindow(fEditor.TextArea);
  fCompletionWindow.MinWidth := 280;
  var data := fCompletionWindow.CompletionList.CompletionData;
  foreach var item in items do
    data.Add(item);

  fCompletionWindow.Show();
  fCompletionWindow.Closed += procedure(s: System.Object; ev: System.EventArgs) ->
  begin fCompletionWindow := nil; end;
end;

procedure TPascalIntelliSense.ShowKeywordCompletion(prefix: string);
var
  items: System.Collections.Generic.List<ICompletionData>;
  ctrl : TControlInfo;
begin
  CloseCompletion();
  items := new System.Collections.Generic.List<ICompletionData>();

  // 1) Pascal 키워드
  foreach var kw in PASCAL_KEYWORDS do
    if (prefix = '') or kw.ToLower().StartsWith(prefix.ToLower()) then
      items.Add(new TCompletionItem(kw, 'keyword'));

  // 2) 컨트롤명 (x:Name)
  if fControls <> nil then
    foreach ctrl in fControls do
      if (prefix = '') or ctrl.Name.ToLower().StartsWith(prefix.ToLower()) then
        items.Add(new TCompletionItem(ctrl.Name,
          ctrl.TypeName + ' (control)', 1.0));

  // 3) 클래스명
  if fClassName <> '' then
    if (prefix = '') or fClassName.ToLower().StartsWith(prefix.ToLower()) then
      items.Add(new TCompletionItem(fClassName, 'class'));

  if items.Count = 0 then exit;

  fCompletionWindow := new CompletionWindow(fEditor.TextArea);
  fCompletionWindow.MinWidth := 260;
  var data := fCompletionWindow.CompletionList.CompletionData;
  foreach var item in items do
    data.Add(item);

  // prefix 로 미리 필터링
  if prefix <> '' then
    fCompletionWindow.CompletionList.SelectItem(prefix);

  fCompletionWindow.Show();
  fCompletionWindow.Closed += procedure(s: System.Object; ev: System.EventArgs) ->
  begin fCompletionWindow := nil; end;
end;

// =============================================================================
// TXamlIntelliSense 구현
// =============================================================================

constructor TXamlIntelliSense.Create(editor: TextEditor);
begin
  fEditor := editor;
  fEditor.TextArea.TextEntered  += OnTextEntered;
  fEditor.TextArea.TextEntering += OnTextEntering;
end;

procedure TXamlIntelliSense.SetCodeText(code: string);
begin
  fCodeText := code;
end;

procedure TXamlIntelliSense.Detach;
begin
  fEditor.TextArea.TextEntered  -= OnTextEntered;
  fEditor.TextArea.TextEntering -= OnTextEntering;
end;

procedure TXamlIntelliSense.CloseCompletion;
begin
  if fCompletionWindow <> nil then
  begin
    fCompletionWindow.Close();
    fCompletionWindow := nil;
  end;
end;

// 커서 앞에서 현재 열린 태그명을 역방향 탐색으로 추출
// 예: "<Button Width=" → "Button"
function TXamlIntelliSense.GetCurrentTagName: string;
var
  doc   : TextDocument;
  offset: integer;
  sb    : System.Text.StringBuilder;
  ch    : char;
  inTag : boolean;
begin
  Result := '';
  doc    := fEditor.Document;
  offset := fEditor.CaretOffset - 1;
  inTag  := false;

  // 공백/속성 건너뛰기 → '<TagName' 찾기
  while offset >= 0 do
  begin
    ch := doc.GetCharAt(offset);
    if ch = '<' then
    begin inTag := true; break; end;
    if ch = '>' then exit; // 이미 닫힌 태그
    offset -= 1;
  end;

  if not inTag then exit;
  offset += 1; // '<' 다음 위치

  // 태그명 수집
  sb := new System.Text.StringBuilder();
  while offset < doc.TextLength do
  begin
    ch := doc.GetCharAt(offset);
    if System.Char.IsLetterOrDigit(ch) or (ch = '_') or (ch = ':') then
    begin sb.Append(ch); offset += 1; end
    else break;
  end;
  Result := sb.ToString();

  // "local:MyControl" → "MyControl" (로컬 prefix 제거)
  var colonPos := Result.IndexOf(':');
  if colonPos >= 0 then
    Result := Result.Substring(colonPos + 1);
end;

// 현재 태그에서 이미 사용된 속성명 목록
function TXamlIntelliSense.GetAlreadyUsedAttrs:
  System.Collections.Generic.List<string>;
var
  doc   : TextDocument;
  offset: integer;
  tagStart, tagEnd: integer;
  tagText: string;
  re    : System.Text.RegularExpressions.Regex;
  mc    : System.Text.RegularExpressions.MatchCollection;
  m     : System.Text.RegularExpressions.Match;
  list  : System.Collections.Generic.List<string>;
begin
  list   := new System.Collections.Generic.List<string>();
  doc    := fEditor.Document;
  offset := fEditor.CaretOffset;

  // 태그 시작 '<' 찾기
  tagStart := offset;
  while tagStart >= 0 do
  begin
    if doc.GetCharAt(tagStart) = '<' then break;
    tagStart -= 1;
  end;
  if tagStart < 0 then begin Result := list; exit; end;

  // 태그 끝 '>' 찾기 (커서 위치까지만)
  tagEnd := tagStart;
  while (tagEnd < doc.TextLength) and (tagEnd < offset) do
  begin
    if doc.GetCharAt(tagEnd) = '>' then break;
    tagEnd += 1;
  end;

  tagText := doc.GetText(tagStart, tagEnd - tagStart);

  re := new System.Text.RegularExpressions.Regex(
    '([\w:\.]+)\s*=\s*"[^"]*"');
  mc := re.Matches(tagText);
  foreach m in mc do
    list.Add(m.Groups[1].Value);

  Result := list;
end;

// Pascal 코드에서 기존 핸들러명 추출 (이벤트="..." 자동완성용)
function TXamlIntelliSense.ExtractHandlerNames(eventName: string):
  System.Collections.Generic.List<string>;
var
  list: System.Collections.Generic.List<string>;
  re  : System.Text.RegularExpressions.Regex;
  mc  : System.Text.RegularExpressions.MatchCollection;
  m   : System.Text.RegularExpressions.Match;
begin
  list := new System.Collections.Generic.List<string>();
  if fCodeText = '' then begin Result := list; exit; end;

  // Pascal 코드에서 "procedure ClassName.HandlerName" 패턴 추출
  re := new System.Text.RegularExpressions.Regex(
    'procedure\s+\w+\.(\w+)\s*\(sender');
  mc := re.Matches(fCodeText);
  foreach m in mc do
  begin
    var name := m.Groups[1].Value;
    // 이벤트명을 포함하는 핸들러만 필터링 (예: Closing → window1_Closing)
    if (eventName = '') or
       name.ToLower().Contains(eventName.ToLower()) then
      list.Add(name);
  end;
  Result := list;
end;

function TXamlIntelliSense.BuildTagList:
  System.Collections.Generic.List<ICompletionData>;
var
  list: System.Collections.Generic.List<ICompletionData>;
begin
  list := new System.Collections.Generic.List<ICompletionData>();
  foreach var tag in XAML_TAGS do
    list.Add(new TCompletionItem(tag, 'WPF element <' + tag + '>'));
  Result := list;
end;

function TXamlIntelliSense.BuildAttributeList(
  tagName: string;
  usedAttrs: System.Collections.Generic.List<string>):
  System.Collections.Generic.List<ICompletionData>;
var
  list    : System.Collections.Generic.List<ICompletionData>;
  specific: array of string;
begin
  list := new System.Collections.Generic.List<ICompletionData>();

  // 타입별 고유 속성/이벤트 먼저 (우선순위 높음)
  specific := GetTypeSpecificAttrs(tagName);
  foreach var attr in specific do
  begin
    if usedAttrs.Contains(attr) then continue;
    var isEvent := IsWpfEvent(attr);
    var desc    := (if isEvent then '[Event] ' else '[Property] ') + tagName + '.' + attr;
    list.Add(new TCompletionItem(attr + '="', desc,
      (if isEvent then 0.5 else 1.0)));
  end;

  // 공통 속성
  foreach var attr in COMMON_ATTRS do
  begin
    if usedAttrs.Contains(attr) then continue;
    list.Add(new TCompletionItem(attr + '="',
      '[Property] FrameworkElement.' + attr));
  end;

  // 공통 이벤트
  foreach var attr in COMMON_EVENT_ATTRS do
  begin
    if usedAttrs.Contains(attr) then continue;
    list.Add(new TCompletionItem(attr + '="',
      '[Event] FrameworkElement.' + attr, 0.5));
  end;

  Result := list;
end;

procedure TXamlIntelliSense.ShowTagCompletion;
var
  items: System.Collections.Generic.List<ICompletionData>;
begin
  CloseCompletion();
  items := BuildTagList();
  if items.Count = 0 then exit;

  fCompletionWindow := new CompletionWindow(fEditor.TextArea);
  fCompletionWindow.MinWidth := 240;
  var data := fCompletionWindow.CompletionList.CompletionData;
  foreach var item in items do
    data.Add(item);

  fCompletionWindow.Show();
  fCompletionWindow.Closed += procedure(s: System.Object; ev: System.EventArgs) ->
  begin fCompletionWindow := nil; end;
end;

procedure TXamlIntelliSense.ShowAttributeCompletion(tagName: string);
var
  items    : System.Collections.Generic.List<ICompletionData>;
  usedAttrs: System.Collections.Generic.List<string>;
begin
  if tagName = '' then exit;
  CloseCompletion();

  usedAttrs := GetAlreadyUsedAttrs();
  items     := BuildAttributeList(tagName, usedAttrs);
  if items.Count = 0 then exit;

  fCompletionWindow := new CompletionWindow(fEditor.TextArea);
  fCompletionWindow.MinWidth := 320;
  var data := fCompletionWindow.CompletionList.CompletionData;
  foreach var item in items do
    data.Add(item);

  fCompletionWindow.Show();
  fCompletionWindow.Closed += procedure(s: System.Object; ev: System.EventArgs) ->
  begin fCompletionWindow := nil; end;
end;

procedure TXamlIntelliSense.ShowHandlerCompletion(eventName: string);
var
  names: System.Collections.Generic.List<string>;
  items: System.Collections.Generic.List<ICompletionData>;
begin
  CloseCompletion();
  names := ExtractHandlerNames(eventName);
  if names.Count = 0 then exit;

  items := new System.Collections.Generic.List<ICompletionData>();
  foreach var name in names do
    items.Add(new TCompletionItem(name,
      'Existing handler: ' + name));

  fCompletionWindow := new CompletionWindow(fEditor.TextArea);
  fCompletionWindow.MinWidth := 240;
  var data := fCompletionWindow.CompletionList.CompletionData;
  foreach var item in items do
    data.Add(item);

  fCompletionWindow.Show();
  fCompletionWindow.Closed += procedure(s: System.Object; ev: System.EventArgs) ->
  begin fCompletionWindow := nil; end;
end;

procedure TXamlIntelliSense.OnTextEntered(
  sender: System.Object;
  e: System.Windows.Input.TextCompositionEventArgs);
var
  tagName : string;
  doc     : TextDocument;
  offset  : integer;
  ch2prev : char;
begin
  doc    := fEditor.Document;
  offset := fEditor.CaretOffset;

  case e.Text of
    '<':
      // 태그 시작 → 태그 목록
      ShowTagCompletion();

    ' ':
      begin
        // 태그 안에서 공백 → 속성/이벤트 목록
        tagName := GetCurrentTagName();
        if tagName <> '' then
          ShowAttributeCompletion(tagName);
      end;

    '"':
      begin
        // '="' 입력 직후 → 이벤트면 핸들러 목록
        // 커서 앞 2글자가 '="' 인지 확인 후 이벤트명 역탐색
        if offset >= 2 then
        begin
          ch2prev := doc.GetCharAt(offset - 2);
          if ch2prev = '=' then
          begin
            // 이벤트명 역방향 추출 (예: "Closing=" → "Closing")
            var evOffset := offset - 2;
            var evSb := new System.Text.StringBuilder();
            evOffset -= 1;
            while evOffset >= 0 do
            begin
              var evCh := doc.GetCharAt(evOffset);
              if System.Char.IsLetterOrDigit(evCh) or (evCh = '_') then
              begin evSb.Insert(0, evCh); evOffset -= 1; end
              else break;
            end;
            var evName := evSb.ToString();
            if IsWpfEvent(evName) then
              ShowHandlerCompletion(evName);
          end;
        end;
      end;
  end;
end;

procedure TXamlIntelliSense.OnTextEntering(
  sender: System.Object;
  e: System.Windows.Input.TextCompositionEventArgs);
begin
  if (fCompletionWindow <> nil) and (Length(e.Text) > 0) then
  begin
    var ch := e.Text[1];
    // 공백, '>', '/', '"' 가 아닌 이상 열린 채로 필터링 계속
    if (ch = '>') or (ch = '/') then
      CloseCompletion();
  end;
end;

end.