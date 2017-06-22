unit ksSlideMenuUI;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  ksTypes, ksVirtualListView, FMX.Effects;

type
  TfrmSlideMenuUI = class(TForm)
    ksVirtualListView1: TksVirtualListView;
    Image1: TImage;
    ShadowEffect1: TShadowEffect;
    procedure Image1Click(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  private
    FCanSelect: Boolean;
    FOnSelectItem: TksVListItemClickEvent;
    procedure Delay;
    { Private declarations }
  protected
    procedure DoShow; override;
    procedure SelectItem(Sender: TObject; AItem: TksVListItem);
  public
    procedure OpenMenu(ACallingForm: TCommonCustomForm);
    procedure CloseMenu;
    property OnSelectItem: TksVListItemClickEvent read FOnSelectItem write FOnSelectItem;
    { Public declarations }
  end;


implementation

uses FMX.Ani, ksCommon, ksSlideMenu, DateUtils;

{$R *.fmx}

{ TfrmSlideMenuUI }

procedure TfrmSlideMenuUI.Delay;
var
  ANow: TDatetime;
begin
  ANow := Now;
  while MilliSecondsBetween(ANow, Now) < 100 do
    Application.ProcessMessages;
end;

procedure TfrmSlideMenuUI.CloseMenu;
begin
  Delay;
  TAnimator.AnimateFloatWait(Image1, 'Position.X', 0, 0.2, TAnimationType.InOut, TInterpolationType.Sinusoidal);
  Visible := False;
end;

procedure TfrmSlideMenuUI.DoShow;
begin
  inherited;
  Delay;
  TAnimator.AnimateFloatWait(Image1, 'Position.X', C_DEFAULT_MENU_WIDTH, 0.2, TAnimationType.InOut, TInterpolationType.Sinusoidal);
  FCanSelect := True;
end;

procedure TfrmSlideMenuUI.FormKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkHardwareBack then
    Image1Click(Self);
  Key := 0;
end;

procedure TfrmSlideMenuUI.Image1Click(Sender: TObject);
begin
  SelectItem(Self, ksVirtualListView1.Items[ksVirtualListView1.ItemIndex]);
end;

procedure TfrmSlideMenuUI.OpenMenu(ACallingForm: TCommonCustomForm);
begin
  FCanSelect := False;
  if ksVirtualListView1.ItemIndex = -1 then
    ksVirtualListView1.ItemIndex := 0;
  ksVirtualListView1.OnItemClick := SelectItem;
  ksVirtualListView1.Width := C_DEFAULT_MENU_WIDTH;
  Image1.Bitmap := GenerateFormImageExt(ACallingForm);
  Image1.SetBounds(0, 0, ACallingForm.Width, ACallingForm.Height);


  {$IFDEF XE10_OR_NEWER}
  SetBounds(ACallingForm.Bounds);
  {$ELSE}
  SetBounds(ACallingForm.Left, ACallingForm.Top, ACallingForm.Width, ACallingForm.Height);
  {$ENDIF}


  Visible := True;
end;

procedure TfrmSlideMenuUI.SelectItem(Sender: TObject; AItem: TksVListItem);
begin
  if FCanSelect = False then
    Exit;
  FCanSelect := False;
  if Assigned(FOnSelectItem) then
    FOnSelectItem(Self, AItem);
end;

end.
