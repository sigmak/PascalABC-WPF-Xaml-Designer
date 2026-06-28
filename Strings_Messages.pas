unit Strings_Messages;

// =============================================================================
// Strings_Messages.pas — MessageBox / 알림 메시지 문자열 테이블
//
// 동적 값({0} 등)이 들어가는 메시지는 TLoc.F('key', args) 로 사용한다.
//   예) TLoc.F('msg.error.save_file', ex.Message)
//
// 키 네이밍 규칙:
//   msg.error.<상황>   — 오류 메시지박스
//   msg.info.<상황>    — 정보 메시지박스
//   title.<상황>       — 메시지박스 제목
//
// ★ 수정 이력 (Ver 2.3.0):
//   - 3번째 언어 인덱스가 Ukrainian(우크라이나어)으로 등록되어 있었으나
//     Strings_Common.pas 와 동일하게 Russian(러시아어)으로 통일.
//     (LocalizationCore.AllLanguages 순서: Korean=0, English=1, Russian=2)
//   - 빌드 오류 메시지가 English 설정에서 한글로 표시되던 버그 원인이
//     이 파일의 언어 인덱스 불일치였음.
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
  // 순서: Korean, English, Russian  (LocalizationCore.AllLanguages 순서와 일치)
  // ★ 수정: 이전 코드는 3번째 언어가 Ukrainian 이었으나 Russian 으로 수정.

  // ── 오류 메시지 (대부분 {0} 에 ex.Message 가 들어감) ────────────────────
  TLoc.Register('msg.error.save_file',
    ['파일 저장 오류: {0}',
     'File save error: {0}',
     'Ошибка сохранения файла: {0}']);

  TLoc.Register('msg.error.build_start',
    ['빌드 시작 오류: {0}',
     'Build start error: {0}',
     'Ошибка запуска сборки: {0}']);

  TLoc.Register('msg.error.run',
    ['실행 오류: {0}',
     'Run error: {0}',
     'Ошибка запуска: {0}']);

  TLoc.Register('msg.error.test_host_run',
    ['테스트 호스트 실행 오류: {0}',
     'Test host run error: {0}',
     'Ошибка запуска тестового хоста: {0}']);

  TLoc.Register('msg.error.read_file',
    ['읽기 오류: {0}',
     'Read error: {0}',
     'Ошибка чтения: {0}']);

  TLoc.Register('msg.error.xaml_preprocess',
    ['XAML 전처리 오류: {0}',
     'XAML preprocessing error: {0}',
     'Ошибка предварительной обработки XAML: {0}']);

  TLoc.Register('msg.error.xaml_load',
    ['XAML 로드 오류: {0}',
     'XAML load error: {0}',
     'Ошибка загрузки XAML: {0}']);

  TLoc.Register('msg.error.type_not_found',
    ['타입 없음: {0}',
     'Type not found: {0}',
     'Тип не найден: {0}']);

  TLoc.Register('msg.error.add_control',
    ['컨트롤 추가 실패: {0}',
     'Failed to add control: {0}',
     'Не удалось добавить элемент: {0}']);

  TLoc.Register('msg.error.compiler_not_found',
    ['pabcnetc.exe를 찾을 수 없습니다.',
     'pabcnetc.exe not found.',
     'pabcnetc.exe не найден.']);

  TLoc.Register('msg.error.save_options',
    ['옵션 저장 실패: {0}',
     'Failed to save options: {0}',
     'Не удалось сохранить параметры: {0}']);

  // 새 프로젝트 생성 직후 자동 저장(.pwsln/.pwproj/.pwproj.user) 실패 시
  TLoc.Register('msg.error.new_project_save_failed',
    ['새 프로젝트 파일을 저장하지 못했습니다. 출력 창을 확인하세요.',
     'Failed to save the new project files. Check the Output window.',
     'Не удалось сохранить файлы нового проекта. Проверьте окно вывода.']);

  // .pwsln을 열었는데 내부에 유효한 프로젝트 참조가 없거나 대상 .pwproj가 없을 때
  TLoc.Register('msg.error.solution_has_no_project',
    ['솔루션 파일에 유효한 프로젝트가 없습니다.',
     'The solution file does not reference a valid project.',
     'Файл решения не содержит ссылку на допустимый проект.']);
 
  // .pwproj.user(사용자 로컬 옵션) 로드 실패 시 — 기존 msg.error.save_options 패턴과 동일하게
  // {0} = 예외 메시지
  TLoc.Register('msg.error.load_options',
    ['사용자 옵션 파일을 불러오지 못했습니다 (기본값 사용): {0}',
     'Failed to load the local options file (using defaults): {0}',
     'Не удалось загрузить локальный файл параметров (используются значения по умолчанию): {0}']);
 


  // ── 정보 메시지 ──────────────────────────────────────────────────────────
  TLoc.Register('msg.info.save_done',
    ['XAML: {0}' + System.Environment.NewLine +
     'PAS: {1}' + System.Environment.NewLine + '저장 완료!',

     'XAML: {0}' + System.Environment.NewLine +
     'PAS: {1}' + System.Environment.NewLine + 'Saved successfully!',

     'XAML: {0}' + System.Environment.NewLine +
     'PAS: {1}' + System.Environment.NewLine + 'Сохранено!']);

  // ── About(정보) 다이얼로그 본문 ──────────────────────────────────────────
  // ★ {0} 에 APP_VERSION 이 들어옵니다. 호출부: TLoc.F('dlg.about.body', APP_VERSION)
  TLoc.Register('dlg.about.body',
    ['PascalABC-WPF-Designer Ver {0}' + System.Environment.NewLine +
     System.Environment.NewLine +
     '■ 리팩토링 구조' + System.Environment.NewLine +
     '  Models/   : ProjectOptions, ControlInfo' + System.Environment.NewLine +
     '  Events/   : WpfEventMap' + System.Environment.NewLine +
     '  Editor/   : PascalHighlighting, PascalFolding' + System.Environment.NewLine +
     '  CodeGen/  : XamlParser, XamlPreprocessor, PascalCodeGenerator' + System.Environment.NewLine +
     '  Docking/  : DockContents (DockPanelSuite)' + System.Environment.NewLine +
     '  Form1.pas : UI + 이벤트 핸들러 + 빌드/실행' + System.Environment.NewLine +
     System.Environment.NewLine +
     '■ 주요 기능' + System.Environment.NewLine +
     '  · Pascal/PascalABC.NET 구문 강조 (XSHD)' + System.Environment.NewLine +
     '  · begin/end 블록 폴딩' + System.Environment.NewLine +
     '  · 프로젝트 옵션 (Alt+Enter)' + System.Environment.NewLine +
     '  · DockPanelSuite 기반 도킹 레이아웃' + System.Environment.NewLine +
     '  · 이벤트 탭 더블클릭으로 핸들러 자동 생성' + System.Environment.NewLine +
     System.Environment.NewLine +
     'Built with PascalABC.NET 3.11.1.3833' + System.Environment.NewLine +
     'ICSharpCode.WpfDesign + AvalonEdit + DockPanelSuite' + System.Environment.NewLine +
     System.Environment.NewLine +
     'made by sigmak (dwfree74@gmail.com) with claude.ai',

     'PascalABC-WPF-Designer Ver {0}' + System.Environment.NewLine +
     System.Environment.NewLine +
     '■ Refactored Structure' + System.Environment.NewLine +
     '  Models/   : ProjectOptions, ControlInfo' + System.Environment.NewLine +
     '  Events/   : WpfEventMap' + System.Environment.NewLine +
     '  Editor/   : PascalHighlighting, PascalFolding' + System.Environment.NewLine +
     '  CodeGen/  : XamlParser, XamlPreprocessor, PascalCodeGenerator' + System.Environment.NewLine +
     '  Docking/  : DockContents (DockPanelSuite)' + System.Environment.NewLine +
     '  Form1.pas : UI + Event Handlers + Build/Run' + System.Environment.NewLine +
     System.Environment.NewLine +
     '■ Key Features' + System.Environment.NewLine +
     '  · Pascal/PascalABC.NET syntax highlighting (XSHD)' + System.Environment.NewLine +
     '  · begin/end block folding' + System.Environment.NewLine +
     '  · Project Options (Alt+Enter)' + System.Environment.NewLine +
     '  · DockPanelSuite-based docking layout' + System.Environment.NewLine +
     '  · Event tab double-click auto-generates handlers' + System.Environment.NewLine +
     System.Environment.NewLine +
     'Built with PascalABC.NET 3.11.1.3833' + System.Environment.NewLine +
     'ICSharpCode.WpfDesign + AvalonEdit + DockPanelSuite' + System.Environment.NewLine +
     System.Environment.NewLine +
     'made by sigmak (dwfree74@gmail.com) with claude.ai',

     'PascalABC-WPF-Designer Ver {0}' + System.Environment.NewLine +
     System.Environment.NewLine +
     '■ Структура рефакторинга' + System.Environment.NewLine +
     '  Models/   : ProjectOptions, ControlInfo' + System.Environment.NewLine +
     '  Events/   : WpfEventMap' + System.Environment.NewLine +
     '  Editor/   : PascalHighlighting, PascalFolding' + System.Environment.NewLine +
     '  CodeGen/  : XamlParser, XamlPreprocessor, PascalCodeGenerator' + System.Environment.NewLine +
     '  Docking/  : DockContents (DockPanelSuite)' + System.Environment.NewLine +
     '  Form1.pas : UI + обработчики событий + сборка/запуск' + System.Environment.NewLine +
     System.Environment.NewLine +
     '■ Основные возможности' + System.Environment.NewLine +
     '  · Подсветка синтаксиса Pascal/PascalABC.NET (XSHD)' + System.Environment.NewLine +
     '  · Свёртывание блоков begin/end' + System.Environment.NewLine +
     '  · Параметры проекта (Alt+Enter)' + System.Environment.NewLine +
     '  · Макет на основе DockPanelSuite' + System.Environment.NewLine +
     '  · Двойной щелчок на вкладке событий создаёт обработчик' + System.Environment.NewLine +
     System.Environment.NewLine +
     'Built with PascalABC.NET 3.11.1.3833' + System.Environment.NewLine +
     'ICSharpCode.WpfDesign + AvalonEdit + DockPanelSuite' + System.Environment.NewLine +
     System.Environment.NewLine +
     'made by sigmak (dwfree74@gmail.com) with claude.ai']);

  // ── 메시지박스 제목 ──────────────────────────────────────────────────────
  TLoc.Register('title.error',
    ['오류', 'Error', 'Ошибка']);

  TLoc.Register('title.no_compiler',
    ['컴파일러 없음', 'No Compiler', 'Компилятор не найден']);

  TLoc.Register('title.info',
    ['정보', 'Information', 'Информация']);

  // 새 기능에서 메시지박스를 추가할 때는 이 파일 하단에 같은 패턴으로 추가하면 됩니다.
end;

end.