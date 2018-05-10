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

unit DDuce.Logger.Interfaces;

interface

uses
  System.Classes, System.Rtti, System.SysUtils, System.Types, System.UITypes,
  Vcl.Menus, Vcl.Graphics,

  Spring.Collections;

type
  { Remark: Enumerated types with explicitly assigned ordinality don't have RTTI
    generated for them. Enumerated constants without a specific value however
    do have RTTI.}
  TLogMessageType = (
    lmtInfo        = 0,
    lmtError       = 1,
    lmtWarning     = 2,
    lmtValue       = 3,
    lmtEnterMethod = 4,
    lmtLeaveMethod = 5,
    lmtConditional = 6,
    lmtCheckpoint  = 7,
    lmtStrings     = 8,   // TStrings and descendants
    lmtCallStack   = 9,   // not supported yet
    lmtComponent   = 10,
    lmtException   = 11,
    lmtBitmap      = 12,
    lmtHeapInfo    = 13,  // not supported yet
    lmtMemory      = 14,
    lmtCustomData  = 15,  // not supported yet
    lmtWatch       = 20,
    lmtCounter     = 21,
    lmtColor       = 22,
    lmtAlphaColor  = 23,
    lmtScreenShot  = 24,  // not supported yet
    lmtText        = 25,  // arbitrary text with optional highlighter info
    lmtClear       = 99
  );

  ILogger = interface;

  TLogMessage = packed record
    MsgType   : Integer;     // TLogMessageType
    TimeStamp : TDateTime;
    Text      : UTF8String;
    Data      : TStream;
  end;

  (*
    ProcessId                  source process Id (WinIPC, WinODS)
    ThreadId
    IpAddress                  source IP address (ZeroMQ)

  *)


  TCustomDataCallbackMethod = function(
    ASender     : ILogger;
    AData       : TValue;
    var ADoSend : Boolean
  ): string of object;

  TCustomDataCallbackFunction = function(
    ASender     : ILogger;
    AData       : TValue;
    var ADoSend : Boolean
  ): string;

  ILogChannel = interface
  ['{FDE37401-BB4F-4362-863A-CCCCF9228BD9}']
    function GetActive: Boolean;
    procedure SetActive(const Value: Boolean);
    function GetConnected: Boolean;
    procedure SetConnected(const Value: Boolean);

    function Write(const AMsg: TLogMessage): Boolean;
    function Connect: Boolean;
    function Disconnect: Boolean;

    property Active: Boolean
      read GetActive write SetActive;

    { True when the channel is connected with the server (or receiving)
      instance. }
    property Connected: Boolean
      read GetConnected write SetConnected;
  end;

  TChannelList = IList<ILogChannel>;

  // TODO send TTimeSpan
  //      send stream?
  //      send file

  ILogger = interface(IInterface)
  ['{28E9BADE-6B42-4399-8867-1CA115576E40}']
    function GetChannels: TChannelList;

    procedure Send(const AName: string; const AArgs: array of const); overload;

    procedure Send(const AName: string; const AValue: string = ''); overload;

    { These three overloads are here because TValue would cast them implicitely
      to string (and we would lose type information of AValue) }
    procedure Send(const AName: string; const AValue: AnsiString); overload;
    procedure Send(const AName: string; const AValue: WideString); overload;
    procedure Send(const AName: string; const AValue: ShortString); overload;

    //procedure Send(const AName: string; const AValue: Cardinal); overload;

    { All primary types that can implicitely be casted to TValue will be
      handled through this call. }

    { These are (tested):
       Boolean
       Integer
       Int64
       Single
       Double
       Extended
       string
    }
    procedure Send(const AName: string; const AValue: TValue); overload;

    { Send methods for types that do not have an implicit cast to TValue
      These are equivalent to Send(AName, TValue.From(AValue)); }
    procedure SendDateTime(const AName: string; AValue: TDateTime);
    procedure SendDate(const AName: string; AValue: TDate);
    procedure SendTime(const AName: string; AValue: TTime);

    { Send methods for types that need a custom representation. }
    procedure SendColor(const AName: string; AColor: TColor);
    procedure SendAlphaColor(const AName: string; AAlphaColor: TAlphaColor);
    procedure SendObject(const AName: string; AValue: TObject);
    procedure SendInterface(const AName: string; AValue: IInterface);
    procedure SendRect(const AName: string; const AValue: TRect);
    procedure SendPoint(const AName: string; const APoint: TPoint);
    procedure SendStrings(const AName: string; AValue: TStrings);
    //TODO procedure SendPersistent(const AName: string; AValue: TPersistent); -> log published properties
    procedure SendComponent(const AName: string; AValue: TComponent);
    procedure SendPointer(const AName: string; APointer: Pointer);
    procedure SendException(const AName: string; AException: Exception);
    procedure SendBitmap(const AName: string; ABitmap: TBitmap);
    procedure SendMemory(
      const AName: string;
      AAddress   : Pointer;
      ASize      : LongWord
    );
    procedure SendShortCut(const AName: string; AShortCut: TShortCut);

    procedure SendVariant(const AName: string; const AValue: Variant);

    // SendBitmap

    { Send methods for text that can be displayed with a dedicated
      highlighter. }
    procedure SendText(
      const AName        : string;
      const AText        : string;
      const AHighlighter : string = ''
    );

    procedure IncCounter(const AName: string);
    procedure DecCounter(const AName: string);
    procedure ResetCounter(const AName: string);
    function GetCounter(const AName: string): Integer;

    procedure Enter(const AName: string); overload;
    procedure Enter(ASender: TObject; const AName: string); overload;
    procedure Leave(const AName: string); overload;
    procedure Leave(ASender: TObject; const AName: string); overload;
    { Track uses an interface variable to replace Enter/Leave calls in the
      scope of the method where it is called. A call to Track will create an
      instance and trigger the Enter method. When the interface variable goes
      out of scope (end of the routine or method) a call to the logger's Leave
      method is triggered. }
    function Track(const AName: string): IInterface; overload;
    function Track(ASender: TObject; const AName: string): IInterface; overload;

    procedure AddCheckPoint(const AName: string = '');
    procedure ResetCheckPoint(const AName: string = '');

    { Monitors a named value in the LogViewer application }
    procedure Watch(const AName: string; const AValue: TValue); overload;
    procedure Watch(const AName: string; const AValue: string = ''); overload;
    procedure Watch(const AName: string; const AValue: AnsiString); overload;

    procedure Warn(const AText: string); overload;
    procedure Warn(
      const AText : string;
      const AArgs : array of const
    ); overload;
    procedure Error(const AText: string); overload;
    procedure Error(
      const AText : string;
      const AArgs : array of const
    ); overload;
    procedure Info(const AText: string); overload;
    procedure Info(
      const AText: string;
      const AArgs: array of const
    ); overload;

    procedure SendIf(
      const AText : string;
      AExpression : Boolean;
      AIsTrue     : Boolean = True
    );
    { Sends out a dedicated message to clear the logviewer contents. }
    procedure Clear;

    property Channels: TChannelList
      read GetChannels;
  end;

