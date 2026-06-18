unit Unit1;
{$reference ICSharpCode.WpfDesign.dll}
{$reference ICSharpCode.WpfDesign.Designer.dll}
{$reference ICSharpCode.WpfDesign.XamlDom.dll}
{$reference PresentationFramework.dll}
{$reference PresentationCore.dll}
{$reference WindowsBase.dll}
{$reference System.Windows.Forms.dll}
{$reference WindowsFormsIntegration.dll}

uses
  System.Windows.Forms,
  System.Collections.Generic,
  ICSharpCode.WpfDesign;

type
  Form1 = class(System.Windows.Forms.Form)
  private
    fSurface : ICSharpCode.WpfDesign.Designer.DesignSurface;
    fPropView: ICSharpCode.WpfDesign.Designer.PropertyGrid.PropertyGridView;

    menuStrip     : System.Windows.Forms.MenuStrip;
    hostDesign    : System.Windows.Forms.Integration.ElementHost;
    hostLeft      : System.Windows.Forms.Integration.ElementHost;
    hostRight     : System.Windows.Forms.Integration.ElementHost;
    fToolboxPanel : System.Windows.Controls.StackPanel;
    splitContainer: System.Windows.Forms.SplitContainer;
    txtXaml       : System.Windows.Forms.RichTextBox;
    btnApply      : System.Windows.Forms.Button;
    lineNumPanel    : System.Windows.Forms.Panel;      // 라인번호 패널
    editorTable     : System.Windows.Forms.TableLayoutPanel; // 에디터 영역 레이아웃
    menuItemLineNum   : System.Windows.Forms.ToolStripMenuItem;
    fShowLineNumbers  : boolean;                       // 라인번호 표시 여부
    fHighlighting     : boolean;                       // 하이라이트 활성 여부
    fInHighlight      : boolean;                       // 재진입 방지 플래그
    menuItemHighlight : System.Windows.Forms.ToolStripMenuItem;

    procedure BuildMenu;
    procedure BuildToolbox;
    procedure BuildLayout;
    procedure ConnectEvents;

    procedure OnToolboxClick(sender: System.Object; e: System.Windows.RoutedEventArgs); // ← 별도 핸들러
    // 선언부에서 시그니처 변경
    procedure OnSelectionChanged(sender: System.Object; e: ICSharpCode.WpfDesign.DesignItemCollectionEventArgs);
    procedure OnUndoStackChanged(sender: System.Object; e: System.EventArgs);
    procedure OnSave(sender: System.Object; e: System.EventArgs);
    procedure OnOpen(sender: System.Object; e: System.EventArgs);
    procedure OnApplyXaml(sender: System.Object; e: System.EventArgs);  // RoutedEventArgs → EventArgs    
    
    procedure OnSyncXamlMenu(sender: System.Object; e: System.EventArgs);  // 메뉴용 WinForms
    procedure OnToggleLineNumbers(sender: System.Object; e: System.EventArgs);
    procedure OnToggleHighlight(sender: System.Object; e: System.EventArgs);
    procedure OnXamlVScroll(sender: System.Object; e: System.EventArgs);
    procedure OnXamlTextChanged(sender: System.Object; e: System.EventArgs);
    procedure ApplyHighlight;

    procedure OnLineNumPaint(sender: System.Object; e: System.Windows.Forms.PaintEventArgs);
    procedure UpdateLineNumbers;
    procedure SyncLineNumberScroll;
    procedure OnAbout(sender: System.Object; e: System.EventArgs);
    
    procedure LoadXaml(xaml: string);
    procedure SyncXamlEditor;
    function  SaveDesignerToString: string;
    function  StripCustomNamespaces(xaml: string): string;
    function  PreprocessXaml(xaml: string): string;
  public
    constructor Create;
  end;

// ─────────────────────────────────────────────
constructor Form1.Create;
begin
  inherited Create;
  Self.Text   := 'PascalABC-WPF-Xaml-Designer Ver 1.1.3';
  Self.Width  := 1500;
  Self.Height := 900;

  ICSharpCode.WpfDesign.Designer.BasicMetadata.Register();

  BuildToolbox;
  BuildLayout;
  BuildMenu;

  fHighlighting  := true;   // 구문 강조 기본 활성
  fInHighlight   := false;

  LoadXaml(
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
    '      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"' +
    '      Background="White" Width="600" Height="400">' +
    '  <Button Width="100" Height="30" Content="Hello"' +
    '          HorizontalAlignment="Left" VerticalAlignment="Top"' +
    '          Margin="20,20,0,0"/>' +
    '</Grid>'
  );
end;

// ─────────────────────────────────────────────
// 디자이너 내용을 인덴트된 XAML 문자열로 반환
function Form1.SaveDesignerToString: string;
var
  sw        : System.IO.StringWriter;
  xwSettings: System.Xml.XmlWriterSettings;
  xw        : System.Xml.XmlWriter;
begin
  if fSurface.DesignContext = nil then
  begin
    Result := '';
    exit;
  end;
  sw            := new System.IO.StringWriter();
  xwSettings    := new System.Xml.XmlWriterSettings();
  xwSettings.Indent      := true;
  xwSettings.IndentChars := '  ';
  xw := System.Xml.XmlWriter.Create(sw, xwSettings);
  fSurface.SaveDesigner(xw);
  xw.Flush();
  Result := sw.ToString();
end;

// ─────────────────────────────────────────────
// 하단 XAML 에디터를 디자이너 현재 상태로 동기화
procedure Form1.SyncXamlEditor;
var
  s: string;
