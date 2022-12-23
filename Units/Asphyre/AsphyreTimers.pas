unit AsphyreTimers;
//---------------------------------------------------------------------------
// AsphyreTimers.pas                                    Modified: 01-Jan-2006
// Processing-independent Timer                                   Version 3.1
//---------------------------------------------------------------------------
// Changes since v2.0:
//
//   * Working internally with latency instead of frame-rate, giving much
//     higher accuracy and avoiding some division problems.
//   * Changed event name from OnRender to OnTimer, to avoid confusion
//     with TAsphyreDevice events.
//   + Added MaxFPS property which will limit OnTimer occurence to certain
//     fixed speed. This is useful to prevent the application using all
//     system's resources just to render a scene like 1000 FPS, which is
//     not necessary anyway.
//   * Changed Speed type to floating-point. This allows choosing fractional
//     processing speeds like "74.2".
//   * Changed MayRender property name to Enabled.
//   + Added Precision property which will inform the user about the
//     precision system used.
//   + Added Delta property which informs the actual ratio between running
//     speed (OnTimer event) and the specified one in Speed property.
//   + Added Latency property, which informs the time elapsed since
//     previous OnTimer event (in milliseconds).
//
// Changes since v3.0:
//
//   * Using 12:20 fixed-point instead of floating-point numbers now, which
//     reduces the consequential errors and prevents any unnecessary jumps
//     in OnProcess event.
//   - Removed Theta parameter from Process() function, because it wasn't of
//     much use and it doesn't work well with fixed-point math.
//
//---------------------------------------------------------------------------
// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Windows, SysUtils, Classes, Forms, Math;

//---------------------------------------------------------------------------
type
 TPerformancePrecision = (ppLow, ppHigh);

//---------------------------------------------------------------------------
 TAsphyreTimer = class(TComponent)
 private
  FMaxFPS : Integer;
  FSpeed  : Real;
  FEnabled: Boolean;
  FOnTimer: TNotifyEvent;

  FFrameRate: Integer;

  FPrecision : TPerformancePrecision;
  PrevTime  : Cardinal;
  PrevTime64: Int64;
  FOnProcess: TNotifyEvent;
  Processed : Boolean;

  LatencyFP : Integer;
  DeltaFP   : Integer;
  HighFreq  : Int64;
  MinLatency: Integer;
  SpeedLatcy: Integer;
  FixedDelta: Integer;

  SampleLatency: Integer;
  SampleIndex: Integer;

  function RetreiveLatency(): Integer;
  procedure AppIdle(Sender: TObject; var Done: Boolean);
  procedure SetSpeed(const Value: Real);
  procedure SetMaxFPS(const Value: Integer);
  function GetDelta(): Real;
  function GetLatency(): Real;
 public
  property Delta  : Real read GetDelta;
  property Latency: Real read GetLatency;
  property FrameRate: Integer read FFrameRate;

  procedure Process();

  constructor Create(AOwner: TComponent); override;
 published
  // The speed at which processing will be made.
  property Speed: Real read FSpeed write SetSpeed;
  // The maximum allowed frame rate.
  property MaxFPS: Integer read FMaxFPS write SetMaxFPS;
  // Whether this timer is active or not.
  property Enabled: Boolean read FEnabled write FEnabled;
  // The precision of timer's calculations.
  property Precision: TPerformancePrecision read FPrecision;

  property OnTimer: TNotifyEvent read FOnTimer write FOnTimer;
  property OnProcess: TNotifyEvent read FOnProcess write FOnProcess;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 FixedHigh = $100000;
 DeltaLimit = 32 * FixedHigh;

//---------------------------------------------------------------------------
constructor TAsphyreTimer.Create(AOwner: TComponent);
begin
 inherited;

 Speed := 60.0;
 MaxFPS:= 100;

 FPrecision:= ppLow;
 if (QueryPerformanceFrequency(HighFreq)) then FPrecision:= ppHigh;

 if (not (csDesigning in ComponentState)) then
  begin
   if (FPrecision = ppHigh) then
    QueryPerformanceCounter(PrevTime64) else PrevTime:= GetTickCount;

   Application.OnIdle:= AppIdle;
  end;

 FixedDelta := 0;
 FFrameRate := 0;
 SampleLatency:= 0;
 SampleIndex  := 0;
 Processed    := False;
