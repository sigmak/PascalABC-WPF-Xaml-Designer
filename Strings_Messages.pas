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
//
// ★ 리팩토링 (구조 정리):
//   - RegisterAll 이 너무 길어져 카테고리별로 분리
//     (RegisterErrorMessages / RegisterInfoMessages / RegisterAboutDialog / RegisterTitles)
//   - About 다이얼로그 본문은 3개 언어에서 구조(Models/, Events/, ... 및 하단 크레딧)가
//     동일하고 섹션 제목/기능 설명만 다르므로, BuildAboutBody 로 템플릿화하여 중복 제거.
//     (기능 추가/문구 수정 시 실수로 한 언어만 고치는 사고를 방지)
// =============================================================================

interface

uses
  LocalizationCore;

type
  TStrings_Messages = static class
  public
    class procedure RegisterAll; //static;
  private
    class procedure RegisterErrorMessages; //static;
    class procedure RegisterInfoMessages; //static;
    class procedure RegisterAboutDialog; //static;
    class procedure RegisterTitles; //static;
    class function BuildAboutBody(const LangIdx: Integer): string; //static;
  end;

implementation

// 언어 인덱스 상수 (LocalizationCore.AllLanguages 순서와 일치: Korean=0, English=1, Russian=2)
const
  LANG_KO = 0;
  LANG_EN = 1;
  LANG_RU = 2;

class procedure TStrings_Messages.RegisterAll;
begin
  RegisterErrorMessages;
  RegisterInfoMessages;
  RegisterAboutDialog;
  RegisterTitles;
end;

// ── 오류 메시지 (대부분 {0} 에 ex.Message 가 들어감) ────────────────────────
class procedure TStrings_Messages.RegisterErrorMessages;
begin
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

  // .pwproj.user(사용자 로컬 옵션) 로드 실패 시 — {0} = 예외 메시지
  TLoc.Register('msg.error.load_options',
    ['사용자 옵션 파일을 불러오지 못했습니다 (기본값 사용): {0}',
     'Failed to load the local options file (using defaults): {0}',
     'Не удалось загрузить локальный файл параметров (используются значения по умолчанию): {0}']);
end;

// ── 정보 메시지 ──────────────────────────────────────────────────────────
class procedure TStrings_Messages.RegisterInfoMessages;
begin
  TLoc.Register('msg.info.save_done',
    ['XAML: {0}' + System.Environment.NewLine +
     'PAS: {1}' + System.Environment.NewLine + '저장 완료!',

     'XAML: {0}' + System.Environment.NewLine +
     'PAS: {1}' + System.Environment.NewLine + 'Saved successfully!',

     'XAML: {0}' + System.Environment.NewLine +
     'PAS: {1}' + System.Environment.NewLine + 'Сохранено!']);
end;

// ── About(정보) 다이얼로그 본문 ──────────────────────────────────────────
// {0} 에 APP_VERSION 이 들어옵니다. 호출부: TLoc.F('dlg.about.body', APP_VERSION)
//
// 3개 언어 모두 구조(Models/, Events/, Editor/, CodeGen/, Docking/, 하단 크레딧)는
// 동일하고, 섹션 제목과 기능 설명 문구만 다르므로 BuildAboutBody 에서 조립한다.
class function TStrings_Messages.BuildAboutBody(const LangIdx: Integer): string;
const
  NL = System.Environment.NewLine;

  StructureHeader: array[0..2] of string = (
    '■ 리팩토링 구조', '■ Refactored Structure', '■ Структура рефакторинга');

  Form1Line: array[0..2] of string = (
    '  Form1.pas : UI + 이벤트 핸들러 + 빌드/실행',
    '  Form1.pas : UI + Event Handlers + Build/Run',
    '  Form1.pas : UI + обработчики событий + сборка/запуск');

  FeaturesHeader: array[0..2] of string = (
    '■ 주요 기능', '■ Key Features', '■ Основные возможности');

  FeatureSyntax: array[0..2] of string = (
    '  · Pascal/PascalABC.NET 구문 강조 (XSHD)',
    '  · Pascal/PascalABC.NET syntax highlighting (XSHD)',
    '  · Подсветка синтаксиса Pascal/PascalABC.NET (XSHD)');

  FeatureFolding: array[0..2] of string = (
    '  · begin/end 블록 폴딩',
    '  · begin/end block folding',
    '  · Свёртывание блоков begin/end');

  FeatureOptions: array[0..2] of string = (
    '  · 프로젝트 옵션 (Alt+Enter)',
    '  · Project Options (Alt+Enter)',
    '  · Параметры проекта (Alt+Enter)');

  FeatureDocking: array[0..2] of string = (
    '  · DockPanelSuite 기반 도킹 레이아웃',
    '  · DockPanelSuite-based docking layout',
    '  · Макет на основе DockPanelSuite');

  FeatureEventGen: array[0..2] of string = (
    '  · 이벤트 탭 더블클릭으로 핸들러 자동 생성',
    '  · Event tab double-click auto-generates handlers',
    '  · Двойной щелчок на вкладке событий создаёт обработчик');
begin
  Result :=
    'PascalABC-WPF-Designer Ver {0}' + NL + NL +
    StructureHeader[LangIdx] + NL +
    '  Models/   : ProjectOptions, ControlInfo' + NL +
    '  Events/   : WpfEventMap' + NL +
    '  Editor/   : PascalHighlighting, PascalFolding' + NL +
    '  CodeGen/  : XamlParser, XamlPreprocessor, PascalCodeGenerator' + NL +
    '  Docking/  : DockContents (DockPanelSuite)' + NL +
    Form1Line[LangIdx] + NL + NL +
    FeaturesHeader[LangIdx] + NL +
    FeatureSyntax[LangIdx] + NL +
    FeatureFolding[LangIdx] + NL +
    FeatureOptions[LangIdx] + NL +
    FeatureDocking[LangIdx] + NL +
    FeatureEventGen[LangIdx] + NL + NL +
    'Built with PascalABC.NET 3.11.1.3833' + NL +
    'ICSharpCode.WpfDesign + AvalonEdit + DockPanelSuite' + NL + NL +
    'made by sigmak (dwfree74@gmail.com) with claude.ai';
end;

class procedure TStrings_Messages.RegisterAboutDialog;
begin
  TLoc.Register('dlg.about.body',
    [BuildAboutBody(LANG_KO),
     BuildAboutBody(LANG_EN),
     BuildAboutBody(LANG_RU)]);
end;

// ── 메시지박스 제목 ──────────────────────────────────────────────────────
class procedure TStrings_Messages.RegisterTitles;
begin
  TLoc.Register('title.error',
    ['오류', 'Error', 'Ошибка']);

  TLoc.Register('title.no_compiler',
    ['컴파일러 없음', 'No Compiler', 'Компилятор не найден']);

  TLoc.Register('title.info',
    ['정보', 'Information', 'Информация']);

  // 새 기능에서 메시지박스를 추가할 때는 해당 카테고리 메서드에 같은 패턴으로 추가하면 됩니다.
end;

end.