begin
  s := SaveDesignerToString();
  if s <> '' then
  begin
    txtXaml.Text := s;
    ApplyHighlight();
  end;
end;

// ─────────────────────────────────────────────
// clr-namespace 커스텀 xmlns 제거 + 본문의 커스텀 prefix 사용도 제거
// 처리 순서:
//   1) xmlns:xx="clr-namespace:..." 속성 목록 수집
//   2) 해당 prefix를 사용하는 엘리먼트 태그 전체 제거  (<vm:Foo .../>  <vm:Foo>...</vm:Foo>)
//   3) 해당 prefix를 사용하는 속성값/Converter 참조 제거
//   4) xmlns 선언 자체 제거
function Form1.StripCustomNamespaces(xaml: string): string;
var
  prefixes : System.Collections.Generic.List<string>;
  m        : System.Text.RegularExpressions.Match;
  re       : System.Text.RegularExpressions.Regex;
  prefix   : string;
  pattern  : string;
  s        : string;
begin
  s        := xaml;
  prefixes := new System.Collections.Generic.List<string>();

  // ① clr-namespace xmlns 선언에서 prefix 목록 수집
  re := new System.Text.RegularExpressions.Regex(
    'xmlns:(\w+)="clr-namespace:[^"]*"');
  m := re.Match(s);
  while m.Success do
  begin
    prefixes.Add(m.Groups[1].Value);
    m := m.NextMatch();
  end;

  // ② 각 prefix에 대해 본문 사용 제거
  foreach prefix in prefixes do
  begin
    // 2-a) 자기완결 엘리먼트 제거: <prefix:Foo ... />
    pattern := '<' + prefix + ':[^>]*/>';
    s := System.Text.RegularExpressions.Regex.Replace(s, pattern, '');

    // 2-b) 시작+끝 태그 쌍 제거: <prefix:Foo ...>...</prefix:Foo>
    pattern := '<' + prefix + ':[^>]*>[\s\S]*?</' + prefix + ':[^>]*>';
    s := System.Text.RegularExpressions.Regex.Replace(s, pattern, '');

    // 2-c) 속성값에 사용된 커스텀 타입 참조 제거
    //      예) Converter={StaticResource FileSizeConverter}  → 속성 전체 제거
    //          {x:Type prefix:Foo}  → 빈 문자열
    pattern := '\s+\w[\w.]*="\{[^"]*' + prefix + ':[^"]*\}"';
    s := System.Text.RegularExpressions.Regex.Replace(s, pattern, '');

    // 2-d) xmlns 선언 제거
    pattern := '\s+xmlns:' + prefix + '="clr-namespace:[^"]*"';
    s := System.Text.RegularExpressions.Regex.Replace(s, pattern, '');
  end;

  Result := s;
end;

// ─────────────────────────────────────────────
// A. 메뉴바 (저장/열기/동기화)
procedure Form1.BuildMenu;
var
  fileMenu, saveItem, openItem, syncItem: System.Windows.Forms.ToolStripMenuItem;
  viewMenu: System.Windows.Forms.ToolStripMenuItem;
  helpMenu, aboutItem: System.Windows.Forms.ToolStripMenuItem;
begin
  menuStrip := new System.Windows.Forms.MenuStrip();

  // ── 파일 메뉴 ──
  fileMenu := new System.Windows.Forms.ToolStripMenuItem('파일(&F)');
  openItem := new System.Windows.Forms.ToolStripMenuItem('열기(&O)');
  saveItem := new System.Windows.Forms.ToolStripMenuItem('저장(&S)');
  syncItem := new System.Windows.Forms.ToolStripMenuItem('XAML 동기화(&X)');

  openItem.Click += OnOpen;
  saveItem.Click += OnSave;
  syncItem.Click += OnSyncXamlMenu;

  fileMenu.DropDownItems.Add(openItem);
  fileMenu.DropDownItems.Add(saveItem);
  fileMenu.DropDownItems.Add(new System.Windows.Forms.ToolStripSeparator());
  fileMenu.DropDownItems.Add(syncItem);

  // ── 보기 메뉴 ──
  viewMenu              := new System.Windows.Forms.ToolStripMenuItem('보기(&V)');
  menuItemLineNum       := new System.Windows.Forms.ToolStripMenuItem('라인 번호 표시(&L)');
  menuItemLineNum.CheckOnClick := true;
  menuItemLineNum.Checked      := false;
  menuItemLineNum.Click        += OnToggleLineNumbers;

  menuItemHighlight     := new System.Windows.Forms.ToolStripMenuItem('구문 강조 표시(&H)');
  menuItemHighlight.CheckOnClick := true;
  menuItemHighlight.Checked      := true;   // 기본값: 활성
  menuItemHighlight.Click        += OnToggleHighlight;

  viewMenu.DropDownItems.Add(menuItemLineNum);
  viewMenu.DropDownItems.Add(menuItemHighlight);

  // Help 메뉴
  helpMenu          := new System.Windows.Forms.ToolStripMenuItem('도움말(&H)');
  aboutItem         := new System.Windows.Forms.ToolStripMenuItem('정보(&A)...');
  aboutItem.Click  += OnAbout;
  helpMenu.DropDownItems.Add(aboutItem);

  menuStrip.Items.Add(fileMenu);
  menuStrip.Items.Add(viewMenu);
  menuStrip.Items.Add(helpMenu);
  Self.Controls.Add(menuStrip);
  Self.MainMenuStrip := menuStrip;