const
  LOG_PREFIXES: array [lmtInfo..lmtCounter] of string = (
    'INFO',
    'ERROR',
    'WARNING',
    'VALUE',
    '>>ENTER METHOD',
    '<<LEAVE METHOD',
    'CONDITIONAL',
    'CHECKPOINT',
    'STRINGS',
    'CALL STACK',
    'OBJECT',
    'EXCEPTION',
    'BITMAP',
    'HEAP INFO',
    'MEMORY',
    '',
    '',
    '',
    '',
    '',
    'WATCH',
    'COUNTER'
  );

function LogMessageTypeNameOf(ALogMessageType: TLogMessageType): string;

implementation

{$REGION 'interfaced routines'}
function LogMessageTypeNameOf(ALogMessageType: TLogMessageType): string;
var
  S : string;
begin
  case ALogMessageType of
    lmtInfo        : S := 'lmtInfo';
    lmtError       : S := 'lmtError' ;
    lmtWarning     : S := 'lmtWaring';
    lmtValue       : S := 'lmtValue';
    lmtEnterMethod : S := 'lmtEnterMethod';
    lmtLeaveMethod : S := 'lmtLeaveMethod';
    lmtConditional : S := 'lmtConditional';
    lmtCheckpoint  : S := 'lmtCheckpoint';
    lmtStrings     : S := 'lmtStrings';
    lmtCallStack   : S := 'lmtCallStack';
    lmtComponent   : S := 'lmtComponent';
    lmtException   : S := 'lmtException';
    lmtBitmap      : S := 'lmtBitmap';
    lmtHeapInfo    : S := 'lmtHeapInfo';
    lmtMemory      : S := 'lmtMemory';
    lmtCustomData  : S := 'lmtCustomData';
    lmtWatch       : S := 'lmtWatch';
    lmtCounter     : S := 'lmtCounter';
    lmtColor       : S := 'lmtColor';
    lmtAlphaColor  : S := 'lmtAlphaColor';
    lmtScreenShot  : S := 'lmtScreenShot';
    lmtText        : S := 'lmtText';
    lmtClear       : S := 'lmtClear';
  else
    S := '';
  end;
  Result := S;
end;
{$ENDREGION}

end.
