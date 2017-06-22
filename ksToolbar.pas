{*******************************************************************************
*                                                                              *
*  TkToolbar - Toolbar with form stack/transitions awareness                   *
*                                                                              *
*  https://github.com/gmurt/KernowSoftwareFMX                                  *
*                                                                              *
*  Copyright 2017 Graham Murt                                                  *
*                                                                              *
*  email: graham@kernow-software.co.uk                                         *
*                                                                              *
*  Licensed under the Apache License, Version 2.0 (the "License");             *
*  you may not use this file except in compliance with the License.            *
*  You may obtain a copy of the License at                                     *
*                                                                              *
*    http://www.apache.org/licenses/LICENSE-2.0                                *
*                                                                              *
*  Unless required by applicable law or agreed to in writing, software         *
*  distributed under the License is distributed on an "AS IS" BASIS,           *
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    *
*  See the License for the specific language governing permissions and         *
*  limitations under the License.                                              *
*                                                                              *
*******************************************************************************}

unit ksToolBar;

interface

{$I ksComponents.inc}


uses Classes, FMX.StdCtrls, FMX.Graphics, ksTypes, FMX.Objects, FMX.Types,
  System.UITypes, System.UIConsts, ksSpeedButton, ksFormTransition,
  FMX.Controls.Presentation, FMX.Controls, System.Types;

type
 // TksToolbar = class;

  {IksToolbar = interface
  ['{42609FB8-4DE0-472F-B49C-A6CD636A530D}//]
    //procedure SetTransition(ATransition: TksTransitionType);
  //end;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or
    {$IFDEF XE8_OR_NEWER} pidiOSDevice32 or pidiOSDevice64
    {$ELSE} pidiOSDevice {$ENDIF} or pidiOSSimulator or pidAndroid)]
  TksToolbar = class(TPresentedControl)
  private
    FTintColor: TAlphaColor;
    FFont: TFont;
    FTextColor: TAlphaColor;
    FText: string;
    FMouseDown: Boolean;
    FFormTransition: TksFormTransition;
    FOnMenuButtonClick: TNotifyEvent;
    FShowMenuButton: Boolean;
    FOnBackButtonClick: TNotifyEvent;
    FBackButtonEnabled: Boolean;
    FShowBackButton: Boolean;
    procedure Changed(Sender: TObject);
    procedure BackButtonClicked;
    procedure SetShowMenuButton(const Value: Boolean);
    procedure SetTintColor(const Value: TAlphaColor);
    procedure SetTextColor(const Value: TAlphaColor);
    procedure SetText(const Value: string);
    procedure SetFont(const Value: TFont);
    function GetButtonOpacity: single;
    procedure SetShowBackButton(const Value: Boolean);
  protected
    procedure Paint; override;
    function GetDefaultSize: TSizeF; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure DoMouseLeave; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DisableBackButton;
    procedure EnableBackButton;
  published
    property Font: TFont read FFont write SetFont;
    property Text: string read FText write SetText;
    property Size;
    property TabOrder;

    property TintColor: TAlphaColor read FTintColor write SetTintColor default claWhitesmoke;
    property TextColor: TAlphaColor read FTextColor write SetTextColor default claBlack;
    property ShowMenuButton: Boolean read FShowMenuButton write SetShowMenuButton default True;
    property ShowBackButton: Boolean read FShowBackButton write SetShowBackButton default True;


    property OnClick;
    property OnMenuButtonClick: TNotifyEvent read FOnMenuButtonClick write FOnMenuButtonClick;
    property OnBackButtonClick: TNotifyEvent read FOnBackButtonClick write FOnBackButtonClick;
  end;


  procedure Register;

implementation

uses Math, System.TypInfo, ksCommon, SysUtils, ksPickers,
  Fmx.Forms, FMX.Platform;

procedure Register;
begin
  RegisterComponents('Kernow Software FMX', [TksToolbar]);
end;


{ TksToolbar }

procedure TksToolbar.BackButtonClicked;
begin
  PickerService.HidePickers;
  HideKeyboard;
  Application.ProcessMessages;

  if FFormTransition.GetFormDepth(Root as TCommonCustomForm) = 0 then
  begin
    if (Assigned(FOnMenuButtonClick)) and (FShowMenuButton) then
      FOnMenuButtonClick(Self);
  end
  else
  begin
    if (Assigned(FOnBackButtonClick))and (FShowBackButton)  then
      FOnBackButtonClick(Self);
    FFormTransition.Pop;
  end;
end;