end;

// ─────────────────────────────────────────────
// 왼쪽 Toolbox (Expander 버전)
procedure Form1.BuildToolbox;
var
  scroll      : System.Windows.Controls.ScrollViewer;
  title       : System.Windows.Controls.TextBlock;
  expLayout   : System.Windows.Controls.Expander;
  expCommon   : System.Windows.Controls.Expander;
  panelLayout : System.Windows.Controls.StackPanel;
  panelCommon : System.Windows.Controls.StackPanel;

  procedure AddBtn(panel: System.Windows.Controls.StackPanel;
                   name: string; typeName: string);
  var
    btn : System.Windows.Controls.Button;
    sp  : System.Windows.Controls.StackPanel;
    icon: System.Windows.Controls.TextBlock;
    lbl : System.Windows.Controls.TextBlock;
  begin
    sp             := new System.Windows.Controls.StackPanel();
    sp.Orientation := System.Windows.Controls.Orientation.Horizontal;

    icon                   := new System.Windows.Controls.TextBlock();
    icon.FontFamily        := new System.Windows.Media.FontFamily('Segoe UI Symbol');
    icon.FontSize          := 13;
    icon.Width             := 20;
    icon.TextAlignment     := System.Windows.TextAlignment.Center;
    icon.VerticalAlignment := System.Windows.VerticalAlignment.Center;
    icon.Margin            := new System.Windows.Thickness(2, 0, 4, 0);
    case name of
      'Grid'        : icon.Text := '▦';
      'StackPanel'  : icon.Text := '☰';
      'Canvas'      : icon.Text := '▭';
      'DockPanel'   : icon.Text := '⊞';
      'Button'      : icon.Text := '⬜';
      'TextBox'     : icon.Text := '▤';
      'Label'       : icon.Text := 'A';
      'CheckBox'    : icon.Text := '☑';
      'ComboBox'    : icon.Text := '⊟';
      'ListBox'     : icon.Text := '≡';
      'Image'       : icon.Text := '▨';
      'TextBlock'   : icon.Text := 'T';
      'Slider'      : icon.Text := '⊸';
      'ProgressBar' : icon.Text := '▬';
      'RadioButton' : icon.Text := '◎';
      'Border'      : icon.Text := '▢';
    else
      icon.Text := '◆';
    end;

    lbl                   := new System.Windows.Controls.TextBlock();
    lbl.Text              := name;
    lbl.FontSize          := 12;
    lbl.VerticalAlignment := System.Windows.VerticalAlignment.Center;

    sp.Children.Add(icon);
    sp.Children.Add(lbl);

    btn                            := new System.Windows.Controls.Button();
    btn.Content                    := sp;
    btn.Tag                        := typeName;
    btn.Margin                     := new System.Windows.Thickness(1);
    btn.Padding                    := new System.Windows.Thickness(4, 3, 4, 3);
    btn.HorizontalAlignment        := System.Windows.HorizontalAlignment.Stretch;
    btn.HorizontalContentAlignment := System.Windows.HorizontalAlignment.Left;
    btn.BorderThickness            := new System.Windows.Thickness(0);
    btn.Background                 := System.Windows.Media.Brushes.Transparent;
    btn.Click                      += OnToolboxClick;
    panel.Children.Add(btn);
  end;

  function MakeExpander(header: string): System.Windows.Controls.Expander;
  var
    exp: System.Windows.Controls.Expander;
    hdr: System.Windows.Controls.TextBlock;
  begin
    hdr            := new System.Windows.Controls.TextBlock();
    hdr.Text       := header;
    hdr.FontWeight := System.Windows.FontWeights.Bold;
    hdr.FontSize   := 12;
    hdr.Foreground := new System.Windows.Media.SolidColorBrush(
      System.Windows.Media.Color.FromRgb(30, 30, 30));

    exp            := new System.Windows.Controls.Expander();
    exp.Header     := hdr;
    exp.IsExpanded := true;
    exp.Margin     := new System.Windows.Thickness(0, 2, 0, 2);
    Result         := exp;
  end;

