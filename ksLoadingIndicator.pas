unit ksLoadingIndicator;

interface

uses FMX.Forms, Classes, FMX.Controls, FMX.Objects, ksTypes, FMX.Graphics,
  FMX.StdCtrls
  {$IFDEF IOS}
  , iOSapi.UIKit, iOSapi.Foundation
  {$ENDIF}
  ;

type
  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or
    {$IFDEF XE8_OR_NEWER} pidiOSDevice32 or pidiOSDevice64
    {$ELSE} pidiOSDevice {$ENDIF} or pidiOSSimulator or pidAndroid)]



  TksLoadingIndicator = class(TRectangle)
  private
    FLoadingText: string;
    FFadeBackground: Boolean;
    FIsModal: Boolean;
    FLabel: TLabel;
    procedure SetIsModal(const Value: Boolean);
  protected
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ShowLoading;
    procedure HideLoading;
  published
    property IsModal: Boolean read FIsModal write SetIsModal default False;
    property LoadingText: string read FLoadingText write FLoadingText;
    property FadeBackground: Boolean read FFadeBackground write FFadeBackground default False;
  end;


  procedure ShowLoadingIndicator(AForm: TCommonCustomForm);
  procedure HideLoadingIndicator(AForm: TCommonCustomForm);
  function IsLoadingIndicatorVisible(AForm: TCommonCustomForm): Boolean;



//procedure Register;


implementation

uses
  System.UIConsts, FMX.Types, SysUtils, Types, FMX.Ani
  {$IFDEF IOS}
  ,iOSapi.CoreGraphics, FMX.Helpers.iOS
  {$ENDIF}
  ;

var
  APos: TPointF;
  {$IFDEF IOS}
  FIndicator: UIActivityIndicatorView;
  {$ENDIF}

 (*
procedure Register;
begin
  //RegisterComponents('Kernow Software FMX', [TksLoadingIndicator]);
end;  *)



function FindLoadingIndicator(AForm: TCommonCustomForm): TksLoadingIndicator;
var
  ICount: integer;
begin
  Result := nil;
  if AForm = nil then
    Exit;
  for ICount := AForm.ComponentCount-1 downto 0 do
  begin
    if AForm.Components[ICount] is TksLoadingIndicator then
    begin
      Result := (AForm.Components[ICount] as TksLoadingIndicator);
      Exit;
    end;
  end;
end;

function IsLoadingIndicatorVisible(AForm: TCommonCustomForm): Boolean;
var
  ALoading: TksLoadingIndicator;
begin
  Result := False;
  ALoading := FindLoadingIndicator(AForm);
  if ALoading <> nil then
  begin
    if ALoading.Parent = AForm then
      Result := True;
  end;
end;

procedure ShowLoadingIndicator(AForm: TCommonCustomForm);
var
  {$IFDEF IOS}
  ACenter: NSPoint;
  {$ENDIF}
  ALoadingIndicator: TksLoadingIndicator;
begin
  {$IFDEF IOS}
  if FIndicator = nil then
  begin
      {$IFDEF IOS}
  ACenter.x := MainScreen.bounds.size.width/2;
  ACenter.y := MainScreen.bounds.size.height/2;
  FIndicator := TUIActivityIndicatorView.Alloc;
  FIndicator.initWithActivityIndicatorStyle(UIActivityIndicatorViewStyleGray);
  FIndicator.setCenter(CGPointMake(ACenter.x, ACenter.y));
  {$ENDIF}

  end;
  FIndicator.startAnimating;
  SharedApplication.keyWindow.rootViewController.view.AddSubview(FIndicator);
  Exit;
  {$ENDIF}

  ALoadingIndicator := FindLoadingIndicator(AForm);
  if ALoadingIndicator = nil then
    ALoadingIndicator := TksLoadingIndicator.Create(AForm);
  begin
    ALoadingIndicator.Position.X := (AForm.FormFactor.Width-ALoadingIndicator.Width) / 2;
    ALoadingIndicator.Position.Y := ((AForm.FormFactor.Height-ALoadingIndicator.Height) / 2)+30;
    APos.X := ALoadingIndicator.Position.X;
    APos.Y := ALoadingIndicator.Position.Y;
  end;

  AForm.AddObject(ALoadingIndicator);

  ALoadingIndicator.BringToFront;
  Application.ProcessMessages;
end;

procedure HideLoadingIndicator(AForm: TCommonCustomForm);
var
  ALoadingIndicator: TksLoadingIndicator;
begin
  {$IFDEF IOS}
  FIndicator.stopAnimating;
  FIndicator.removeFromSuperview;
  Exit;
  {$ENDIF}
  ALoadingIndicator := FindLoadingIndicator(AForm);
  //TAnimator.AnimateFloat(ALoadingIndicator, 'Opacity', 0);
  if ALoadingIndicator <> nil then
    AForm.RemoveObject(ALoadingIndicator);

end;

{ TksLoadingIndicator }

constructor TksLoadingIndicator.Create(AOwner: TComponent);
begin
  inherited;


  HitTest := False;
  FLoadingText := 'LOADING';
  FFadeBackground := False;
  FIsModal := False;
  Stroke.Kind := TBrushKind.None;
  Stroke.Color := claNull;
  Fill.Color := claBlack;
  Width := 90;
  Height := 70;
  {$IFNDEF MSWINDOWS}
  XRadius := 5;
  YRadius := 5;
  {$ENDIF}
  Opacity := 0.7;

  FLabel := TLabel.Create(Self);
  FLabel.Align := TAlignLayout.Client;
  FLabel.TextSettings.FontColor := claWhite;
  FLabel.Text := FLoadingText;
  FLabel.TextSettings.HorzAlign := TTextAlign.Center;
  FLabel.TextSettings.VertAlign := TTextAlign.Center;
  FLabel.StyledSettings := [];
  AddObject(FLabel);
end;


destructor TksLoadingIndicator.Destroy;
begin
  inherited;
end;

procedure TksLoadingIndicator.HideLoading;
begin
  HideLoadingIndicator(Owner as TForm);
end;


procedure TksLoadingIndicator.SetIsModal(const Value: Boolean);
begin
  FIsModal := Value;
end;

procedure TksLoadingIndicator.ShowLoading;
begin
  ShowLoadingIndicator(Owner as TForm);

end;

initialization

  APos := PointF(0, 0);


end.