procedure TksToolbar.Changed(Sender: TObject);
begin
  InvalidateRect(ClipRect);
end;

constructor TksToolbar.Create(AOwner: TComponent);
begin
  inherited;
  FFont := TFont.Create;
  FFont.Size := 14;
  Align := TAlignLayout.MostTop;
  FFormTransition := TksFormTransition.Create(nil);

  FTintColor := claWhitesmoke;
  FTextColor := claBlack;
  FMouseDown := False;

  FFont.OnChanged := Changed;

  FShowMenuButton := True;
  FShowBackButton := True;
  FBackButtonEnabled := True;
end;

destructor TksToolbar.Destroy;
begin
  FreeAndNil(FFormTransition);
  //FreeAndNil(FMenuBmp);
  //FreeAndNil(FBackBmp);
  FreeAndNil(FFont);
  inherited;
end;

procedure TksToolbar.DisableBackButton;
begin
  FBackButtonEnabled := False;
end;

procedure TksToolbar.DoMouseLeave;
begin
  inherited;
  FMouseDown := False;
  InvalidateRect(ClipRect);
end;

procedure TksToolbar.EnableBackButton;
begin
  FBackButtonEnabled := True;
end;

function TksToolbar.GetButtonOpacity: single;
begin
  Result := 1;
  if FMouseDown then
    Result := 0.5;
end;

function TksToolbar.GetDefaultSize: TSizeF;
begin
  Result := TSizeF.Create(120, 44);
end;

procedure TksToolbar.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Single);
begin
  inherited;
  FMouseDown := X < 30;
  if FMouseDown then
  begin
    if FBackButtonEnabled = False then
      Exit;
    InvalidateRect(ClipRect);
    Application.ProcessMessages;
  end;
end;

procedure TksToolbar.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Single);
begin
  inherited;
  if FMouseDown then
  begin
    FMouseDown := False;
    InvalidateRect(ClipRect);
    Application.ProcessMessages;

    TThread.Synchronize (TThread.CurrentThread,
      procedure ()
      begin
        BackButtonClicked;
      end);

  end;
end;

procedure TksToolbar.Paint;
var
  ABmp: TBitmap;
  s: single;
begin
  inherited;
  ABmp := nil;
  s := GetScreenScale(False);

  if (csDesigning in ComponentState) then
    ABmp := AAccessories.GetAccessoryImage(TksAccessoryType.atDetails)
  else
  begin
    if (FFormTransition.GetFormDepth(Root as TCommonCustomForm) = 0) then
    begin
      if (FShowMenuButton) then
        ABmp := AAccessories.GetAccessoryImage(TksAccessoryType.atDetails);
    end
    else
      if FShowBackButton then
        ABmp := AAccessories.GetAccessoryImage(TksAccessoryType.atArrowLeft);
  end;



  Canvas.BeginScene;
  try
    Canvas.Fill.Color := FTintColor;
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.FillRect(ClipRect, 0, 0, AllCorners, 1);

    Canvas.Font.Assign(FFont);
    Canvas.Fill.Color := FTextColor;
    Canvas.FillText(ClipRect, FText, False, 1, [], TTextAlign.Center);

    if ABmp <> nil then
    begin
      ReplaceOpaqueColor(ABmp, FTextColor);
      Canvas.DrawBitmap(ABmp,
                        RectF(0, 0, ABmp.Width, ABmp.Height),
                        RectF(4, (Height/2)-((ABmp.Height/s)/2), 4+(ABmp.Width/s), (Height/2)+((ABmp.Height/s)/2)),
                        GetButtonOpacity);
    end;

  finally
    Canvas.EndScene;
  end;
end;

procedure TksToolbar.SetFont(const Value: TFont);
begin
  FFont.Assign(Value);
end;

procedure TksToolbar.SetShowBackButton(const Value: Boolean);
begin
  FShowBackButton := Value;
  //InvalidateRect(ClipRect);
end;

procedure TksToolbar.SetShowMenuButton(const Value: Boolean);
begin
  FShowMenuButton := Value;
  //InvalidateRect(ClipRect);
end;

procedure TksToolbar.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    InvalidateRect(ClipRect);
  end;
end;

procedure TksToolbar.SetTextColor(const Value: TAlphaColor);
begin
  FTextColor := Value;
end;

procedure TksToolbar.SetTintColor(const Value: TAlphaColor);
begin
  if FTintColor <> Value then
  begin
    FTintColor := Value;
    Repaint;
  end;
end;

initialization

  Classes.RegisterClass(TksToolbar);

end.