begin
  fToolboxPanel            := new System.Windows.Controls.StackPanel();
  fToolboxPanel.Background := System.Windows.Media.Brushes.White;

  title            := new System.Windows.Controls.TextBlock();
  title.Text       := '도구 상자';
  title.FontSize   := 13;
  title.FontWeight := System.Windows.FontWeights.Bold;
  title.Padding    := new System.Windows.Thickness(6);
  title.Background := new System.Windows.Media.SolidColorBrush(
    System.Windows.Media.Color.FromRgb(240, 240, 240));
  fToolboxPanel.Children.Add(title);

  panelLayout        := new System.Windows.Controls.StackPanel();
  panelLayout.Margin := new System.Windows.Thickness(8, 2, 0, 2);
  AddBtn(panelLayout, 'Grid',       'System.Windows.Controls.Grid');
  AddBtn(panelLayout, 'StackPanel', 'System.Windows.Controls.StackPanel');
  AddBtn(panelLayout, 'Canvas',     'System.Windows.Controls.Canvas');
  AddBtn(panelLayout, 'DockPanel',  'System.Windows.Controls.DockPanel');

  expLayout         := MakeExpander('레이아웃');
  expLayout.Content := panelLayout;
  fToolboxPanel.Children.Add(expLayout);

  panelCommon        := new System.Windows.Controls.StackPanel();
  panelCommon.Margin := new System.Windows.Thickness(8, 2, 0, 2);
  AddBtn(panelCommon, 'Button',      'System.Windows.Controls.Button');
  AddBtn(panelCommon, 'TextBox',     'System.Windows.Controls.TextBox');
  AddBtn(panelCommon, 'Label',       'System.Windows.Controls.Label');
  AddBtn(panelCommon, 'CheckBox',    'System.Windows.Controls.CheckBox');
  AddBtn(panelCommon, 'ComboBox',    'System.Windows.Controls.ComboBox');
  AddBtn(panelCommon, 'ListBox',     'System.Windows.Controls.ListBox');
  AddBtn(panelCommon, 'Image',       'System.Windows.Controls.Image');
  AddBtn(panelCommon, 'TextBlock',   'System.Windows.Controls.TextBlock');
  AddBtn(panelCommon, 'Slider',      'System.Windows.Controls.Slider');
  AddBtn(panelCommon, 'ProgressBar', 'System.Windows.Controls.ProgressBar');
  AddBtn(panelCommon, 'RadioButton', 'System.Windows.Controls.RadioButton');
  AddBtn(panelCommon, 'Border',      'System.Windows.Controls.Border');

  expCommon         := MakeExpander('공용 컨트롤');
  expCommon.Content := panelCommon;
  fToolboxPanel.Children.Add(expCommon);

  scroll         := new System.Windows.Controls.ScrollViewer();
  scroll.Content := fToolboxPanel;
  scroll.VerticalScrollBarVisibility :=
    System.Windows.Controls.ScrollBarVisibility.Auto;

  hostLeft       := new System.Windows.Forms.Integration.ElementHost();
  hostLeft.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostLeft.Child := scroll;
end;

// ─────────────────────────────────────────────
// 툴박스 클릭 → 루트에 컨트롤 추가
procedure Form1.OnToolboxClick(sender: System.Object; e: System.Windows.RoutedEventArgs);
var
  tname    : string;
  t        : System.Type;
  inst     : System.Object;
  newItem  : ICSharpCode.WpfDesign.DesignItem;
  rootItem : ICSharpCode.WpfDesign.DesignItem;
  childProp: ICSharpCode.WpfDesign.DesignItemProperty;
  lst: List<DesignItem>;
begin
  if fSurface.DesignContext = nil then exit;

  tname := (sender as System.Windows.Controls.Button).Tag.ToString();

  // AppDomain 전체에서 타입 검색
  t := nil;
  var asms := System.AppDomain.CurrentDomain.GetAssemblies();
  var i := 0;
  while (i < asms.Length) and (t = nil) do
  begin
    t := asms[i].GetType(tname);
    i += 1;
  end;

  if t = nil then
  begin
    System.Windows.Forms.MessageBox.Show('타입을 찾을 수 없습니다: ' + tname);
    exit;
  end;

  try
    inst := System.Activator.CreateInstance(t);
    if inst = nil then exit;

    var services := fSurface.DesignContext.Services;
    rootItem  := fSurface.DesignContext.RootItem;

    // ChangeGroup으로 Undo 지원하며 추가
    var grp     := rootItem.OpenGroup('Add ' + tname);
    newItem := services.Component.RegisterComponentForDesigner(inst);

    // 루트 ContentProperty(Children 컬렉션)에 추가
    childProp := rootItem.ContentProperty;
    if childProp <> nil then
    begin
      if childProp.IsCollection then
        childProp.CollectionElements.Add(newItem)
      else
        childProp.SetValue(newItem);
    end;

    grp.Commit();

    var arr := new ICSharpCode.WpfDesign.DesignItem[1];
//    arr[0]  := newItem;
//    services.Selection.SetSelectedComponents(arr);
    lst := new List<DesignItem>;
    
    foreach var item in arr do
      lst.Add(item);
  
    services.Selection.SetSelectedComponents(
      ICollection&<DesignItem>(lst)
    );

    // XAML 에디터 즉시 동기화
    SyncXamlEditor();

  except
    on ex: System.Exception do
      System.Windows.Forms.MessageBox.Show('컨트롤 추가 실패: ' + ex.Message);
  end;
end;

// ─────────────────────────────────────────────
// 레이아웃
procedure Form1.BuildLayout;
var
  topPanel   : System.Windows.Forms.TableLayoutPanel;
  mainPanel  : System.Windows.Forms.Panel;
