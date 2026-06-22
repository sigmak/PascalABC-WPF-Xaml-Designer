# PascalABC-WPF-Xaml-Designer
PascalABC.net 개발툴을 활용한 pascal wpf xaml Designer

[Ver 2.2.1]
* 디자인에서 버튼을 더블 클릭하면 pascal 코드 에디터 창에 버튼 이벤트 소스코드에 커서가 위치되도록 수정.

<img src='https://github.com/sigmak/PascalABC-WPF-Xaml-Designer/blob/main/screenshot/ver-2-2-1.png' />
<img src='https://github.com/sigmak/PascalABC-WPF-Xaml-Designer/blob/main/screenshot/ver-2-2-1B.png' />
  

[Ver 2.2.0]

* 프로젝트 파일 explorer 추가

* 디자인탭과 XAML 에디터 탭은 하나의 탭으로 합쳐서 '상-하' 와 '좌-우'로 같이 배치되도록 수정.

* unit1.pas 소스코드 하나가 너머 길어져서 기능별로 분리함.

* Models  기능 : ProjectOptions.pas, ControlInfo.pas

* Events  기능 : WpfEventMap.pas

* Editor  기능 : PascalHighlighting.pas, PascalFolding.pas

* CodeGen 기능 : XamlParser.pas, XamlPreprocessor.pas, PascalCodeGenerator.pas

* 메인 폼   기능 : Form1Unit.pas


빌드 전에 정의되지 않은 커스텀 타입을 미리 스캔해서 ".NET 예외 대신" 친절한 한글 안내("이 클래스를 구현하세요")를 띄우는 기능이 필요한데 아직 미구현.

* 주의사항

 MainWindow.exe 의 정상적인 작동을 위해 같은 폴더에 MainWindow.xaml 파일이 존재해야함.
 
 그외 소소한(?) 버그가 있을수도 있음.

<img src='https://github.com/sigmak/PascalABC-WPF-Xaml-Designer/blob/main/screenshot/ver-2-2-0.png' />

