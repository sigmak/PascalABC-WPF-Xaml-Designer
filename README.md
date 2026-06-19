# PascalABC-WPF-Xaml-Designer
PascalABC.net 개발툴을 활용한 pascal wpf xaml Designer

[Ver 2.0.2]
기본 예제 빌드 후 실행시 program 이름을 fNamespace와 불일치 해결

[Ver 2.0.1]

* function  ExtractInnerXamlForBuild 을 function  PrepareXamlForBuild 로 함수 교체

* function  GenerateInitializeComponent 함수 내용 전부 교체

* OnBuild에서 호출부 수정 buildXaml := ExtractInnerXamlForBuild(fXamlEditor.Text); ->  buildXaml := PrepareXamlForBuild(fXamlEditor.Text);

* GenerateWpfAppCode에 참조/uses 추가

* GenerateControlLibCode에도 동일하게 추가

* PreprocessXaml (디자이너 미리보기용)도 같은 버그가 있어서 함께 수정
  

빌드 전에 정의되지 않은 커스텀 타입을 미리 스캔해서 ".NET 예외 대신" 친절한 한글 안내("이 클래스를 구현하세요")를 띄우는 기능이 필요한데 아직 미구현.

* 주의사항

 MainWindow.exe 의 정상적인 작동을 위해 같은 폴더에 MainWindow.xaml 파일이 존재해야함.
 
 그외 소소한(?) 버그가 있을수도 있음.

<img src='https://github.com/sigmak/PascalABC-WPF-Xaml-Designer/blob/main/screenshot/ver-2-0-1.png' />

<img src='https://github.com/sigmak/PascalABC-WPF-Xaml-Designer/blob/main/screenshot/ver-2-0-1B.png' />