begin
  // PropertyGridView 생성
  fPropView := new ICSharpCode.WpfDesign.Designer.PropertyGrid.PropertyGridView();

  hostRight       := new System.Windows.Forms.Integration.ElementHost();
  hostRight.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostRight.Child := fPropView;

  // 디자이너 호스트
  hostDesign      := new System.Windows.Forms.Integration.ElementHost();
  hostDesign.Dock := System.Windows.Forms.DockStyle.Fill;

  // 상단 3분할: Toolbox | Designer | Properties
  topPanel             := new System.Windows.Forms.TableLayoutPanel();
  topPanel.Dock        := System.Windows.Forms.DockStyle.Fill;
  topPanel.ColumnCount := 3;
  topPanel.RowCount    := 1;
  topPanel.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(
    System.Windows.Forms.SizeType.Absolute, 160));
  topPanel.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(
    System.Windows.Forms.SizeType.Percent, 100));
  topPanel.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(
    System.Windows.Forms.SizeType.Absolute, 280));
  topPanel.RowStyles.Add(new System.Windows.Forms.RowStyle(
    System.Windows.Forms.SizeType.Percent, 100));
  topPanel.Controls.Add(hostLeft,   0, 0);
  topPanel.Controls.Add(hostDesign, 1, 0);
  topPanel.Controls.Add(hostRight,  2, 0);

  // C. 하단 XAML 에디터
  txtXaml            := new System.Windows.Forms.RichTextBox();
  txtXaml.Font       := new System.Drawing.Font('Consolas', 9);
  txtXaml.Dock       := System.Windows.Forms.DockStyle.Fill;
  txtXaml.ScrollBars := System.Windows.Forms.RichTextBoxScrollBars.Both;
  txtXaml.WordWrap   := false;
  txtXaml.VScroll     += OnXamlVScroll;
  txtXaml.TextChanged += OnXamlTextChanged;

  // ── 라인번호 패널 (Paint 이벤트로 직접 그림) ──
  lineNumPanel           := new System.Windows.Forms.Panel();
  lineNumPanel.Dock      := System.Windows.Forms.DockStyle.Fill;
  lineNumPanel.BackColor := System.Drawing.Color.FromArgb(240, 240, 240);
  lineNumPanel.Visible   := true;
  lineNumPanel.Paint     += OnLineNumPaint;

  // ── 적용 버튼 ──
  btnApply        := new System.Windows.Forms.Button();
  btnApply.Text   := '▶ XAML 적용';
  btnApply.Dock   := System.Windows.Forms.DockStyle.Fill;
  btnApply.Click  += OnApplyXaml;

  // ── 에디터 영역 TableLayoutPanel ──
  //   행0(Auto): 버튼
  //   행1(*):    라인번호 | txtXaml
  editorTable             := new System.Windows.Forms.TableLayoutPanel();
  editorTable.Dock        := System.Windows.Forms.DockStyle.Fill;
  editorTable.ColumnCount := 2;
  editorTable.RowCount    := 2;
  editorTable.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(
    System.Windows.Forms.SizeType.Absolute, 0));   // 라인번호 열 (초기 숨김=0)
  editorTable.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(
    System.Windows.Forms.SizeType.Percent, 100));  // 에디터 열
  editorTable.RowStyles.Add(new System.Windows.Forms.RowStyle(
    System.Windows.Forms.SizeType.Absolute, 30));  // 버튼 행
  editorTable.RowStyles.Add(new System.Windows.Forms.RowStyle(
    System.Windows.Forms.SizeType.Percent, 100));  // 에디터 행
  // 버튼: 열0~1 병합, 행0
  editorTable.Controls.Add(btnApply, 0, 0);
  editorTable.SetColumnSpan(btnApply, 2);
  // 라인번호: 열0, 행1
  editorTable.Controls.Add(lineNumPanel, 0, 1);
  // 에디터: 열1, 행1
  editorTable.Controls.Add(txtXaml, 1, 1);

  // SplitContainer: 위=디자이너 영역 / 아래=XAML 에디터
  splitContainer                  := new System.Windows.Forms.SplitContainer();
  splitContainer.Dock             := System.Windows.Forms.DockStyle.Fill;
  splitContainer.Orientation      := System.Windows.Forms.Orientation.Horizontal;
  splitContainer.SplitterDistance := 580;
  splitContainer.Panel1.Controls.Add(topPanel);
  splitContainer.Panel2.Controls.Add(editorTable);

  mainPanel      := new System.Windows.Forms.Panel();
  mainPanel.Dock := System.Windows.Forms.DockStyle.Fill;
  mainPanel.Controls.Add(splitContainer);

  Self.Controls.Add(mainPanel);
end;

// ─────────────────────────────────────────────
// XAML 로드 + 이벤트 연결
procedure Form1.LoadXaml(xaml: string);
var
  strReader: System.IO.StringReader;
  xmlReader: System.Xml.XmlReader;
  settings : ICSharpCode.WpfDesign.Designer.Xaml.XamlLoadSettings;
  scroll   : System.Windows.Controls.ScrollViewer;
begin
  fSurface  := new ICSharpCode.WpfDesign.Designer.DesignSurface();
  settings  := new ICSharpCode.WpfDesign.Designer.Xaml.XamlLoadSettings();
  strReader := new System.IO.StringReader(xaml);
  xmlReader := new System.Xml.XmlTextReader(strReader);
  fSurface.LoadDesigner(xmlReader, settings);

  scroll := new System.Windows.Controls.ScrollViewer();
  scroll.HorizontalScrollBarVisibility :=
    System.Windows.Controls.ScrollBarVisibility.Auto;
  scroll.VerticalScrollBarVisibility :=
    System.Windows.Controls.ScrollBarVisibility.Auto;
  scroll.Content   := fSurface;
  hostDesign.Child := scroll;

  ConnectEvents();
  SyncXamlEditor();
end;

// ─────────────────────────────────────────────
// 이벤트 연결
procedure Form1.ConnectEvents;
var
  undoSvc: ICSharpCode.WpfDesign.Designer.Services.UndoService;
begin
  if fSurface.DesignContext = nil then exit;

  // 선택 변경 → PropertyGrid 갱신
  fSurface.DesignContext.Services.Selection.SelectionChanged += OnSelectionChanged;

  // UndoService 변경 → XAML 에디터 자동 동기화
  // 드래그/크기변경/속성변경 등 모든 디자인 변경을 감지함
  undoSvc := fSurface.DesignContext.Services.GetService(
    typeof(ICSharpCode.WpfDesign.Designer.Services.UndoService)
  ) as ICSharpCode.WpfDesign.Designer.Services.UndoService;

  if undoSvc <> nil then
    undoSvc.UndoStackChanged += OnUndoStackChanged;
