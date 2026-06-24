unit Strings_Messages;

// =============================================================================
// Strings_Messages.pas — MessageBox / 알림 메시지 문자열 테이블
//
// 동적 값({0} 등)이 들어가는 메시지는 TLoc.F('key', [args]) 로 사용한다.
//   예) TLoc.F('msg.error.save_file', [ex.Message])
//
// 키 네이밍 규칙:
//   msg.error.<상황>   — 오류 메시지박스
//   msg.info.<상황>    — 정보 메시지박스
//   title.<상황>       — 메시지박스 제목
// =============================================================================

interface

uses
  LocalizationCore;

type
  TStrings_Messages = static class
  public
    class procedure RegisterAll;
  end;

implementation

class procedure TStrings_Messages.RegisterAll;
begin
  // ── 오류 메시지 (대부분 {0} 에 ex.Message 가 들어감) ────────────────────
  TLoc.Register('msg.error.save_file',        ['파일 저장 오류: {0}',         'File save error: {0}',         'Помилка збереження файлу: {0}']);
  TLoc.Register('msg.error.build_start',      ['빌드 시작 오류: {0}',         'Build start error: {0}',       'Помилка запуску збірки: {0}']);
  TLoc.Register('msg.error.run',              ['실행 오류: {0}',              'Run error: {0}',               'Помилка запуску: {0}']);
  TLoc.Register('msg.error.test_host_run',    ['테스트 호스트 실행 오류: {0}', 'Test host run error: {0}',     'Помилка запуску тестового хосту: {0}']);
  TLoc.Register('msg.error.read_file',        ['읽기 오류: {0}',              'Read error: {0}',              'Помилка читання: {0}']);
  TLoc.Register('msg.error.xaml_preprocess',  ['XAML 전처리 오류: {0}',       'XAML preprocessing error: {0}', 'Помилка попередньої обробки XAML: {0}']);
  TLoc.Register('msg.error.xaml_load',        ['XAML 로드 오류: {0}',         'XAML load error: {0}',         'Помилка завантаження XAML: {0}']);
  TLoc.Register('msg.error.type_not_found',   ['타입 없음: {0}',              'Type not found: {0}',          'Тип не знайдено: {0}']);
  TLoc.Register('msg.error.add_control',      ['컨트롤 추가 실패: {0}',       'Failed to add control: {0}',   'Не вдалося додати елемент: {0}']);
  TLoc.Register('msg.error.compiler_not_found', ['pabcnetc.exe를 찾을 수 없습니다.', 'pabcnetc.exe not found.', 'pabcnetc.exe не знайдено.']);
  TLoc.Register('msg.error.save_options',     ['옵션 저장 실패: {0}',         'Failed to save options: {0}', 'Не вдалося зберегти параметри: {0}']);

  // ── 정보 메시지 ──────────────────────────────────────────────────────────
  TLoc.Register('msg.info.save_done',
    ['XAML: {0}' + System.Environment.NewLine + 'PAS: {1}' + System.Environment.NewLine + '저장 완료!',
     'XAML: {0}' + System.Environment.NewLine + 'PAS: {1}' + System.Environment.NewLine + 'Saved successfully!',
     'XAML: {0}' + System.Environment.NewLine + 'PAS: {1}' + System.Environment.NewLine + 'Збережено!']);

  // ── About(정보) 다이얼로그 본문 ──────────────────────────────────────────
  TLoc.Register('dlg.about.body',
    ['PascalABC-WPF-Designer Ver 2.2.5' + System.Environment.NewLine + System.Environment.NewLine +
     '■ 리팩토링 구조' + System.Environment.NewLine +
     '  Models/   : ProjectOptions, ControlInfo' + System.Environment.NewLine +
     '  Events/   : WpfEventMap' + System.Environment.NewLine +
     '  Editor/   : PascalHighlighting, PascalFolding' + System.Environment.NewLine +
     '  CodeGen/  : XamlParser, XamlPreprocessor, PascalCodeGenerator' + System.Environment.NewLine +
     '  Docking/  : DockContents (DockPanelSuite)' + System.Environment.NewLine +
     '  Form1.pas : UI + 이벤트 핸들러 + 빌드/실행' + System.Environment.NewLine + System.Environment.NewLine +
     '■ 주요 기능' + System.Environment.NewLine +
     '  · Pascal/PascalABC.NET 구문 강조 (XSHD)' + System.Environment.NewLine +
     '  · begin/end 블록 폴딩' + System.Environment.NewLine +
     '  · 프로젝트 옵션 (Alt+Enter)' + System.Environment.NewLine +
     '  · DockPanelSuite 기반 도킹 레이아웃 (도구상자/탐색기/속성/출력/오류 최소화 가능)' + System.Environment.NewLine + System.Environment.NewLine +
     'Built with PascalABC.NET 3.11.1.3833' + System.Environment.NewLine +
     'ICSharpCode.WpfDesign + AvalonEdit + DockPanelSuite' + System.Environment.NewLine + System.Environment.NewLine +
     'made by sigmak (dwfree74@gmail.com) with claude.ai',

     'PascalABC-WPF-Designer Ver 2.2.5' + System.Environment.NewLine + System.Environment.NewLine +
     '■ Refactored Structure' + System.Environment.NewLine +
     '  Models/   : ProjectOptions, ControlInfo' + System.Environment.NewLine +
     '  Events/   : WpfEventMap' + System.Environment.NewLine +
     '  Editor/   : PascalHighlighting, PascalFolding' + System.Environment.NewLine +
     '  CodeGen/  : XamlParser, XamlPreprocessor, PascalCodeGenerator' + System.Environment.NewLine +
     '  Docking/  : DockContents (DockPanelSuite)' + System.Environment.NewLine +
     '  Form1.pas : UI + Event Handlers + Build/Run' + System.Environment.NewLine + System.Environment.NewLine +
     '■ Key Features' + System.Environment.NewLine +
     '  · Pascal/PascalABC.NET syntax highlighting (XSHD)' + System.Environment.NewLine +
     '  · begin/end block folding' + System.Environment.NewLine +
     '  · Project Options (Alt+Enter)' + System.Environment.NewLine +
     '  · DockPanelSuite-based docking layout (toolbox/explorer/properties/output/errors can be minimized)' + System.Environment.NewLine + System.Environment.NewLine +
     'Built with PascalABC.NET 3.11.1.3833' + System.Environment.NewLine +
     'ICSharpCode.WpfDesign + AvalonEdit + DockPanelSuite' + System.Environment.NewLine + System.Environment.NewLine +
     'made by sigmak (dwfree74@gmail.com) with claude.ai',

     'PascalABC-WPF-Designer Ver 2.2.5' + System.Environment.NewLine + System.Environment.NewLine +
     '■ Структура рефакторингу' + System.Environment.NewLine +
     '  Models/   : ProjectOptions, ControlInfo' + System.Environment.NewLine +
     '  Events/   : WpfEventMap' + System.Environment.NewLine +
     '  Editor/   : PascalHighlighting, PascalFolding' + System.Environment.NewLine +
     '  CodeGen/  : XamlParser, XamlPreprocessor, PascalCodeGenerator' + System.Environment.NewLine +
     '  Docking/  : DockContents (DockPanelSuite)' + System.Environment.NewLine +
     '  Form1.pas : UI + обробники подій + збірка/запуск' + System.Environment.NewLine + System.Environment.NewLine +
     '■ Основні можливості' + System.Environment.NewLine +
     '  · Підсвітка синтаксису Pascal/PascalABC.NET (XSHD)' + System.Environment.NewLine +
     '  · Згортання блоків begin/end' + System.Environment.NewLine +
     '  · Параметри проєкту (Alt+Enter)' + System.Environment.NewLine +
     '  · Розкладка на основі DockPanelSuite (панель елементів/огляд/властивості/вивід/помилки можна згорнути)' + System.Environment.NewLine + System.Environment.NewLine +
     'Built with PascalABC.NET 3.11.1.3833' + System.Environment.NewLine +
     'ICSharpCode.WpfDesign + AvalonEdit + DockPanelSuite' + System.Environment.NewLine + System.Environment.NewLine +
     'made by sigmak (dwfree74@gmail.com) with claude.ai']);

  // ── 메시지박스 제목 ──────────────────────────────────────────────────────
  TLoc.Register('title.error',            ['오류',          'Error',          'Помилка']);
  TLoc.Register('title.no_compiler',      ['컴파일러 없음',  'No Compiler',    'Компілятор не знайдено']);
  TLoc.Register('title.info',             ['정보',          'Information',   'Інформація']);

  // ── 정보 / 확인 메시지 ───────────────────────────────────────────────────
  // (필요 시 여기에 msg.info.* 추가)

  // 새 기능에서 메시지박스를 추가할 때는 이 파일 하단에 같은 패턴으로 추가하면 됩니다.
end;

end.