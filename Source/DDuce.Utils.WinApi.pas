{
  Copyright (C) 2013-2018 Tim Sinaeve tim.sinaeve@gmail.com

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
}

unit DDuce.Utils.Winapi;

interface

uses
  Winapi.Windows,
  System.SysUtils;

function GetExenameForProcess(AProcessID: DWORD): string;

function GetExenameForWindow(AWndHandle: HWND): string;

function GetExenameForProcessUsingPsAPI(AProcessID: DWORD): string;

function GetExenameForProcessUsingToolhelp32(AProcessID: DWORD): string;

function GetExePathForProcess(AProcessID: DWORD): string;

implementation

uses
  Winapi.PsAPI, Winapi.TlHelp32;

{$REGION 'interfaced routines'}
function GetExenameForProcessUsingPsAPI(AProcessID: DWORD): string;
var
  I           : DWORD;
  LCBNeeded   : DWORD;
  LModules    : array [1 .. 1024] of HINST;
  LProcHandle : THandle;
  LFileName   : array [0 .. 512] of Char;
begin
  SetLastError(0);
  Result     := '';
  LProcHandle := OpenProcess(
    PROCESS_QUERY_INFORMATION or PROCESS_VM_READ,
    False,
    AProcessID
  );
  if LProcHandle <> 0 then
  begin
    try
      if EnumProcessModules(LProcHandle, @LModules[1], SizeOf(LModules), LCBNeeded)
      then
        for I := 1 to LCBNeeded div SizeOf(HINST) do
        begin
          if GetModuleFilenameEx(LProcHandle, LModules[I], LFileName,
            SizeOf(LFileName)) > 0 then
          begin
            if CompareText(ExtractFileExt(LFileName), '.EXE') = 0 then
            begin
              Result := LFileName;
              Break;
            end;
          end;
        end;
    finally
      CloseHandle(LProcHandle);
    end;
  end;
end;

function GetExenameForProcessUsingToolhelp32(AProcessID: DWORD): string;
var
  LSnapshot  : THandle;
  LProcEntry : TProcessEntry32;
  LRet       : BOOL;
begin
  SetLastError(0);
  Result   := '';
  LSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if LSnapshot <> INVALID_HANDLE_VALUE then
    try
      LProcEntry.dwSize := SizeOf(LProcEntry);
      LRet              := Process32First(LSnapshot, LProcEntry);
      while LRet do
      begin
        if LProcEntry.th32ProcessID = AProcessID then
        begin
          Result := LProcEntry.szExeFile;
          Break;
        end
        else
          LRet := Process32Next(LSnapshot, LProcEntry);
      end;
    finally
      CloseHandle(LSnapshot);
    end;
end;

function GetExenameForProcess(AProcessID: DWORD): string;
begin
  if (Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion <= 4) then
    Result := GetExenameForProcessUsingPSAPI(AProcessID)
  else
    Result := GetExenameForProcessUsingToolhelp32(AProcessID);
  Result := ExtractFileName(Result)
end;

function GetExenameForWindow(AWndHandle: HWND): string;
var
  LProcessID: DWORD;
begin
  Result := '';
  if IsWindow(AWndHandle) then
  begin
    GetWindowThreadProcessID(AWndHandle, LProcessID);
    if LProcessID <> 0 then
      Result := GetExenameForProcess(LProcessID);
  end;
end;

function GetExePathForProcess(AProcessID: DWORD): string;
var
  hProcess: THandle;
  path: array[0..MAX_PATH - 1] of char;
begin
  hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, false, AProcessID);
  if hProcess <> 0 then
    try
      if GetModuleFileNameEx(hProcess, 0, path, MAX_PATH) = 0 then
        RaiseLastOSError;
      result := path;
    finally
      CloseHandle(hProcess)
    end
  else
    RaiseLastOSError;
end;
{$ENDREGION}

end.

{
function GetPathFromPID(const PID: cardinal): string;

end;
}