end;

// ─────────────────────────────────────────────
// 선택 변경 → PropertyGrid 업데이트
procedure Form1.OnSelectionChanged(sender: System.Object;
  e: ICSharpCode.WpfDesign.DesignItemCollectionEventArgs);
begin
  if fSurface.DesignContext = nil then exit;
  fPropView.SelectedItems :=
    fSurface.DesignContext.Services.Selection.SelectedItems;
end;

// ─────────────────────────────────────────────
// 디자인 변경(드래그/크기/속성) → XAML 자동 동기화
procedure Form1.OnUndoStackChanged(sender: System.Object; e: System.EventArgs);
begin
  SyncXamlEditor();
end;

// ─────────────────────────────────────────────
procedure Form1.OnSave(sender: System.Object; e: System.EventArgs);
var
  dlg : System.Windows.Forms.SaveFileDialog;
  xaml: string;
begin
  if fSurface.DesignContext = nil then exit;
  dlg          := new System.Windows.Forms.SaveFileDialog();
  dlg.Filter   := 'XAML 파일|*.xaml|모든 파일|*.*';
  dlg.FileName := 'design.xaml';
  if dlg.ShowDialog() = System.Windows.Forms.DialogResult.OK then
  begin
    xaml := SaveDesignerToString();
    if xaml <> '' then
    begin
      System.IO.File.WriteAllText(dlg.FileName, xaml);
      System.Windows.Forms.MessageBox.Show('저장 완료: ' + dlg.FileName);
    end;
  end;
end;

// ─────────────────────────────────────────────
// Window/UserControl XAML → 디자이너용 Grid XAML 로 변환
// OnOpen 과 OnApplyXaml 양쪽에서 공통 사용
function Form1.PreprocessXaml(xaml: string): string;
var
  cleanedXaml : string;
  doc         : System.Xml.XmlDocument;
  root        : System.Xml.XmlElement;
  nsMgr       : System.Xml.XmlNamespaceManager;
  resNode     : System.Xml.XmlNode;
  resourcesXml: string;
  inner       : string;
  nodesToRemove: System.Collections.Generic.List<System.Xml.XmlNode>;
  node        : System.Xml.XmlNode;
begin
  Result := xaml; // 변환 불필요 시 원본 반환

  if not (xaml.Contains('<Window ') or xaml.Contains('<UserControl ')) then
    exit;

  // ① clr-namespace prefix 선언 + 본문 사용 전체 제거
  cleanedXaml := StripCustomNamespaces(xaml);

  doc := new System.Xml.XmlDocument();
  doc.LoadXml(cleanedXaml);
  root := doc.DocumentElement;

  nsMgr := new System.Xml.XmlNamespaceManager(doc.NameTable);
  nsMgr.AddNamespace('wpf',
    'http://schemas.microsoft.com/winfx/2006/xaml/presentation');

  // ② Window.Resources → Grid.Resources 로 이식
  resNode      := root.SelectSingleNode('wpf:Window.Resources', nsMgr);
  resourcesXml := '';
  if resNode <> nil then
    resourcesXml := '<Grid.Resources>' + resNode.InnerXml + '</Grid.Resources>';

  // ③ Window.* / UserControl.* 자식 노드 전체 제거
  //    (DataContext, Resources, Style, InputBindings 등)
  nodesToRemove := new System.Collections.Generic.List<System.Xml.XmlNode>();
  foreach node in root.ChildNodes do
  begin
    var localName := node.LocalName;
    if localName.StartsWith('Window.') or localName.StartsWith('UserControl.') then
      nodesToRemove.Add(node);
  end;
  foreach node in nodesToRemove do
    root.RemoveChild(node);

  inner := root.InnerXml;

  Result :=
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
    '      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' +
    resourcesXml +
    inner +
    '</Grid>';
end;

// ─────────────────────────────────────────────
procedure Form1.OnOpen(sender: System.Object; e: System.EventArgs);
var
  dlg : System.Windows.Forms.OpenFileDialog;
  xaml: string;
begin
  dlg        := new System.Windows.Forms.OpenFileDialog();
  dlg.Filter := 'XAML 파일|*.xaml|모든 파일|*.*';
  if dlg.ShowDialog() <> System.Windows.Forms.DialogResult.OK then exit;

  try
    xaml := System.IO.File.ReadAllText(dlg.FileName);
  except
    on ex: System.Exception do
    begin
      System.Windows.Forms.MessageBox.Show('파일 읽기 오류: ' + ex.Message);
      exit;
    end;
  end;

  try
    xaml := PreprocessXaml(xaml);
  except
    on ex: System.Exception do
    begin
      System.Windows.Forms.MessageBox.Show('XAML 전처리 오류: ' + ex.Message);
      exit;
    end;
  end;

  try
    LoadXaml(xaml);
  except
    on ex: System.Exception do
      System.Windows.Forms.MessageBox.Show('XAML 로드 오류: ' + ex.Message);
  end;
end;

// ─────────────────────────────────────────────
// 하단 XAML → 디자이너 적용
// XAML 에디터에서 붙여넣기 후 적용
// Window/UserControl 루트도 자동 전처리하여 디자이너에 반영
procedure Form1.OnApplyXaml(sender: System.Object; e: System.EventArgs);
var
  xaml: string;
