unit Strings_Common;

// =============================================================================
// Strings_Common.pas — 공통 UI 문자열 테이블 (메뉴 / 다이얼로그 라벨 / 컬럼 헤더)
//
// 이 파일은 "데이터"만 담는다. 로직은 LocalizationCore.pas 에 있다.
// 새 메뉴/라벨을 추가할 때는 이 파일 맨 아래에 Register 줄만 추가하면 된다.
//
// 키 네이밍 규칙: <영역>.<하위영역>.<항목>
//   menu.<menu명>.<item명>      예) menu.file.new
//   dlg.<다이얼로그명>.<항목>    예) dlg.options.lang_label
//   col.<목록명>.<컬럼명>        예) col.errors.message
// =============================================================================

interface

uses
  LocalizationCore;

type
  TStrings_Common = static class
  public
    class procedure RegisterAll;
  end;

implementation

class procedure TStrings_Common.RegisterAll;
begin
  // 순서: Korean, English, Ukrainian  (LocalizationCore.AllLanguages 순서와 일치)

  // ── 파일 메뉴 ────────────────────────────────────────────────────────────
  TLoc.Register('menu.file',          ['파일(&F)',            'File(&F)',            'Файл(&F)']);
  TLoc.Register('menu.file.new',      ['새 프로젝트(&N)...',   'New Project(&N)...',   'Новый проект(&N)...']);
  TLoc.Register('menu.file.open',     ['열기(&O)...',          'Open(&O)...',          'Открыть(&O)...']);
  TLoc.Register('menu.file.save',     ['저장(&S)',             'Save(&S)',             'Сохранить(&S)']);
  
  TLoc.Register('menu.file.save_as',     ['다른 이름으로 저장(&A)...',             'Save &As...',             'Сохранить &как...']);
  TLoc.Register('menu.file.exit',     ['종료(&X)',             'E&xit',             '&Выход']);
 


  // ── 프로젝트 메뉴 ────────────────────────────────────────────────────────
  TLoc.Register('menu.project',           ['프로젝트(&P)',                    'Project(&P)',                    'Проект(&P)']);
  TLoc.Register('menu.project.options',   ['프로젝트 옵션(&O)...    Alt+Enter', 'Project Options(&O)...    Alt+Enter', 'Параметры проекта(&O)...    Alt+Enter']);

  // ── 보기 메뉴 ────────────────────────────────────────────────────────────
  TLoc.Register('menu.view',              ['보기(&V)',                  'View(&V)',                  'Вид(&V)']);
  TLoc.Register('menu.view.apply_xaml',   ['XAML 적용(&Y)',             'Apply XAML(&Y)',            'Применить XAML(&Y)']);
  TLoc.Register('menu.view.sync_xaml',    ['XAML 동기화(&X)',           'Sync XAML(&X)',             'Синхронизировать XAML(&X)']);
  TLoc.Register('menu.view.split_orient', ['디자인/XAML 분할 전환(&Z)', 'Toggle Design/XAML Split(&Z)', 'Переключить разбиение Design/XAML(&Z)']);
  TLoc.Register('menu.view.toolbox',      ['도구 상자(&T)',             'Toolbox(&T)',               'Панель инструментов(&T)']);
  TLoc.Register('menu.view.explorer',     ['솔루션 탐색기(&E)',         'Solution Explorer(&E)',     'Обозреватель решений(&E)']);
  TLoc.Register('menu.view.properties',   ['속성(&P)',                  'Properties(&P)',            'Свойства(&P)']);
  TLoc.Register('menu.view.output',       ['출력(&O)',                  'Output(&O)',                'Вывод(&O)']);
  TLoc.Register('menu.view.errors',       ['오류 목록(&R)',             'Error List(&R)',            'Список ошибок(&R)']);
  TLoc.Register('menu.view.reset_layout', ['레이아웃 초기화(&L)',       'Reset Layout(&L)',          'Сбросить макет(&L)']);
  TLoc.Register('menu.view.line_numbers', ['라인 번호(&L)',             'Line Numbers(&L)',          'Номера строк(&L)']);
  TLoc.Register('menu.view.highlight',    ['구문 강조(&I)',             'Syntax Highlight(&I)',      'Подсветка синтаксиса(&I)']);
  TLoc.Register('menu.view.word_wrap',    ['자동 줄바꿈(&W)',           'Word Wrap(&W)',             'Перенос строк(&W)']);
  TLoc.Register('menu.view.folding',      ['XML 폴딩(&D)',              'XML Folding(&D)',           'Свёртывание XML(&D)']);

  // ── 빌드 메뉴 ────────────────────────────────────────────────────────────
  TLoc.Register('menu.build',         ['빌드(&B)',         'Build(&B)',         'Сборка(&B)']);
  TLoc.Register('menu.build.build',   ['빌드(&B)    F6',   'Build(&B)    F6',   'Сборка(&B)    F6']);
  TLoc.Register('menu.build.run',     ['실행(&R)    F5',   'Run(&R)    F5',     'Запуск(&R)    F5']);

  // ── 도움말 메뉴 ──────────────────────────────────────────────────────────
  TLoc.Register('menu.help',        ['도움말(&H)',  'Help(&H)',  'Справка(&H)']);
  TLoc.Register('menu.help.about',  ['정보(&A)...', 'About(&A)...', 'О программе(&A)...']);

  // ── 서비스 메뉴 (첨부 이미지 2번: Сервис) ────────────────────────────────
  TLoc.Register('menu.tools',          ['서비스(&T)',   'Tools(&T)',    'Сервис(&T)']);
  TLoc.Register('menu.tools.settings', ['설정(&S)...',  'Settings(&S)...', 'Настройки(&S)...']);

  // ── 솔루션 탐색기 컨텍스트 메뉴 ──────────────────────────────────────────
  TLoc.Register('menu.explorer.refresh',        ['새로 고침(&R)',           'Refresh(&R)',           'Обновить(&R)']);
  TLoc.Register('menu.explorer.show_in_folder',  ['파일 탐색기에서 보기(&E)', 'Show in Explorer(&E)',  'Показать в проводнике(&E)']);

  // ── 오류 목록 / 출력 컨텍스트 메뉴 ───────────────────────────────────────
  TLoc.Register('menu.errors.copy',   ['복사(&C)' + #9 + 'Ctrl+C', 'Copy(&C)' + #9 + 'Ctrl+C', 'Копировать(&C)' + #9 + 'Ctrl+C']);
  TLoc.Register('menu.output.copy',   ['복사(&C)' + #9 + 'Ctrl+C', 'Copy(&C)' + #9 + 'Ctrl+C', 'Копировать(&C)' + #9 + 'Ctrl+C']);
  TLoc.Register('menu.output.clear',  ['지우기(&L)', 'Clear(&L)', 'Очистить(&L)']);

  // ── 오류 목록 컬럼 헤더 ──────────────────────────────────────────────────
  TLoc.Register('col.errors.message', ['오류 메시지', 'Message', 'Сообщение']);
  TLoc.Register('col.errors.line',    ['줄',         'Line',    'Строка']);
  TLoc.Register('col.errors.file',    ['파일',       'File',    'Файл']);

  // ── 새 프로젝트 다이얼로그 ───────────────────────────────────────────────
  TLoc.Register('dlg.newproject.title',        ['새 프로젝트 만들기', 'Create New Project', 'Создание нового проекта']);
  TLoc.Register('dlg.newproject.type_label',   ['프로젝트 형식',  'Project Type', 'Тип проекта']);
  TLoc.Register('dlg.newproject.name_label',   ['프로젝트 이름',  'Project Name', 'Имя проекта']);
  TLoc.Register('dlg.newproject.folder_label', ['위치',           'Location',     'Расположение']);
 
  TLoc.Register('dlg.newproject.type_app',
    ['WPF 애플리케이션              (.exe)',
     'WPF Application                (.exe)',
     'WPF приложение                 (.exe)']);

  TLoc.Register('dlg.newproject.type_lib',
    ['WPF 사용자 정의 컨트롤 라이브러리  (.dll)',
     'WPF Custom Control Library     (.dll)',
     'Библиотека элементов WPF       (.dll)']);

  TLoc.Register('dlg.newproject.create_subfolder', ['프로젝트와 같은 이름의 폴더에 솔루션 만들기',           'Place project in a folder with the same name',     'Создать каталог для решения с именем проекта']);

  TLoc.Register('dlg.newproject.path_preview', ['위치: {0}',           'Location: {0}',     'Расположение: {0}']);
 
  TLoc.Register('dlg.saveas.folder_description', ['솔루션을 저장할 폴더를 선택하세요.',           'Select the folder where the solution will be saved.',     'Выберите папку для сохранения решения.']);


  // ── 설정(Настройки) 다이얼로그 — 첨부 이미지 기준 ───────────────────────
  // 좌측 내비게이션
  TLoc.Register('dlg.settings.title',            ['설정',        'Settings',        'Настройки']);
  TLoc.Register('dlg.settings.nav.general',      ['일반',        'General',         'Общие']);
  TLoc.Register('dlg.settings.nav.editor',       ['편집기',      'Editor',          'Редактор']);
  TLoc.Register('dlg.settings.nav.compile',      ['컴파일 옵션', 'Compile Options', 'Параметры компиляции']);
  TLoc.Register('dlg.settings.nav.intellisense', ['Intellisense','Intellisense',    'Intellisense']);
  
  // 일반 패널
  TLoc.Register('dlg.settings.general.header',          ['일반',                       'General',                             'Общие']);
  TLoc.Register('dlg.settings.general.lang_label',      ['언어',                       'Language',                            'Язык']);
  TLoc.Register('dlg.settings.general.pause_console',   ['콘솔 프로그램 종료 후 일시 정지', 'Pause after console program finishes', 'Пауза после завершения консольной программы']);
  TLoc.Register('dlg.settings.general.save_on_success', ['컴파일이 성공하면 파일 저장',   'Save files if compilation succeeded',  'Сохранять файлы при успешной компиляции']);
  TLoc.Register('dlg.settings.general.autocomplete',    ['시작 시 코드 자동완성 모드 켜기','Enable code auto-completion on startup','Включить автодополнение кода при запуске']);

  // ── 버튼 공통 ────────────────────────────────────────────────────────────
  TLoc.Register('btn.ok',     ['확인', 'OK',          'OK']);
  TLoc.Register('btn.cancel', ['취소', 'Cancel',      'Отмена']);
  TLoc.Register('btn.apply',  ['적용', 'Apply',       'Применить']);
  TLoc.Register('btn.browse', ['찾아보기...', 'Browse...', 'Обзор...']);

  // ── 메인 폼 제목 ─────────────────────────────────────────────────────────
  TLoc.Register('title.main_app', ['PascalABC-WPF-Designer', 'PascalABC-WPF-Designer', 'PascalABC-WPF-Designer']);

  // DockContent 창 제목
  TLoc.Register('dock.toolbox',    ['도구 상자',     'Toolbox',           'Панель инструментов']);
  TLoc.Register('dock.explorer',   ['솔루션 탐색기',  'Solution Explorer',  'Обозреватель решений']);
  TLoc.Register('dock.properties', ['속성',        'Properties',          'Свойства']);
  TLoc.Register('dock.output',     ['출력',        'Output',              'Вывод']);
  TLoc.Register('dock.errors',     ['오류 목록',    'Error List',          'Список ошибок']);
  TLoc.Register('dock.editor',     ['편집기',       'Editor',             'Редактор']);

  // 툴박스
  TLoc.Register('toolbox.title',             ['도구 상자',   'Toolbox',          'Панель инструментов']);
  TLoc.Register('toolbox.category.layout',   ['레이아웃',    'Layout',           'Макет']);
  TLoc.Register('toolbox.category.common',   ['공용 컨트롤',  'Common Controls',  'Общие элементы']);

  // 탭
  TLoc.Register('tab.design_xaml',           ['🎨 디자인 + XAML',   '🎨 Design + XAML',   '🎨 Дизайн + XAML']);
  TLoc.Register('tab.code',                  ['💻 코드',           '💻 Code',            '💻 Код']);
  TLoc.Register('btn.apply_xaml',         ['▶ XAML 적용',                '▶ Apply XAML',                 '▶ Применить XAML']);
  TLoc.Register('explorer.solution_root', ['솔루션 ''{0}'' (1개 프로젝트)', 'Solution ''{0}'' (1 project)', 'Решение ''{0}'' (1 проект)']);
 
 // 코드 생성기 주석
  TLoc.Register('codegen.comment.init_fields',    ['컨트롤 필드 초기화 (FindName)', 'Initialize control fields (FindName)', 'Инициализация полей элементов (FindName)']);
  TLoc.Register('codegen.comment.connect_events', ['이벤트 핸들러 연결',            'Connect event handlers',               'Подключение обработчиков событий']);
  TLoc.Register('codegen.comment.event_decl',     ['이벤트 핸들러 선언',            'Event handler declarations',           'Объявление обработчиков событий']);
  TLoc.Register('codegen.comment.event_impl',     ['이벤트 핸들러 구현',            'Event handler implementations',        'Реализация обработчиков событий']);
  TLoc.Register('codegen.comment.event_handler',  ['이벤트 핸들러',                'event handler',                        'обработчик события']);
  TLoc.Register('codegen.comment.impl',           ['구현',                        'implementation',                       'реализация']);
  TLoc.Register('codegen.comment.entrypoint',     ['애플리케이션 진입점',            'Application entry point',              'Точка входа приложения']);
  TLoc.Register('codegen.runtime_error',          ['실행 오류',                    'Runtime Error',                        'Ошибка выполнения']);

// 프로젝트 옵션 다이얼로그
  TLoc.Register('dlg.projectoptions.title',               ['프로젝트 옵션 — {0}',         'Project Options — {0}',         'Параметры проекта — {0}']);
  TLoc.Register('dlg.projectoptions.nav.info',            ['  🏷  프로젝트 정보',          '  🏷  Project Info',            '  🏷  Сведения о проекте']);
  TLoc.Register('dlg.projectoptions.nav.compiler',        ['  🔧  컴파일러',               '  🔧  Compiler',                '  🔧  Компилятор']);
  TLoc.Register('dlg.projectoptions.nav.output',          ['  📦  출력 설정',              '  📦  Output',                  '  📦  Вывод']);
  TLoc.Register('dlg.projectoptions.nav.optimize',        ['  ⚡  최적화',                 '  ⚡  Optimize',                '  ⚡  Оптимизация']);
  TLoc.Register('dlg.projectoptions.nav.codestyle',       ['  🎨  코드 스타일',            '  🎨  Code Style',              '  🎨  Стиль кода']);
  TLoc.Register('dlg.projectoptions.nav.editor',          ['  📝  에디터',                 '  📝  Editor',                  '  📝  Редактор']);
  TLoc.Register('dlg.projectoptions.nav.debug',           ['  ▶  디버그/실행',             '  ▶  Debug/Run',               '  ▶  Отладка/Запуск']);
  // 프로젝트 정보 페이지
  TLoc.Register('dlg.projectoptions.info.header',         ['프로젝트 정보',                'Project Info',                  'Сведения о проекте']);
  TLoc.Register('dlg.projectoptions.info.path',           ['프로젝트 경로',                'Project Path',                  'Путь к проекту']);
  TLoc.Register('dlg.projectoptions.info.classname',      ['클래스 이름',                  'Class Name',                    'Имя класса']);
  TLoc.Register('dlg.projectoptions.info.rootns',         ['루트 네임스페이스',             'Root Namespace',                'Корневое пространство имён']);
  TLoc.Register('dlg.projectoptions.info.type',           ['프로젝트 형식',                'Project Type',                  'Тип проекта']);
  TLoc.Register('dlg.projectoptions.info.name',           ['프로젝트 이름',                'Project Name',                  'Имя проекта']);
  TLoc.Register('dlg.projectoptions.info.hint',           ['프로젝트의 기본 정보를 설정합니다.', 'Configure basic project information.', 'Настройка основных сведений о проекте.']);
  TLoc.Register('dlg.projectoptions.info.type_app',       ['WPF 애플리케이션 (.exe)',      'WPF Application (.exe)',        'WPF приложение (.exe)']);
  TLoc.Register('dlg.projectoptions.info.type_lib',       ['WPF 컨트롤 라이브러리 (.dll)', 'WPF Control Library (.dll)',    'Библиотека элементов WPF (.dll)']);
  // 컴파일러 페이지
  TLoc.Register('dlg.projectoptions.compiler.header',     ['컴파일러 설정',                'Compiler Settings',             'Настройки компилятора']);
  TLoc.Register('dlg.projectoptions.compiler.path',       ['컴파일러 경로',                'Compiler Path',                 'Путь к компилятору']);
  TLoc.Register('dlg.projectoptions.compiler.args',       ['추가 컴파일 인수',             'Additional Arguments',          'Дополнительные аргументы']);
  TLoc.Register('dlg.projectoptions.compiler.no_console', ['콘솔 창 숨기기 (/noconsole)',  'Hide console (/noconsole)',      'Скрыть консоль (/noconsole)']);
  TLoc.Register('dlg.projectoptions.compiler.debug',      ['디버그 심볼 포함 (/debug)',    'Include debug symbols (/debug)', 'Включить отладочные символы (/debug)']);
  TLoc.Register('dlg.projectoptions.compiler.warn_err',   ['경고를 오류로 처리 (/werr)',   'Warnings as errors (/werr)',     'Предупреждения как ошибки (/werr)']);
  TLoc.Register('dlg.projectoptions.compiler.auto_clean', ['빌드 전 .pcu 캐시 자동 삭제', 'Auto-clean .pcu cache before build', 'Авто-очистка кэша .pcu перед сборкой']);
  TLoc.Register('dlg.projectoptions.compiler.hint',       ['PascalABC.NET 컴파일러(pabcnetc.exe) 경로와 빌드 옵션을 설정합니다.', 'Configure PascalABC.NET compiler path and build options.', 'Настройка пути к компилятору PascalABC.NET и параметров сборки.']);
  // 출력 페이지
  TLoc.Register('dlg.projectoptions.output.header',       ['출력 설정',                   'Output Settings',               'Настройки вывода']);
  TLoc.Register('dlg.projectoptions.output.copy_xaml',    ['XAML 파일을 출력 디렉터리에 복사', 'Copy XAML to output directory', 'Копировать XAML в каталог вывода']);
  TLoc.Register('dlg.projectoptions.output.embed_asm',    ['어셈블리 정보 포함',           'Embed assembly info',           'Включить сведения о сборке']);
  TLoc.Register('dlg.projectoptions.output.asm_header',   ['어셈블리 정보',               'Assembly Info',                 'Сведения о сборке']);
  TLoc.Register('dlg.projectoptions.output.asm_ver',      ['어셈블리 버전',               'Assembly Version',              'Версия сборки']);
  TLoc.Register('dlg.projectoptions.output.asm_copy',     ['저작권',                      'Copyright',                     'Авторское право']);
  TLoc.Register('dlg.projectoptions.output.asm_company',  ['회사',                        'Company',                       'Компания']);
  TLoc.Register('dlg.projectoptions.output.asm_title',    ['제목',                        'Title',                         'Заголовок']);
  TLoc.Register('dlg.projectoptions.output.dir',          ['출력 디렉터리',               'Output Directory',              'Каталог вывода']);
  TLoc.Register('dlg.projectoptions.output.file',         ['출력 파일명',                 'Output File',                   'Файл вывода']);
  TLoc.Register('dlg.projectoptions.output.hint',         ['빌드 출력 파일 경로와 어셈블리 메타데이터를 설정합니다.', 'Configure build output path and assembly metadata.', 'Настройка пути вывода сборки и метаданных сборки.']);
  // 최적화 페이지
  TLoc.Register('dlg.projectoptions.optimize.header',     ['최적화 설정',                 'Optimization Settings',         'Настройки оптимизации']);
  TLoc.Register('dlg.projectoptions.optimize.x86',        ['x86 (32비트)',                'x86 (32-bit)',                   'x86 (32-разрядная)']);
  TLoc.Register('dlg.projectoptions.optimize.x64',        ['x64 (64비트)',                'x64 (64-bit)',                   'x64 (64-разрядная)']);
  TLoc.Register('dlg.projectoptions.optimize.optimize',   ['코드 최적화 (/optimize)',     'Code optimization (/optimize)', 'Оптимизация кода (/optimize)']);
  TLoc.Register('dlg.projectoptions.optimize.inline',     ['인라인 확장 (/inline)',       'Inline expansion (/inline)',    'Встраивание (/inline)']);
  TLoc.Register('dlg.projectoptions.optimize.platform',   ['대상 플랫폼',                 'Target Platform',               'Целевая платформа']);
  TLoc.Register('dlg.projectoptions.optimize.hint',       ['컴파일 최적화 옵션을 설정합니다.', 'Configure compilation optimization options.', 'Настройка параметров оптимизации компиляции.']);
  // 코드 스타일 페이지
  TLoc.Register('dlg.projectoptions.codestyle.header',        ['코드 스타일',                          'Code Style',                            'Стиль кода']);
  TLoc.Register('dlg.projectoptions.codestyle.brace_pascal',  ['Pascal (begin/end 같은 줄)',           'Pascal (begin/end same line)',           'Pascal (begin/end на той же строке)']);
  TLoc.Register('dlg.projectoptions.codestyle.brace_allman',  ['Allman (begin 새 줄)',                 'Allman (begin new line)',                'Allman (begin на новой строке)']);
  TLoc.Register('dlg.projectoptions.codestyle.use_tabs',      ['탭 문자 사용',                         'Use tab characters',                    'Использовать символы табуляции']);
  TLoc.Register('dlg.projectoptions.codestyle.auto_begin',    ['procedure/function 뒤 begin 자동 삽입','Auto-insert begin after procedure/function','Авто-вставка begin после procedure/function']);
  TLoc.Register('dlg.projectoptions.codestyle.auto_end',      ['begin 뒤 end 자동 완성',              'Auto-complete end after begin',          'Авто-завершение end после begin']);
  TLoc.Register('dlg.projectoptions.codestyle.gen_comments',  ['이벤트 핸들러에 TODO 주석 생성',       'Generate TODO comments in event handlers','Создавать TODO-комментарии в обработчиках']);
  TLoc.Register('dlg.projectoptions.codestyle.comment_style', ['주석 스타일',                          'Comment Style',                         'Стиль комментариев']);
  TLoc.Register('dlg.projectoptions.codestyle.brace_style',   ['중괄호 스타일',                        'Brace Style',                           'Стиль скобок']);
  TLoc.Register('dlg.projectoptions.codestyle.indent_size',   ['들여쓰기 크기',                        'Indent Size',                           'Размер отступа']);
  TLoc.Register('dlg.projectoptions.codestyle.hint',          ['자동 코드 생성 시 적용되는 스타일을 설정합니다.','Configure style applied during auto code generation.','Настройка стиля автоматической генерации кода.']);
  // 에디터 페이지
  TLoc.Register('dlg.projectoptions.editor.header',       ['에디터 설정',                 'Editor Settings',               'Настройки редактора']);
  TLoc.Register('dlg.projectoptions.editor.linenum_xaml', ['XAML 에디터',                 'XAML Editor',                   'Редактор XAML']);
  TLoc.Register('dlg.projectoptions.editor.linenum_code', ['코드 에디터',                 'Code Editor',                   'Редактор кода']);
  TLoc.Register('dlg.projectoptions.editor.hl_xaml',      ['XAML 구문 강조',              'XAML syntax highlight',         'Подсветка синтаксиса XAML']);
  TLoc.Register('dlg.projectoptions.editor.hl_code',      ['Pascal 구문 강조',            'Pascal syntax highlight',       'Подсветка синтаксиса Pascal']);
  TLoc.Register('dlg.projectoptions.editor.word_wrap',    ['자동 줄바꿈',                 'Word wrap',                     'Перенос строк']);
  TLoc.Register('dlg.projectoptions.editor.fold_xaml',    ['XAML XML 폴딩',               'XAML XML folding',              'Свёртывание XML в XAML']);
  TLoc.Register('dlg.projectoptions.editor.fold_code',    ['Pascal begin/end 폴딩',       'Pascal begin/end folding',      'Свёртывание begin/end в Pascal']);
  TLoc.Register('dlg.projectoptions.editor.show_ws',      ['공백 문자 표시',              'Show whitespace',               'Показать пробельные символы']);
  TLoc.Register('dlg.projectoptions.editor.hl_line',      ['현재 줄 강조',                'Highlight current line',        'Выделить текущую строку']);
  TLoc.Register('dlg.projectoptions.editor.auto_comp',    ['자동 완성',                   'Auto-complete',                 'Автодополнение']);
  TLoc.Register('dlg.projectoptions.editor.linenum_label',['줄 번호 표시',                'Show line numbers',             'Показать номера строк']);
  TLoc.Register('dlg.projectoptions.editor.tab_size',     ['탭 너비',                     'Tab size',                      'Ширина табуляции']);
  TLoc.Register('dlg.projectoptions.editor.font_size',    ['폰트 크기',                   'Font size',                     'Размер шрифта']);
  TLoc.Register('dlg.projectoptions.editor.font',         ['폰트',                        'Font',                          'Шрифт']);
  TLoc.Register('dlg.projectoptions.editor.hint',         ['XAML/코드 에디터 표시 옵션을 설정합니다.', 'Configure XAML/code editor display options.', 'Настройка параметров отображения редактора XAML/кода.']);
  // 디버그 페이지
  TLoc.Register('dlg.projectoptions.debug.header',        ['디버그/실행 설정',            'Debug/Run Settings',            'Настройки отладки/запуска']);
  TLoc.Register('dlg.projectoptions.debug.start_project', ['프로젝트 (기본)',             'Project (default)',             'Проект (по умолчанию)']);
  TLoc.Register('dlg.projectoptions.debug.start_ext',     ['외부 프로그램',               'External program',              'Внешняя программа']);
  TLoc.Register('dlg.projectoptions.debug.use_env',       ['현재 환경 변수 사용',         'Use current environment variables', 'Использовать текущие переменные среды']);
  TLoc.Register('dlg.projectoptions.debug.run_before',    ['빌드 전 프로젝트 저장 확인',  'Confirm save before build',     'Подтвердить сохранение перед сборкой']);
  TLoc.Register('dlg.projectoptions.debug.work_dir',      ['작업 디렉터리',               'Working Directory',             'Рабочий каталог']);
  TLoc.Register('dlg.projectoptions.debug.start_args',    ['시작 인수',                   'Start Arguments',               'Аргументы запуска']);
  TLoc.Register('dlg.projectoptions.debug.ext_prog',      ['외부 프로그램',               'External Program',              'Внешняя программа']);
  TLoc.Register('dlg.projectoptions.debug.start_act',     ['시작 동작',                   'Start Action',                  'Действие при запуске']);
  TLoc.Register('dlg.projectoptions.debug.hint',          ['빌드 후 실행 방식과 디버그 환경을 설정합니다.', 'Configure run mode and debug environment after build.', 'Настройка режима запуска и среды отладки после сборки.']);
  // 파일 대화상자
  TLoc.Register('dlg.browse_compiler.filter', ['실행 파일|pabcnetc.exe|모든 파일|*.*', 'Executable|pabcnetc.exe|All files|*.*', 'Исполняемый файл|pabcnetc.exe|Все файлы|*.*']);
  TLoc.Register('dlg.browse_compiler.title',  ['컴파일러 선택',  'Select Compiler',  'Выбрать компилятор']);

  //TLoc.Register('dlg.save.filter',            ['XAML 파일|*.xaml|모든 파일|*.*', 'XAML files|*.xaml|All files|*.*', 'Файлы XAML|*.xaml|Все файлы|*.*']);
  //TLoc.Register('dlg.open.filter',            ['XAML 파일|*.xaml|모든 파일|*.*', 'XAML files|*.xaml|All files|*.*', 'Файлы XAML|*.xaml|Все файлы|*.*']);
  TLoc.Register('dlg.open.filter',            ['PascalABC-WPF 솔루션|*.pwsln|PascalABC-WPF 프로젝트|*.pwproj|모든 파일|*.*',
   'PascalABC-WPF Solution|*.pwsln|PascalABC-WPF Project|*.pwproj|All Files|*.*',
   'Решение PascalABC-WPF|*.pwsln|Проект PascalABC-WPF|*.pwproj|Все файлы|*.*']);

  
  // 빌드 출력 메시지
  TLoc.Register('msg.build.start',            ['빌드 시작: {0}',            'Build started: {0}',            'Сборка запущена: {0}']);
  TLoc.Register('msg.build.file_saved',       ['파일 저장: {0}',            'File saved: {0}',               'Файл сохранён: {0}']);
  TLoc.Register('msg.build.compiler',         ['컴파일러: {0}',             'Compiler: {0}',                 'Компилятор: {0}']);
  TLoc.Register('msg.build.target',           ['대상: {0}',                 'Target: {0}',                   'Цель: {0}']);
  TLoc.Register('msg.build.end',              ['빌드 종료 (경과: {0}초, 종료코드: {1})', 'Build finished (elapsed: {0}s, exit code: {1})', 'Сборка завершена (прошло: {0}с, код выхода: {1})']);
  TLoc.Register('msg.build.success',          ['빌드 성공: {0}',            'Build succeeded: {0}',          'Сборка успешна: {0}']);
  TLoc.Register('msg.build.asm_patched',      ['{0} 에 어셈블리 버전 정보가 적용되었습니다.', 'Assembly version info applied to {0}.', 'Сведения о версии сборки применены к {0}.']);
  TLoc.Register('msg.build.asm_patch_failed', ['어셈블리 버전 정보 적용 실패: {0}', 'Failed to apply assembly version info: {0}', 'Не удалось применить сведения о версии: {0}']);
  TLoc.Register('msg.build.run',              ['실행: {0}',                 'Running: {0}',                  'Запуск: {0}']);
  TLoc.Register('msg.build.process_exit',     ['프로세스 종료 (종료코드: {0})', 'Process exited (exit code: {0})', 'Процесс завершён (код выхода: {0})']);
  TLoc.Register('msg.build.failed_check_output', ['빌드 실패 — 출력 탭을 확인하세요.', 'Build failed — check the Output tab.', 'Сборка не удалась — проверьте вкладку «Вывод».']);
  TLoc.Register('msg.build.failed_check_log',    ['빌드 실패 — 출력 탭에서 전체 로그를 확인하세요.', 'Build failed — see full log in the Output tab.', 'Сборка не удалась — полный журнал во вкладке «Вывод».']);
  // 테스트 호스트 메시지
  TLoc.Register('msg.testhost.creating',      ['컨트롤 테스트 호스트 생성',  'Creating control test host',    'Создание тестового хоста элемента']);
  TLoc.Register('msg.testhost.build_failed',  ['테스트 호스트 빌드 실패.',   'Test host build failed.',       'Сборка тестового хоста не удалась.']);
  TLoc.Register('msg.testhost.build_success', ['테스트 호스트 빌드 성공: {0}', 'Test host build succeeded: {0}', 'Сборка тестового хоста успешна: {0}']);
  TLoc.Register('msg.testhost.window_title',  ['컨트롤 테스트: {0}',         'Control Test: {0}',             'Тест элемента: {0}']);
  TLoc.Register('msg.testhost.error_title',   ['테스트 호스트 오류',         'Test Host Error',               'Ошибка тестового хоста']);
  TLoc.Register('msg.testhost.save_error',    ['호스트 파일 저장 오류: {0}', 'Host file save error: {0}',     'Ошибка сохранения файла хоста: {0}']);
  

  // ── 속성창 이벤트 탭 (Properties ⚡) ─────────────────────────────────────
  TLoc.Register('dock.properties.mode_props',  ['속성',  'Properties', 'Свойства']);
  TLoc.Register('dock.properties.mode_events', ['이벤트', 'Events',    'События']);

  TLoc.Register('col.events.name',    ['이벤트', 'Event',   'Событие']);
  TLoc.Register('col.events.handler', ['핸들러', 'Handler', 'Обработчик']);

  TLoc.Register('dock.properties.events_hint_default',
    ['컨트롤을 더블클릭하면 핸들러로 이동합니다.',
     'Double-click an event to jump to its handler.',
     'Дважды щёлкните событие, чтобы перейти к обработчику.']);
  TLoc.Register('dock.properties.events_hint_none',
    ['디자이너에서 컨트롤을 선택하면 이벤트 목록이 표시됩니다.',
     'Select a control in the designer to see its events.',
     'Выберите элемент в дизайнере, чтобы увидеть его события.']);
  TLoc.Register('dock.properties.events_hint_noname',
    ['이 컨트롤은 이름(x:Name)이 없어 이벤트를 연결할 수 없습니다.',
     'This control has no name (x:Name), so events cannot be wired.',
     'У этого элемента нет имени (x:Name), события подключить нельзя.']);
  TLoc.Register('dock.properties.events_hint_selected',
    ['{0} ({1}) — 더블클릭하면 핸들러로 이동합니다.',
     '{0} ({1}) — double-click to jump to its handler.',
     '{0} ({1}) — дважды щёлкните, чтобы перейти к обработчику.']);
  TLoc.Register('dock.properties.events_placeholder',
    ['(더블클릭하여 생성)', '(double-click to create)', '(дважды щёлкните для создания)']);

  TLoc.Register('msg.event.navigated', ['이벤트 핸들러로 이동: {0}', 'Navigated to event handler: {0}', 'Переход к обработчику события: {0}']);

  // 새 메뉴/라벨 추가 시 이 아래에 계속 추가하면 됩니다.
end;

end.