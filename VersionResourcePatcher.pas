unit VersionResourcePatcher;

// =============================================================================
// VersionResourcePatcher.pas
//
//   빌드된 EXE/DLL 에 Win32 VERSIONINFO 리소스(어셈블리 버전/제목/회사/저작권)를
//   직접 패치(삽입)하는 유닛.
//
//   배경
//   ----
//   PascalABC.NET 컴파일러(pabcnetc.exe)는 csc.exe 의 /win32res: 같은
//   "컴파일 시점에 VERSIONINFO 리소스를 끼워넣는" 옵션이 문서화되어 있지 않다.
//   그래서 이 방식을 빌드 인자에만 의존하면 동작을 신뢰할 수 없다.
//
//   대신 Resource Hacker, verpatch 같은 도구들이 쓰는 방식과 동일하게,
//   "빌드가 끝난 뒤 이미 만들어진 EXE/DLL 파일"에 대해
//     BeginUpdateResource → UpdateResource → EndUpdateResource
//   Win32 API 를 P/Invoke 로 직접 호출해서 VS_VERSION_INFO 리소스를 박아넣는다.
//   rc.exe / Windows SDK / 외부 도구가 전혀 필요 없다.
//
//   사용법
//   ------
//   if TVersionResourcePatcher.TryPatch(exePath, options, errMsg) then ...
// =============================================================================

uses
  System,
  System.IO,
  System.Text,
  System.Runtime.InteropServices,
  ProjectOptions;        // TProjectOptions

// ── Win32 P/Invoke 선언 (유닛 레벨 전역 함수) ──
// pFileName 을 IntPtr(LPCWSTR) 로 받아 Wide 문자열 마샬링을 직접 제어한다.
// PascalABC.NET 의 P/Invoke 는 string 파라미터를 ANSI 로 마샬링할 수 있어
// BeginUpdateResourceW(W = Wide) 에 넘기면 경로가 깨져 코드 6 이 반환된다.
function Win32_BeginUpdateResourceW(pFileName: IntPtr;
  bDeleteExistingResources: boolean): IntPtr;
  external 'kernel32.dll' name 'BeginUpdateResourceW';

function Win32_UpdateResourceW(hUpdate: IntPtr;
  lpType: IntPtr; lpName: IntPtr; wLanguage: UInt16;
  lpData: IntPtr; cbData: UInt32): boolean;
  external 'kernel32.dll' name 'UpdateResourceW';

function Win32_EndUpdateResourceW(hUpdate: IntPtr;
  fDiscard: boolean): boolean;
  external 'kernel32.dll' name 'EndUpdateResourceW';

const
  RT_VERSION : UInt16 = 16;
  VS_FFI_SIGNATURE   : UInt32 = $FEEF04BD;
  VS_FFI_STRUCVERSION: UInt32 = $00010000;

type
  TVersionResourcePatcher = class
  private
    class function MakeIntResource(id: UInt16): IntPtr;
    class function PadLen(len: integer): integer;
    class procedure WriteWord(stream: System.IO.MemoryStream; v: UInt16);
    class procedure WriteDWord(stream: System.IO.MemoryStream; v: UInt32);
    class procedure WritePadding(stream: System.IO.MemoryStream);
    class procedure WriteWideStringZ(stream: System.IO.MemoryStream; s: string);
    class function BuildStringEntry(key, value: string): array of byte;
    class function BuildStringFileInfo(entries: array of array of byte): array of byte;
    class function BuildVarFileInfo: array of byte;
    class function BuildVersionInfoResource(opt: TProjectOptions): array of byte;
    class procedure ParseVersionParts(verStr: string;
      var p1, p2, p3, p4: UInt16);

  public
    class function TryPatch(targetFilePath: string; opt: TProjectOptions;
      var errorMessage: string): boolean;
  end;

//implementation

class function TVersionResourcePatcher.PadLen(len: integer): integer;
begin
  Result := (4 - (len mod 4)) mod 4;
end;

class function TVersionResourcePatcher.MakeIntResource(id: UInt16): IntPtr;
begin
  Result := IntPtr(integer(id));
end;

class procedure TVersionResourcePatcher.WriteWord(stream: System.IO.MemoryStream; v: UInt16);
begin
  stream.WriteByte(byte(v and $FF));
  stream.WriteByte(byte((v shr 8) and $FF));
end;

class procedure TVersionResourcePatcher.WriteDWord(stream: System.IO.MemoryStream; v: UInt32);
begin
  stream.WriteByte(byte(v and $FF));
  stream.WriteByte(byte((v shr 8)  and $FF));
  stream.WriteByte(byte((v shr 16) and $FF));
  stream.WriteByte(byte((v shr 24) and $FF));
