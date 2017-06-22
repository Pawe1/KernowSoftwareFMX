unit ksFormTransitionUI;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  ksFormTransition;

type
  TfrmFormTransitionUI = class(TForm)
    Image1: TImage;
    Image2: TImage;
    Fade: TRectangle;
  private

    //function GenerateFormImageExt(AForm: TCommonCustomForm): TBitmap;
    procedure Delay;
    { Private declarations }
  public
    procedure Initialise(AFrom, ATo: TCommonCustomForm);
    procedure Animate(ATransition: TksTransitionType; APop: Boolean);
    { Public declarations }
  end;

implementation

uses ksCommon, System.UIConsts, FMX.Ani, DateUtils, FMX.Platform,
  ksLoadingIndicator;

{$R *.fmx}




procedure TfrmFormTransitionUI.Delay;
var
  ANow: TDatetime;
begin
  ANow := Now;
  while MilliSecondsBetween(ANow, Now) < 100 do
    Application.ProcessMessages;
end;


procedure TfrmFormTransitionUI.Initialise(AFrom, ATo: TCommonCustomForm);
begin

  ATo.SetBounds(0, 0, AFrom.Width, AFrom.Height);
  Image1.WrapMode := TImageWrapMode.Original;
  Image2.WrapMode := TImageWrapMode.Original;
  Fade.Fill.Kind := TBrushKind.Solid;
  Fade.Fill.Color := claBlack;
  Fade.Align := TAlignLayout.Client;
  Fade.Opacity := 0;
  ATo.SetBounds(0, 0, AFrom.Width, AFrom.Height);
  Image1.Bitmap := GenerateFormImageExt(AFrom);
  Image2.Bitmap := GenerateFormImageExt(ATo);
  Fade.Opacity := 0;
  {$IFDEF MSWINDOWS}
  SetBounds(AFrom.Left, AFrom.Top, AFrom.Width, AFrom.Height);
  {$ENDIF}
end;

procedure TfrmFormTransitionUI.Animate(ATransition: TksTransitionType; APop: Boolean);
var
  w,h: single;
begin
  w := Image1.Bitmap.Width / GetScreenScale;
  h := Image1.Bitmap.Height / GetScreenScale;


  if ATransition = ksFtSlideInFromRight then
  begin
    if APop then
    begin
      Fade.Opacity := C_FADE_OPACITY;
      Image2.AddObject(Fade);
      Image2.SetBounds(0-(w/3), 0, w, h);
      Image1.SetBounds(0, 0, w, h);
      Image1.BringToFront;
      Delay;
      TAnimator.AnimateFloat(Image1, 'Position.X', w, C_TRANSITION_DURATION);
      TAnimator.AnimateFloat(Fade, 'Opacity', 0, C_TRANSITION_DURATION);
      TAnimator.AnimateFloatWait(Image2, 'Position.X', 0, C_TRANSITION_DURATION);
    end
    else
    begin
      Fade.Opacity := 0;
      Image1.AddObject(Fade);
      Image1.SetBounds(0, 0, w, h);
      Image2.SetBounds(w, 0, w, h);
      Image2.BringToFront;
      Delay;
      TAnimator.AnimateFloat(Image1, 'Position.X', 0-(w/3), C_TRANSITION_DURATION);
      TAnimator.AnimateFloat(Fade, 'Opacity', C_FADE_OPACITY, C_TRANSITION_DURATION);
      TAnimator.AnimateFloatWait(Image2, 'Position.X', 0, C_TRANSITION_DURATION);
    end;
  end;

  if ATransition = ksFtSlideInFromBottom then
  begin
    if APop then
    begin
      Fade.Opacity := C_FADE_OPACITY;
      Image2.AddObject(Fade);
      Image2.SetBounds(0, 0, w, h);
      Image1.SetBounds(0, 0, w, h);
      Image1.BringToFront;
      Delay;
      TAnimator.AnimateFloat(Fade, 'Opacity', 0, C_TRANSITION_DURATION);
      TAnimator.AnimateFloatWait(Image1, 'Position.Y', h, C_TRANSITION_DURATION);
    end
    else
    begin
      Fade.Opacity := 0;
      Image1.AddObject(Fade);
      Image1.SetBounds(0, 0, w, h);
      Image2.SetBounds(0, h, w, h);
      Image2.BringToFront;
      Delay;
      TAnimator.AnimateFloat(Fade, 'Opacity', C_FADE_OPACITY, C_TRANSITION_DURATION);
      TAnimator.AnimateFloatWait(Image2, 'Position.Y', 0, C_TRANSITION_DURATION);
    end;
  end;

  if ATransition = ksFtSlideInFromLeft then
  begin
    if APop then
    begin
      Fade.Opacity := C_FADE_OPACITY;
      Image2.AddObject(Fade);
      Image2.SetBounds((w/3), 0, w, h);
      Image1.SetBounds(0, 0, w, h);
      Image1.BringToFront;
      Delay;
      TAnimator.AnimateFloat(Image1, 'Position.X', 0-w, C_TRANSITION_DURATION);
      TAnimator.AnimateFloat(Fade, 'Opacity', 0, C_TRANSITION_DURATION);
      TAnimator.AnimateFloatWait(Image2, 'Position.X', 0, C_TRANSITION_DURATION);
    end
    else
    begin
      Fade.Opacity := 0;
      Image1.AddObject(Fade);
      Image1.SetBounds(0, 0, w, h);
      Image2.SetBounds(0-w, 0, w, h);
      Image2.BringToFront;
      Delay;
      TAnimator.AnimateFloat(Image1, 'Position.X', (w/3), C_TRANSITION_DURATION);
      TAnimator.AnimateFloat(Fade, 'Opacity', C_FADE_OPACITY, C_TRANSITION_DURATION);
      TAnimator.AnimateFloatWait(Image2, 'Position.X', 0, C_TRANSITION_DURATION);
    end;
  end;

  if ATransition = ksFtSlideInFromTop then
  begin
    if APop then
    begin
      Fade.Opacity := C_FADE_OPACITY;
      Image2.AddObject(Fade);
      Image2.SetBounds(0, 0, w, h);
      Image1.SetBounds(0, 0, w, h);
      Image1.BringToFront;
      Delay;
      TAnimator.AnimateFloat(Fade, 'Opacity', 0, C_TRANSITION_DURATION);
      TAnimator.AnimateFloatWait(Image1, 'Position.Y', 0-h, C_TRANSITION_DURATION);
    end
    else
    begin
      Fade.Opacity := 0;
      Image1.AddObject(Fade);
      Image1.SetBounds(0, 0, w, h);
      Image2.SetBounds(0, 0-h, w, h);
      Image2.BringToFront;
      Delay;
      TAnimator.AnimateFloat(Fade, 'Opacity', C_FADE_OPACITY, C_TRANSITION_DURATION);
      TAnimator.AnimateFloatWait(Image2, 'Position.Y', 0, C_TRANSITION_DURATION);
    end;
  end;


end;

end.
