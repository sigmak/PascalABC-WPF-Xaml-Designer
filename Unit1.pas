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
  System.Windows.Forms;

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
    procedure AddToolboxButton(name: string; typeName: string);  // ← 클래스 메서드로
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
  public
    constructor Create;
  end;

// ─────────────────────────────────────────────
constructor Form1.Create;
begin
  inherited Create;
  Self.Text   := 'PascalABC-WPF-Xaml-Designer Ver 1.0.3';
  Self.Width  := 1500;
  Self.Height := 900;

  ICSharpCode.WpfDesign.Designer.BasicMetadata.Register();

  BuildMenu;
  BuildToolbox;
  BuildLayout;

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
// A. 왼쪽 Toolbox 패널
procedure Form1.BuildToolbox;
var
  scroll: System.Windows.Controls.ScrollViewer;
  title : System.Windows.Controls.TextBlock;
begin
  fToolboxPanel            := new System.Windows.Controls.StackPanel();
  fToolboxPanel.Background := System.Windows.Media.Brushes.WhiteSmoke;

  title            := new System.Windows.Controls.TextBlock();
  title.Text       := '■ Toolbox';
  title.FontWeight := System.Windows.FontWeights.Bold;
  title.Margin     := new System.Windows.Thickness(4);
  fToolboxPanel.Children.Add(title);
  fToolboxPanel.Children.Add(new System.Windows.Controls.Separator());

  // 레이아웃 컨트롤 (어셈블리 한정자 제거 - AppDomain 전체 검색)
  AddToolboxButton('Grid',       'System.Windows.Controls.Grid');
  AddToolboxButton('StackPanel', 'System.Windows.Controls.StackPanel');
  AddToolboxButton('Canvas',     'System.Windows.Controls.Canvas');
  AddToolboxButton('DockPanel',  'System.Windows.Controls.DockPanel');

  fToolboxPanel.Children.Add(new System.Windows.Controls.Separator());

  // 컨트롤
  AddToolboxButton('Button',      'System.Windows.Controls.Button');
  AddToolboxButton('TextBox',     'System.Windows.Controls.TextBox');
  AddToolboxButton('Label',       'System.Windows.Controls.Label');
  AddToolboxButton('CheckBox',    'System.Windows.Controls.CheckBox');
  AddToolboxButton('ComboBox',    'System.Windows.Controls.ComboBox');
  AddToolboxButton('ListBox',     'System.Windows.Controls.ListBox');
  AddToolboxButton('Image',       'System.Windows.Controls.Image');
  AddToolboxButton('TextBlock',   'System.Windows.Controls.TextBlock');
  AddToolboxButton('Slider',      'System.Windows.Controls.Slider');
  AddToolboxButton('ProgressBar', 'System.Windows.Controls.ProgressBar');
  AddToolboxButton('RadioButton', 'System.Windows.Controls.RadioButton');
  AddToolboxButton('Border',      'System.Windows.Controls.Border');

  scroll         := new System.Windows.Controls.ScrollViewer();
  scroll.Content := fToolboxPanel;
  scroll.VerticalScrollBarVisibility :=
    System.Windows.Controls.ScrollBarVisibility.Auto;

  hostLeft       := new System.Windows.Forms.Integration.ElementHost();
  hostLeft.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostLeft.Child := scroll;
end;

// ─────────────────────────────────────────────
// 툴박스 버튼 추가
procedure Form1.AddToolboxButton(name: string; typeName: string);
var
  btn: System.Windows.Controls.Button;
begin
  btn         := new System.Windows.Controls.Button();
  btn.Content := name;
  btn.Tag     := typeName;
  btn.Margin  := new System.Windows.Thickness(2);
  btn.HorizontalAlignment := System.Windows.HorizontalAlignment.Stretch;
  btn.Click += OnToolboxClick;
  fToolboxPanel.Children.Add(btn);
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
  //grp      : ICSharpCode.WpfDesign.DesignItemChangeGroup;
  list     : System.Collections.Generic.List<ICSharpCode.WpfDesign.DesignItem>;
  childProp: ICSharpCode.WpfDesign.DesignItemProperty;
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

    // 추가된 컨트롤 선택
    list := new System.Collections.Generic.List<ICSharpCode.WpfDesign.DesignItem>();
    list.Add(newItem);
    services.Selection.SetSelectedComponents(
      list as System.Collections.Generic.ICollection<ICSharpCode.WpfDesign.DesignItem>
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
  topPanel: System.Windows.Forms.TableLayoutPanel;
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

  var bottomPanel := new System.Windows.Forms.Panel();
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

  Self.Controls.Add(splitContainer);
end;

// ─────────────────────────────────────────────
// XAML 로드 + 이벤트 연결
procedure Form1.LoadXaml(xaml: string);
var
  strReader: System.IO.StringReader;
  xmlReader: System.Xml.XmlReader;
  settings : ICSharpCode.WpfDesign.Designer.Xaml.XamlLoadSettings;
begin
  fSurface  := new ICSharpCode.WpfDesign.Designer.DesignSurface();
  settings  := new ICSharpCode.WpfDesign.Designer.Xaml.XamlLoadSettings();
  strReader := new System.IO.StringReader(xaml);
  xmlReader := new System.Xml.XmlTextReader(strReader);
  fSurface.LoadDesigner(xmlReader, settings);
  hostDesign.Child := fSurface;

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
// 저장
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
// 열기 - Window/UserControl 루트를 Grid로 변환
procedure Form1.OnOpen(sender: System.Object; e: System.EventArgs);
var
  dlg  : System.Windows.Forms.OpenFileDialog;
  xaml : string;
  doc  : System.Xml.XmlDocument;
  root : System.Xml.XmlElement;
  inner: string;
begin
  dlg        := new System.Windows.Forms.OpenFileDialog();
  dlg.Filter := 'XAML 파일|*.xaml|모든 파일|*.*';
  if dlg.ShowDialog() <> System.Windows.Forms.DialogResult.OK then exit;

  xaml := System.IO.File.ReadAllText(dlg.FileName);

  // Window / UserControl 루트 → Grid로 변환
  if xaml.Contains('<Window ') or xaml.Contains('<UserControl ') then
  begin
    try
      doc   := new System.Xml.XmlDocument();
      doc.LoadXml(xaml);
      root  := doc.DocumentElement;
      inner := root.InnerXml;
      xaml  :=
        '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
        '      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">' +
        inner + '</Grid>';
      System.Windows.Forms.MessageBox.Show(
        'Window/UserControl 루트를 Grid로 변환하여 로드합니다.',
        '알림', System.Windows.Forms.MessageBoxButtons.OK,
        System.Windows.Forms.MessageBoxIcon.Information);
    except
      on ex: System.Exception do
      begin
        System.Windows.Forms.MessageBox.Show('XAML 변환 오류: ' + ex.Message);
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
    'Ver 1.0.3' + System.Environment.NewLine + System.Environment.NewLine +
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