end;

class procedure TVersionResourcePatcher.WritePadding(stream: System.IO.MemoryStream);
var
  pad, i: integer;
begin
  pad := PadLen(integer(stream.Length));
  i := 0;
  while i < pad do
  begin
    stream.WriteByte(0);
    i += 1;
  end;
end;

class procedure TVersionResourcePatcher.WriteWideStringZ(stream: System.IO.MemoryStream; s: string);
var
  bytes: array of byte;
begin
  bytes := System.Text.Encoding.Unicode.GetBytes(s + #0);
  stream.Write(bytes, 0, bytes.Length);
end;

class function TVersionResourcePatcher.BuildStringEntry(key, value: string): array of byte;
var
  ms       : System.IO.MemoryStream;
  valueLen : integer;
  totalLen : UInt16;
begin
  ms := new System.IO.MemoryStream();
  valueLen := value.Length + 1;

  WriteWord(ms, 0);               // wLength (나중에 패치)
  WriteWord(ms, UInt16(valueLen)); // wValueLength (WCHAR 단위)
  WriteWord(ms, 1);               // wType = 1 (텍스트)
  WriteWideStringZ(ms, key);      // szKey
  WritePadding(ms);               // Value 시작 전 4바이트 정렬
  WriteWideStringZ(ms, value);    // Value
  WritePadding(ms);               // 다음 항목을 위한 4바이트 정렬

  Result := ms.ToArray();
  totalLen := UInt16(Result.Length);
  Result[0] := byte(totalLen and $FF);
  Result[1] := byte((totalLen shr 8) and $FF);
end;

class function TVersionResourcePatcher.BuildStringFileInfo(
  entries: array of array of byte): array of byte;
var
  msTable, msInfo      : System.IO.MemoryStream;
  e                    : array of byte;
  tableBytes, infoBytes: array of byte;
begin
  msTable := new System.IO.MemoryStream();
  WriteWord(msTable, 0);  // wLength (나중에 패치)
  WriteWord(msTable, 0);  // wValueLength = 0
  WriteWord(msTable, 1);  // wType = 1
  WriteWideStringZ(msTable, '040904B0');
  WritePadding(msTable);
  foreach e in entries do
    msTable.Write(e, 0, e.Length);

  tableBytes := msTable.ToArray();
  tableBytes[0] := byte(tableBytes.Length and $FF);
  tableBytes[1] := byte((tableBytes.Length shr 8) and $FF);

  msInfo := new System.IO.MemoryStream();
  WriteWord(msInfo, 0);  // wLength (나중에 패치)
  WriteWord(msInfo, 0);  // wValueLength = 0
  WriteWord(msInfo, 1);  // wType = 1
  WriteWideStringZ(msInfo, 'StringFileInfo');
  WritePadding(msInfo);
  msInfo.Write(tableBytes, 0, tableBytes.Length);

  infoBytes := msInfo.ToArray();
  infoBytes[0] := byte(infoBytes.Length and $FF);
  infoBytes[1] := byte((infoBytes.Length shr 8) and $FF);

  Result := infoBytes;
end;

class function TVersionResourcePatcher.BuildVarFileInfo: array of byte;
var
  msVar, msTrans      : System.IO.MemoryStream;
  transBytes, varBytes: array of byte;
begin
  msTrans := new System.IO.MemoryStream();
  WriteWord(msTrans, 0);  // wLength
  WriteWord(msTrans, 4);  // wValueLength = 4바이트(DWORD 1개)
  WriteWord(msTrans, 0);  // wType = 0 (바이너리)
  WriteWideStringZ(msTrans, 'Translation');
  WritePadding(msTrans);
  WriteWord(msTrans, $0409); // langID
  WriteWord(msTrans, $04B0); // codepage(1200=유니코드)
  WritePadding(msTrans);

  transBytes := msTrans.ToArray();
  transBytes[0] := byte(transBytes.Length and $FF);
  transBytes[1] := byte((transBytes.Length shr 8) and $FF);

  msVar := new System.IO.MemoryStream();
  WriteWord(msVar, 0);  // wLength
  WriteWord(msVar, 0);  // wValueLength = 0
  WriteWord(msVar, 1);  // wType = 1
  WriteWideStringZ(msVar, 'VarFileInfo');
  WritePadding(msVar);
  msVar.Write(transBytes, 0, transBytes.Length);

  varBytes := msVar.ToArray();
  varBytes[0] := byte(varBytes.Length and $FF);
  varBytes[1] := byte((varBytes.Length shr 8) and $FF);

  Result := varBytes;
end;

class procedure TVersionResourcePatcher.ParseVersionParts(verStr: string;
  var p1, p2, p3, p4: UInt16);
var
  parts        : array of string;
  v1, v2, v3, v4: integer;
begin
  p1 := 0; p2 := 0; p3 := 0; p4 := 0;
  if verStr.Trim() = '' then exit;
  parts := verStr.Trim().Split('.');
  v1 := 0; v2 := 0; v3 := 0; v4 := 0;
  if parts.Length >= 1 then integer.TryParse(parts[0], v1);
  if parts.Length >= 2 then integer.TryParse(parts[1], v2);
  if parts.Length >= 3 then integer.TryParse(parts[2], v3);
  if parts.Length >= 4 then integer.TryParse(parts[3], v4);
  p1 := UInt16(v1 and $FFFF);
  p2 := UInt16(v2 and $FFFF);
  p3 := UInt16(v3 and $FFFF);
  p4 := UInt16(v4 and $FFFF);
end;

class function TVersionResourcePatcher.BuildVersionInfoResource(
  opt: TProjectOptions): array of byte;
var
  ms             : System.IO.MemoryStream;
  // ★ AddEntry 중첩 프로시저 제거 — 외부 변수 캡처 시 PascalABC.NET 이
  //   잘못된 IL 을 생성해 "invalid program" 오류를 유발하므로 인라인으로 전개
  stringEntries  : array of array of byte;
  entryCount     : integer;
  stringFileInfo : array of byte;
  varFileInfo    : array of byte;
  fileVerHi, fileVerLo, prodVerHi, prodVerLo: UInt32;
  p1, p2, p3, p4: UInt16;
  productName    : string;
  title, company, copyrightTxt, version: string;
  totalLen       : UInt32;
begin
  title        := (if opt.AssemblyTitle.Trim()   <> '' then opt.AssemblyTitle.Trim()   else opt.ProjectName);
  company      := opt.AssemblyCompany.Trim();
  copyrightTxt := opt.AssemblyCopyright.Trim();
  version      := (if opt.AssemblyVersion.Trim() <> '' then opt.AssemblyVersion.Trim() else '1.0.0.0');
  productName  := opt.ProjectName;

  ParseVersionParts(version, p1, p2, p3, p4);
  fileVerHi := (UInt32(p1) shl 16) or UInt32(p2);
  fileVerLo := (UInt32(p3) shl 16) or UInt32(p4);
  prodVerHi := fileVerHi;
  prodVerLo := fileVerLo;

  // ── StringFileInfo 자식 항목 구성 (AddEntry 인라인 전개) ──
  SetLength(stringEntries, 8);
  entryCount := 0;

  stringEntries[entryCount] := BuildStringEntry('FileVersion',      version);      entryCount += 1;
  stringEntries[entryCount] := BuildStringEntry('ProductVersion',   version);      entryCount += 1;
  stringEntries[entryCount] := BuildStringEntry('ProductName',      productName);  entryCount += 1;
  stringEntries[entryCount] := BuildStringEntry('FileDescription',  title);        entryCount += 1;
  stringEntries[entryCount] := BuildStringEntry('InternalName',     productName);  entryCount += 1;
  stringEntries[entryCount] := BuildStringEntry('OriginalFilename', productName + '.exe'); entryCount += 1;
  if company <> '' then
  begin
    stringEntries[entryCount] := BuildStringEntry('CompanyName', company);
    entryCount += 1;
  end;
  if copyrightTxt <> '' then
  begin
    stringEntries[entryCount] := BuildStringEntry('LegalCopyright', copyrightTxt);
    entryCount += 1;
  end;
  SetLength(stringEntries, entryCount);

  stringFileInfo := BuildStringFileInfo(stringEntries);
  varFileInfo    := BuildVarFileInfo();

  ms := new System.IO.MemoryStream();
  WriteWord(ms, 0);    // wLength (나중에 패치)
  WriteWord(ms, 52);   // wValueLength = sizeof(VS_FIXEDFILEINFO)
  WriteWord(ms, 0);    // wType = 0 (바이너리)
  WriteWideStringZ(ms, 'VS_VERSION_INFO');
  WritePadding(ms);

  // VS_FIXEDFILEINFO (52바이트, 13개 DWORD)
  WriteDWord(ms, VS_FFI_SIGNATURE);    // dwSignature
  WriteDWord(ms, VS_FFI_STRUCVERSION); // dwStrucVersion
  WriteDWord(ms, fileVerHi);           // dwFileVersionMS
  WriteDWord(ms, fileVerLo);           // dwFileVersionLS
  WriteDWord(ms, prodVerHi);           // dwProductVersionMS
  WriteDWord(ms, prodVerLo);           // dwProductVersionLS
  WriteDWord(ms, $3F);                 // dwFileFlagsMask
  WriteDWord(ms, 0);                   // dwFileFlags
  WriteDWord(ms, $00040004);           // dwFileOS = VOS_NT_WINDOWS32
  WriteDWord(ms, (if opt.ProjectType = ptWpfControlLibrary then UInt32($00000002) else UInt32($00000001)));
  WriteDWord(ms, 0);                   // dwFileSubtype
  WriteDWord(ms, 0);                   // dwFileDateMS
  WriteDWord(ms, 0);                   // dwFileDateLS
  WritePadding(ms);

  ms.Write(stringFileInfo, 0, stringFileInfo.Length);
  ms.Write(varFileInfo,    0, varFileInfo.Length);

  Result := ms.ToArray();
  totalLen := UInt32(Result.Length);
  Result[0] := byte(totalLen and $FF);
  Result[1] := byte((totalLen shr 8) and $FF);
end;

class function TVersionResourcePatcher.TryPatch(targetFilePath: string;
  opt: TProjectOptions; var errorMessage: string): boolean;
var
  resBytes : array of byte;
  hUpdate  : IntPtr;
  pData    : IntPtr;
  ok       : boolean;
begin
  Result := false;
  errorMessage := '';

  if not opt.EmbedAssemblyInfo then
  begin
    Result := true;
    exit;
  end;

  if not System.IO.File.Exists(targetFilePath) then
  begin
    errorMessage := '대상 파일을 찾을 수 없습니다: ' + targetFilePath;
    exit;
  end;

  try
    resBytes := BuildVersionInfoResource(opt);
  except
    on ex: System.Exception do
    begin
      errorMessage := 'VERSIONINFO 리소스 생성 오류: ' + ex.Message;
      exit;
    end;
  end;

  // BeginUpdateResourceW 는 Wide(UTF-16) 경로를 요구한다.
  // PascalABC.NET P/Invoke 가 string 을 ANSI 로 마샬링할 수 있으므로
  // Marshal.StringToHGlobalUni 로 직접 변환해서 넘긴다.
  // 빌드 프로세스 종료 직후 OS 잠금 해제까지 시간이 걸리므로 최대 10회 재시도.
  var pFileName := System.Runtime.InteropServices.Marshal.StringToHGlobalUni(targetFilePath);
  try
    hUpdate := IntPtr.Zero;
    var retryIdx := 0;
    while retryIdx < 10 do
    begin
      hUpdate := Win32_BeginUpdateResourceW(pFileName, false);
      if hUpdate <> IntPtr.Zero then break;
      System.Threading.Thread.Sleep(100);
      retryIdx += 1;
    end;
  finally
    System.Runtime.InteropServices.Marshal.FreeHGlobal(pFileName);
  end;
  if hUpdate = IntPtr.Zero then
  begin
    errorMessage := 'BeginUpdateResource 실패 (코드 ' +
      System.Runtime.InteropServices.Marshal.GetLastWin32Error().ToString() + ')';
    exit;
  end;

  pData := System.Runtime.InteropServices.Marshal.AllocHGlobal(resBytes.Length);
  try
    System.Runtime.InteropServices.Marshal.Copy(resBytes, 0, pData, resBytes.Length);

    ok := Win32_UpdateResourceW(hUpdate, MakeIntResource(RT_VERSION),
      MakeIntResource(1), $0409, pData, UInt32(resBytes.Length));

    if not ok then
    begin
      errorMessage := 'UpdateResource 실패 (코드 ' +
        System.Runtime.InteropServices.Marshal.GetLastWin32Error().ToString() + ')';
      Win32_EndUpdateResourceW(hUpdate, true);
      exit;
    end;
  finally
    System.Runtime.InteropServices.Marshal.FreeHGlobal(pData);
  end;

  if not Win32_EndUpdateResourceW(hUpdate, false) then
  begin
    errorMessage := 'EndUpdateResource 실패 (코드 ' +
      System.Runtime.InteropServices.Marshal.GetLastWin32Error().ToString() + ')';
    exit;
  end;

  Result := true;
end;

end.