# PascalABC-WPF-Xaml-Designer
PascalABC.net 개발툴을 활용한 pascal wpf xaml Designer

[Ver 1.3.0]

* 정상적으로 빌드 최초 성공

* XAML 디자인 으로 빌드후 실행시 그 디자인 그대로 실행

* 다만 MainWindow.pas 에 버튼 클릭 이벤트 내 코드가 삽입되면 그건 아직 지원이 안됨.

  현재 loaded := XamlReader.Load(fs) as Window; 이런 방식으로는 C# WPF 처럼 사용할수 없고

  새로 구성해야됨.
  
<img src='https://github.com/sigmak/PascalABC-WPF-Xaml-Designer/blob/main/screenshot/ver-1-3-0.png' />

