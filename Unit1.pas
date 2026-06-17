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

    // WinForms 레이아웃
    panel    : System.Windows.Forms.TableLayoutPanel;
    menuStrip: System.Windows.Forms.MenuStrip;

    // ElementHost (WPF→WinForms 브릿지)
    hostDesign: System.Windows.Forms.Integration.ElementHost;
    hostLeft  : System.Windows.Forms.Integration.ElementHost;
    hostRight : System.Windows.Forms.Integration.ElementHost;

    // 왼쪽 Toolbox (WPF StackPanel)
    fToolboxPanel: System.Windows.Controls.StackPanel;

    // XAML 텍스트 에디터 (하단)
    splitContainer: System.Windows.Forms.SplitContainer;
    txtXaml       : System.Windows.Forms.RichTextBox;
    btnApply      : System.Windows.Forms.Button;

    procedure BuildMenu;
    procedure BuildToolbox;
    procedure BuildLayout;
    procedure ConnectPropertyGrid;
    procedure AddToolboxButton(name: string; typeName: string);  // ← 클래스 메서드로
    procedure OnToolboxClick(sender: System.Object; e: System.Windows.RoutedEventArgs); // ← 별도 핸들러
    // 선언부에서 시그니처 변경
    procedure OnSelectionChanged(sender: System.Object; e: ICSharpCode.WpfDesign.DesignItemCollectionEventArgs);
    procedure OnSave(sender: System.Object; e: System.EventArgs);
    procedure OnOpen(sender: System.Object; e: System.EventArgs);
    //procedure OnApplyXaml(sender: System.Object; e: System.Windows.RoutedEventArgs);  // WPF 버튼
    procedure OnApplyXaml(sender: System.Object; e: System.EventArgs);  // RoutedEventArgs → EventArgs    
    
    procedure OnSyncXamlMenu(sender: System.Object; e: System.EventArgs);  // 메뉴용 WinForms
    procedure OnSyncXaml(sender: System.Object; e: System.Windows.RoutedEventArgs);  // WPF 버튼용 (현재 미사용이면 제거 가능)
    
    procedure OnAbout(sender: System.Object; e: System.EventArgs);
    
    procedure LoadXaml(xaml: string);
  public
    constructor Create;
  end;

// ─────────────────────────────────────────────
constructor Form1.Create;
begin
  inherited Create;
  Self.Text   := 'PascalABC-WPF-Xaml-Designer Ver 1.0.0';
  Self.Width  := 1500;
  Self.Height := 900;

  ICSharpCode.WpfDesign.Designer.BasicMetadata.Register();

  BuildMenu;
  BuildToolbox;
  BuildLayout;
  LoadXaml(
    '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"' +
    '      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"' +
    '      Background="White" Width="400" Height="300">' +
    '  <Button Width="100" Height="30" Content="Hello" />' +
    '</Grid>'
  );
  ConnectPropertyGrid;
end;

// ─────────────────────────────────────────────
// A. 메뉴바 (저장/열기)
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
  syncItem.Click += OnSyncXamlMenu;  // OnSyncXaml → OnSyncXamlMenu

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
// A. 3분할 레이아웃 + C. XAML 에디터
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
  txtXaml           := new System.Windows.Forms.RichTextBox();
  txtXaml.Font      := new System.Drawing.Font('Consolas', 9);
  txtXaml.Dock      := System.Windows.Forms.DockStyle.Fill;
  txtXaml.ScrollBars := System.Windows.Forms.RichTextBoxScrollBars.Both;
  txtXaml.WordWrap  := false;

  btnApply        := new System.Windows.Forms.Button();
  btnApply.Text   := '▶ XAML 적용';
  btnApply.Dock   := System.Windows.Forms.DockStyle.Bottom;
  btnApply.Height := 28;
  btnApply.Click  += OnApplyXaml;

  var bottomPanel := new System.Windows.Forms.Panel();
  bottomPanel.Dock   := System.Windows.Forms.DockStyle.Fill;
  bottomPanel.Controls.Add(txtXaml);
  bottomPanel.Controls.Add(btnApply);

  // SplitContainer: 위=디자이너영역 / 아래=XAML에디터
  splitContainer                    := new System.Windows.Forms.SplitContainer();
  splitContainer.Dock               := System.Windows.Forms.DockStyle.Fill;
  splitContainer.Orientation        := System.Windows.Forms.Orientation.Horizontal;
  splitContainer.SplitterDistance   := 620;
  splitContainer.Panel1.Controls.Add(topPanel);
  splitContainer.Panel2.Controls.Add(bottomPanel);

  Self.Controls.Add(splitContainer);
end;

// ─────────────────────────────────────────────
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
  txtXaml.Text     := xaml;
end;

// ─────────────────────────────────────────────
// A. PropertyGrid 와 선택 이벤트 연결
procedure Form1.ConnectPropertyGrid;
begin
  if fSurface.DesignContext = nil then exit;
  fSurface.DesignContext.Services.Selection.SelectionChanged += OnSelectionChanged;