begin
  xaml := txtXaml.Text.Trim();
  if xaml = '' then exit;

  try
    xaml := PreprocessXaml(xaml);  // Window/UserControl이면 Grid로 변환
  except
    on ex: System.Exception do
    begin
      System.Windows.Forms.MessageBox.Show('XAML 전처리 오류: ' + ex.Message);
      exit;
    end;
  end;

  try
    LoadXaml(xaml);
  except
    on ex: System.Exception do
      System.Windows.Forms.MessageBox.Show('XAML 로드 오류: ' + ex.Message);
  end;
end;

// ─────────────────────────────────────────────
// 메뉴: 수동 동기화
procedure Form1.OnSyncXamlMenu(sender: System.Object; e: System.EventArgs);
begin
  SyncXamlEditor();
end;

// ─────────────────────────────────────────────
procedure Form1.OnXamlVScroll(sender: System.Object; e: System.EventArgs);
begin
  SyncLineNumberScroll();
end;

// ─────────────────────────────────────────────
procedure Form1.OnXamlTextChanged(sender: System.Object; e: System.EventArgs);
begin
  UpdateLineNumbers();
  ApplyHighlight();
end;

// ─────────────────────────────────────────────
// 라인번호 패널 Paint 이벤트 — 현재 스크롤 위치에 맞는 줄번호만 그림
procedure Form1.OnLineNumPaint(sender: System.Object; e: System.Windows.Forms.PaintEventArgs);
var
  lineH       : integer;
  firstVisible: integer;
  lastVisible : integer;
  totalLines  : integer;
  i           : integer;
  y           : integer;
  numStr      : string;
  brush       : System.Drawing.SolidBrush;
  fmt         : System.Drawing.StringFormat;
  rect        : System.Drawing.RectangleF;
begin
  lineH      := txtXaml.Font.Height + 1;
  totalLines := txtXaml.Lines.Length;
  if totalLines = 0 then totalLines := 1;

  // 현재 첫 번째 가시 라인 인덱스
  firstVisible := txtXaml.GetLineFromCharIndex(
    txtXaml.GetCharIndexFromPosition(new System.Drawing.Point(0, 0))
  );

  // 마지막 가시 라인 인덱스 (패널 높이 기준)
  lastVisible := firstVisible +
    (lineNumPanel.Height div lineH) + 1;
  if lastVisible >= totalLines then
    lastVisible := totalLines - 1;

  brush := new System.Drawing.SolidBrush(
    System.Drawing.Color.FromArgb(120, 120, 120));
  fmt             := new System.Drawing.StringFormat();
  fmt.Alignment   := System.Drawing.StringAlignment.Far;   // 오른쪽 정렬
  fmt.LineAlignment := System.Drawing.StringAlignment.Center;

  e.Graphics.Clear(System.Drawing.Color.FromArgb(240, 240, 240));

  for i := firstVisible to lastVisible do
  begin
    numStr := (i + 1).ToString();
    y      := (i - firstVisible) * lineH;
    rect   := new System.Drawing.RectangleF(
      0, y, e.ClipRectangle.Width - 4, lineH);
    e.Graphics.DrawString(numStr, txtXaml.Font, brush, rect, fmt);
  end;

  brush.Dispose();
  fmt.Dispose();
end;

// ─────────────────────────────────────────────
// 구문 강조 ON/OFF 토글
procedure Form1.OnToggleHighlight(sender: System.Object; e: System.EventArgs);
begin
  fHighlighting := menuItemHighlight.Checked;
  if fHighlighting then
    ApplyHighlight()
  else
  begin
    // 강조 해제: 전체 텍스트를 기본 색으로 복원
    fInHighlight := true;
    try
      var sel := txtXaml.SelectionStart;
      var len := txtXaml.SelectionLength;
      txtXaml.SelectAll();
      txtXaml.SelectionColor := System.Drawing.Color.Black;
      txtXaml.SelectionStart  := sel;
      txtXaml.SelectionLength := len;
    finally
      fInHighlight := false;
    end;
  end;
end;

// ─────────────────────────────────────────────
// XAML 구문 강조 적용
// 색상 체계:
//   태그명        <Grid  </Grid>          → 파랑  (0,0,205)
//   속성명        Width= Height=          → 빨강  (180,0,0)
//   속성값        "100"  "Center"         → 남색  (0,0,139) + 이탤릭
//   XML 선언/지시 <?xml ...?>             → 회색  (128,128,128)
//   주석          <!-- ... -->            → 초록  (0,128,0)
//   꺾쇠/슬래시   < > / =                → 진청  (0,70,180)
procedure Form1.ApplyHighlight;
var
  text    : string;
  selStart: integer;
  selLen  : integer;

  procedure Colorize(pattern: string; col: System.Drawing.Color;
                     italic: boolean; grp: integer);
  var
    re: System.Text.RegularExpressions.Regex;
    m : System.Text.RegularExpressions.Match;
    s, l: integer;
  begin
    re := new System.Text.RegularExpressions.Regex(pattern);
    m  := re.Match(text);
    while m.Success do
    begin
      if grp = 0 then begin s := m.Index;          l := m.Length; end
      else             begin s := m.Groups[grp].Index; l := m.Groups[grp].Length; end;
      txtXaml.SelectionStart  := s;
      txtXaml.SelectionLength := l;
      txtXaml.SelectionColor  := col;
      if italic then
        txtXaml.SelectionFont := new System.Drawing.Font(
          txtXaml.Font, System.Drawing.FontStyle.Italic)
      else
        txtXaml.SelectionFont := txtXaml.Font;
      m := m.NextMatch();
    end;
  end;

