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
    procedure OnAbout(sender: System.Object; e: System.EventArgs);
    
    procedure LoadXaml(xaml: string);
    procedure SyncXamlEditor;
    function  SaveDesignerToString: string;
    function  StripCustomNamespaces(xaml: string): string;
  public
    constructor Create;
  end;

// ─────────────────────────────────────────────
constructor Form1.Create;
begin
  inherited Create;
  Self.Text   := 'PascalABC-WPF-Xaml-Designer Ver 1.1.1';
  Self.Width  := 1500;
  Self.Height := 900;

  ICSharpCode.WpfDesign.Designer.BasicMetadata.Register();

  BuildToolbox;
  BuildLayout;
  BuildMenu;

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
    txtXaml.Text := s;
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
  helpMenu, aboutItem: System.Windows.Forms.ToolStripMenuItem;
begin
  menuStrip := new System.Windows.Forms.MenuStrip();

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


  // Help 메뉴
  helpMenu          := new System.Windows.Forms.ToolStripMenuItem('도움말(&H)');
  aboutItem         := new System.Windows.Forms.ToolStripMenuItem('정보(&A)...');
  aboutItem.Click  += OnAbout;
  helpMenu.DropDownItems.Add(aboutItem);

  menuStrip.Items.Add(fileMenu);
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
  bottomPanel: System.Windows.Forms.Panel;
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

  btnApply        := new System.Windows.Forms.Button();
  btnApply.Text   := '▶ XAML 적용';
  btnApply.Dock   := System.Windows.Forms.DockStyle.Bottom;
  btnApply.Height := 28;
  btnApply.Click  += OnApplyXaml;

  bottomPanel := new System.Windows.Forms.Panel();
  bottomPanel.Dock := System.Windows.Forms.DockStyle.Fill;
  bottomPanel.Controls.Add(txtXaml);
  bottomPanel.Controls.Add(btnApply);

  // SplitContainer: 위=디자이너 영역 / 아래=XAML 에디터
  splitContainer                  := new System.Windows.Forms.SplitContainer();
  splitContainer.Dock             := System.Windows.Forms.DockStyle.Fill;
  splitContainer.Orientation      := System.Windows.Forms.Orientation.Horizontal;
  splitContainer.SplitterDistance := 580;
  splitContainer.Panel1.Controls.Add(topPanel);
  splitContainer.Panel2.Controls.Add(bottomPanel);

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
procedure Form1.OnOpen(sender: System.Object; e: System.EventArgs);
var
  dlg         : System.Windows.Forms.OpenFileDialog;
  xaml        : string;
  cleanedXaml : string;
  doc         : System.Xml.XmlDocument;
  root        : System.Xml.XmlElement;
  nsMgr       : System.Xml.XmlNamespaceManager;
  resNode     : System.Xml.XmlNode;
  dcNode      : System.Xml.XmlNode;
  resourcesXml: string;
  inner       : string;
  nodesToRemove: System.Collections.Generic.List<System.Xml.XmlNode>;
  node        : System.Xml.XmlNode;
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

  if xaml.Contains('<Window ') or xaml.Contains('<UserControl ') then
  begin
    try
      // ① clr-namespace prefix 선언 및 본문 사용 전체 제거
      //    (vm:, conv: 등 xmlns 선언 + 해당 prefix 엘리먼트/속성 참조 모두 제거)
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
      begin
        resourcesXml := '<Grid.Resources>' + resNode.InnerXml + '</Grid.Resources>';
      end;

      // ③ 디자이너에서 처리 불가한 노드 제거
      //    Window.DataContext, Window.Resources, Window.Style 등
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

      xaml :=
        '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
        '      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' +
        resourcesXml +
        inner +
        '</Grid>';

      System.Windows.Forms.MessageBox.Show(
        'Window/UserControl 루트를 Grid로 변환하여 로드합니다.' + #13#10 +
        '(커스텀 네임스페이스 및 DataContext는 디자이너에서 제외됩니다.)',
        '알림',
        System.Windows.Forms.MessageBoxButtons.OK,
        System.Windows.Forms.MessageBoxIcon.Information);

    except
      on ex: System.Exception do
      begin
        System.Windows.Forms.MessageBox.Show('XAML 전처리 오류: ' + ex.Message);
        exit;
      end;
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
procedure Form1.OnApplyXaml(sender: System.Object; e: System.EventArgs);
begin
  try
    LoadXaml(txtXaml.Text);
  except
    on ex: System.Exception do
      System.Windows.Forms.MessageBox.Show('XAML 오류: ' + ex.Message);
  end;
end;

// ─────────────────────────────────────────────
// 메뉴: 수동 동기화
procedure Form1.OnSyncXamlMenu(sender: System.Object; e: System.EventArgs);
begin
  SyncXamlEditor();
end;
// Help > About
procedure Form1.OnAbout(sender: System.Object; e: System.EventArgs);
begin
  System.Windows.Forms.MessageBox.Show(
    'PascalABC-WPF-Xaml-Designer' + System.Environment.NewLine +
    'Ver 1.1.1' + System.Environment.NewLine + System.Environment.NewLine +
    'ICSharpCode.WpfDesign.Designer' + System.Environment.NewLine +
    'ICSharpCode.WpfDesign' + System.Environment.NewLine +
    'ICSharpCode.WpfDesign.XamlDom' + System.Environment.NewLine +
    'ICSharpCode.AvalonEdit' + System.Environment.NewLine +
    'avalonedit.6.3.1.120' + System.Environment.NewLine +
    ' 기반 WPF XAML 디자이너' + System.Environment.NewLine + System.Environment.NewLine +
    'Built with PascalABC.NET 3.11.1.3764' + System.Environment.NewLine + System.Environment.NewLine +
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