end;

// 툴박스 버튼 추가 (클래스 메서드로 분리)
procedure Form1.AddToolboxButton(name: string; typeName: string);
var
  btn: System.Windows.Controls.Button;
begin
  btn         := new System.Windows.Controls.Button();
  btn.Content := name;
  btn.Tag     := typeName;
  btn.Margin  := new System.Windows.Thickness(2);
  btn.HorizontalAlignment := System.Windows.HorizontalAlignment.Stretch;
  btn.Click += OnToolboxClick;  // 람다 대신 별도 메서드 연결
  fToolboxPanel.Children.Add(btn);
end;

// 툴박스 버튼 클릭 핸들러 (클래스 메서드이므로 람다 불필요)
procedure Form1.OnToolboxClick(sender: System.Object; e: System.Windows.RoutedEventArgs);
var
  tname   : string;
  t       : System.Type;
  inst    : System.Object;
  newItem : ICSharpCode.WpfDesign.DesignItem;
  rootItem: ICSharpCode.WpfDesign.DesignItem;
  list    : System.Collections.Generic.ICollection<ICSharpCode.WpfDesign.DesignItem>;
begin
  if fSurface.DesignContext = nil then exit;

  tname := (sender as System.Windows.Controls.Button).Tag.ToString();
  t     := System.Type.GetType(tname);
  if t = nil then exit;

  inst := System.Activator.CreateInstance(t);
  if inst = nil then exit;

  var services := fSurface.DesignContext.Services;
  rootItem := fSurface.DesignContext.RootItem;
  newItem  := services.Component.RegisterComponentForDesigner(rootItem, inst);

  // List → ICollection 으로 명시적 캐스팅
  list := new System.Collections.Generic.List<ICSharpCode.WpfDesign.DesignItem>([newItem])
    as System.Collections.Generic.ICollection<ICSharpCode.WpfDesign.DesignItem>;

  services.Selection.SetSelectedComponents(list);
end;

// BuildToolbox에서 AddButton 대신 AddToolboxButton 호출
procedure Form1.BuildToolbox;
var
  scroll: System.Windows.Controls.ScrollViewer;
  title : System.Windows.Controls.TextBlock;
  sep   : System.Windows.Controls.Separator;
begin
  fToolboxPanel            := new System.Windows.Controls.StackPanel();
  fToolboxPanel.Background := System.Windows.Media.Brushes.WhiteSmoke;

  title            := new System.Windows.Controls.TextBlock();
  title.Text       := '■ Toolbox';
  title.FontWeight := System.Windows.FontWeights.Bold;
  title.Margin     := new System.Windows.Thickness(4);
  fToolboxPanel.Children.Add(title);

  fToolboxPanel.Children.Add(new System.Windows.Controls.Separator());

  // 레이아웃
  AddToolboxButton('Grid',       'System.Windows.Controls.Grid, PresentationFramework');
  AddToolboxButton('StackPanel', 'System.Windows.Controls.StackPanel, PresentationFramework');
  AddToolboxButton('Canvas',     'System.Windows.Controls.Canvas, PresentationFramework');
  AddToolboxButton('DockPanel',  'System.Windows.Controls.DockPanel, PresentationFramework');

  fToolboxPanel.Children.Add(new System.Windows.Controls.Separator());

  // 컨트롤
  AddToolboxButton('Button',    'System.Windows.Controls.Button, PresentationFramework');
  AddToolboxButton('TextBox',   'System.Windows.Controls.TextBox, PresentationFramework');
  AddToolboxButton('Label',     'System.Windows.Controls.Label, PresentationFramework');
  AddToolboxButton('CheckBox',  'System.Windows.Controls.CheckBox, PresentationFramework');
  AddToolboxButton('ComboBox',  'System.Windows.Controls.ComboBox, PresentationFramework');
  AddToolboxButton('ListBox',   'System.Windows.Controls.ListBox, PresentationFramework');
  AddToolboxButton('Image',     'System.Windows.Controls.Image, PresentationFramework');
  AddToolboxButton('TextBlock', 'System.Windows.Controls.TextBlock, PresentationFramework');

  scroll         := new System.Windows.Controls.ScrollViewer();
  scroll.Content := fToolboxPanel;
  scroll.VerticalScrollBarVisibility :=
    System.Windows.Controls.ScrollBarVisibility.Auto;

  hostLeft       := new System.Windows.Forms.Integration.ElementHost();
  hostLeft.Dock  := System.Windows.Forms.DockStyle.Fill;
  hostLeft.Child := scroll;
end;

procedure Form1.OnSelectionChanged(sender: System.Object;
  e: ICSharpCode.WpfDesign.DesignItemCollectionEventArgs);
begin
  if fSurface.DesignContext = nil then exit;
  fPropView.SelectedItems :=
    fSurface.DesignContext.Services.Selection.SelectedItems;