begin
  if not fHighlighting then exit;
  if fInHighlight then exit;
  fInHighlight := true;
  txtXaml.SuspendLayout();
  try
    text     := txtXaml.Text;
    selStart := txtXaml.SelectionStart;
    selLen   := txtXaml.SelectionLength;

    // 전체를 기본 색(검정)으로 초기화
    txtXaml.SelectAll();
    txtXaml.SelectionColor := System.Drawing.Color.Black;
    txtXaml.SelectionFont  := txtXaml.Font;

    // ① 주석  <!-- ... -->  (가장 먼저 — 다른 규칙보다 우선)
    Colorize('<!--[\s\S]*?-->', System.Drawing.Color.FromArgb(0, 128, 0), false, 0);

    // ② XML 선언/처리 지시  <? ... ?>
    Colorize('<\?[\s\S]*?\?>', System.Drawing.Color.FromArgb(128, 128, 128), false, 0);

    // ③ 꺾쇠·슬래시  < > / (태그 구조 문자)
    Colorize('[<>/]', System.Drawing.Color.FromArgb(0, 70, 180), false, 0);

    // ④ 태그명  예) Grid  Button  Window.Resources
    Colorize('</?([\w.:]+)', System.Drawing.Color.FromArgb(0, 0, 205), false, 1);

    // ⑤ 속성명  예) Width=  x:Key=
    Colorize('([\w:]+)=', System.Drawing.Color.FromArgb(180, 0, 0), false, 1);

    // ⑥ 속성값  "..."  (이탤릭)
    Colorize('"[^"]*"', System.Drawing.Color.FromArgb(0, 100, 0), true, 0);

    // 커서 위치 복원
    txtXaml.SelectionStart  := selStart;
    txtXaml.SelectionLength := selLen;
    txtXaml.SelectionColor  := System.Drawing.Color.Black;
    txtXaml.SelectionFont   := txtXaml.Font;
  finally
    fInHighlight := false;
    txtXaml.ResumeLayout();
  end;
end;

// ─────────────────────────────────────────────
// 라인번호 표시/숨기기 토글
procedure Form1.OnToggleLineNumbers(sender: System.Object; e: System.EventArgs);
begin
  fShowLineNumbers := menuItemLineNum.Checked;
  if fShowLineNumbers then
  begin
    // 라인번호 열 너비 복원 (자릿수에 맞게 UpdateLineNumbers 가 조정)
    editorTable.ColumnStyles[0].SizeType := System.Windows.Forms.SizeType.Absolute;
    editorTable.ColumnStyles[0].Width    := 40;
    UpdateLineNumbers();
  end
  else
  begin
    // 라인번호 열 너비를 0 으로 축소해 숨김
    editorTable.ColumnStyles[0].SizeType := System.Windows.Forms.SizeType.Absolute;
    editorTable.ColumnStyles[0].Width    := 0;
  end;
end;

// ─────────────────────────────────────────────
// 라인번호 텍스트 갱신
procedure Form1.UpdateLineNumbers;
var
  lineCount: integer;
  digits   : integer;
  colW     : integer;
begin
  if not fShowLineNumbers then exit;

  lineCount := txtXaml.Lines.Length;
  if lineCount = 0 then lineCount := 1;

  // 자릿수에 따라 열 너비 자동 조정
  digits := lineCount.ToString().Length;
  colW   := 14 + digits * 8;
  editorTable.ColumnStyles[0].SizeType := System.Windows.Forms.SizeType.Absolute;
  editorTable.ColumnStyles[0].Width    := colW;

  lineNumPanel.Invalidate();
end;

// ─────────────────────────────────────────────
// txtXaml 스크롤 위치와 라인번호 스크롤 동기화
procedure Form1.SyncLineNumberScroll;
begin
  if not fShowLineNumbers then exit;
  // 스크롤 위치가 바뀌면 Paint 이벤트에서 현재 첫 가시 라인을 다시 계산해 그림
  lineNumPanel.Invalidate();
end;

// Help > About
procedure Form1.OnAbout(sender: System.Object; e: System.EventArgs);
begin
  System.Windows.Forms.MessageBox.Show(
    'PascalABC-WPF-Xaml-Designer' + System.Environment.NewLine +
    'Ver 1.1.3' + System.Environment.NewLine + System.Environment.NewLine +
    'ICSharpCode.WpfDesign.Designer' + System.Environment.NewLine +
    'ICSharpCode.WpfDesign' + System.Environment.NewLine +
    'ICSharpCode.WpfDesign.XamlDom' + System.Environment.NewLine +
    'ICSharpCode.AvalonEdit' + System.Environment.NewLine +
    'avalonedit.6.3.1.120' + System.Environment.NewLine +
    ' 기반 WPF XAML 디자이너' + System.Environment.NewLine + System.Environment.NewLine +
    'Built with PascalABC.NET 3.11.1.3833' + System.Environment.NewLine + System.Environment.NewLine +
    'made by sigmak (dwfree74@gmail.com)',
    '프로그램 정보',
    System.Windows.Forms.MessageBoxButtons.OK,
    System.Windows.Forms.MessageBoxIcon.Information
  );
end;
// ─────────────────────────────────────────────
begin
  System.Threading.Thread.CurrentThread.SetApartmentState(
    System.Threading.ApartmentState.STA
  );
  System.Windows.Forms.Application.EnableVisualStyles();
  System.Windows.Forms.Application.Run(new Form1());
end.