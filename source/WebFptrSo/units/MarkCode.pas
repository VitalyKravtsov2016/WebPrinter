unit MarkCode;

interface

uses
  // VCL
  SysUtils,
  // Opos
  OposException,
  // This
  RegExpr;

procedure CheckMarkCode(const MarkCode: AnsiString);
function ValidMarkCode(const MarkCode: AnsiString): Boolean;
function GetMarkCode(const MarkCode: AnsiString): AnsiString;

implementation

function FindRegExpr(const ARegExpr, AInputStr: AnsiString;
  var S: AnsiString): Boolean;
var
  R: TRegExpr;
begin
  S := AInputStr;
  R := TRegExpr.Create;
  try
    R.Expression := ARegExpr;
    Result := R.Exec (AInputStr);
    if Result then
      S := Copy(AInputStr, 1, R.MatchLen[0]);
  finally
    R.Free;
  end;
end;

function ValidMarkCode(const MarkCode: AnsiString): Boolean;
var
  L: Integer;
  S1, S2: AnsiString;
begin
  S1 := StringReplace(MarkCode, #$1D, '', [rfReplaceAll, rfIgnoreCase]);
  Result := FindRegExpr('^01[0-9]{14}', S1, S2);
  if not Result then
  begin
    L := Length(S1);
    if L > 14 then L := 14;
    Result := FindRegExpr(Format('^[0-9]{%d}', [L]), S1, S2);
  end;
end;

procedure CheckMarkCode(const MarkCode: AnsiString);
begin
  if not ValidMarkCode(MarkCode) then
    raiseIllegalError('Invalid markcode, ' + MarkCode);
end;

function GetMarkCode(const MarkCode: AnsiString): AnsiString;
var
  S: AnsiString;
begin
  Result := StringReplace(MarkCode, #$1D, '', [rfReplaceAll, rfIgnoreCase]);
  if FindRegExpr('^01[0-9]{14}', Result, S) then
  begin
    if FindRegExpr('^01[0-9]{14}21.{7,20}93', Result, S) or
      FindRegExpr('^01[0-9]{14}21.{7,20}91', Result, S) then
    begin
      Result := Copy(S, 1, Length(S)-2);
    end;
  end else
  begin
    Result := Copy(Result, 1, 21);
    if Length(Result) < 14 then
      Result := StringOfChar('0', 14-Length(Result)) + Result;
  end;
end;

end.