end;

// ─────────────────────────────────────────────
// B. 저장
procedure Form1.OnSave(sender: System.Object; e: System.EventArgs);
var
  dlg: System.Windows.Forms.SaveFileDialog;
  sw : System.IO.StringWriter;
  xw : System.Xml.XmlWriter;  // XmlWriter로 선언
begin
  if fSurface.DesignContext = nil then exit;
  dlg          := new System.Windows.Forms.SaveFileDialog();
  dlg.Filter   := 'XAML 파일|*.xaml|모든 파일|*.*';
  dlg.FileName := 'design.xaml';
  if dlg.ShowDialog() = System.Windows.Forms.DialogResult.OK then
  begin
    sw            := new System.IO.StringWriter();
    xw            := new System.Xml.XmlTextWriter(sw);  // XmlTextWriter로 생성
    (xw as System.Xml.XmlTextWriter).Formatting := System.Xml.Formatting.Indented;
    fSurface.SaveDesigner(xw);
    System.IO.File.WriteAllText(dlg.FileName, sw.ToString());
    System.Windows.Forms.MessageBox.Show('저장 완료: ' + dlg.FileName);
  end;
end;

// B. 열기
procedure Form1.OnOpen(sender: System.Object; e: System.EventArgs);
var
  dlg : System.Windows.Forms.OpenFileDialog;
  xaml: string;
begin
  dlg := new System.Windows.Forms.OpenFileDialog();
  dlg.Filter := 'XAML 파일|*.xaml|모든 파일|*.*';
  if dlg.ShowDialog() = System.Windows.Forms.DialogResult.OK then
  begin
    xaml := System.IO.File.ReadAllText(dlg.FileName);
    LoadXaml(xaml);
    ConnectPropertyGrid;
  end;
end;

// C. XAML 텍스트 → 디자이너 적용
procedure Form1.OnApplyXaml(sender: System.Object; e: System.EventArgs);
begin
  try
    LoadXaml(txtXaml.Text);
    ConnectPropertyGrid;
  except
    on ex: System.Exception do
      System.Windows.Forms.MessageBox.Show('XAML 오류: ' + ex.Message);
  end;
end;

// 메뉴 클릭용 (WinForms EventHandler)
procedure Form1.OnSyncXamlMenu(sender: System.Object; e: System.EventArgs);
var
  sw: System.IO.StringWriter;
  xw: System.Xml.XmlWriter;  // XmlWriter로 선언
begin
  if fSurface.DesignContext = nil then exit;
  sw            := new System.IO.StringWriter();
  xw            := new System.Xml.XmlTextWriter(sw);  // XmlTextWriter로 생성
  (xw as System.Xml.XmlTextWriter).Formatting := System.Xml.Formatting.Indented;
  fSurface.SaveDesigner(xw);
  txtXaml.Text  := sw.ToString();
end;

// Help > About
procedure Form1.OnAbout(sender: System.Object; e: System.EventArgs);
begin
  System.Windows.Forms.MessageBox.Show(
    'PascalABC-WPF-Xaml-Designer' + System.Environment.NewLine +
    'Ver 1.0.0' + System.Environment.NewLine + System.Environment.NewLine +
    'ICSharpCode.WpfDesign.Designer' + System.Environment.NewLine +
    'ICSharpCode.WpfDesign' + System.Environment.NewLine +
    'ICSharpCode.WpfDesign.XamlDom' + System.Environment.NewLine +
    'ICSharpCode.AvalonEdit' + System.Environment.NewLine +
    'avalonedit.6.3.1.120' + System.Environment.NewLine +
    ' 기반 WPF XAML 디자이너' + System.Environment.NewLine + System.Environment.NewLine +
    'Built with PascalABC.NET 3.11.1.3764',
    '프로그램 정보',
    System.Windows.Forms.MessageBoxButtons.OK,
    System.Windows.Forms.MessageBoxIcon.Information
  );
end;

// C. 디자이너 → XAML 텍스트 동기화
procedure Form1.OnSyncXaml(sender: System.Object; e: System.Windows.RoutedEventArgs);
var
  sw: System.IO.StringWriter;
  xw: System.Xml.XmlWriter;
begin
  if fSurface.DesignContext = nil then exit;
  sw            := new System.IO.StringWriter();
  xw            := new System.Xml.XmlTextWriter(sw);  // XmlTextWriter로 생성
  (xw as System.Xml.XmlTextWriter).Formatting := System.Xml.Formatting.Indented;
  fSurface.SaveDesigner(xw);
  txtXaml.Text  := sw.ToString();
end;

// ─────────────────────────────────────────────
begin
  System.Threading.Thread.CurrentThread.SetApartmentState(
    System.Threading.ApartmentState.STA
  );
  System.Windows.Forms.Application.EnableVisualStyles();
  System.Windows.Forms.Application.Run(new Form1());
end.