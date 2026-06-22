unit ControlInfo;

// =============================================================================
// ControlInfo.pas
//   XAML 파싱 결과로 얻은 컨트롤 정보를 담는 클래스
// =============================================================================

uses
  System.Collections.Generic;

type
  TControlInfo = class
    Name     : string;
    TypeName : string;
    // Tuple<이벤트명, 핸들러명>
    Events   : System.Collections.Generic.List<System.Tuple<string, string>>;

    constructor Create(aName, aTypeName: string);
  end;

constructor TControlInfo.Create(aName, aTypeName: string);
begin
  Name     := aName;
  TypeName := aTypeName;
  Events   := new System.Collections.Generic.List<System.Tuple<string, string>>();
end;

end.