end;

//---------------------------------------------------------------------------
procedure TAsphyreTimer.SetSpeed(const Value: Real);
begin
 FSpeed:= Value;
 if (FSpeed < 1.0) then FSpeed:= 1.0;
 SpeedLatcy:= Round(FixedHigh * 1000.0 / FSpeed);
end;

//---------------------------------------------------------------------------
procedure TAsphyreTimer.SetMaxFPS(const Value: Integer);
begin
 FMaxFPS:= Value;
 if (FMaxFPS < 1) then FMaxFPS:= 1;
 MinLatency:= Round(FixedHigh * 1000.0 / FMaxFPS);
end;

//---------------------------------------------------------------------------
function TAsphyreTimer.GetDelta(): Real;
begin
 Result:= DeltaFP / FixedHigh;
end;

//---------------------------------------------------------------------------
function TAsphyreTimer.GetLatency(): Real;
begin
 Result:= LatencyFP / FixedHigh;
end;

//---------------------------------------------------------------------------
function TAsphyreTimer.RetreiveLatency(): Integer;
var
 CurTime  : Cardinal;
 CurTime64: Int64;
begin
 if (FPrecision = ppHigh) then
  begin
   QueryPerformanceCounter(CurTime64);
   Result:= ((CurTime64 - PrevTime64) * FixedHigh * 1000) div HighFreq;
   PrevTime64:= CurTime64;
  end else
  begin
   CurTime := GetTickCount;
   Result  := (CurTime - PrevTime) * FixedHigh;
   PrevTime:= CurTime;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreTimer.AppIdle(Sender: TObject; var Done: Boolean);
var
 WaitAmount: Integer;
 SampleMax : Integer;
begin
 Done:= False;
                
 // (1) Retreive current latency.
 LatencyFP:= RetreiveLatency();

 // (2) If Timer is disabled, wait a little to avoid using 100% of CPU.
 if (not FEnabled) then
  begin
   SleepEx(5, True);
   Exit;
  end;

 // (3) Adjust to maximum FPS, if necessary.
 if (LatencyFP < MinLatency) then
  begin
   WaitAmount:= (MinLatency - LatencyFP) div FixedHigh;
   SleepEx(WaitAmount, True);
  end else WaitAmount:= 0;

 // (4) The running speed ratio.
 DeltaFP:= (Int64(LatencyFP) * FixedHigh) div SpeedLatcy;
 // -> provide Delta limit to prevent auto-loop lockup.
 if (DeltaFP > DeltaLimit) then DeltaFP:= DeltaLimit;

 // (5) Calculate Frame Rate every second.
 SampleLatency:= SampleLatency + LatencyFP + (WaitAmount * FixedHigh);
 if (LatencyFP <= 0) then SampleMax:= 4
  else SampleMax:= (Int64(FixedHigh) * 1000) div LatencyFP;

 Inc(SampleIndex);
 if (SampleIndex >= SampleMax) then
  begin
   FFrameRate   := (Int64(SampleIndex) * FixedHigh * 1000) div SampleLatency;
   SampleLatency:= 0;
   SampleIndex  := 0;
  end;

 // (6) Increase processing queque, if processing was made last time.
 if (Processed) then
  begin
   Inc(FixedDelta, DeltaFP);
   Processed:= False;
  end;

 // (7) Call timer event.
 if (Assigned(FOnTimer)) then FOnTimer(Self);
end;

//---------------------------------------------------------------------------
procedure TAsphyreTimer.Process();
var
 i, Amount: Integer;
begin
 Processed:= True;

 Amount:= FixedDelta div FixedHigh;
 if (Amount < 1) then Exit;

 if (Assigned(FOnProcess)) then
  for i:= 1 to Amount do
   FOnProcess(Self);

 FixedDelta:= FixedDelta and (FixedHigh - 1);  
end;

//---------------------------------------------------------------------------
end.

